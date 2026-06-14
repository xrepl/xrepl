//! A minimal interactive-fiction engine that implements
//! [`xrepl_core::Backend`].
//!
//! It exists for two reasons at once:
//!
//! 1. **It is the PoC's mock backend.** It plays the role the protocol client
//!    will later play — turning a line of input into output frames pushed
//!    through the core's event channel — so the infrastructure can be exercised
//!    end-to-end with no BEAM in sight. Because [`xrepl_core::Backend::handle`]
//!    is pure and synchronous, the whole game is trivially testable without any
//!    async machinery.
//! 2. **It is the seed of the in-REPL text adventure.** The scene below is
//!    deliberately tiny — two rooms, a couple of objects. The engine is
//!    data-driven so that growing it (more rooms, items, verbs) is *content*,
//!    not plumbing. This is the thing Duncan and Claude get to write together;
//!    what's here is just enough to prove the seam and set the tone.

use std::collections::HashMap;

use xrepl_core::{Backend, OutputFrame};

/// A location in the world.
#[derive(Debug)]
struct Room {
    /// Heading shown when the room is described.
    name: &'static str,
    /// The room's prose.
    blurb: &'static str,
    /// `(direction, destination-room-id)` pairs. Multiple directions may lead
    /// to the same room (e.g. `aft` and `out`).
    exits: &'static [(&'static str, &'static str)],
    /// Items currently on the floor here. Mutated as the player takes/drops.
    items: Vec<&'static str>,
}

/// The interactive-fiction engine: the world plus the player's state.
#[derive(Debug)]
pub struct Adventure {
    rooms: HashMap<&'static str, Room>,
    here: &'static str,
    carrying: Vec<&'static str>,
}

impl Default for Adventure {
    fn default() -> Self {
        Self::new()
    }
}

impl Adventure {
    /// Build the world in its starting state.
    #[must_use]
    pub fn new() -> Self {
        let mut rooms = HashMap::new();
        rooms.insert(
            "cockpit",
            Room {
                name: "Survey Skiff — Cockpit",
                blurb: "You're folded into the pilot's couch of a grounded survey \
                        skiff. Frost has drawn ferns across the canopy, and somewhere \
                        below the deck a cooling pump ticks like a patient clock.",
                exits: &[("aft", "gangway"), ("out", "gangway")],
                items: vec!["logbook"],
            },
        );
        rooms.insert(
            "gangway",
            Room {
                name: "Gangway — Open Air",
                blurb: "The boarding ramp is down. Outside, a tilted plain of violet \
                        grass runs to a horizon of slow, impossible spires — the kind \
                        of sky that was painted long before anyone thought to fly it.",
                exits: &[("fore", "cockpit"), ("in", "cockpit")],
                items: vec!["lichen"],
            },
        );

        Self { rooms, here: "cockpit", carrying: Vec::new() }
    }

    /// The room the player is currently in. Panics only if the world is
    /// internally inconsistent (`here` always names a room by construction).
    fn current(&self) -> &Room {
        self.rooms.get(self.here).expect("`here` always names a known room")
    }

    fn look(&self, eval_id: u64) -> Vec<OutputFrame> {
        let room = self.current();
        let mut out = vec![
            OutputFrame::stdout(eval_id, room.name),
            OutputFrame::stdout(eval_id, room.blurb),
        ];
        if !room.items.is_empty() {
            out.push(OutputFrame::stdout(
                eval_id,
                format!("You can see: {}.", room.items.join(", ")),
            ));
        }
        let dirs: Vec<&str> = room.exits.iter().map(|(dir, _)| *dir).collect();
        out.push(OutputFrame::stdout(eval_id, format!("Exits: {}.", dirs.join(", "))));
        out
    }

    fn go(&mut self, eval_id: u64, dir: &str) -> Vec<OutputFrame> {
        if dir.is_empty() {
            return vec![OutputFrame::stdout(eval_id, "Go where?")];
        }
        let dest = self
            .current()
            .exits
            .iter()
            .find(|(d, _)| d.eq_ignore_ascii_case(dir))
            .map(|(_, id)| *id);
        match dest {
            Some(id) => {
                self.here = id;
                self.look(eval_id)
            }
            None => vec![OutputFrame::stdout(eval_id, format!("You can't go {dir} from here."))],
        }
    }

    fn examine(&self, eval_id: u64, what: &str) -> Vec<OutputFrame> {
        if what.is_empty() {
            return vec![OutputFrame::stdout(eval_id, "Examine what?")];
        }
        let present = self
            .current()
            .items
            .iter()
            .chain(self.carrying.iter())
            .any(|item| item.eq_ignore_ascii_case(what));
        if present {
            vec![OutputFrame::stdout(eval_id, describe_item(what))]
        } else {
            vec![OutputFrame::stdout(eval_id, format!("You see no {what} here."))]
        }
    }

    fn take(&mut self, eval_id: u64, what: &str) -> Vec<OutputFrame> {
        if what.is_empty() {
            return vec![OutputFrame::stdout(eval_id, "Take what?")];
        }
        let room = self.rooms.get_mut(self.here).expect("`here` always names a known room");
        if let Some(pos) = room.items.iter().position(|i| i.eq_ignore_ascii_case(what)) {
            let item = room.items.remove(pos);
            self.carrying.push(item);
            vec![OutputFrame::stdout(eval_id, format!("You take the {item}."))]
        } else {
            vec![OutputFrame::stdout(eval_id, format!("There is no {what} to take."))]
        }
    }

    fn drop_item(&mut self, eval_id: u64, what: &str) -> Vec<OutputFrame> {
        if what.is_empty() {
            return vec![OutputFrame::stdout(eval_id, "Drop what?")];
        }
        if let Some(pos) = self.carrying.iter().position(|i| i.eq_ignore_ascii_case(what)) {
            let item = self.carrying.remove(pos);
            self.rooms
                .get_mut(self.here)
                .expect("`here` always names a known room")
                .items
                .push(item);
            vec![OutputFrame::stdout(eval_id, format!("You set down the {item}."))]
        } else {
            vec![OutputFrame::stdout(eval_id, format!("You aren't carrying a {what}."))]
        }
    }

    fn inventory(&self, eval_id: u64) -> Vec<OutputFrame> {
        if self.carrying.is_empty() {
            vec![OutputFrame::stdout(eval_id, "Your hands are empty.")]
        } else {
            vec![OutputFrame::stdout(
                eval_id,
                format!("You are carrying: {}.", self.carrying.join(", ")),
            )]
        }
    }

    fn help(eval_id: u64) -> Vec<OutputFrame> {
        const LINES: &[&str] = &[
            "Commands:",
            "  look (l)             — describe where you are",
            "  go <dir> / <dir>     — move (try: aft, out, fore, in)",
            "  examine <thing> (x)  — look closer",
            "  take <thing>         — pick something up",
            "  drop <thing>         — set something down",
            "  inventory (i)        — what you're carrying",
            "  help (?)             — this list",
            "  quit                 — leave",
        ];
        LINES.iter().map(|line| OutputFrame::stdout(eval_id, *line)).collect()
    }
}

impl Backend for Adventure {
    fn banner(&self) -> Vec<OutputFrame> {
        let mut out = vec![
            OutputFrame::stdout(0, "～  a survey in miniature  ～"),
            OutputFrame::stdout(0, "type  look  ·  help  ·  quit"),
            OutputFrame::stdout(0, ""),
        ];
        out.extend(self.look(0));
        out
    }

    fn handle(&mut self, eval_id: u64, line: &str) -> Vec<OutputFrame> {
        let mut words = line.split_whitespace();
        let verb = words.next().unwrap_or_default().to_ascii_lowercase();
        let arg = words.collect::<Vec<_>>().join(" ");

        match verb.as_str() {
            "look" | "l" => self.look(eval_id),
            "go" | "move" | "walk" => self.go(eval_id, &arg),
            // Bare compass / ship directions move you directly.
            "north" | "n" | "south" | "s" | "east" | "e" | "west" | "w" | "aft" | "fore"
            | "in" | "out" | "up" | "down" => self.go(eval_id, &verb),
            "examine" | "x" | "inspect" => self.examine(eval_id, &arg),
            "take" | "get" | "grab" => self.take(eval_id, &arg),
            "drop" | "leave" => self.drop_item(eval_id, &arg),
            "inventory" | "i" | "inv" => self.inventory(eval_id),
            "help" | "?" | "commands" => Self::help(eval_id),
            "" => Vec::new(),
            other => {
                vec![OutputFrame::stdout(eval_id, format!("I don't know how to \"{other}\"."))]
            }
        }
    }
}

/// Flavour text for an item, whether it's on the floor or in hand.
fn describe_item(item: &str) -> String {
    match item.to_ascii_lowercase().as_str() {
        "logbook" => {
            "The skiff's logbook. The last entry is in a hand you don't recognise, and \
             it stops mid-sentence."
                .to_owned()
        }
        "lichen" => {
            "A pale lichen that keeps a faint blue light even when it's in your shadow."
                .to_owned()
        }
        other => format!("It's a perfectly ordinary {other}."),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use xrepl_core::Backend;

    /// Collapse a frame batch to one string for easy assertions.
    fn text(frames: &[OutputFrame]) -> String {
        frames.iter().map(|f| f.text.as_str()).collect::<Vec<_>>().join("\n")
    }

    #[test]
    fn starts_in_the_cockpit() {
        let mut game = Adventure::new();
        let out = text(&game.handle(1, "look"));
        assert!(out.contains("Cockpit"), "expected to start in the cockpit, got:\n{out}");
    }

    #[test]
    fn a_bare_direction_changes_room() {
        let mut game = Adventure::new();
        let out = text(&game.handle(1, "out"));
        assert!(out.contains("Gangway"), "expected to reach the gangway, got:\n{out}");
    }

    #[test]
    fn take_then_inventory_shows_the_item() {
        let mut game = Adventure::new();
        let _ = game.handle(1, "take logbook");
        let out = text(&game.handle(2, "inventory"));
        assert!(out.contains("logbook"), "logbook should be carried, got:\n{out}");
    }

    #[test]
    fn item_taken_is_gone_from_the_room() {
        let mut game = Adventure::new();
        let _ = game.handle(1, "take logbook");
        let out = text(&game.handle(2, "look"));
        assert!(!out.contains("logbook"), "logbook should be gone from the room, got:\n{out}");
    }

    #[test]
    fn unknown_verb_is_reported_not_panicked() {
        let mut game = Adventure::new();
        let out = text(&game.handle(1, "xyzzy"));
        assert!(out.contains("don't know"), "unknown verb should be reported, got:\n{out}");
    }

    #[test]
    fn cannot_take_what_isnt_there() {
        let mut game = Adventure::new();
        let out = text(&game.handle(1, "take moon"));
        assert!(out.to_lowercase().contains("no moon"), "got:\n{out}");
    }

    #[test]
    fn banner_opens_on_the_scene() {
        let game = Adventure::new();
        let out = text(&game.banner());
        assert!(out.contains("Cockpit"), "banner should show the opening scene, got:\n{out}");
    }
}
