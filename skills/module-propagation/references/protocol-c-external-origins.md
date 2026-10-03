# Reference: Protocol C — External Origins & Configuration

*`module-propagation` reference — read when the run needs it.*

## Protocol C — External Origins & Configuration

- Update **every** place the policy is declared. Security policies are commonly duplicated — a markup meta tag *and* a server header, a dev config *and* a prod config, a manifest *and* a deployment env. Update all copies or the resource is silently blocked in one environment and works in another.
- Pick the directive by sink: images, network calls, fonts, scripts, frames each have their own.
- **Blind spot:** a blocked resource renders *consistently* broken, so its visual baseline still matches and the visual gate **passes**. Verify in a real served build, not by green tests.
- Same logic for env vars, feature flags, and build-time constants: enumerate every environment that declares them.
- **A new origin or config value is also a security change** (OWASP A02/A03). Apply the `security-architect` skill: the origin is one you meant to trust, the directive is the narrowest that works, and nothing added here is a secret living in a tracked file.

---
