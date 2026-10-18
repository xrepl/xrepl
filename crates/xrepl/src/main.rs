//! xrepl Rust terminal: default IF mock or shared Cayrn session consumer.
use clap::Parser;
use std::path::PathBuf;
use xrepl_adventure::Adventure;

#[derive(Parser)]
#[command(about = "xrepl terminal: IF demo or shared Cayrn/LFE session")]
struct Options {
    /// Cayrn state directory; defaults to the existing IF demo when omitted.
    #[arg(long)]
    cayrn: Option<PathBuf>,
    /// Existing session to attach to; otherwise create one.
    #[arg(long, requires = "cayrn")]
    session: Option<String>,
    /// Last displayed event cursor (decimal string); replay begins after this.
    #[arg(long, default_value = "0", requires = "cayrn")]
    after: u64,
    /// Source lines on stdin, full JSON events on stdout (tool/test mode).
    #[arg(long, requires = "cayrn")]
    cayrn_json: bool,
}
#[tokio::main]
async fn main() -> xrepl_core::Result<()> {
    let options = Options::parse();
    if let Some(directory) = options.cayrn {
        xrepl_core::cayrn::run(
            &directory.join("cayrn.sock"),
            options.session.as_deref(),
            cayrn_protocol::Cursor(options.after),
            options.cayrn_json,
        )
        .await
    } else {
        xrepl_core::run(Adventure::new()).await
    }
}
