# Reference: Slow — Regressions and Speed Goals

*`debugging-architect` reference — read when the symptom is slowness: a regression, a timeout, or "make it faster".*

## Slow

Different discipline: you're moving a number, not fixing a state. "Faster" without a measured before and after is an invented number (Guidelines §15).

1. **Write the measurement before touching code.** One command that prints the number the user feels — window open time, p95 request latency, time to first token, renders per keystroke, idle memory. Reuse the project's benchmark script if it has one; otherwise add one the user can rerun. If the symptom doesn't say which number matters, that is the one question to ask.
2. **Baseline under stated conditions.** Same machine, release build, same data size, cold or warm said out loud. Run it 5–10 times and record the median and the spread; a change smaller than the spread is noise.
3. **Profile, then hypothesise.** A profiler, query log, or network waterfall says where the time goes; the Phase 3 hypothesis targets the largest slice. The usual causes: N+1 queries, work repeated per item or per render, synchronous I/O on a hot path, a missing index, an unbounded payload, start-up work that could be deferred.
4. **One change, same command.** Predict the number before running. A result inside the spread is not a fix — revert it. The three-hypothesis ceiling still holds.
5. **Guard by count, not by clock.** The Phase 5 test asserts what the fix removed — query count, render count, payload size. A wall-clock bound in a unit test is a flake (`references/flaky.md`). A timing budget belongs in a benchmark the project already runs, not in the suite.
6. **Report before → after** with command, conditions, and run count:

```
idle memory 212 → 148 MB — median of 7, release build, cold start — `npm run bench:idle`
```

---
