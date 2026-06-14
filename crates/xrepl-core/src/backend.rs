//! The backend abstraction — the seam where a *response source* plugs into the
//! core loop.
//!
//! In the real client this seam is filled by the protocol client that speaks
//! `xrepl_protocol` to the BEAM. In this PoC it is filled by an in-process
//! interactive-fiction engine (`xrepl-adventure`). The core loop neither knows
//! nor cares which: it hands the backend a line of input and renders whatever
//! frames come back.

use crate::event::OutputFrame;

/// A source of responses to user input.
///
/// Implementations are deliberately **pure and synchronous**: given an input
/// line and a monotonically increasing `eval_id`, return the frames to emit.
/// All the async plumbing — running the backend on its own task, forwarding
/// frames onto the event channel, signalling end-of-turn — lives in the core
/// loop. That keeps backends trivially unit-testable and ignorant of tokio and
/// channels, and it is what will let the BEAM-backed implementation slot in
/// behind the same trait.
///
/// The `Send + 'static` bound is required because the core loop drives the
/// backend on a spawned task.
pub trait Backend: Send + 'static {
    /// Frames to show once, at startup, before the first prompt.
    ///
    /// The default is no banner. Frames should use `eval_id` `0`.
    #[must_use]
    fn banner(&self) -> Vec<OutputFrame> {
        Vec::new()
    }

    /// Handle one line of input, producing zero or more output frames.
    ///
    /// `eval_id` identifies this turn; it is propagated onto every frame so the
    /// renderer can attribute output (a no-op today, load-bearing under G-01).
    fn handle(&mut self, eval_id: u64, line: &str) -> Vec<OutputFrame>;
}
