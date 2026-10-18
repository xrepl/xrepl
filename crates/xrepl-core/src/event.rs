//! The event vocabulary of the core loop.
//!
//! Every concurrent concern in the client — the line editor, the backend,
//! and (later) the BEAM child-process monitor — is a *producer* of [`Event`]s
//! on a single channel. The core loop is the sole *consumer*. This is the
//! message-driven shape locked as decision D-01 in the architecture addendum:
//! the front-end is "who renders events," not "who owns the loop."
//!
//! The types here carry a little more structure than the PoC strictly needs
//! (an `eval_id` and a [`Stream`] tag on every [`OutputFrame`]) so that the
//! deferred work — G-01 streaming output, G-02 interrupt — can light them up
//! without changing these signatures.

/// Which logical stream an [`OutputFrame`] belongs to.
///
/// Mirrors the `{stream}` field that G-01's streaming-output frames will carry.
/// For the infra PoC we only need to *distinguish* the channels; the wire
/// encoding and the dim per-eval attribution land with G-01.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Stream {
    /// Normal program / scene output — the equivalent of evaluated-code stdout.
    Stdout,
    /// Diagnostics, banners, and errors the client surfaces on the user's behalf.
    Meta,
}

/// A unit of output bound for the user's screen.
///
/// The `eval_id` ties a frame to the input that produced it. In the PoC it is
/// rendered plainly, but it is the hook G-01 needs to attribute *late* frames
/// from an earlier evaluation (the dim `[3]│` prefix idea) once output can
/// arrive asynchronously.
#[derive(Debug, Clone)]
pub struct OutputFrame {
    /// The evaluation this frame belongs to (`0` for startup / unattributed).
    pub eval_id: u64,
    /// The stream this frame should be routed to.
    pub stream: Stream,
    /// The text to show. May contain embedded newlines.
    pub text: String,
}

impl OutputFrame {
    /// A normal-output frame on [`Stream::Stdout`].
    #[must_use]
    pub fn stdout(eval_id: u64, text: impl Into<String>) -> Self {
        Self {
            eval_id,
            stream: Stream::Stdout,
            text: text.into(),
        }
    }

    /// A diagnostic / meta frame on [`Stream::Meta`].
    #[must_use]
    pub fn meta(eval_id: u64, text: impl Into<String>) -> Self {
        Self {
            eval_id,
            stream: Stream::Meta,
            text: text.into(),
        }
    }
}

/// Everything the core loop can react to.
///
/// Marked `#[non_exhaustive]` on purpose: the deferred milestones add variants
/// (`ChildDown`, `Interrupted`, a streamed-chunk frame) and they must be able
/// to do so without a breaking change to this enum.
#[non_exhaustive]
#[derive(Debug)]
pub enum Event {
    /// A committed line of input from the line editor.
    Input(String),
    /// The user pressed Ctrl-C at the prompt (an empty-line cancel). In the
    /// PoC this simply re-prompts; G-02 will route it to the backend as an
    /// interrupt of the in-flight evaluation.
    CancelLine,
    /// The user asked to quit the line editor (Ctrl-D / EOF at the prompt).
    Eof,
    /// Output produced by the backend, to be rendered.
    Output(OutputFrame),
    /// The backend has finished handling the current input; the loop may grant
    /// the line editor another turn. Stands in for the protocol client's
    /// end-of-evaluation reply.
    BackendIdle,
    /// The line-editor thread hit an unrecoverable error and is stopping.
    InputError(String),
}
