# Reference: Kickoff Mode

*`brainstorming-planner` reference — read when the run needs it.*

## Kickoff Mode (a project that doesn't exist yet)

Triggered by "kickoff", or whenever there is no meaningful code to brainstorm against. This is the **entry point for a greenfield project** — the pack's other skills need decisions that nobody has made yet, and this conversation is where they get made.

**Run it as a conversation, not an intake form.** Five questions maximum before you start proposing; propose with a rationale and let the user correct you. Deciding badly and being corrected is faster than interrogating someone into boredom, and a wrong default is cheap to change on day one.

### 1. Establish what it is (this is the only part nobody else can do)
- **What is being built, for whom, and what does success look like for that person?**
- **What already exists?** A design, an API, a prior version, a competitor they like, nothing.
- **What is the smallest thing that would be genuinely useful?** Everything else is v2 — name it as such and move on.
- **What are the hard constraints?** Deadline, platform, team size, budget, a service that must be integrated, a compliance requirement.

### 2. Route the foundational decisions to the skill that owns them
**Do not decide these yourself.** Each is another skill's §Profile section (Guidelines §5); your job is to notice which are needed *now* and hand them over. Most greenfield projects need only the first two on day one.

| Decision | Owner | Needed when |
|---|---|---|
| Stack, repo shape, gate commands | recorded by the session bootstrap once files exist | as soon as there's a manifest |
| Test layers, placement, coverage bar | `testing-architect` | before the first test — which is before the first feature |
| Visual world, tokens, component vocabulary | `design-architect` (**Establish** mode) | before the first screen |
| Hosting, environments, rollback | `deployment-architect` | before the first deploy, **not now** |
| Changelog format, commit convention | `rolling-history` | at the first commit |

Say plainly which of these you are deferring and to when. **Deferring is the default** — a project that hasn't been built has no business deciding its rollback mechanism.

### 3. Seed the profile with what was actually decided
Write only the rows this conversation genuinely settled, and mark the rest `pending: <when>` (Guidelines §5). No `assumed:` values in a greenfield profile — an unchallenged guess recorded on day one becomes a fact nobody remembers choosing.

### 4. Then run Active Discovery on the first slice
Kickoff ends where the normal skill begins: take the smallest useful thing from step 1 and pressure-test it below. The emitted Deep-Dive Execution Prompt is for **that slice**, not for the whole product.

> **The failure mode to avoid:** turning kickoff into an architecture-astronomy session that designs a system for a product nobody has used yet. Decide what's needed to build the first slice. Everything else is `pending`, and that is the correct answer.

---
