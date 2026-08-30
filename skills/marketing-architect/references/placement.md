# Reference: Placement

*`marketing-architect` reference. Read for `spread` — the default mode. Every channel here is a candidate, never a recommendation: Constraint 3 requires reading its live rules before it enters an output.*

## Placement

### 1. Order of Operations

Do these in order. The order is the advice — most people run 3 first and skip 1 entirely.

1. **The evergreen layer** — directories, registries, marketplaces, curated lists, category aggregators. Documented submission processes, no social capital required, and unlike a launch they do not decay: they keep delivering people who are *already searching for the category*. Cheapest work in the skill, and the only part that compounds unattended.
2. **The narrow channel** — the smallest place where the audience from `SKILL.md` §1 is concentrated. It converts best, and it is also the most likely to have rules about newcomers.
3. **The broad channel** — the aggregator or link community. Highest ceiling, highest variance, one shot per project, and the medians are sober (`evidence-base.md`). Do not start here.
4. **The owned surface** — a changelog, a mailing list, a feed people opted into. Slow to build, and the only distribution nobody can revoke.

### 2. The Evergreen Layer, Concretely

The specific destinations depend on what the project is; the *kinds* do not.

| Kind | What it is | How it is entered |
|---|---|---|
| **Package / plugin registry** | Where the audience's tooling installs from | Publish correctly: description, keywords, links, license, a working install line. Most of the traffic is search inside the registry, so the description is the ranking surface. |
| **Marketplaces and plugin directories** | Third-party catalogs for an ecosystem, often auto-indexed from the source repo | Some ingest automatically — the fix is in the repo's own metadata. Others take a submission. Find which, per directory. |
| **Curated lists** | `awesome-*` and equivalent, per ecosystem | A pull request against their stated contribution rules, in their entry format, in the right section. Read the last ten merged PRs; most rejections are formatting. |
| **Category directories and comparison sites** | Where buyers browse a category | A profile with the positioning sentence and honest limitations. Long-lived. |
| **Ecosystem docs and integration pages** | The upstream project's own list of things that work with it | Usually a PR or a form. The highest-intent traffic in this table, and the least contested. |

**The metadata is the placement.** For registries and auto-indexed directories, nothing is written *to* the directory — it reads the repo. So the description, keywords, topics, license, and homepage in the project's own manifest *are* the listing, and fixing them updates every directory that mirrors them at once.

### 3. The Social Layer, By Audience

Resolve the audience first (`SKILL.md` §1), then pick two or three. Never all of them.

| Audience | Channel kinds worth the effort | What the post has to be |
|---|---|---|
| **Developers / OSS** | Link aggregators; language-, framework-, and tool-specific forums and chat communities; technical newsletters; developer blogging platforms | Something runnable, a real limitation stated, and the author present in the thread. Marketing register is detected instantly and is fatal. |
| **Technical buyers** | Practitioner communities, sector newsletters, meetups and conference CFPs, peer referral | Evidence: a migration path, a real cost, what it does badly, someone comparable already using it. |
| **Prosumers** | Workflow-specific forums and chat servers, long-form video, template and gallery surfaces | The result first. Show the output before the architecture. |
| **Consumers** | The store's own search, short-form video, creator communities | The first ten seconds, and proof from someone they already follow. |
| **Niche professional** | Trade associations, professional groups, sector publications, existing operators | Credibility the field recognizes, and a person rather than a product. |

### 4. Rules of Entry — the Checklist Per Channel

Before a channel enters an output, all six, read **this run**:

- [ ] **Written rules read**, and the self-promotion rule quoted with where it was read.
- [ ] **The last ~20 posts read** — what gets removed is in the rules; what gets ignored is only in the feed.
- [ ] **The permitted form identified** — standalone post, weekly thread, dedicated flair, comment-only, or not permitted at all.
- [ ] **Disclosure requirement identified**, and the disclosure written into the draft.
- [ ] **Account standing checked** — age, history, whether the user has participated there. A first post from a fresh account is the pattern moderators screen for.
- [ ] **Prior history checked** against the profile's launch-history row. This community may already have seen this project.

**When a channel forbids it, the finding is "not permitted", and that is the end of it.** Do not propose a workaround, a reframe, or a second account. A community you are banned from is worth zero permanently, and no later work recovers it.

### 5. The Post Itself

- **Written for that place, once.** Identical text across communities is detectable, reads as spam to humans and moderators alike, and is the fastest way to lose several channels at once.
- **Affiliation in the post, not in a reply.** One clause: "I built this."
- **Lead with the thing, not the story.** The origin story earns attention only after the reader knows what it is.
- **State one real limitation.** It is the single most credible sentence available to you, it pre-empts the top comment, and it costs nothing that was not going to come out anyway.
- **No superlatives, no "revolutionary", no competitor disparagement.** Comparisons are checkable and being caught costs more than the comparison was worth.
- **Someone is present for the next few hours.** Unstaffed is link 4 of the funnel floor failing, and it is the cheapest link to hold.

Sweep every draft against `module-writing-floor` before emitting, and hand it over as copy-ready text per `module-handover` — this skill does not post.

---
