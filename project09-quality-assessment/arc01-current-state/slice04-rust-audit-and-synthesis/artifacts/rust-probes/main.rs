//! Neutral public-API lifecycle probe; no adventure or personal state.
use xrepl_core::{Backend, OutputFrame};

struct Probe { panic: bool }

impl Backend for Probe {
    fn banner(&self) -> Vec<OutputFrame> {
        vec![OutputFrame::meta(0, "PROBE_READY")]
    }

    fn handle(&mut self, eval_id: u64, line: &str) -> Vec<OutputFrame> {
        if self.panic { panic!("PROBE_BACKEND_PANIC"); }
        vec![OutputFrame::stdout(eval_id, format!("HANDLED:{line}"))]
    }
}

#[tokio::main]
async fn main() {
    let panic = std::env::args().nth(1).as_deref() == Some("panic");
    let result = xrepl_core::run(Probe { panic }).await;
    eprintln!("PROBE_RETURNED:{result:?}");
}
