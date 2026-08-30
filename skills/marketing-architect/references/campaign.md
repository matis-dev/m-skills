# Reference: Campaign

*`marketing-architect` reference. Read for `campaign` — the heavy door. Read §1 before anything else in this file.*

## Campaign

### 1. When a Campaign Is the Wrong Instrument

Most projects that ask for a campaign need `positioning.md` and `placement.md` and a month of showing up. Say so before building one. A campaign is warranted only when **all** of these hold:

- [ ] Positioning has been tested against strangers and held (`positioning.md` §2), not merely written.
- [ ] Something already worked at small scale — a channel that returned real users, not just attention. A campaign amplifies a known-working motion; it does not discover one.
- [ ] There is a **named owner with recurring time**, not an intention. A campaign is a standing commitment, and an abandoned one is worse than none because it advertises the abandonment.
- [ ] There is a metric the user will actually look at, and a date they will look at it on.
- [ ] Retention is not the bottleneck. Pouring people into a leaking bucket is the most expensive way to learn what `adoption-metrics.md` §2 would have told you for free.

**If any box is unchecked, say which, and run the lighter mode instead.** That is finished work, not a refusal, and it is usually the more valuable answer.

### 2. The Plan, in Six Rows

Keep it to one page. A campaign plan longer than a page is a document nobody will re-read on the review date, which makes it decoration.

| Row | What it holds |
|---|---|
| **Audience** | The specific person (`SKILL.md` §1), and the evidence that this is who actually shows up — not who was hoped for. |
| **Message** | The positioning sentence, plus the two or three proof points that support it. One message. A campaign carrying three messages carries none. |
| **Channels** | Two or three, each with its rules of entry (`placement.md` §4), its owner, and its cadence. Not a list of everywhere. |
| **Cadence** | What ships, how often, sustainably. Weekly forever beats daily for three weeks — and the second pattern is the one that gets planned. |
| **Budget** | Money and hours, both stated. Hours are the one that runs out first and the one never written down. |
| **Kill criteria** | Per channel, in advance: the observation that would mean *stop doing this*. Written before the channel starts, because afterwards it is unwritable. |

### 3. Kill Criteria

The row that makes the difference between a campaign and an open-ended expense. A kill criterion names an **observation and a date**, chosen so that it is possible to fail:

> *"By `<date>`, `<channel>` has produced fewer than `<n>` `<adoption events — not impressions>`. Then we stop it and say so."*

Two rules. **Never state the number as a projection** — it is a decision threshold the user chooses, not a forecast (Constraint 1); write it as "below this, we stop", never as "we expect". And **hold the review date**. A campaign whose kill criteria are quietly renegotiated on the day is one that cannot end, and the sunk-cost renegotiation is the normal failure, not the exception.

### 4. The Content Engine

If the campaign involves publishing, the failure mode is a burst that stops. Three rules:

- **Formats before topics.** Two or three repeatable shapes (a build log, a teardown, a benchmark, a release note) beat a list of one-off ideas, because a shape can be filled on a bad week.
- **Write from work that is happening anyway.** Content that requires inventing a reason to exist is the first thing dropped, and it reads that way.
- **Publish to an owned surface first, syndicate second.** The channel can change its rules; the archive cannot be revoked.

Every piece goes through `module-writing-floor`. A campaign is not an exemption from writing well — it is a commitment to doing it repeatedly.

### 5. Paid

Out of scope for most projects here, and mentioned so the answer is explicit rather than an omission. If it comes up:

- Paid amplifies a converting funnel and reveals a broken one expensively. Everything in `SKILL.md` §2 applies first, and unchanged.
- **Disclosure is not optional.** Paid placement, sponsorship, and affiliate arrangements are labelled, both because platforms and regulators require it and because being caught costs more than the placement bought.
- **Never project a return** (Constraint 1). Set a fixed amount the user is willing to lose entirely, a date, and a kill criterion — the same three rows as §3.
- This skill does not buy, bid, or place anything. Like every outward action, it hands over the plan (`module-handover`).

### 6. Review

On the date, in writing, in four lines: what was done, what the numbers did against the baseline, which kill criteria fired, what stops. **A campaign with no honest review is indistinguishable from one that worked**, which is exactly why the review is the deliverable rather than the plan.

---
