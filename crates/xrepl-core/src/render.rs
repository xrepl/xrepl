//! Output rendering.
//!
//! Today this is a thin, correct wrapper over stdout. Because the input thread
//! only reads when the core grants it a turn (see [`crate::input`]), no output
//! ever races the line editor in the steady state, so a plain write is right.
//!
//! The struct exists as the **seam** where the arm-while-editing
//! buffer-and-flush policy will live once streaming output (G-01) can deliver
//! frames mid-prompt. Keeping it behind a type now means that change is local.

use std::io::{self, Write};

use crate::event::{OutputFrame, Stream};

/// Renders [`OutputFrame`]s to the terminal.
#[derive(Debug, Default)]
pub struct Renderer;

impl Renderer {
    /// Create a renderer.
    #[must_use]
    pub fn new() -> Self {
        Self
    }

    /// Write one frame to the terminal.
    ///
    /// The `match` on [`Stream`] is the divergence point for G-01: stdout and
    /// meta frames are written identically today, but meta is where the dim
    /// per-eval attribution prefix will attach.
    pub fn render(&mut self, frame: &OutputFrame) {
        let mut out = io::stdout().lock();
        let result = match frame.stream {
            Stream::Stdout => writeln!(out, "{}", frame.text),
            Stream::Meta => writeln!(out, "{}", frame.text),
        };
        // Rendering is best-effort: a broken pipe on stdout is not a reason to
        // tear down the REPL. (Documented boundary for the ignored Result.)
        let _ = result;
        let _ = out.flush();
    }
}
