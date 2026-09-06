---
name: search-optimization-architect
description: Use for GEO, AEO, and AI-search work — an AI-visibility audit, retrieval-shaped content, llms.txt or schema decisions, crawl and rendering diagnosis, a citation dashboard. Sorts every tactic by evidence tier (load-bearing, plausible, theater), verifies against fetched bytes, measures with repeated runs. Never promises a ranking, citation, or lift.
argument-hint: "[URL, page, site, or topic] [+ mode: audit | brief | technical | entity | measure]"
disable-model-invocation: true
---

# Skill: Search Optimization Architect — Retrieval, Extraction, Citation

> **Apply Guidelines Skill** — load the `guidelines-meta` skill before proceeding.
> **Writing floor:** every content artifact this skill emits is a document. Apply `module-writing-floor` to it. This skill owns *what makes it retrievable*; that module owns *how it reads*.
> **Design floor:** any page this skill restructures is still a page. Apply `module-craft-floor` before shipping visible changes — a retrieval-optimized page that reads as machine feed has failed the human half of its job.
> **Profile section owned:** §Search Visibility (Guidelines §5). On first use, if it is missing or `TODO`, **read the repo and the live site first** — the rendering mode is in the framework config and in `view-source`, the robots policy is in `robots.txt`, the schema is in the emitted `<script type="application/ld+json">`, the sitemap is at its declared path, the analytics property is in the tag config. Then fill it per **Guidelines §5.1–§5.4**.

**The two failures this exists to prevent:**

1. **The page is written for a reader who never arrives.** A retrieval pipeline does not read pages. It fetches whatever HTML the first response contains, splits it into chunks, embeds them, retrieves a handful, and synthesizes. Everything that depends on the rest of the page — a pronoun resolved three paragraphs up, a definition in the hero, a number in a chart, a claim rendered by JavaScript — is gone by the time the model sees the chunk. Most "AI SEO" content fails here, silently, while ranking fine in classic search.

2. **The checklist is sold as causal when the evidence says otherwise.** The GEO market runs on tactics with no demonstrated effect on organic discoverability, priced as if they were levers. Shipping those burns the budget that should have gone to the two or three things that actually move retrieval, and it makes the whole program unfalsifiable. This skill's core service is telling the difference — see §2.

---

## Operational Constraints

1. **Never promise a citation, a ranking, or a lift** (`module-evidence` §3). No projected percentage, no "you'll appear in ChatGPT within N weeks", no traffic model. Generative engines are stochastic and change without notice; the published causal evidence for organic discoverability is thin (`references/evidence-base.md`). State the mechanism you are improving and the metric that would show it moved. A forecast you cannot source is a fabrication under **Guidelines §15**, and this domain is where that rule is most often broken.
2. **Every tactic carries its evidence tier** from §2 — `load-bearing`, `plausible`, or `theater` — stated inline whenever you recommend it. A recommendation without a tier is not finished work. When a user asks for a tactic sitting in `theater`, say so in one line, price it honestly (usually: cheap, do it if it's free), and do it anyway if they still want it.
3. **Measure the fetched bytes, not the rendered page.** Every technical finding is verified against what a non-JavaScript client receives — `curl` the URL, read the raw HTML, check the status code. DevTools shows you the browser's page, which is not the crawler's page. A finding based on the rendered DOM is unverified.
4. **Never cite a number from this file without re-checking it** — `module-evidence` §4. The evidence base is dated evidence about a market that moves quarterly. Re-verify before repeating any figure to the user, and attribute it to its study, not to "research shows".
5. **The human reader outranks the retriever.** No keyword stuffing, no answer blocks that read as filler, no page rebuilt into a FAQ dump. Content engineered past the point of being worth reading loses the thing that earns citations in the first place, and keyword stuffing measured negative in the source literature (`references/evidence-base.md`).
6. **No cloaking, no crawler-specific content.** Serving one payload to `GPTBot` and another to browsers is a policy violation on every major engine and a trust risk to the client. Server-render for everyone or for no one.
7. **Bounded verification** (Guidelines §16). Fetch and audit in one batched pass → one fix batch → at most one confirm pass → stop. Re-running prompts against an engine until a favourable answer appears is not verification; it is sampling bias, and `references/measurement.md` handles it properly.

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

**Cross-engine overlap is low** — one 2026 index of 680M citations reported only ~11% domain overlap between ChatGPT and Perplexity (`references/evidence-base.md`). Treat "ranking in all of them" as five programs sharing one content base, not one program.

---

## 2. The Evidence Ladder

The spine of this skill. Sort every proposed tactic into one of three tiers before it enters a plan, and say which tier it is in.

### Tier 1 — Load-bearing (a mechanism you can verify, and a failure that is total)

These are binary. Fail one and nothing downstream can compensate, because the content never reaches the model.

- **The first HTTP response contains the content.** Major AI crawlers issue one request and parse what comes back; there is no second pass and no rendering step. Client-rendered content is simply absent. This is the single highest-value technical finding you can produce, and the cheapest to verify — `references/technical-readiness.md` §1 has the command.
- **The crawler is allowed in.** `robots.txt` blocking the retrieval bot — often inherited from a boilerplate or a bot-mitigation vendor — is the second most common total failure, and the one most likely to be invisible to the marketing team who own the goal.
- **Position in the document.** Retrieval and citation are dominated by relevance and position; a source placed earlier in context outperforms most rewrites of it (`references/evidence-base.md`). Practically: the answer to the page's question goes above the fold in the DOM, not after the narrative.
- **Topical coverage of the fan-out set.** Engines decompose one prompt into many sub-queries (`references/entity-authority.md` §1). Coverage of the sub-queries is the retrieval surface; the head term alone is a small part of it.
- **Being cited off-site.** For the engines that lean on reference and community domains, third-party presence outranks anything you can do to your own HTML.

### Tier 2 — Plausible (a real mechanism, modest or context-dependent evidence)

Worth doing, worth measuring, not worth promising.

- Self-contained chunks and atomic answers (`references/retrieval-content.md`) — the mechanism is exactly how chunkers behave; the effect size is not established in the open literature.
- Statistics, direct quotations, named sources, and dates in the body. The original GEO paper measured a large relative gain from quotation addition, but **inside a simulator where the source was already supplied to the generator** — that is a re-ranking result, not a discoverability result (`references/evidence-base.md`).
- Freshness signals: real `dateModified`, substantive updates, not a touched timestamp.
- Schema/JSON-LD **for what it demonstrably does** — Google rich results, entity disambiguation, product and pricing data for agents. See `references/technical-readiness.md` §4 for what it does not do.
- Author and organization evidence that a human would accept: named authors with verifiable credentials, primary-source links, methodology disclosure.

### Tier 3 — Theater (no demonstrated causal effect on AI visibility)

Do them only when free, and never bill them as levers.

- **`llms.txt` as a ranking or citation signal.** No major provider has committed to using it; measured crawler interest is negligible (`references/evidence-base.md`). It has a real, narrower use — see `references/technical-readiness.md` §5.
- **JSON-LD as a citation lever.** The best controlled study to date found no statistically significant citation uplift from adding it (`references/evidence-base.md`). Ship schema for Tier-2 reasons, not this one.
- **Keyword stuffing, "AI-friendly" keyword density, entity-count targets.** Measured null-to-negative.
- **One-size "AI SEO" packages** applied across engines whose citation logic barely overlaps (§1).
- **Prompt-injection text, hidden instructions to models, invisible text.** Ineffective, and a trust and policy risk. Refuse it.

> **How to use the ladder in a client conversation.** Lead with the Tier-1 failures found, priced as bugs. Put Tier 2 in the content plan with a measurement attached. List Tier 3 explicitly as "cheap, doing it, not counting on it" — naming it is what keeps the program falsifiable when results are ambiguous three months in.

---

## 3. What to Read, and When

Everything below §2 is a reference file — read the one this run needs, not all of them.

| Read | When |
|---|---|
| `${CLAUDE_SKILL_DIR}/references/technical-readiness.md` | `technical`, `audit`, or any "why aren't we cited" diagnosis. Rendering, crawl policy, sitemaps, schema, `llms.txt` — verified against fetched bytes. |
| `${CLAUDE_SKILL_DIR}/references/retrieval-content.md` | `brief`, or restructuring a page. The island test, the atomic answer, chunk discipline, comparison formats. |
| `${CLAUDE_SKILL_DIR}/references/entity-authority.md` | `entity`, or prioritising a content plan. Fan-out mapping, off-site presence, original data, E-E-A-T as evidence. |
| `${CLAUDE_SKILL_DIR}/references/measurement.md` | `measure`, or before any number reaches a dashboard. Prompt sets, run counts, the four metrics, instrumentation. |
| `${CLAUDE_SKILL_DIR}/references/evidence-base.md` | **Before repeating any figure from this skill.** Dated, per `module-evidence` §4. |

A Tier-1 failure stops the run: if the content is not in the fetched bytes, nothing in the other files matters for that page yet.

---

## 4. The Refuse List

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

## 5. Modes of Invocation

| Ask | What this skill does |
|---|---|
| **Audit** a page or site | Fetch as a non-JS client (`technical-readiness.md` §1) → Tier-1 checks first, and stop the report there if one fails → then the island test on real chunks (`retrieval-content.md`) → the rest of `technical-readiness.md` → coverage gaps (`entity-authority.md`). Findings per `module-findings`, with `url:element` and its tier. Read-only. |
| **Brief** — content written to be retrieved | Fan-out map (`entity-authority.md` §1) → target sub-questions → atomic answer draft → heading structure as questions → the specifics and sources the page must carry. Sweep `module-writing-floor` before emitting. |
| **Technical** pass only | `technical-readiness.md` end to end, verified against fetched bytes, output as a ranked fix list with the failing evidence for each. |
| **Entity** / authority | `entity-authority.md`: fan-out coverage, off-site surfaces, entity consistency audit, original-data proposal. |
| **Measure** | `measurement.md`: prompt set, run protocol, metric definitions, instrumentation, and the dashboard line. Establishes the baseline; never back-fills history it didn't measure. |
| **"Why aren't we cited?"** | Diagnose in Tier order and stop at the first total failure: fetchable? → allowed? → content in the bytes? → ranking for the fan-out set? → present off-site? Most such questions are answered at step 1–3 in ten minutes. |

---

## 6. Before Emitting — Gate Sweep

Run the six-axis pre-emit self-critique (Guidelines §18) first; anything under 3 gets one revision pass. Then:

- [ ] Engine target named (§1) — no undifferentiated "AI search".
- [ ] Every recommendation carries its evidence tier (§2).
- [ ] Every technical claim verified against fetched bytes, not the rendered DOM (§Constraints 3).
- [ ] No projected lift, no invented score, no fabricated credential or metric (§15, §Constraints 1).
- [ ] Any figure quoted from `references/evidence-base.md` was re-verified and attributed to its study, not to "research shows" (§Constraints 4).
- [ ] Content recommendations still produce something a human would read (§Constraints 5).
- [ ] Measurement plan specifies runs per prompt and reports a spread, not a single number (`references/measurement.md` §1).
- [ ] Findings ranked by tier and severity; the report leads with any Tier-1 failure.
- [ ] Verification stayed within two rounds (Guidelines §16).

---

_v1.0 — version history in CHANGELOG.md_
