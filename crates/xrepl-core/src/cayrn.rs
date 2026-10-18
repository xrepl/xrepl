//! Cayrn consumer: independent event reception and editing-safe presentation.
use crate::{Event, Result, XreplError, input};
use cayrn_client::{Client, EventSpool};
use cayrn_protocol::{Cursor, ErrorCode, EventKind, Fault, Request, Response, Submission};
use std::{
    io::{self, BufRead, Write},
    path::Path,
    sync::{Arc, Mutex, mpsc},
    thread,
};
use tokio::sync::mpsc as channel;

const SPOOL_BYTES: u64 = 8 * 1024 * 1024;
fn poisoned() -> Fault {
    Fault::new(ErrorCode::Io, "presentation spool poisoned")
}

/// Attach to a Cayrn session, or create one. EOF/quit detaches only this client.
/// JSON mode takes one source line per turn and emits full events for tools/tests.
/// Runtime environments and durable history remain owned by the host.
///
/// # Errors
/// Returns transport/protocol/storage errors or terminal failures. No code is retried.
pub async fn run(
    socket: &Path,
    session: Option<&str>,
    after: Cursor,
    json_mode: bool,
) -> Result<()> {
    let mut commands = Client::connect(socket).await?;
    let response = match session {
        Some(session) => {
            commands
                .request(Request::InspectSession {
                    session: session.into(),
                })
                .await?
        }
        None => commands.request(Request::Create).await?,
    };
    let Response::Session(session) = response else {
        return Err(Fault::new(ErrorCode::Protocol, "expected session").into());
    };
    if json_mode {
        println!(
            "{}",
            serde_json::json!({"session":session.id,"generation":session.generation,"after":after})
        );
    } else {
        eprintln!(
            "Cayrn session {} (resume with --session {} --after {})",
            session.id, session.id, after.0
        );
    }
    let spool = Arc::new(Mutex::new(EventSpool::new(
        &session.id,
        after,
        SPOOL_BYTES,
    )?));
    let mut events = Client::connect(socket).await?;
    let receiver_spool = spool.clone();
    let sid = session.id.clone();
    let (notice, mut notices) = channel::channel::<std::result::Result<(), Fault>>(1);
    let reader = tokio::spawn(async move {
        let result = async {
            loop {
                let after = receiver_spool.lock().map_err(|_| poisoned())?.received();
                let page = events.follow(&sid, after, 500).await?;
                if page.events.is_empty() {
                    continue;
                }
                let buffer = receiver_spool.clone();
                tokio::task::spawn_blocking(move || {
                    buffer.lock().map_err(|_| poisoned())?.append(&page)
                })
                .await
                .map_err(|e| Fault::new(ErrorCode::Io, e.to_string()))??;
                match notice.try_send(Ok(())) {
                    Ok(()) | Err(channel::error::TrySendError::Full(_)) => {}
                    Err(channel::error::TrySendError::Closed(_)) => return Ok::<(), Fault>(()),
                }
            }
        }
        .await;
        if let Err(error) = result {
            let _ = notice.send(Err(error)).await;
        } // UI may already have detached.
    });
    let (event_tx, mut event_rx) = channel::channel(64);
    let (pulse, pulses) = mpsc::channel();
    let input = if json_mode {
        line_input(event_tx, pulses)
    } else {
        input::spawn(event_tx, pulses)
    };
    let client_id = uuid::Uuid::new_v4().to_string();
    let mut pending: Option<String> = None;
    let mut editing = true;
    let mut failure = None;
    let mut notices_open = true;
    let _ = pulse.send(());
    let result=async {
        loop {
            tokio::select! {
                signal=tokio::signal::ctrl_c(),if pending.is_some()=>{
                    signal?;
                    if let Some(operation)=pending.as_ref() {
                        let reply=commands.request(Request::Cancel {session:session.id.clone(),operation:operation.clone()}).await?;
                        if let Response::Control {disposition}=reply {eprintln!("Interrupt: {disposition}");}
                    }
                },
                event=event_rx.recv()=>match event {
                    Some(Event::Input(line))=>{
                        editing=false;
                        drain(spool.clone(),json_mode,pending.as_deref()).await?;
                        if let Some(error)=failure.take() {return Err(XreplError::Cayrn(error));}
                        let line=line.trim();
                        if matches!(line,":quit"|":q"|"quit"|"exit") {break;}
                        if line==":close" {
                            commands.request(Request::Close {session:session.id.clone()}).await?;
                            eprintln!("Close requested; inspect the session for its barrier/completion.");
                            break;
                        }
                        if !line.is_empty() {
                            let id=uuid::Uuid::new_v4().to_string();
                            commands.request(Request::Submit {submission:Submission {session:session.id.clone(),generation:session.generation.clone(),operation:id.clone(),client:client_id.clone(),source:line.into()}}).await?;
                            pending=Some(id);
                            if drain(spool.clone(),json_mode,pending.as_deref()).await? {pending=None;}
                        }
                        if pending.is_none() {editing=true;let _=pulse.send(());}
                    },
                    Some(Event::Eof)=>{drain(spool.clone(),json_mode,pending.as_deref()).await?;break;},
                    Some(Event::CancelLine)=>{
                        editing=false;
                        drain(spool.clone(),json_mode,pending.as_deref()).await?;
                        editing=true;let _=pulse.send(());
                    },
                    Some(Event::InputError(error))=>return Err(io::Error::other(error).into()),
                    Some(_)=>{},None=>break,
                },
                notice=notices.recv(),if notices_open=>{
                    match notice {Some(Err(error))=>failure=Some(error),None=>notices_open=false,_=>{}}
                    if !editing || json_mode {
                        if drain(spool.clone(),json_mode,pending.as_deref()).await? {pending=None;}
                        if let Some(error)=failure.take() {return Err(XreplError::Cayrn(error));}
                        if !editing && pending.is_none() {editing=true;let _=pulse.send(());}
                    }
                }
            }
        }
        Ok(())
    }.await;
    reader.abort();
    let _ = reader.await; // Deliberate cancellation closes this observation connection only.
    drop(pulse);
    if input.join().is_err() {
        return Err(io::Error::other("input thread panicked").into());
    }
    if !json_mode {
        eprintln!(
            "Detached. Resume session {} after displayed cursor {}",
            session.id,
            spool.lock().map_err(|_| poisoned())?.displayed().0
        );
    }
    result
}
fn line_input(
    events: channel::Sender<Event>,
    pulses: mpsc::Receiver<()>,
) -> thread::JoinHandle<()> {
    thread::spawn(move || {
        let stdin = io::stdin();
        let mut lines = stdin.lock().lines();
        while pulses.recv().is_ok() {
            let event = match lines.next() {
                Some(Ok(line)) => Event::Input(line),
                Some(Err(e)) => Event::InputError(e.to_string()),
                None => Event::Eof,
            };
            let terminal = matches!(event, Event::Eof | Event::InputError(_));
            if events.blocking_send(event).is_err() || terminal {
                break;
            }
        }
    })
}
async fn drain(
    spool: Arc<Mutex<EventSpool>>,
    json_mode: bool,
    pending: Option<&str>,
) -> Result<bool> {
    let pending = pending.map(str::to_owned);
    tokio::task::spawn_blocking(move || -> Result<bool> {
        let mut spool = spool.lock().map_err(|_| poisoned())?;
        let mut finished = false;
        let stdout = io::stdout();
        let mut output = stdout.lock();
        while let Some(event) = spool.next_event()? {
            if let EventKind::Outcome { operation, .. } = &event.event {
                finished |= pending.as_ref() == Some(operation);
            }
            if json_mode {
                writeln!(
                    output,
                    "{}",
                    serde_json::to_string(&event).map_err(io::Error::other)?
                )?;
            } else {
                match event.event {
                    EventKind::Output { operation, text } => {
                        writeln!(output, "[{operation}] {text}")?
                    }
                    EventKind::Outcome {
                        operation,
                        phase,
                        value,
                    } => writeln!(
                        output,
                        "[{operation} {phase:?}] {}",
                        value.unwrap_or_default()
                    )?,
                    EventKind::SessionClosing => writeln!(output, "[session closing]")?,
                    EventKind::SessionClosed => writeln!(output, "[session closed]")?,
                    EventKind::StateLost { reason } => writeln!(output, "[state lost] {reason}")?,
                    EventKind::Accepted { submission } => {
                        writeln!(output, "[{}] {}", submission.client, submission.source)?
                    }
                    _ => {}
                }
            }
        }
        output.flush()?;
        Ok(finished)
    })
    .await
    .map_err(|e| io::Error::other(e.to_string()))?
}
