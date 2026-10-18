//! The core loop — the single point that consumes [`Event`]s and coordinates
//! the line editor, the backend, and the renderer.
//!
//! Topology (the D-01 shape, with only the pieces this PoC needs):
//!
//! ```text
//!   input thread ─┐                         ┌─► Renderer (stdout)
//!   (reedline)    ├─► [event channel] ─► core loop ─┤
//!   backend task ─┘                         └─► pulse ─► input thread
//!                  ▲                         │
//!                  └────── command channel ◄─┘
//! ```
//!
//! The cadence is strictly turn-based, so no output ever races the prompt:
//! grant a turn → user submits a line → forward it to the backend → render the
//! backend's frames → on `BackendIdle`, grant the next turn. Building it on a
//! message-driven channel (rather than a straight read→eval→print call stack)
//! is what keeps the asynchronous futures — streamed output, a child-down
//! signal, an interrupt — *reachable* without reshaping the loop.

use std::sync::mpsc as std_mpsc;

use tokio::sync::mpsc as tokio_mpsc;
use tokio::task::JoinHandle;

use crate::backend::Backend;
use crate::error::Result;
use crate::event::{Event, OutputFrame};
use crate::input;
use crate::render::Renderer;

/// Bound on the event channel. Bounded for backpressure (CA-39); a REPL has a
/// human at one end, so this is generous.
const EVENT_CAPACITY: usize = 256;

/// Bound on the command channel (core → backend). One in flight at a time in
/// the PoC's turn-based cadence; the slack is headroom for G-01/G-02.
const COMMAND_CAPACITY: usize = 32;

/// A unit of work handed to the backend task.
#[derive(Debug)]
struct Command {
    eval_id: u64,
    line: String,
}

/// Run the REPL to completion, driving `backend` as the response source.
///
/// Returns once the user quits (a quit verb, or Ctrl-D), once input fails, or
/// once a peer task disappears. On return, the backend task has been awaited
/// and the line-editor thread joined, so the terminal is restored.
///
/// # Errors
///
/// Currently infallible in practice (the loop handles its own peer failures by
/// shutting down cleanly), but returns [`Result`] so that error propagation can
/// be added — for transport or child-process failures — without an API change.
pub async fn run<B: Backend>(backend: B) -> Result<()> {
    let (event_tx, mut event_rx) = tokio_mpsc::channel::<Event>(EVENT_CAPACITY);
    let (command_tx, command_rx) = tokio_mpsc::channel::<Command>(COMMAND_CAPACITY);
    let (pulse_tx, pulse_rx) = std_mpsc::channel::<()>();

    // The banner is the one bit of output we read off the backend before it
    // moves into its task.
    let banner = backend.banner();
    let backend_task = spawn_backend(backend, command_rx, event_tx.clone());
    // `event_tx` is *moved* into the input thread here, leaving only the
    // backend task's clone. Once both peers stop, every sender is dropped.
    let input_handle = input::spawn(event_tx, pulse_rx);

    let mut renderer = Renderer::new();
    for frame in &banner {
        renderer.render(frame);
    }

    let mut eval_id: u64 = 0;

    // Grant the first turn. If the input thread never came up, fall straight
    // through to teardown.
    if pulse_tx.send(()).is_ok() {
        while let Some(event) = event_rx.recv().await {
            match event {
                Event::Input(line) => {
                    let trimmed = line.trim();
                    if trimmed.is_empty() {
                        // Nothing to evaluate; just re-prompt.
                        if pulse_tx.send(()).is_err() {
                            break;
                        }
                    } else if is_quit(trimmed) {
                        break;
                    } else {
                        eval_id += 1;
                        let command = Command {
                            eval_id,
                            line: trimmed.to_owned(),
                        };
                        // Wait for the backend to reply (BackendIdle) before
                        // prompting again — do not pulse here.
                        if command_tx.send(command).await.is_err() {
                            break; // backend task is gone.
                        }
                    }
                }
                Event::Output(frame) => renderer.render(&frame),
                Event::BackendIdle | Event::CancelLine => {
                    if pulse_tx.send(()).is_err() {
                        break;
                    }
                }
                Event::Eof => break,
                Event::InputError(message) => {
                    renderer.render(&OutputFrame::meta(0, format!("input error: {message}")));
                    break;
                }
            }
        }
    }

    // Teardown. Dropping the senders unblocks the peers: the backend task's
    // `recv` returns `None`, and the input thread's pulse `recv` returns `Err`.
    // (When we reach here the input thread is either already exiting — EOF /
    // error — or parked on the pulse after a quit verb, never mid-`read_line`,
    // so the join cannot hang.) The ignored results are the documented
    // shutdown boundary (CA-07).
    drop(command_tx);
    drop(pulse_tx);
    let _ = backend_task.await;
    let _ = input_handle.join();
    Ok(())
}

/// Spawn the backend on its own task: drain commands, turn each into frames,
/// and signal end-of-turn. This is the stand-in for the protocol-client task.
fn spawn_backend<B: Backend>(
    mut backend: B,
    mut commands: tokio_mpsc::Receiver<Command>,
    events: tokio_mpsc::Sender<Event>,
) -> JoinHandle<()> {
    tokio::spawn(async move {
        while let Some(command) = commands.recv().await {
            for frame in backend.handle(command.eval_id, &command.line) {
                if events.send(Event::Output(frame)).await.is_err() {
                    return; // core gone; stop.
                }
            }
            if events.send(Event::BackendIdle).await.is_err() {
                return;
            }
        }
    })
}

/// Loop-level control verbs. Quitting the REPL is the core's concern, not the
/// backend's — the backend is only a response source.
fn is_quit(line: &str) -> bool {
    matches!(
        line.trim().to_ascii_lowercase().as_str(),
        "quit" | "exit" | ":q" | ":quit"
    )
}
