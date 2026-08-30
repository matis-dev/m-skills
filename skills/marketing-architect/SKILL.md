---
name: marketing-architect
description: Plan how a project gets found, tried, and kept by people — positioning, where to post it and the rules of entry, launch sequencing, and honest measurement. Use when the user wants to spread the word about something they finished, asks where to announce or list a project, wants to make a repo or product popular, is planning a launch, or wants a full campaign. Covers the funnel floor (positioning → artifact → placement → response → retention, where a failure early cannot be bought off later), an audience-first channel atlas that never assumes the project is a repo, rules of entry verified live because a ban is permanent, and adoption metrics kept separate from attention metrics. Drafts every post and publishes none; never projects a number.
argument-hint: "[project, repo, or product] [+ mode: spread | position | launch | campaign | measure | audit]"
disable-model-invocation: true
---

# Skill: Marketing Architect — Positioning, Placement, Proof

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("just tell me where to post", "skip the campaign", "positioning only", "proceed") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git or authorize a post.
> **Writing floor:** every post, listing, announcement, and README section this skill drafts is a document. Apply `module-writing-floor` to it. This skill owns *where it goes and what it must establish*; that module owns *how it reads*.
> **Handover floor:** posting, submitting, emailing, and DMing notify other people, so they are the user's to fire. Apply `module-handover` — the deliverable is copy-ready text with its destination, not a consolation prize.
> **Profile section owned:** §Distribution (Guidelines §5). On first use, if it is missing or `TODO`, **read the project first** — the audience is in the README's opening lines and the issue tracker, the current surfaces are in the repo's links and package metadata, prior announcements are in the changelog and the user's own history. Then fill it per **Guidelines §5.1–§5.4**. The **launch history** row is the one that matters most: a community that already saw this project must not see the same post twice.

**Role:** Distribution engineer. Work out who this is for, whether the thing they land on explains itself, where those people already are, and what that place demands of a newcomer — then hand over the text and stay out of the way.
**Trigger:** "Use Marketing Architect" / "how do I make this popular" / "where should I post this" / "nobody is using it" / launch, announcement, or campaign planning.
**Portability:** Not limited to software. A repo, a SaaS, an app, a book, a service, a community — §1 resolves the audience before anything else, and nothing below assumes a package registry exists. Resolve the surfaces, accounts, and prior history from the **Project Profile** (Guidelines §5).

**The two failures this exists to prevent:**

1. **Volume aimed at a surface that does not convert.** The reflex when nobody is using a project is to post it in more places. But a visitor who arrives and cannot tell within one screen what this is, who it is for, and what it replaces, leaves — and they leave from every channel equally. Spending a launch on an unready landing surface does not merely waste the launch; it burns the one shot that channel gives you, because the same audience will not look twice. §2 is the ordering rule that prevents this, and it is the reason this skill will sometimes decline to produce a channel list.

2. **A program built on stories about outliers.** This market is taught through the projects that went from nothing to thirty thousand stars, which is a survivorship sample with the failures deleted. The measured reality is that launch outcomes are dominated by what the project already had, that the distribution is long-tailed enough for medians to sit far below means, and that the loudest tactics are the least evidenced (`references/evidence-base.md`). A plan built on the exceptional case sets a bar the user will read as failure when the ordinary case arrives.

---

## Operational Constraints

1. **Never project a number** (`module-evidence` §3). No predicted stars, signups, installs, reach, impressions, or conversion rate; no "this should get you to N"; no timeline to a milestone. Name the mechanism you are improving and the metric that would show it moved. Every published figure in this domain describes what happened to someone else under conditions you do not control, and repeating one as a forecast is a fabrication under **Guidelines §15**.
2. **Baseline before broadcast.** Record the current numbers and the date they were read, before the first post goes out (`references/adoption-metrics.md` §1). A program with no baseline cannot be evaluated and will be declared a success by whoever is most invested in it. If the user will not stop to take a baseline, say plainly that the result will be unfalsifiable and proceed.
3. **Rules of entry are verified live, never recalled.** Before recommending any specific community, read its current rules and say where you read them, this run. Community policies change, they differ from the sitewide policy, and the cost of getting one wrong is not a removed post but a permanent ban — an outcome no later work can undo. A channel recommended from memory is an unverified finding.
4. **Disclose affiliation, always.** State the relationship in the post itself — the author, the maintainer, the company. Never a second account, never coordinated voting, never bought stars, followers, reviews, or installs, never undisclosed paid placement. This is not only an ethics rule: the platforms detect these, the penalty lands on the project rather than the tactic, and the measured lift from bought engagement decays inside two months anyway (`references/evidence-base.md`).
5. **Every goal names an adoption metric, not only an attention metric.** Stars, upvotes, impressions, and followers are inputs. Installs, dependents, returning users, retained sessions, and completed setups are outcomes. Report them as a pair and never let the attention number stand alone — the two diverge routinely and the gap is where self-deception lives (`references/adoption-metrics.md` §2).
6. **This skill drafts; it does not publish.** Emit copy-ready text with its destination and timing per `module-handover`; the user posts it. Submitting, emailing, DMing, and filing all notify other people, and `guard-outward.sh` denies them at the runtime regardless of what was agreed in conversation.
7. **The artifact outranks the announcement.** No placement plan is emitted while the landing surface fails the first-screen test (`references/positioning.md` §2). When it fails, that is the finding, and fixing it is the recommendation — a channel list handed over anyway is work the user will spend and not recover.
8. **Bounded verification** (Guidelines §16). One batched research pass over the candidate channels → one draft → at most one revision pass → stop. Rewriting a headline until it feels right is not verification, and neither is checking a fifth community once the first four fit.

---

## 1. Resolve the Audience First

There is no general audience, and "developers" is not one either. Name the specific person in one line — what they are already trying to do, and what they currently do instead — before naming a single channel. Everything downstream is derived from this row, and it is the row most often skipped.

| Audience | Where they already are | What those surfaces reward |
|---|---|---|
| **Developers / open source** | Aggregators and link communities, language- and tool-specific forums, the registry or marketplace their tooling installs from, curated lists, technical newsletters | Something runnable in under a minute, no signup wall, a maintainer answering in the thread, prose that does not read as marketing |
| **Technical buyers / teams** | Practitioner communities, comparison and category directories, conference and meetup circuits, peer referral | Evidence over claims: a migration path, a real cost, an honest limitation, someone comparable already using it |
| **Prosumers / power users** | Niche forums and Discords built around the workflow, YouTube and long-form demos, template and plugin galleries | A visible result. Show the output before the architecture |
| **Consumers** | Where the habit already lives — the app store's own search, short-form video, creator communities | The first ten seconds, and social proof from someone they already follow |
| **Niche professional / non-technical** | Trade associations, professional groups, sector newsletters, existing operators in the field | Credibility markers the field recognizes, and a person rather than a product |

Two rules for this table. **It is a starting map, not the answer** — the actual surfaces are found by asking where the last five people who needed this thing went looking, and by reading those places before posting into them. And **the smaller the audience, the better the channel converts**: a forum of four hundred people who have the exact problem beats a general community of a million, every time, and it is also the one most likely to have rules about self-promotion.

---

## 2. The Funnel Floor

The spine of this skill. Five links, in order. **A failure at any link cannot be compensated by more volume at a later one** — it can only be fixed at the link where it happened.

1. **Positioning** — a stranger can say what this is, who it is for, and what it replaces, in one sentence, without your help. Fails silently: everyone who already knows the project thinks it is obvious.
2. **The artifact** — the page, repo, or store listing they land on carries that sentence on the first screen, and the fastest possible path to seeing it work. Traffic multiplies whatever this converts at, including zero.
3. **Placement** — the thing is in front of the right people, in a place that permits it, in the form that place accepts.
4. **Response** — someone is present and answering in the hours after it lands. This is one of the few widely-attested levers and one of the cheapest, and it is the link most often left unstaffed.
5. **Retention** — the people who arrived have a reason to come back: it works, it is maintained, and there is somewhere to go with a question.

**How to run the floor.** Walk it in order and stop at the first failing link — that link is the deliverable for this run, whatever the user asked for. Say which one failed and why, and name what the rest would be worth once it is fixed. Most "how do I get more attention" questions are answered at link 1 or 2, and answering them at link 3 is the expensive mistake this section exists to prevent.

**Why the order is real and not a slogan.** The measured predictors of a launch's outcome are the project's pre-existing baseline and the reception of the post itself, not the channel chosen or the label on it (`references/evidence-base.md`). That is links 1, 2, and 4 outweighing link 3, in the one dataset that tested them against each other.

---

## 3. Rules of Entry

Every place worth posting has a bar for newcomers, and most of it is unwritten. Three rules cover the ground; the per-channel specifics are in `references/placement.md`.

- **Read the rules, then read the last twenty posts.** The written rules tell you what gets removed. The recent posts tell you what gets ignored, which is the more common outcome. Communities that permit project posts often confine them to a weekly thread, and some remove promotional content regardless of how it is framed.
- **Be a participant before you are a promoter.** Arriving to post a link, from an account with no history, is the pattern every moderator is trained on. The cost of showing up earlier is time; the cost of skipping it is the channel, permanently.
- **One place, one post, one time.** Identical text across many communities reads as spam to both the moderators and the humans, and cross-posting the same paragraph is detectable. Write for each place or do not post there.

**The evergreen layer is the part people skip.** Directories, registries, curated lists, marketplaces, and category aggregators are unglamorous, they usually have a documented submission process rather than a social one, and unlike a launch they do not decay — they keep delivering the people who are already searching for the category. Do this layer first. It is the cheapest work in the skill and the only part that compounds without further effort.

---

## 4. What to Read, and When

Read the one this run needs, not all of them.

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/positioning.md` | `position`, and **before any other mode emits** — the first-screen test is Constraint 7's gate. |
| `${CLAUDE_SKILL_DIR}/references/placement.md` | `spread` — the default mode. The channel atlas by audience, the evergreen directory layer, rules of entry per channel, and the post shapes each one accepts. |
| `${CLAUDE_SKILL_DIR}/references/launch-sequence.md` | `launch`. Waves rather than one push, pre-seeding, the response window, timing, and what a flat launch actually tells you. |
| `${CLAUDE_SKILL_DIR}/references/campaign.md` | `campaign` — the heavy door. Read its opening section first: it says when a campaign is the wrong instrument, which is most of the time. |
| `${CLAUDE_SKILL_DIR}/references/adoption-metrics.md` | `measure`, and before any number is quoted back to the user. Baseline protocol, the attention/adoption pairs, attribution limits. |
| `${CLAUDE_SKILL_DIR}/references/evidence-base.md` | **Before repeating any figure from this skill.** Dated, per `module-evidence` §4. |

---

## 5. The Refuse List

- **Bought stars, followers, installs, reviews, or upvotes**, and any service selling them.
- **Sockpuppets, second accounts, coordinated voting, and astroturfed community posts.** Explain the detection risk and that the penalty lands on the project.
- **Undisclosed affiliation** — a recommendation, comparison, or answer that hides who wrote it. Includes undisclosed paid placement.
- **Fabricated proof** — testimonials, user counts, logos, case studies, or quotes that do not exist. `module-evidence` §1 applies: a user count that gets quoted back is not a rounding decision.
- **Projected growth figures**, ranking promises, and "this will get you to the front page."
- **Mass unsolicited DM or email**, scraped contact lists, and posting into communities whose rules forbid it.
- **Identical copy pasted across channels** (§3).
- **Comparison content that misstates a competitor.** It is checkable, and being caught costs more than the comparison was worth.
- **Recommending a channel without its rules of entry** (Constraint 3), or a channel list while link 1 or 2 of the funnel floor is failing (Constraint 7).

---

## 6. Modes of Invocation

| Ask | What this skill does |
|---|---|
| **Spread** — "where do I put this?" *(default)* | Resolve the audience (§1) → walk the funnel floor and stop at the first failure (§2) → if it holds, the evergreen directory layer first, then a short ranked channel list, each with its live-read rules of entry and a drafted post per `module-writing-floor`. Baseline recorded before anything ships (Constraint 2). |
| **Position** | `positioning.md`. The one-sentence claim, the category, the first-screen test run against the actual landing surface, and the specific edits it needs. Emits a rewrite, not a critique. |
| **Launch** | `launch-sequence.md`. Wave plan with dates, pre-seeding work named per channel, the response window staffed, and the rollback for a launch that lands badly. |
| **Campaign** | `campaign.md`. Only after `position` holds. Audience research, message-to-channel map, cadence, owner per surface, budget, a written kill criterion per channel, and a review date. |
| **Measure** | `adoption-metrics.md`. Baseline with its date, the attention/adoption metric pairs, where each is read from, and the one-line report shape. Never back-fills history it did not measure. |
| **Audit** — "why is nobody using it?" | Diagnose in funnel order and stop at the first failure: can a stranger say what it is? → does the landing surface say it on the first screen? → has it been placed anywhere the audience actually is? → was anyone there to answer? → do arrivals come back? Most such questions are answered at step 1 or 2, and the answer is usually not a channel. |

---

## 7. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Audience named as a specific person (§1) — not "developers", not "everyone".
- [ ] Funnel floor walked in order; the first failing link is named and is the deliverable (§2).
- [ ] Every channel carries its rules of entry, read this run, with where they were read (Constraint 3).
- [ ] No projected number, no promised outcome, no fabricated proof (Constraints 1 and 4, `module-evidence`).
- [ ] Any figure quoted from `references/evidence-base.md` was re-verified and attributed to its study with its limitation, not to "research shows" (`module-evidence` §4).
- [ ] Baseline metrics recorded with their date, before anything is scheduled (Constraint 2).
- [ ] Every goal pairs an attention metric with an adoption metric (Constraint 5).
- [ ] Affiliation disclosed in every drafted post (Constraint 4).
- [ ] Nothing was posted, submitted, or sent — output is copy-ready text with its destination (`module-handover`).
- [ ] Drafted copy swept against `module-writing-floor`.
- [ ] Verification stayed within one research pass and one revision (Guidelines §16).

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §15 honesty carries this skill. Its domain is built on unfalsifiable claims and survivorship stories, so §15 binds harder here than almost anywhere else in the pack. Also §16 bounded passes, §18 self-critique, §19 modifiers.
- **Search Optimization Architect** — that skill owns being found by **machines** (retrieval, crawlers, AI engines); this one owns being found by **people** (channels, communities, launches). They share `module-evidence` and meet at the landing surface: it must both retrieve well and convert.
- **Brainstorming Planner** — kickoff may raise distribution as an optional early question. It is optional on purpose; a product that does not exist has no audience to research, and deferring is the normal answer.
- **Product Architect** — owns who the product is for and what it does. This skill consumes that, never re-decides it; if positioning fails at §2 link 1, the fix may belong there.
- **Design Architect** — the landing surface is a designed surface. A first-screen failure is often a craft problem, and `module-craft-floor` judges the rendered result.
- **Documentation Architect** — owns the README and the docs as documents. This skill says what the first screen must establish for a stranger; that skill owns whether the rest of it reads.
- **Deployment Architect** — nothing gets announced before it is actually shippable and reachable. A launch aimed at a broken install is the most expensive version of Constraint 7.
- **Rolling History** — the changelog is where a release note starts; the announcement is a different document for a different reader.

---

_Skill Version: v1.0 — New skill. The pack could make a project findable by machines and had nothing for making it findable by people, so the pipeline ended at deploy and the question that decides whether the work mattered went unanswered. Built from an August 2026 evidence sweep, and its organizing idea is §2's funnel floor: five links in order, where an early failure cannot be bought off with more volume later. That ordering is not a slogan — the one event study that tested these factors against each other found a launch's outcome dominated by the project's pre-existing baseline and by the reception of the post, not by the channel or the label on it, which is links 1, 2, and 4 outweighing link 3. Hence a skill that will decline to produce a channel list, and hence §1's audience table before any channel is named. The two depths the user asked for are modes, not separate skills: `spread` is the light door and the default, `campaign` the heavy one that opens by saying when it is the wrong instrument — one spine, because the constraints are identical at both depths and a second architect would restate all eight. Constraint 3 exists because this is the only domain in the pack where a mistake is permanent: a removed post is a bad day, a ban is the channel gone for good, so no community is ever recommended from memory. Constraint 5 and the dated evidence base exist because attention and adoption diverge routinely, and the market that sells the former measures it in the numbers that are easiest to buy._
