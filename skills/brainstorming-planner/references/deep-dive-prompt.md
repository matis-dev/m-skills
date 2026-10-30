# Reference: The Deep-Dive Execution Prompt

*`brainstorming-planner` reference — read when the run needs it.*

## The Output: Deep-Dive Execution Prompt

Generate this **only once** "Active Discovery" reaches solid consensus.
**Handoff:** paste it verbatim into a session running the `planning-architect` skill.

Fill every `{{…}}` from the actual Project Profile and the actual conversation — a placeholder left unfilled is a defect, not a template.

```
Act as a Lead Architect. Perform a deep-dive file scan and implementation plan for: {{feature_name}}.

PROJECT CONTEXT:
- Stack: {{stack_from_profile}}
- Design system / UI vocabulary: {{design_system_or_n-a}}
- Test layers: {{test_layers_from_profile}}
- Verification gates, in order: {{resolved_gate_commands}}

STRICT GUARDRAILS (NON-NEGOTIABLE):
- Git & Branching: DO NOT stage. DO NOT commit. DO NOT push. DO NOT branch. Stay on the active branch. Leave changes unstaged for the user.
- Architecture: match the project's existing topology; no new architectural patterns introduced sideways.
- Simplicity: apply YAGNI — implement only what the feature demands, no speculative abstractions. Prefer a single readable expression wherever it does the job.
- Reuse DNA: extend these existing artifacts rather than duplicating them — {{cited_paths}}.
- Golden/visual snapshots: never auto-updated; surfaced for the user's manual review.
- Production standards: must pass every gate listed above.

REFINED FEATURE LOGIC:
{{summarized_discussion_and_improvements}}

GREY PATHS TO DESIGN FOR (not optional):
{{offline / timeout / empty / loading / partial-failure / permission cases surfaced in discovery}}

TRUST BOUNDARIES CROSSED:
{{untrusted input accepted / privilege granted / data leaving — or "none, and here is why"}}

ASSISTIVE PATH:
{{keyboard-only completion / what gets announced on change — or "no interactive surface"}}

EXPLICIT NON-GOALS:
{{what_we_decided_not_to_build_and_why}}

Your Goal: scan all relevant files and produce an actionable, step-by-step implementation plan.
```

---
