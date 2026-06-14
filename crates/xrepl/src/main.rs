//! `xrepl` — proof-of-concept binary for the inverted xrepl terminal client.
//!
//! This wires the interactive-fiction engine ([`xrepl_adventure::Adventure`])
//! into the event-driven core ([`xrepl_core::run`]) as a stand-in backend. It
//! is *infrastructure only*: no LFE is read, printed, or evaluated. The point
//! is to prove the plumbing — the tokio event channel, the reedline input
//! source, the backend task, the renderer — with a backend that needs no BEAM.
//!
//! Run it with `cargo run -p xrepl`.

use xrepl_adventure::Adventure;

#[tokio::main]
async fn main() -> xrepl_core::Result<()> {
    xrepl_core::run(Adventure::new()).await
}
