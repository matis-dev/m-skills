# Decisions

Why this project is built the way it is, including what was considered and rejected. The changelog records what shipped; this file records what was chosen.

## Adding an entry

- **Log a choice a person made**: a question put to the user and answered, or a call the team made. A detail an agent picked on its own is not an entry.
- **Append only**, in this shape:

  ```markdown
  ### YYYY-MM-DD — <the decision, as a statement>
  Why: <the reason, one or two lines>
  Rejected: <the alternatives, briefly — or "none considered">
  By: <skill or person> · revisit if: <the trigger that would reopen it | never>
  ```

- **Reversing one:** add a new entry with a `Supersedes: YYYY-MM-DD — <title>` line, and add one line, `Superseded by YYYY-MM-DD`, to the old entry. Change nothing else in it.
- **Check before appending.** A decision already logged is not logged twice.

## Entries
