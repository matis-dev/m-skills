# Reference: Measurement

*`search-optimization-architect` reference. Read for `measure`, and before any number reaches a dashboard.*

## Measurement

### 1. The Discipline That Makes the Numbers Real

Generative answers are stochastic. Published stability measurements put run-to-run overlap far below what a single check would imply (`evidence-base.md`), which means **one prompt run once is not data.** The protocol:

1. **Fix the prompt set** — 20–30 prompts, versioned in a file, changed only deliberately. Changing the set silently is how every GEO dashboard becomes meaningless.
2. **Repeat each prompt ≥7–8 times per engine per cycle**, fresh session, no personalization, locale held constant. Fewer runs measure noise.
3. **Report medians with a spread**, never a single number. Trend direction over weeks beats any snapshot.
4. **Hold the denominator constant.** Share of voice moves when competitors change too; if the prompt set or engine mix changes, the series is broken — start a new one and say so.
5. **Segment by engine, always.** A blended "AI visibility score" across engines with ~11% source overlap (`SKILL.md` §1) is an average of unrelated things.

### 2. The Four Metrics That Mean Different Things

Conflating these is the most common dashboard error.

| Metric | Question it answers | How it's captured |
|---|---|---|
| **Retrieval** | Was the page fetched at all? | Server logs — the only ground truth you own |
| **Citation rate** | How often is the brand cited for the prompt set? | Repeated prompt runs, per engine |
| **Prominence** | Where in the answer, and named or paraphrased? | Position + a named/unnamed flag per run |
| **Absorption** | Was the content used without attribution? | The claim appears; no citation. Real, and it is why traffic under-reports influence. |

### 3. Instrumentation

- **Server logs are the primary instrument.** They show which AI user-agents fetched which URLs, how often, and what status they got — outside analytics entirely, and unfakeable. Any technical fix in §4 should show up here within a crawl cycle; if it doesn't, the fix didn't land.
- **Analytics: one dedicated channel group** for assistant referrers, ordered above generic referral so the traffic stops hiding inside it. Resolve the referrer list at build time; it changes.
- **Conversion, not sessions.** Assistant referrals are typically low-volume and high-intent — a session count makes the channel look trivial. Track the conversion event from the Profile, and report rate alongside volume.
- **Attribution honesty.** The largest effect of AI search is answers that never produce a click. Never present referral traffic as the measure of AI visibility; pair it with citation-rate data and say plainly which part is unmeasurable.

### 4. What the Dashboard Says at the Top

One line, in this shape: *"Across `<N>` prompts × `<R>` runs on `<engine>`, cited in `<x>%` (median, `<range>`), up from `<y>%` on `<date>`; `<M>` AI-crawler fetches of the target pages this period."* Everything else is a drill-down. If a number cannot be stated in that shape, it is not ready to be on the dashboard.

---
