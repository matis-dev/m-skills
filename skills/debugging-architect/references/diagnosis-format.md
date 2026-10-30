# Reference: The Diagnosis Format

*`debugging-architect` reference — read when the run needs it.*

## Output Format (Fixed)

```markdown
# Diagnosis: <symptom in one line>

**Status:** root cause proven / probable cause (unproven) / not reproduced
**Next action:** <the single thing the user does now>

## Symptom
- Expected: <…> · Actual: <…>
- Smallest reproduction: <steps or command>
- Deterministic: yes / no (<rate>) · Environments affected: <…>

## Ruled Out
- <hypothesis> — disproved by <observation>

## Root Cause
`path/to/file.ext:LN` — <the mechanism, in plain language>
**Why now:** <what changed to expose it>
**Confidence:** <proven — toggled on and off / probable — consistent but not isolated>

## Fix
- Failing test added: `<path>` — fails before, passes after
- Change: `<path:LN>` — <what and why>
- Propagation checked: <n-a / protocol A|B|C run>
- Gates: <results>

## Guard Against Recurrence
- Regression test: `<path>`
- Blind spot recorded: <one line for the profile — or n-a>
- Probes removed: yes
```

---
