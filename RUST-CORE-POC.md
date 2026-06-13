# xrepl Rust core — infrastructure PoC

A first proof-of-concept for the **inverted** xrepl REPL: a Rust front-end that
owns the terminal and the human, with the BEAM (the LFE OTP app in this same
repo) owning the language. This PoC is **infrastructure only** — it does *not*
read, print, or evaluate LFE. It proves the plumbing:

- a single **tokio event channel** that every producer feeds and the loop drains
  (decision D-01: message-driven, not a `read → eval → print` call stack);
- the **reedline** line editor wrapped as an input *event source* on its own
  OS thread;
- a pluggable **`Backend`** trait, driven on its own task — the seam where the
  BEAM-backed protocol client will plug in;
- a **`Renderer`** seam for output.

In place of the BEAM, the backend is a tiny **interactive-fiction engine**
(`xrepl-adventure`). It streams scene text through the same event channel a real
backend would, so the infra is exercised end-to-end with nothing to install.
It's also the seed of the in-REPL text adventure — deliberately two rooms; the
engine is data-driven so growing it is content, not plumbing.

## Layout

This Rust workspace shares the repo root with the rebar3 LFE project:

```
Cargo.toml                     # virtual workspace (this side)
rebar.config                   # the LFE OTP app (other side)
crates/
  xrepl-core/                  # the plumbing (event loop, input source, traits)
  xrepl-adventure/             # IF engine = the zero-BEAM mock backend
  xrepl/                       # the binary that wires them together
```

## Build & run (host-side)

This PoC was written without a Rust toolchain available in the authoring
sandbox (no `cargo`, no crates.io), so **it has not been compiled or run in that
environment** — see `workbench/2026.06.13-rust-core-poc-notes.md`. The commands
below are the host-side verification path (or use the `*-rust` make targets):

```sh
cargo build
cargo test            # exercises the IF engine's pure handle()
cargo clippy --all-targets -- -D warnings
cargo run -p xrepl    # play the scene; type `look`, `help`, `quit`
```

If `reedline = "0.38"` does not resolve, run `cargo update -p reedline` or bump
the pin in the root `Cargo.toml` `[workspace.dependencies]`. The reedline
surface used here (`Reedline::create`, `read_line`, `Signal`) has been stable
across many releases.

## What's reachable but not built (by design)

The PoC depth was scoped to the event-core spine. These are wired *for* but not
*in* this pass, with the hooks already in place:

- **Streaming output (G-01)** — the arm-while-editing buffer-and-flush policy.
  Hooks: `#[non_exhaustive]` `Event`, the per-frame `eval_id`/`Stream`, and the
  `Renderer` type as the buffer's home.
- **Interrupt (G-02)** — Ctrl-C currently just re-prompts; the `CancelLine`
  event is where it will route to the backend.
- **BEAM child lifecycle** — the three-rung shutdown ladder and the stdin-EOF
  watchdog; a `ChildDown` event variant slots into the same channel.

See `workbench/2026.06.10-rust-core-architecture-review.md` and its 2026.06.11
addendum for the full architecture these hooks anticipate.
