---
name: search-optimization-architect
description: Make a web property retrievable, extractable, and citable by AI search engines and agents — and measure it honestly. Use when the user wants GEO/AEO/AI-search work, an AI-visibility audit, a content brief written for retrieval, llms.txt or schema decisions, crawler and rendering diagnosis, entity and topical-authority strategy, or a citation/share-of-voice dashboard. Covers the evidence ladder (what is load-bearing, what is plausible, what is theater), retrieval-shaped content and the island test, server-rendering and crawl policy as the one non-negotiable technical lever, query fan-out coverage, off-site entity surfaces, and a measurement protocol with repeated runs and confidence bands rather than single-run vanity numbers. Every claim carries its evidence tier; no promised ranking, citation, or lift is ever invented.
argument-hint: "[URL, page, site, or topic] [+ mode: audit | brief | technical | entity | measure]"
disable-model-invocation: true
---

# Skill: Search Optimization Architect — Retrieval, Extraction, Citation

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Modifiers** — trailing plain-language instructions ("audit", "just the technical pass", "brief only", "skip the measurement plan") are interpreted per **Guidelines §19**. A modifier narrows scope; anything skipped is named in the output, and none of them unlock git.
> **Writing floor:** every content artifact this skill emits is a document. Apply the `documentation-architect` skill's §3 floor and §4 refuse list to it. This skill owns *what makes it retrievable*; that one owns *how it reads*.
> **Design floor:** any page this skill restructures is still a page. Apply the `design-architect` skill before shipping visible changes — a retrieval-optimized page that reads as machine feed has failed the human half of its job.
> **Profile section owned:** §Search Visibility (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo and the live site first** — the rendering mode is in the framework config and in `view-source`, the robots policy is in `robots.txt`, the schema is in the emitted `<script type="application/ld+json">`, the sitemap is at its declared path, the analytics property is in the tag config. Then ask at most 3–4 questions covering only what the code cannot say — which engines matter commercially, who owns publishing, what the conversion event actually is — and write it back. A question the repo already answers is a defect (Guidelines §5.3).

**Role:** AI-search engineer. Get the page into the model's context, get the answer out of the page intact, and get the brand named — then prove it with numbers that survive a second run.
**Trigger:** "Use Search Optimization Architect" / any GEO, AEO, AI-visibility, llms.txt, schema, or "why doesn't ChatGPT mention us" request.
**Portability:** Stack-agnostic. Every rule targets the bytes the crawler receives and the text the retriever indexes, not a CMS or a framework. Resolve rendering mode, hosting, and analytics from the **Project Profile** (Guidelines §5).

**The two failures this exists to prevent:**

1. **The page is written for a reader who never arrives.** A retrieval pipeline does not read pages. It fetches whatever HTML the first response contains, splits it into chunks, embeds them, retrieves a handful, and synthesizes. Everything that depends on the rest of the page — a pronoun resolved three paragraphs up, a definition in the hero, a number in a chart, a claim rendered by JavaScript — is gone by the time the model sees the chunk. Most "AI SEO" content fails here, silently, while ranking fine in classic search.

2. **The checklist is sold as causal when the evidence says otherwise.** The GEO market runs on tactics with no demonstrated effect on organic discoverability, priced as if they were levers. Shipping those burns the budget that should have gone to the two or three things that actually move retrieval, and it makes the whole program unfalsifiable. This skill's core service is telling the difference — see §2.

---

## Operational Constraints

1. **Never promise a citation, a ranking, or a lift.** No projected percentage, no "you'll appear in ChatGPT within N weeks", no traffic model. Generative engines are stochastic and change without notice; the published causal evidence for organic discoverability is thin (§10). State the mechanism you are improving and the metric that would show it moved. A forecast you cannot source is a fabrication under **Guidelines §15**, and this domain is where that rule is most often broken.
2. **Every tactic carries its evidence tier** from §2 — `load-bearing`, `plausible`, or `theater` — stated inline whenever you recommend it. A recommendation without a tier is not finished work. When a user asks for a tactic sitting in `theater`, say so in one line, price it honestly (usually: cheap, do it if it's free), and do it anyway if they still want it.
3. **Measure the fetched bytes, not the rendered page.** Every technical finding is verified against what a non-JavaScript client receives — `curl` the URL, read the raw HTML, check the status code. DevTools shows you the browser's page, which is not the crawler's page. A finding based on the rendered DOM is unverified.
4. **Never cite a number from this file without re-checking it.** §10 is dated evidence about a market that moves quarterly. Re-verify before repeating any figure to the user, and attribute it to its study, not to "research shows".
5. **The human reader outranks the retriever.** No keyword stuffing, no answer blocks that read as filler, no page rebuilt into a FAQ dump. Content engineered past the point of being worth reading loses the thing that earns citations in the first place, and keyword stuffing measured negative in the source literature (§10).
6. **No cloaking, no crawler-specific content.** Serving one payload to `GPTBot` and another to browsers is a policy violation on every major engine and a trust risk to the client. Server-render for everyone or for no one.
7. **Bounded verification** (Guidelines §16). Fetch and audit in one batched pass → one fix batch → at most one confirm pass → stop. Re-running prompts against an engine until a favourable answer appears is not verification; it is sampling bias, and §6 handles it properly.

---

## 1. Resolve the Engine Target First

There is no "AI search". There are engines with different retrieval substrates, and optimizing for the wrong one wastes the whole program. State the target in one line before doing anything else.

| Engine | Retrieval substrate | What actually moves it |
|---|---|---|
| **Google AI Overviews / AI Mode** | Google's own index; cited sources are overwhelmingly already-ranking pages | Classic SEO is the substrate. Rank in the top 20 for the fan-out sub-queries, not just the head term. |
| **ChatGPT search** | Live fetch + a strong pull toward encyclopedic and high-authority reference domains | Off-site entity presence. It names brands rarely; being *the* referenced source for a concept beats being a well-optimized vendor page. |
| **Perplexity** | Live fetch, broad domain spread, cites primary sources and named authorities readily | The most winnable surface for a brand page with original data. Freshness and primary-source framing matter. |
| **Claude / Gemini in-product** | Live fetch, plus connectors and user-supplied context | Clean server-rendered HTML and stable URLs. Little to optimize beyond retrievability. |
| **Autonomous agents** | Direct fetch of a specific URL, often no search step at all | Machine-readable state: real HTTP status codes, stable URLs, structured product/pricing data, no interstitials, no JS-gated content. |

**Cross-engine overlap is low** — one 2026 index of 680M citations reported only ~11% domain overlap between ChatGPT and Perplexity (§10). Treat "ranking in all of them" as five programs sharing one content base, not one program.

---

## 2. The Evidence Ladder

The spine of this skill. Sort every proposed tactic into one of three tiers before it enters a plan, and say which tier it is in.

### Tier 1 — Load-bearing (a mechanism you can verify, and a failure that is total)

These are binary. Fail one and nothing downstream can compensate, because the content never reaches the model.

- **The first HTTP response contains the content.** Major AI crawlers issue one request and parse what comes back; there is no second pass and no rendering step. Client-rendered content is simply absent. This is the single highest-value technical finding you can produce, and the cheapest to verify (§4.1).
- **The crawler is allowed in.** `robots.txt` blocking the retrieval bot — often inherited from a boilerplate or a bot-mitigation vendor — is the second most common total failure, and the one most likely to be invisible to the marketing team who own the goal.
- **Position in the document.** Retrieval and citation are dominated by relevance and position; a source placed earlier in context outperforms most rewrites of it (§10). Practically: the answer to the page's question goes above the fold in the DOM, not after the narrative.
- **Topical coverage of the fan-out set.** Engines decompose one prompt into many sub-queries (§5.1). Coverage of the sub-queries is the retrieval surface; the head term alone is a small part of it.
- **Being cited off-site.** For the engines that lean on reference and community domains, third-party presence outranks anything you can do to your own HTML.

### Tier 2 — Plausible (a real mechanism, modest or context-dependent evidence)

Worth doing, worth measuring, not worth promising.

- Self-contained chunks and atomic answers (§3) — the mechanism is exactly how chunkers behave; the effect size is not established in the open literature.
- Statistics, direct quotations, named sources, and dates in the body. The original GEO paper measured a large relative gain from quotation addition, but **inside a simulator where the source was already supplied to the generator** — that is a re-ranking result, not a discoverability result (§10).
- Freshness signals: real `dateModified`, substantive updates, not a touched timestamp.
- Schema/JSON-LD **for what it demonstrably does** — Google rich results, entity disambiguation, product and pricing data for agents. See §4.4 for what it does not do.
- Author and organization evidence that a human would accept: named authors with verifiable credentials, primary-source links, methodology disclosure.

### Tier 3 — Theater (no demonstrated causal effect on AI visibility)

Do them only when free, and never bill them as levers.

- **`llms.txt` as a ranking or citation signal.** No major provider has committed to using it; measured crawler interest is negligible (§10). It has a real, narrower use — see §4.5.
- **JSON-LD as a citation lever.** The best controlled study to date found no statistically significant citation uplift from adding it (§10). Ship schema for Tier-2 reasons, not this one.
- **Keyword stuffing, "AI-friendly" keyword density, entity-count targets.** Measured null-to-negative.
- **One-size "AI SEO" packages** applied across engines whose citation logic barely overlaps (§1).
- **Prompt-injection text, hidden instructions to models, invisible text.** Ineffective, and a trust and policy risk. Refuse it.

> **How to use the ladder in a client conversation.** Lead with the Tier-1 failures found, priced as bugs. Put Tier 2 in the content plan with a measurement attached. List Tier 3 explicitly as "cheap, doing it, not counting on it" — naming it is what keeps the program falsifiable when results are ambiguous three months in.

---

## 3. Retrieval-Shaped Content

### 3.1 The Island Test

Take any paragraph on the page. Delete everything around it. **Does it still answer a question completely, and name what it is about?** If it needs the heading above it, the sentence before it, or a pronoun's antecedent, it fails — because that is precisely the state it will be in when it reaches the model.

Run the test on: the opening answer, every H2's first paragraph, every list item that carries a claim, and every table caption.

### 3.2 The Atomic Answer

Directly under the page's H1 or the relevant H2, before any narrative:

- **40–60 words**, one paragraph, no preamble.
- **Restates the subject by name** — never "it", "this", "the product". The chunk is anonymous without it.
- **Answers the literal question** in the first sentence; qualifies in the second.
- **Carries one verifiable specific** — a number, a date, a threshold, a named standard — where one honestly exists.
- **Reads as prose a person would keep**, not as a definition block.

Everything after it is the narrative, the evidence, and the depth that earns the citation once retrieved.

### 3.3 Chunk Discipline

- **One idea per section, ~120–180 words**, under a descriptive H2/H3. *(A convention that fits how common chunkers segment, not a measured optimum — Tier 2.)*
- **Headings are the questions users actually ask**, phrased naturally. The text immediately under a question heading answers it, with no throat-clearing.
- **No cross-chunk anaphora.** Re-name the entity at the top of each section. Repetition that feels slightly redundant to a linear reader is correct here.
- **Claims travel with their evidence in the same chunk.** A statistic three paragraphs from its source citation is retrieved as an unsourced statistic.
- **Tables and lists carry a lead-in sentence** naming what they contain — a bare table often loses its context entirely in chunking.
- **Anything only in an image, chart, or video is invisible.** Every number in a graphic appears as text somewhere on the page.

### 3.4 Comparison and Decision Content

The highest-yield formats in AI search are the ones users ask about in full sentences: "X vs Y", "best X for Y", "how much does X cost", "is X worth it". These get retrieved because they are shaped like the sub-queries in §5.1. Write them with real, checkable specifics — including where the answer is "not us". A comparison that never concedes anything is not retrieved as a comparison; it is retrieved as marketing, when it is retrieved at all.

---

## 4. Technical AI-Readiness

### 4.1 Rendering — verify, then fix

```bash
# What the crawler actually gets. No JS, no cookies, no second chance.
curl -sSL -A 'GPTBot/1.0' -o /tmp/geo-page.html -w '%{http_code} %{size_download}b %{redirect_url}\n' '<url>'
# Is the answer text in the bytes?
grep -c '<the atomic answer phrase>' /tmp/geo-page.html
# What did the server actually send?
python3 -c "import sys,html,re;t=re.sub(r'<script.*?</script>|<style.*?</style>','',open('/tmp/geo-page.html').read(),flags=re.S);print(html.unescape(re.sub(r'<[^>]+>',' ',t))[:3000])"
```

If the body text is absent from that output, **nothing else in this skill matters for this page.** Fix order, cheapest first: server-render or pre-render the route → static-generate it if content is stable → hydrate on top. Match the project's framework (Profile §Stack); never introduce a rendering library for what the framework already does (Guidelines §2, rung 3).

Also check in the same pass: real status codes (a soft-404 returning 200 poisons the index), redirect chains, `Content-Type`, whether a bot-mitigation layer or a consent interstitial serves a challenge page to non-browser agents, and whether the canonical URL matches the one you want cited.

### 4.2 Crawl Policy — retrieval and training are different decisions

Separate the bots by purpose before writing a single directive, and get the client's explicit decision on each. Blocking training while allowing retrieval is a legitimate and common position; blocking both and then asking why ChatGPT never cites you is the failure this section prevents.

- **Retrieval / citation bots** — fetch on demand to answer a live query. Blocking these removes you from the answer.
- **Training-corpus bots** — bulk collection. Blocking these has no effect on live citation.
- **Agent user-agents** — a user's own assistant fetching a page on their behalf. Blocking these breaks a real user's task.

Resolve the current user-agent strings from each provider's published documentation at the time you write the file — **never from memory, and never from this skill** (Guidelines §15). Then confirm the deployed `robots.txt` matches the intent, and that no CDN or WAF rule silently overrides it.

### 4.3 Sitemaps, Freshness, Stability

`lastmod` that reflects real edits. Stable, human-legible URLs — a cited URL that 404s six months later is a permanent loss, since the citation is not re-crawled on your schedule. Redirect rather than delete. Keep the canonical stable across a redesign.

### 4.4 Schema / JSON-LD — ship it for the right reason

Ship it. Ship it well. Just do not sell it as a citation lever: the strongest controlled test found no significant citation uplift from adding JSON-LD (§10), and at least one experiment indicates the block is read as raw text rather than parsed by some engines.

What it *does* earn, and why it stays in the plan:

- Google rich results and eligibility surfaces, which feed the organic ranking that AI Overviews draw from (§1).
- Entity disambiguation — `Organization` with `sameAs` pointing at the profiles that already resolve the brand, `Person` for real authors, consistent `@id` across the site so the graph connects.
- Machine-readable commercial state for agents: `Product`, `Offer`, `price`, `availability`. This is the part that stops being optional as agents transact.

Keep it honest and validated: mark up only what is visible on the page, use one nested graph over scattered fragments, and validate against the vendor's own tester before shipping. Invented `aggregateRating` is both a fabrication (§15) and a manual-action risk.

### 4.5 `llms.txt` — what it is actually for

Tier 3 for search visibility. Adoption is around a tenth of sites, a large share of those are empty plugin stubs, and direct crawler interest measured near zero (§10).

It is genuinely useful for a narrower audience: **IDE agents, MCP servers, and in-product assistants** that fetch it deliberately — which makes it worth shipping for developer-facing products and documentation sites specifically.

If shipping it: a curated Markdown index of the canonical pages with one-line descriptions, and `llms-full.txt` only if the corpus genuinely fits in a context window. Generate it from the same source as the sitemap so it cannot drift — a stale index is worse than none. Time-box it to an hour, and say out loud that it is speculative.

---

## 5. Entity & Topical Authority

### 5.1 Map the Fan-Out, Not the Keyword

Engines decompose one prompt into many parallel sub-queries — one 2026 vendor measurement put it around 10–11 per prompt (§10). Your coverage of that decomposition is the actual retrieval surface.

Build the map before writing anything:

1. Write the 20–30 prompts a real buyer would type in full sentences. Not keywords — prompts.
2. For each, enumerate the sub-questions an engine would need answered to synthesize a response: definition, comparison, cost, prerequisites, risks, alternatives, "for whom", "when not to".
3. Mark each sub-question: **covered well / covered thinly / absent / covered by a competitor**.
4. The gaps are the content plan, ranked by commercial value of the parent prompt.

This replaces keyword volume as the prioritization input. Volume describes a search box that is no longer the only entry point.

### 5.2 Off-Site Is Where the Citation Actually Lives

For several major engines, the sources cited most are community and reference domains, not vendor sites. You cannot out-optimize that on your own HTML. What works:

1. **Be accurate where the engines already look** — the reference and community surfaces relevant to your category. Participate genuinely; astroturfing is both detectable and a reputational liability. Refuse it if asked.
2. **Earn unlinked brand mentions.** Being named in context, near the concepts you want to own, is the signal — the link is a separate, older game.
3. **Get listed and correct** in the category directories and review sites your buyers actually cite.
4. **Keep the entity consistent** — one name, one description, one canonical URL, everywhere. Inconsistency is what makes an engine hedge instead of naming you.

### 5.3 Original Data Is the Only Durable Moat

Everything in §3 and §4 is replicable by any competitor in a quarter. Proprietary data is not. A survey you ran, a benchmark you published, an anonymized aggregate from your own product, a methodology stated plainly enough to be checked — this is the content that gets cited *by name* rather than paraphrased, and it survives every retrieval-algorithm change because it is the only place the fact exists.

One original dataset per quarter, published as a citable page with its methodology, outperforms a year of optimized service pages. Say this plainly when a client asks for volume instead.

### 5.4 E-E-A-T as Verifiable Evidence

Treat it as evidence a skeptical human would accept, not a checklist: named authors with credentials that resolve, first-hand experience stated concretely ("we ran this on N accounts over M months"), methodology and limitations disclosed, dates on everything, and corrections visible rather than silently patched. **Never fabricate a credential, an author, a customer count, or a case-study number** (§15) — in this domain the fabrication ends up quoted by a model to a stranger.

---

## 6. Measurement

### 6.1 The Discipline That Makes the Numbers Real

Generative answers are stochastic. Published stability measurements put run-to-run overlap far below what a single check would imply (§10), which means **one prompt run once is not data.** The protocol:

1. **Fix the prompt set** — 20–30 prompts, versioned in a file, changed only deliberately. Changing the set silently is how every GEO dashboard becomes meaningless.
2. **Repeat each prompt ≥7–8 times per engine per cycle**, fresh session, no personalization, locale held constant. Fewer runs measure noise.
3. **Report medians with a spread**, never a single number. Trend direction over weeks beats any snapshot.
4. **Hold the denominator constant.** Share of voice moves when competitors change too; if the prompt set or engine mix changes, the series is broken — start a new one and say so.
5. **Segment by engine, always.** A blended "AI visibility score" across engines with ~11% source overlap (§1) is an average of unrelated things.

### 6.2 The Four Metrics That Mean Different Things

Conflating these is the most common dashboard error.

| Metric | Question it answers | How it's captured |
|---|---|---|
| **Retrieval** | Was the page fetched at all? | Server logs — the only ground truth you own |
| **Citation rate** | How often is the brand cited for the prompt set? | Repeated prompt runs, per engine |
| **Prominence** | Where in the answer, and named or paraphrased? | Position + a named/unnamed flag per run |
| **Absorption** | Was the content used without attribution? | The claim appears; no citation. Real, and it is why traffic under-reports influence. |

### 6.3 Instrumentation

- **Server logs are the primary instrument.** They show which AI user-agents fetched which URLs, how often, and what status they got — outside analytics entirely, and unfakeable. Any technical fix in §4 should show up here within a crawl cycle; if it doesn't, the fix didn't land.
- **Analytics: one dedicated channel group** for assistant referrers, ordered above generic referral so the traffic stops hiding inside it. Resolve the referrer list at build time; it changes.
- **Conversion, not sessions.** Assistant referrals are typically low-volume and high-intent — a session count makes the channel look trivial. Track the conversion event from the Profile, and report rate alongside volume.
- **Attribution honesty.** The largest effect of AI search is answers that never produce a click. Never present referral traffic as the measure of AI visibility; pair it with citation-rate data and say plainly which part is unmeasurable.

### 6.4 What the Dashboard Says at the Top

One line, in this shape: *"Across `<N>` prompts × `<R>` runs on `<engine>`, cited in `<x>%` (median, `<range>`), up from `<y>%` on `<date>`; `<M>` AI-crawler fetches of the target pages this period."* Everything else is a drill-down. If a number cannot be stated in that shape, it is not ready to be on the dashboard.

---

## 7. The Refuse List

- **Projected citation gains, visibility scores with invented denominators, "AI readiness scores" out of 100** with no published method. If you build a composite score, its formula ships with it.
- **Hidden text, white-on-white, prompt injection, instructions addressed to models** in page content or metadata.
- **Cloaking** — different content by user-agent (§Constraints 6).
- **Fabricated schema** — ratings, reviews, authors, or FAQs not present on the page.
- **Mass-generated "answer" pages** for every long-tail permutation. Thin pages fail retrieval and drag the domain.
- **FAQ blocks appended to pages that don't need them**, written to hold keywords rather than answer questions.
- **Astroturfed community posts** on the platforms engines cite. Refuse; explain the detection and liability risk in one line.
- **"Optimized for all AI platforms"** as a deliverable. Name the engines (§1).
- **Content rewritten so heavily for machines that a human wouldn't finish it** (§Constraints 5).
- **Recommending a tactic without its evidence tier** (§Constraints 2).

---

## 8. Modes of Invocation

| Ask | What this skill does |
|---|---|
| **Audit** a page or site | Fetch as a non-JS client (§4.1) → Tier-1 checks first, and stop the report there if one fails → then §3 island test on real chunks → §4 technical → §5 gaps. Findings with `url:element`, tier, severity, and the concrete fix. Read-only. |
| **Brief** — content written to be retrieved | Fan-out map (§5.1) → target sub-questions → atomic answer draft → heading structure as questions → the specifics and sources the page must carry. Hand to `documentation-architect` for the writing floor. |
| **Technical** pass only | §4 end to end, verified against fetched bytes, output as a ranked fix list with the failing evidence for each. |
| **Entity** / authority | §5: fan-out coverage, off-site surfaces, entity consistency audit, original-data proposal. |
| **Measure** | §6: prompt set, run protocol, metric definitions, instrumentation, and the dashboard line. Establishes the baseline; never back-fills history it didn't measure. |
| **"Why aren't we cited?"** | Diagnose in Tier order and stop at the first total failure: fetchable? → allowed? → content in the bytes? → ranking for the fan-out set? → present off-site? Most such questions are answered at step 1–3 in ten minutes. |

---

## 9. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Engine target named (§1) — no undifferentiated "AI search".
- [ ] Every recommendation carries its evidence tier (§2).
- [ ] Every technical claim verified against fetched bytes, not the rendered DOM (§Constraints 3).
- [ ] No projected lift, no invented score, no fabricated credential or metric (§15, §Constraints 1).
- [ ] Any figure quoted from §10 was re-verified and attributed to its study, not to "research shows" (§Constraints 4).
- [ ] Content recommendations still produce something a human would read (§Constraints 5).
- [ ] Measurement plan specifies runs per prompt and reports a spread, not a single number (§6.1).
- [ ] Findings ranked by tier and severity; the report leads with any Tier-1 failure.
- [ ] Verification stayed within two rounds (Guidelines §16).

---

## 10. Evidence Base *(dated — re-verify before citing, Constraints 4)*

Gathered August 2026. Each row states what it does and does **not** support. Vendor studies are labelled; they are useful and they are also marketing.

| Finding | Source | Supports / does not support |
|---|---|---|
| Relevance and position dominate first-citation; moving a source earlier beats most rewrites. 252,000-trial factorial across six LLMs, eighteen factors. | *Optimizing Visibility in Generative Engines: A Critical Survey of GEO (2023–2026)*, arXiv 2607.14035 | Supports position-first structuring **within retrieved context**. Not a discoverability result. |
| No technique reviewed had a stable, longitudinal, cross-platform causal effect on organic discoverability or downstream clicks. | Same survey | The central caveat behind Constraint 1. |
| Quotation addition: ~41% relative gain on the position-adjusted metric in the original GEO paper's testbed (five pre-supplied documents). | Same survey, citing the foundational GEO paper | Supports Tier 2 for quotes/stats. Does **not** support the widely-quoted "40% visibility lift" as an organic result. |
| Keyword stuffing: null-to-negative. Fixed heuristics generalize badly — 3 of 54 method–domain combinations significantly positive (C-SEO Bench). Body-only optimization reduced top-20 presence ~9% (SAGEO Arena). | Same survey | Supports the Tier-3 listing and Constraint 5. |
| Run-to-run Jaccard ~0.34–0.42 across four engines over 45 days; cross-engine URL Jaccard 0.11–0.18; ≥7–8 repetitions per prompt recommended. | Same survey | The basis for the entire §6.1 protocol. |
| ChatGPT-referral quasi-experiment: multiplier 1.82 [1.31, 2.54], but placebo test p=0.16. | Same survey | Traffic claims in this market are weakly evidenced. Quote the caveat with the number or neither. |
| Adding JSON-LD produced no statistically significant citation uplift: 1,885 treated pages vs ~4,000 matched controls; AI Mode +2.4%, ChatGPT +2.2%, AI Overviews −4.6%. | Ahrefs study, reported May 2026 | Supports §4.4's framing. Does **not** mean "don't ship schema". |
| Major AI crawlers issue a single request and do not execute JavaScript; a Vercel analysis of >500M GPTBot fetches found no evidence of JS execution. | Vendor analysis, reported 2026 | The strongest available basis for Tier 1 / §4.1. Verify per-bot behavior yourself on the client's own logs. |
| `llms.txt`: ~10.13% adoption across 300,000 domains, ~39.6% of those plugin stubs; of >500M AI-bot visits over 90 days, 408 targeted `llms.txt`. No major provider has confirmed it as a signal. | SE Ranking (adoption) and crawler-log analyses, reported 2026 | Supports Tier 3 and the narrower agent/IDE use case in §4.5. |
| Query fan-out ~10.7 sub-queries per prompt across 501 tracked prompts (Gemini 3 API). A related vendor claim: pages ranking for fan-out queries were 161% more likely to be cited. | Seer Interactive (fan-out count); the 161% figure is a separate vendor claim | Supports §5.1's premise. The 161% figure is vendor-reported — cite it as such or not at all. |
| AI Overviews: ~97% of cited sources came from the top 20 organic results. | Vendor citation analysis, reported 2026 | Supports "classic SEO is the substrate" in §1 for Google surfaces only. |
| Cross-engine divergence: ~11% domain overlap between ChatGPT and Perplexity across an index of 680M citations; brand-citation rate 0.59% (ChatGPT) vs 13.05% (Perplexity) across 34,234 responses. | 5W AI Platform Citation Source Index 2026; separate 2026 brand-citation study | Supports per-engine strategy (§1) and forbids blended visibility scores (§6.1.5). |
| Community and reference domains dominate citations across engines (Reddit ~40% frequency; Wikipedia 26–48% of ChatGPT top-10 citation share). | Same index | Supports §5.2's priority on off-site presence. |

---

## Relationship to Other Skills

- **Guidelines (Meta)** — §15 honesty is the load-bearing one here; this domain's failure mode is confident fabrication. Also §16 bounded passes, §18 self-critique.
- **Documentation Architect** — owns how every page this skill specifies actually reads; §3's structure rules sit on top of its floor, never instead of it.
- **Design Architect** — any page restructured here is still a designed surface; its craft floor applies before shipping.
- **Product Architect** — a content program is scoped and sliced there; this skill supplies the fan-out map and the prioritization input.
- **Planning Architect / Implementing Architect** — rendering and crawl-policy fixes (§4) are code changes and go through the normal plan → implement → gates path.
- **Deployment Architect** — `robots.txt`, redirects, and canonical changes are one-way doors in practice: a wrong directive can drop a site out of retrieval for a crawl cycle. Treat them as deploy-gated changes with a stated rollback.
- **Code Review Architect** — §4 findings are reviewable like any other; cite `path:line` for the rendering change and `url` for the live evidence.

---

_Skill Version: v1.0 — New skill. Built from the user's GEO notebook brief plus a fresh August 2026 evidence sweep, and it deliberately contradicts the brief in two places: `llms.txt` and JSON-LD are demoted from pillars to Tier 3 / Tier 2 respectively, because the strongest available studies show no citation effect from either. What the brief got right is kept and sharpened — the island test, atomic answers, question headings, and fan-out coverage all survive, now with their mechanism (position bias and chunk independence) stated so they can be applied rather than copied. The evidence ladder in §2 is the skill's organizing idea and the pack's §15 honesty rule applied to a market that runs on unfalsifiable claims; §10 exists so no figure in this file can be repeated without its caveat and its date._
