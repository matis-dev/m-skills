---
name: module-findings
description: "Module — loaded by name from an m-skills architect, not an entry point. How a finding is shaped, filtered, and scored: the citation requirement, the confidence gate that drops uncertain findings, the false-positive list, severity bands, and banded verdicts backed by evidence rather than an invented number."
user-invocable: false
---

# Module: Reporting a Finding

**Loaded by:** `code-review-architect` · `security-architect` · `accessibility-architect` · `documentation-architect` · `search-optimization-architect` · `maintenance-architect` · `debugging-architect`. Read it whenever a run emits findings; do not restate its content in a skill file.

**What this exists to prevent:** a report nobody acts on. That happens two ways — the list is padded with things that are not real, so the reader learns to skim it; or the list is real but nothing in it says who fixes what, so it becomes a document instead of work.

---

## 1. The Shape of One Finding

Every finding carries, in this order:

1. **Severity** — from §3.
2. **Category** — the dimension it belongs to, in the emitting skill's vocabulary.
3. **A location** — `path/to/file.ext:42`, or a `url` for a live-page finding. **No floating "consider improving X".** A finding you cannot point at is an opinion.
4. **Why it matters** — the consequence, not the rule it breaks. For a barrier, **name who it blocks**; for a vulnerability, **state reachability** or state that you could not establish it. A rule that is only a rule gets negotiated; a rule attached to a consequence gets fixed.
5. **The concrete fix** — a pointer specific enough to act on.
6. **Who owns the fix**, when the emitting skill does not write code. A security finding goes to `security-architect`, an accessibility barrier to `accessibility-architect`, a test gap to `testing-architect`, a doc defect to `documentation-architect`. **A review that ends in a list nobody can act on is half a deliverable.**

---

## 2. The Confidence Gate

Before listing a finding, self-score your confidence that it is **real**, **introduced by this change set**, and **worth the reader's attention** — 0 = probable false positive, 100 = certain.

**Post only findings you would rate ≥ 80.** Below that, drop it silently rather than padding. A noisy report trains the reader to ignore the whole thing, which costs more than the finding was worth.

**Do not report** — these are false positives, not findings:

- A pre-existing issue this change did not introduce, unless it is directly load-bearing for the change. If you include one, label it `[OUT-OF-DIFF]` and justify in one line.
- Code that *looks* wrong but is functionally correct.
- Pedantic nitpicks with no behavioral or maintainability cost.
- Anything the linter already catches.
- A line carrying an explicit "safe because …" justification that actually holds.

**The one exception:** a correctness or security item you are under 80 on **but that would be severe if true** is not dropped. List it under a short **"Worth a second look (unverified)"** note, kept separate from the scored findings, with what would confirm it.

The same gate applies to a diagnosis: before declaring a root cause, score whether it is *proven* or merely *consistent with the evidence*. Below ~80, say so plainly and keep it labelled a theory. A confidently-stated wrong diagnosis is worse than an honest "not certain yet", because the reader acts on it.

---

## 3. Severity

| Severity | Means | Deduction from the dimension's max |
|---|---|---|
| **Critical** | data exfiltration, auth bypass, RCE-class, or a total functional break | −20 (auto-`BLOCK` regardless of total) |
| **High** | stored injection, a known-CVE dependency with an exploit path, a failing gate | −10 |
| **Medium** | reachable only via developer-controlled input; a real defect with a workaround | −4 |
| **Low** | defense-in-depth gap; cosmetic-but-wrong | −2 |
| **Nit** | preference with a real if small justification | −0.5 |

**Never inflate and never dismiss.** Performing urgency over an unreachable finding and waving away a reachable one are the same defect wearing different clothes (Guidelines §15).

---

## 4. Verdicts

A verdict is one band plus **the evidence that set it**. Never a number out of 100 with no published method, and never a letter grade.

Where a skill scores numerically, the dimensions sum to 100, each floors at 0, and every deduction traces to a listed finding:

| Score | Verdict | Meaning |
|---|---|---|
| 90–100 | 🟢 **Ship-Ready** | At most a few Nits/Lows. |
| 75–89 | 🟡 **Minor Revisions** | Mediums to address. Re-run gates after fixes. |
| 60–74 | 🟠 **Needs Revisions** | Multiple Mediums or one High. |
| 0–59 | 🔴 **Block** | Highs accumulating, or any Critical. |

> **Hard override:** any **Critical** forces 🔴 **Block** regardless of total. State the override in the verdict line.

Where a skill does **not** score numerically, the bands are qualitative and named the same way — for example `Blocked` / `Rough` / `Usable` / `Good` for a documentation audit — and the rule is identical: name the evidence, never invent a score.

---

## 5. Shaping the Report

- **Lead with the verdict and the single next action** (Guidelines §17). The reader gets both from the first two lines.
- **Cap each list at five**, highest severity first. More than five means split by priority and lead with the top group.
- **Group by cause, not by node.** Forty findings of one shape are usually one component. Fix the component and the count collapses; a per-node list is how remediation becomes a month that should have been an hour.
- **Say what was clean.** A section with no findings is noted clean rather than omitted — silence reads as "not assessed", and sometimes it truthfully is, in which case say *that*.
- **State what was not tested.** A claim beyond what was actually run is a fabrication, however reasonable it sounds.
- **Every number is copied from real output**, never estimated (Guidelines §15).
