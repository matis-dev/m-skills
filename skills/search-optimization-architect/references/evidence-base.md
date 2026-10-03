# Reference: Evidence Base

*`search-optimization-architect` reference. Read before repeating any figure. Format and discipline per `module-evidence` §4.*

## Evidence Base *(dated — re-verify before citing, Constraints 4)*

Gathered August 2026. Each row states what it does and does **not** support. Vendor studies are labelled; they are useful and they are also marketing.

| Finding | Source | Supports / does not support |
|---|---|---|
| Relevance and position dominate first-citation; moving a source earlier beats most rewrites. 252,000-trial factorial across six LLMs, eighteen factors. | *Optimizing Visibility in Generative Engines: A Critical Survey of GEO (2023–2026)*, arXiv 2607.14035 | Supports position-first structuring **within retrieved context**. Not a discoverability result. |
| No technique reviewed had a stable, longitudinal, cross-platform causal effect on organic discoverability or downstream clicks. | Same survey | The central caveat behind Constraint 1. |
| Quotation addition: ~41% relative gain on the position-adjusted metric in the original GEO paper's testbed (five pre-supplied documents). | Same survey, citing the foundational GEO paper | Supports Tier 2 for quotes/stats. Does **not** support the widely-quoted "40% visibility lift" as an organic result. |
| Keyword stuffing: null-to-negative. Fixed heuristics generalize badly — 3 of 54 method–domain combinations significantly positive (C-SEO Bench). Body-only optimization reduced top-20 presence ~9% (SAGEO Arena). | Same survey | Supports the Tier-3 listing and Constraint 5. |
| Run-to-run Jaccard ~0.34–0.42 across four engines over 45 days; cross-engine URL Jaccard 0.11–0.18; ≥7–8 repetitions per prompt recommended. | Same survey | The basis for the entire §1 protocol. |
| ChatGPT-referral quasi-experiment: multiplier 1.82 [1.31, 2.54], but placebo test p=0.16. | Same survey | Traffic claims in this market are weakly evidenced. Quote the caveat with the number or neither. |
| Adding JSON-LD produced no statistically significant citation uplift: 1,885 treated pages vs ~4,000 matched controls; AI Mode +2.4%, ChatGPT +2.2%, AI Overviews −4.6%. | Ahrefs study, reported May 2026 | Supports §4's framing. Does **not** mean "don't ship schema". |
| Major AI crawlers issue a single request and do not execute JavaScript; a Vercel analysis of >500M GPTBot fetches found no evidence of JS execution. | Vendor analysis, reported 2026 | The strongest available basis for Tier 1 / §4.1. Verify per-bot behavior yourself on the client's own logs. |
| `llms.txt`: ~10.13% adoption across 300,000 domains, ~39.6% of those plugin stubs; of >500M AI-bot visits over 90 days, 408 targeted `llms.txt`. No major provider has confirmed it as a signal. | SE Ranking (adoption) and crawler-log analyses, reported 2026 | Supports Tier 3 and the narrower agent/IDE use case in §4.5. |
| Query fan-out ~10.7 sub-queries per prompt across 501 tracked prompts (Gemini 3 API). A related vendor claim: pages ranking for fan-out queries were 161% more likely to be cited. | Seer Interactive (fan-out count); the 161% figure is a separate vendor claim | Supports §5.1's premise. The 161% figure is vendor-reported — cite it as such or not at all. |
| AI Overviews: ~97% of cited sources came from the top 20 organic results. | Vendor citation analysis, reported 2026 | Supports "classic SEO is the substrate" in §1 for Google surfaces only. |
| Cross-engine divergence: ~11% domain overlap between ChatGPT and Perplexity across an index of 680M citations; brand-citation rate 0.59% (ChatGPT) vs 13.05% (Perplexity) across 34,234 responses. | 5W AI Platform Citation Source Index 2026; separate 2026 brand-citation study | Supports per-engine strategy (`SKILL.md` §1) and forbids blended visibility scores (§1.5). |
| Community and reference domains dominate citations across engines (Reddit ~40% frequency; Wikipedia 26–48% of ChatGPT top-10 citation share). | Same index | Supports §5.2's priority on off-site presence. |

---
