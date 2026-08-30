---
name: module-evidence
description: "Module — loaded by name from an m-skills architect, not an entry point. Honesty rules for domains where a fabricated identifier or number gets quoted downstream: never invent an identifier, source or label every figure, and keep a dated evidence base that cannot be repeated without its caveat."
user-invocable: false
---

# Module: Evidence and Identifiers

**Loaded by:** `security-architect` · `accessibility-architect` · `search-optimization-architect` · `product-architect` · `documentation-architect` · `marketing-architect`. Read it whenever a run cites a standard, a study, or a number; do not restate its content in a skill file.

**Why this is a module and not just Guidelines §15:** §15 forbids inventing facts. These are the domains where an invented fact does not stay in the conversation — a CWE number ends up in a ticket, a WCAG criterion ends up in a VPAT or a procurement answer, a market size ends up in a board deck, a benchmark ends up in a README a stranger acts on. The rule is the same; the blast radius is what earns the extra discipline.

---

## 1. Never Invent an Identifier

An OWASP category, a CWE number, a WCAG success criterion, an RFC, a CVE, a spec section. If you are not **certain** of the identifier:

> **Describe the weakness or barrier precisely, and omit the number.**

A described finding with no ID is honest work. A confident wrong `CWE-000` is a defect worse than silence, because the number is exactly the part a human downstream will trust without checking.

Two corollaries:

- **Levels and names are part of the identifier.** An AAA criterion quoted as an AA requirement is wrong even though the number is right. A renamed category quoted under its old name is wrong even though it exists.
- **Re-verify before repeating.** A figure you read in a file six months ago is not a figure you verified. Anything quoted out of an evidence base gets re-checked against its source first.

## 2. Every Number Is Sourced or Labelled

A number either came from a command you ran, a file you read, a search result you can cite, or the user — **or it is written as a label, not a finding**:

- `hypothesis:` — a guess worth testing.
- `target (unvalidated):` — a goal somebody set.
- `baseline unknown — instrument before measuring` — the honest state of most metrics.
- `assumption:` — for a persona, a user need, or a competitor claim you did not verify.

**There is no third option**, and there is no rounding a hypothesis into a finding by writing it confidently.

**A target is not a measurement.** "Cut onboarding drop-off to 15%" is a goal and reads as one. "Onboarding drop-off is 38%" is a claim and needs a source. Never let the second shape carry an invented value.

**Never fabricate** a credential, an author, a customer count, a case-study number, a testimonial, a persona quote, or a rating. In a marked-up page or a product document these get quoted onward by people and by models.

## 3. Never Promise an Outcome

No projected ranking, citation, lift, conversion rate, or timeline. State **the mechanism you are improving** and **the metric that would show it moved**. A forecast you cannot source is a fabrication wearing a spreadsheet.

---

## 4. The Dated Evidence Base

Where a skill's guidance rests on outside research, it carries an evidence base rather than asserting the conclusions. The format, and why each column is there:

```markdown
## N. Evidence Base *(dated — re-verify before citing)*

Gathered <month year>.

| Fact | Source | Supports / does not support |
|---|---|---|
| <the finding, with its actual numbers> | <the named study, vendor, or spec — linked> | <what it licenses you to claim, and what it does not> |
```

- **The date is on the section, not on a row.** It is the first thing a reader needs and the first thing that goes stale.
- **The source is named**, never "research shows". Vendor studies are labelled as vendor studies — they are useful and they are also marketing.
- **The third column is the load-bearing one.** It is where a result measured inside a simulator is prevented from being quoted as a field result, and where a correlation is prevented from being quoted as a cause.
- **A caveat travels with its number.** Quote the caveat with the figure, or quote neither.

An evidence base is the provenance of a section's *structure*. It is not a substitute for the source, and definitions should be read from the source rather than quoted from memory.
