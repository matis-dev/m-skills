---
name: module-writing-floor
description: "Module — loaded by name from an m-skills architect, not an entry point. The floor for any document a project ships: prerequisites first, runnable examples, real identifiers, task-shaped headings, resolving links, no time estimates — plus the refuse list of documentation slop."
user-invocable: false
---

# Module: The Writing Floor

**Loaded by:** `documentation-architect` · `product-architect` · `search-optimization-architect` · `rolling-history` · `deployment-architect` · `marketing-architect`. Read it whenever a run emits a document a reader will follow; do not restate its content in a skill file.

Checks on the **rendered document**, not on intentions. Run them together in one batched verification round.

---

## 1. The Floor

- **Time to first success** — prerequisites (runtime versions, accounts, keys, OS constraints) appear **before** the first install command, not in a section below it. The path from landing on the page to something working is the shortest thing on the page.
- **Every code block is runnable as written** — language-tagged, copy-pasteable, no invisible prerequisite, no `$` prompt prefix mixed into copyable lines, no placeholder where a real value from this repo exists. Multi-line commands survive a copy. If output matters, show the real output.
- **Every identifier is real** — commands, paths, flags, env vars, endpoints, types, and defaults each traceable to a file you read. A plausible-looking invented flag is the single most expensive error this floor exists to prevent, because **a fabricated code sample is executed by the reader**, on their machine, not yours.
- **Task-shaped headings, active voice** — headings name what the reader does ("Configure the database"), not what the system is ("Database configuration"). "Run the migration" over "The migration should be run". A reader scanning only the headings should see their task.
- **No time estimates.** "Takes 5 minutes", "a quick setup", "this should be fast" — cut them. They are wrong for anyone on a slow network, a cold cache, or an unfamiliar stack, and being wrong there is exactly where a reader gives up. Describe the *steps*, which are stable, not the *duration*, which isn't. *(This is a documentation rule and does not touch Guidelines §17.6, which asks for specific estimates in replies to the user — a reply estimates a job you are about to do; a doc estimates a stranger's machine.)*
- **Structure is CommonMark-clean** — ATX headers, exactly one H1, no skipped heading levels, fenced blocks with a language tag, real lists rather than dashes in a paragraph. A table of contents once the page passes roughly a screenful of headings.
- **Links resolve** — internal paths exist, anchors match a real heading, external links are ones you actually have reason to believe in. Relative links must survive wherever the docs are rendered (repo view and docs site resolve them differently).
- **Terminology is fixed** — one name per concept for the whole document set. If the code says `workspace` and the docs say `project`, pick one, say which, and record it in the profile.
- **Version and compatibility facts carry their source** — a supported-version range comes from the manifest, the CI matrix, or the engines field. If nothing states it, say "not specified" rather than picking a number that looks right.
- **Diagrams show a mechanism** — a diagram earns its place by showing something prose cannot: a flow, a sequence, a state machine, a boundary. Prefer text-based diagrams the repo can diff. Every diagram gets a caption saying what it shows, and any diagram the current change invalidates is updated in the same edit or removed. A box-and-arrow picture that restates the file tree is decoration; cut it.
- **Accessibility** — images carry real alt text describing the content, not the filename. Never ship a screenshot of text that could be text. Tables have real headers. Nothing is conveyed by colour alone.

---

## 2. The Refuse List

What documentation defaults to when nobody decided. The project's own brief can earn any of them back; reaching for one on autopilot means you weren't writing for a reader. Each line names the default, then what to do instead.

**Voice and framing**
- "Simply", "just", "easy", "obvious", "of course", "as you can see" → delete the word. They add nothing when the reader succeeds and blame them when they fail.
- Time estimates of any kind (§1) → the prerequisite list and the number of steps; the reader has their own clock.
- Marketing voice inside a reference or how-to page → sell on the landing page; the parameter table states types, defaults, and failure behaviour.
- A wall of prose before the reader knows what the thing is → first sentence, what it is; second, who it's for or what problem it kills.
- "See the code for details", "refer to the source", "self-explanatory" → state the behaviour here, or link the exact symbol with a one-line summary. If the code were sufficient, the doc would not be open.
- Apologetic or provisional framing — "this section is a bit rough", "docs coming soon" — left permanently in a shipped file → write it, or open an issue and link it.

**Structure**
- A feature table that restates the module list with no task attached → a task table: *to do X, see Y*.
- An auto-generated symbol dump presented as a guide → generated reference *as reference*, linked from a hand-written page that says when to reach for what.
- Deep heading nests (H4 and below) organising what is really a table → a table.
- Emoji on every heading as a substitute for hierarchy; badge rows longer than the description they sit above → plain headings; one badge row at most, shorter than the line under it.
- A "Contributing" or "License" section crowding the quick start above the fold → below the first success, linked from the top if needed.
- The same fact in three files → one home and links from the other two.

**Content**
- Invented numbers — benchmarks, adoption counts, uptime, "10× faster", coverage nobody measured → a measured figure with source and date, or a labelled placeholder (Guidelines §15).
- `foo` / `bar` / `example.com` / `YOUR_API_KEY_HERE` → a real identifier from this repo; a labelled placeholder only where the value is a secret.
- Documented aspirations — a flag, endpoint, or option that does not exist yet → document what exists; a roadmap lives in a file that says it is one.
- A comment or docstring that restates its own signature (`// gets the user` above `getUser()`) → the contract a caller cannot see from the signature: failure behaviour, side effects, units (Guidelines §13).
- Copying an upstream library's docs into your repo → link the upstream page at the version the lockfile pins. A copy is stale the day the dependency bumps.
- Screenshots as the only home of a value someone needs to type → the value as text beside the image.
