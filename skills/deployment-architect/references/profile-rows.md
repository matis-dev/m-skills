# Reference: Which File Answers Each Deployment Profile Row

*`deployment-architect` reference — read when the run needs it.*

  | Row | Usually answered by |
  |---|---|
  | Hosting model | `Dockerfile`, `vercel.json`, `netlify.toml`, `fly.toml`, `Procfile`, `serverless.yml`, `wrangler.toml`, `k8s/`, `Chart.yaml` |
  | Deploy mechanism, who fires it | the CI workflow with `deploy`/`release`/`publish` in its name — read its triggers and its environment gates |
  | Environments | CI environment names, platform config, per-env config files |
  | Config source, required env vars | `.env.example`, CI secret names, platform config |
  | Migrations | the migrations directory and its tool's config |
  | Health check | an existing health/readiness route, or the platform's configured probe |
  | Versioning | the manifest version field and any release automation |
