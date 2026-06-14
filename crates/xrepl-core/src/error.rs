//! Error type for the core.
//!
//! `thiserror` for the library (EH guidance); applications layered on top use
//! `anyhow`/`eyre` as they see fit. The enum is `#[non_exhaustive]` so new
//! failure modes (transport errors, child-process failures) can be added
//! without a breaking change.

/// Errors the core loop can surface.
#[non_exhaustive]
#[derive(Debug, thiserror::Error)]
pub enum XreplError {
    /// A terminal or stream I/O failure.
    #[error("terminal i/o error: {0}")]
    Io(#[from] std::io::Error),
}

/// Convenience alias for results in this crate.
pub type Result<T> = std::result::Result<T, XreplError>;
