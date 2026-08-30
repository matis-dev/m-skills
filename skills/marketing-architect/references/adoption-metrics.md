# Reference: Adoption Metrics

*`marketing-architect` reference. Read for `measure`, and before any number is quoted back to the user. Honesty discipline per `module-evidence`.*

## Adoption Metrics

### 1. Baseline Before Broadcast

Do this before the first post, not after. It takes minutes and it is the difference between a program that can be evaluated and one that will be declared a success by whoever is most invested in it.

1. **Write down every number that exists today, with the date it was read.** Attention numbers and adoption numbers both.
2. **Record where each was read from** — which page, which dashboard, which command. A number whose source is not recorded cannot be re-read the same way, and the series is broken the first time someone else takes the reading.
3. **Note what is already in flight** — an existing listing, a post from last month, a mention someone else made. Otherwise their tail gets attributed to the launch.
4. **Store it in the profile's §Distribution baseline row, with its date** (Guidelines §5).

**If the user will not stop to do this, say plainly that the result will be unfalsifiable, and proceed** (Constraint 2). Refusing to continue is not the right call; letting them believe the outcome will be readable is.

### 2. The Pairs

Every attention metric is reported next to the adoption metric it is supposed to predict. Alone, the left column is a number that can be bought (`evidence-base.md`); together, the pair tells you whether anything real happened.

| Attention (input) | Adoption (outcome) | What the gap means when it is wide |
|---|---|---|
| Stars, follows, bookmarks | Installs, clones, dependents, active projects | People approve of the idea and are not using it — usually a first-screen or setup-friction problem, not a channel one. |
| Upvotes, impressions, views | Visits that reached the install or signup step | The pitch traveled and the surface did not convert. Funnel floor link 2. |
| Visits | Returning visitors, second sessions, retained users | It was tried once. Whether that is fine or fatal depends on whether the thing is meant to be used repeatedly — decide that before reading the number. |
| Signups, downloads | Completed setup, first successful use, week-two use | The most important gap in the table, and the one most often not instrumented at all. |
| Mentions, inbound links | Issues, questions, contributions | People are talking about it without touching it. Common right after a spike, and it decays. |

**Both columns are reported, always** (Constraint 5). An attention number standing alone is the single most reliable way a project convinces itself it is working.

### 3. What the Numbers Cannot Tell You

- **Attribution is partial and always will be.** Referrers are stripped, links are shared privately, people search the name later. Report what is attributable, say what fraction is not, and never present the attributable slice as the total.
- **A spike is not a trend.** Read the level it settles at afterwards, not the peak. The peak is the least informative number available.
- **Counts do not carry causes.** A rise after three simultaneous actions cannot be assigned to one of them — which is the practical argument for waves (`launch-sequence.md` §1) beyond everything else.
- **Public counts can be manipulated**, including on projects the user is comparing themselves against (`evidence-base.md`). A competitor's star count is not evidence of anything.
- **Absence of a number is not absence of an effect**, and the inverse is also true. Say which, rather than filling the gap.

### 4. The Report Shape

One line, in this shape, then drill-down:

> *"Since `<baseline date>`: `<attention metric>` `<from>` → `<to>`, `<adoption metric>` `<from>` → `<to>`. `<n>` of that is attributable to `<channel>`; the rest is unattributed."*

If a number cannot be stated in that shape — no baseline, no date, no adoption pair — **it is not ready to be reported**, and saying so is the finding. Never back-fill a baseline that was not taken, never reconstruct a series from memory, and never present a projection where a measurement is expected (Constraint 1, `module-evidence` §3).

---
