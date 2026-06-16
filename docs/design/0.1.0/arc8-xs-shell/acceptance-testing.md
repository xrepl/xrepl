# Acceptance testing — the xrepl story (first trial run)

A five-minute walkthrough for testers. No spoilers below: how to install the
story, start xrepl, find the door, and play. The story itself is for you to
discover.

## 1. Drop in the archive

Put the `.xsf` archive here, named **exactly** `support.xsf`:

```
xrepl/xrepl/priv/support.xsf
```

(At runtime xrepl looks it up via `code:priv_dir('xrepl)` + `support.xsf`, so the
name and location matter. If it's missing or misnamed, the story simply won't be
there — you'll get a quiet "nothing here yet" instead of a crash.)

## 2. Build and start xrepl

From the `xrepl/xrepl` directory:

```bash
rebar3 compile      # or: make build
./bin/xrepl
```

You'll land at the LFE prompt:

```
lfe>
```

## 3. Find the door

At the `lfe>` prompt, try typing one of these — as if you were poking around:

```lfe
lfe> (open)
```

Instead of a normal error you'll get a nudge — a "did you mean …?" hint pointing
at the way in. (Other words that nudge the same way: `unlock`, `knock`, `sesame`,
`password`, `passwd`, `secret`, `login`.) Follow the hint, or go straight in:

```lfe
lfe> (xs:run)
```

The first room appears, and you're in the story.

## 4. Play

You're no longer at a Lisp prompt — you're in the story, typing plain commands.
The room text tells you your options; in general:

- type an **exit / direction** the room mentions (e.g. a path or a door) to move;
- **`look`** — re-read the current room;
- **`take <thing>`** (or `get <thing>`) — pick something up;
- **`inventory`** (or **`i`**) — what you're carrying;
- **`help`** — the command list;
- at a prompt that asks for something, just **type your answer**.

## 5. Leave and come back (save / resume)

Type **`quit`** (or `exit`) at any point to leave — your progress is saved. Back
at the `lfe>` prompt, run `(xs:run)` again later and you'll pick up where you left
off. Reaching an ending returns you to the REPL on its own.

## 6. Seeing the paintings

Images render only on a **graphics-capable terminal** — **iTerm2** or **Kitty**.
On any other terminal the story still plays perfectly; you just won't see the
art (it's skipped silently, not an error). If you're acceptance-testing the
visuals, use iTerm2 or Kitty.

## What to check / report

- The nudge fires on a trigger word; `(xs:run)` enters and the first room renders.
- Movement, `look`, `take`/`inventory`, `help`, and any prompt/answer all work.
- `quit` then `(xs:run)` resumes at the same spot, with items/flags intact.
- On iTerm2/Kitty, room art appears; on a plain terminal, text-only with no error.
- An ending returns you cleanly to `lfe>`.

Note anything that crashes, misrenders, or reads wrong — and (gently) whether the
surprise *felt* like a surprise.
