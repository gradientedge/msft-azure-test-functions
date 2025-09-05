# Repository Guidelines

## Project Structure & Module Organization
- Root: Azure Functions OTEL experiments under `functions/` (CJS, ESM, esbuild variants).
- Each experiment is self-contained with its own `package.json`, `tsconfig.json`, `host.json`, optional `run.sh`, and `assets/`.
- Source layout: `src/functions/*.ts|.mts|.mjs` (HTTP triggers), `src/apps/*.ts` (helpers), and `src/opentelemetry.ts|.mts` (OTEL bootstrap).
- Backups and scratch files live in `bak/` (not part of builds).

## Build, Test, and Development Commands
- Install: `cd functions/<experiment> && npm ci`
- Build: `npm run build` (TypeScript → `dist/`; esbuild variants run `node esbuild.js`).
- Local run: `func start` (requires Azure Functions Core Tools).
- E2E script: `./run.sh` (where present) updates app settings, publishes, and measures endpoints.
- Node: repo targets `>=22`; see README for required `languageWorkers__node__arguments`/`NODE_OPTIONS`.

## Coding Style & Naming Conventions
- Language: TypeScript with `"strict": true`, `module`/`moduleResolution: "nodenext"`.
- Modules: choose ESM vs CJS per experiment; keep consistency within a folder.
- Indentation: 2 spaces; avoid trailing whitespace.
- File names: use kebab-case; functions under `src/functions/` named by route (e.g., `http.ts`, `http-with-keyvault.ts`).
- No linter configured; match existing style and import ordering in edited folder.

## Testing Guidelines
- No unit test framework is configured. Prefer smoke-testing:
  - Local: `func start` then hit `/api/http`, `/api/http-with-keyvault`, `/api/http-external-api`.
  - Cloud: run the experiment’s `./run.sh` with `RESOURCE_GROUP_NAME`, `FUNCTION_NAME`, `ENDPOINT`, `VAULT_ENDPOINT` env vars.
- If adding non-trivial logic, include minimal inline validation or a small script in the PR description showing requests/responses.

## Commit & Pull Request Guidelines
- Commits: small, focused, imperative subject (e.g., "add otel-esm keyvault sample").
- Scope in path: group changes per experiment (e.g., `functions/otel-esm/...`).
- PRs include:
  - What changed and why; affected experiment(s).
  - Local/cloud run steps and timings; any updated `languageWorkers__node__arguments`.
  - Screenshots or `assets/` diffs if traces changed.

## Security & Configuration Tips
- Never commit secrets. Use app settings for `VAULT_ENDPOINT` and Azure identities.
- For Node 22, prefer `--import ./telemetry.mjs` with the OTEL loader (`--experimental-loader=@opentelemetry/instrumentation/hook.mjs`).
- Keep `dependencies` minimal; avoid cross-experiment coupling—duplicate small helpers per folder when needed.
