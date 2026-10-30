# Reference: Flaky and Intermittent Failures

*`debugging-architect` reference — read when the run needs it.*

## Flaky / Intermittent Failures

Different discipline: you're proving a *rate*, not a state.

1. **Quantify first.** Run it 20–50 times and record the failure rate. "Sometimes" is not a measurement, and without a baseline you cannot tell a fix from luck.
2. **The usual causes, in the order they actually occur:** shared state between tests (order dependence), real time or timezone, unawaited async work, ordering assumptions over unordered collections, a shared external resource, resource exhaustion under parallelism, and randomness without a fixed seed.
3. **Try order dependence early** — run the test alone, then in reverse order. It's cheap and it's the most common cause.
4. **Never "fix" a flake by retrying it.** A retry hides a real race that will surface in production, where nothing retries for you. Retry is acceptable only for a genuinely external dependency, and only with a comment saying which one.
5. **Verify with the same measurement.** Same run count, failure rate at zero. One green run proves nothing about a 5% flake.

---
