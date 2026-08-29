# Reference: Technical AI-Readiness

*`search-optimization-architect` reference. Read for `technical`, `audit`, and any Tier-1 diagnosis.*

## Technical AI-Readiness

### 1. Rendering — verify, then fix

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

### 2. Crawl Policy — retrieval and training are different decisions

Separate the bots by purpose before writing a single directive, and get the client's explicit decision on each. Blocking training while allowing retrieval is a legitimate and common position; blocking both and then asking why ChatGPT never cites you is the failure this section prevents.

- **Retrieval / citation bots** — fetch on demand to answer a live query. Blocking these removes you from the answer.
- **Training-corpus bots** — bulk collection. Blocking these has no effect on live citation.
- **Agent user-agents** — a user's own assistant fetching a page on their behalf. Blocking these breaks a real user's task.

Resolve the current user-agent strings from each provider's published documentation at the time you write the file — **never from memory, and never from this skill** (Guidelines §15). Then confirm the deployed `robots.txt` matches the intent, and that no CDN or WAF rule silently overrides it.

### 3. Sitemaps, Freshness, Stability

`lastmod` that reflects real edits. Stable, human-legible URLs — a cited URL that 404s six months later is a permanent loss, since the citation is not re-crawled on your schedule. Redirect rather than delete. Keep the canonical stable across a redesign.

### 4. Schema / JSON-LD — ship it for the right reason

Ship it. Ship it well. Just do not sell it as a citation lever: the strongest controlled test found no significant citation uplift from adding JSON-LD (`evidence-base.md`), and at least one experiment indicates the block is read as raw text rather than parsed by some engines.

What it *does* earn, and why it stays in the plan:

- Google rich results and eligibility surfaces, which feed the organic ranking that AI Overviews draw from (`SKILL.md` §1).
- Entity disambiguation — `Organization` with `sameAs` pointing at the profiles that already resolve the brand, `Person` for real authors, consistent `@id` across the site so the graph connects.
- Machine-readable commercial state for agents: `Product`, `Offer`, `price`, `availability`. This is the part that stops being optional as agents transact.

Keep it honest and validated: mark up only what is visible on the page, use one nested graph over scattered fragments, and validate against the vendor's own tester before shipping. Invented `aggregateRating` is both a fabrication (Guidelines §15) and a manual-action risk.

### 5. `llms.txt` — what it is actually for

Tier 3 for search visibility. Adoption is around a tenth of sites, a large share of those are empty plugin stubs, and direct crawler interest measured near zero (`evidence-base.md`).

It is genuinely useful for a narrower audience: **IDE agents, MCP servers, and in-product assistants** that fetch it deliberately — which makes it worth shipping for developer-facing products and documentation sites specifically.

If shipping it: a curated Markdown index of the canonical pages with one-line descriptions, and `llms-full.txt` only if the corpus genuinely fits in a context window. Generate it from the same source as the sitemap so it cannot drift — a stale index is worse than none. Time-box it to an hour, and say out loud that it is speculative.

---
