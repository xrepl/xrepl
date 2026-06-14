//! `xrepl-core` — the event-driven spine of the xrepl terminal client.
//!
//! This crate is the **plumbing** for the inverted xrepl REPL: a Rust front-end
//! that owns the terminal and the human, talking to a response backend. It is
//! deliberately scoped to the infrastructure — there is no reading, printing,
//! or evaluating of LFE here. A [`Backend`] supplies responses; in this PoC the
//! backend is an interactive-fiction engine, but the same trait is where the
//! BEAM-backed protocol client will plug in.
//!
//! What it demonstrates (the agreed PoC depth):
//!
//! * a single tokio event channel that all producers feed and the loop drains
//!   ([`Event`], decision D-01 — message-driven, not a read→eval→print stack);
//! * the line editor wrapped as an input *event source* on its own thread
//!   ([`input`]);
//! * a pluggable [`Backend`] driven on its own task;
//! * a [`Renderer`] seam for output.
//!
//! What it deliberately leaves *reachable but unbuilt* (deselected for this
//! pass): streaming output frames + the arm-while-editing buffer (G-01), the
//! interrupt op (G-02), and the BEAM child-process lifecycle. The
//! `#[non_exhaustive]` [`Event`] enum, the per-frame `eval_id`/[`Stream`], and
//! the [`Renderer`] type are the hooks those will hang from.
//!
//! # Example
//!
//! ```no_run
//! use xrepl_core::{Backend, OutputFrame};
//!
//! struct Echo;
//! impl Backend for Echo {
//!     fn handle(&mut self, eval_id: u64, line: &str) -> Vec<OutputFrame> {
//!         vec![OutputFrame::stdout(eval_id, format!("you said: {line}"))]
//!     }
//! }
//!
//! #[tokio::main]
//! async fn main() -> xrepl_core::Result<()> {
//!     xrepl_core::run(Echo).await
//! }
//! ```

pub mod backend;
pub mod error;
pub mod event;
pub mod input;
pub mod render;

mod repl;

pub use backend::Backend;
pub use error::{Result, XreplError};
pub use event::{Event, OutputFrame, Stream};
pub use render::Renderer;
pub use repl::run;
