//! The line editor, wrapped as an input *event source*.
//!
//! reedline's [`read_line`](reedline::Reedline::read_line) is a **blocking**
//! call that owns the terminal while it runs, so it cannot live on the async
//! runtime (blocking a tokio worker stalls every task on it — AP-50). Instead
//! it gets a dedicated OS thread that owns the [`Reedline`] instance for its
//! whole life and bridges into the async world two ways:
//!
//! * it **emits** [`Event`]s onto the tokio channel via `blocking_send`;
//! * it **waits** for a `()` "your turn" pulse from the core before each read,
//!   so output always lands between prompts. That is Model A's request/response
//!   cadence expressed on a message-driven core — no arm-while-editing buffer
//!   is needed yet (that is the deferred G-01 work).
//!
//! Calling `blocking_send` here is correct *precisely because* this is a plain
//! `std::thread`, not a runtime worker — `blocking_send` panics if called from
//! within an async context.

use std::sync::mpsc::Receiver as PulseReceiver;
use std::thread::{self, JoinHandle};

use reedline::{DefaultPrompt, Reedline, Signal};
use tokio::sync::mpsc::Sender as EventSender;

use crate::event::Event;

/// Spawn the line-editor thread.
///
/// `events` is the core's event channel; `prompts` delivers one `()` per turn
/// the core grants. The returned [`JoinHandle`] should be joined at shutdown so
/// the terminal is restored before the process exits (CA-01).
pub fn spawn(events: EventSender<Event>, prompts: PulseReceiver<()>) -> JoinHandle<()> {
    thread::spawn(move || run_editor(&events, &prompts))
}

fn run_editor(events: &EventSender<Event>, prompts: &PulseReceiver<()>) {
    let mut line_editor = Reedline::create();
    let prompt = DefaultPrompt::default();

    // Each granted turn yields exactly one event back to the core. The loop
    // ends when the core stops granting turns (it dropped the pulse sender) or
    // when we send a terminal event (EOF / error).
    while prompts.recv().is_ok() {
        let event = match line_editor.read_line(&prompt) {
            Ok(Signal::Success(line)) => Event::Input(line),
            Ok(Signal::CtrlC) => Event::CancelLine,
            Ok(Signal::CtrlD) => Event::Eof,
            Err(err) => Event::InputError(err.to_string()),
        };

        let terminal = matches!(event, Event::Eof | Event::InputError(_));

        if events.blocking_send(event).is_err() {
            break; // the core dropped its receiver; no one is listening.
        }
        if terminal {
            break;
        }
    }
}
