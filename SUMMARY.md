# Experiment Summaries

Concise summaries of each experiment under `functions/`. For details and timing tables, see each experiment’s README.

## otel-cjs
- Path: `functions/otel-cjs`
- Setup: npm, CommonJS module
- Observation: Almost all works as expected; DNS moved to bottom of trace for external API.
- Run: `functions/otel-cjs/run.sh`

## otel-cjs-kv4_8
- Path: `functions/otel-cjs-kv4_8`
- Setup: npm, CommonJS module, @azure/keyvault-secrets@4.8.0
- Observation: All works as expected.
- Run: `functions/otel-cjs-kv4_8/run.sh`

## otel-esbuild-esm-dynamic
- Path: `functions/otel-esbuild-esm-dynamic`
- Setup: npm, ESM module, esbuild, dynamic import
- Observation: Missing most tracing except `tls` and `tcp`.
- Run: `functions/otel-esbuild-esm-dynamic/run.sh`

## otel-esbuild-esm-dynamic-kv4_8
- Path: `functions/otel-esbuild-esm-dynamic-kv4_8`
- Setup: npm, ESM module, esbuild, dynamic import, @azure/keyvault-secrets@4.8.0
- Observation: More traces than dynamic, but gaps for `dns`, `internal`, and extra instrumentation (e.g., `fs`).
- Run: `functions/otel-esbuild-esm-dynamic-kv4_8/run.sh`

## otel-esbuild-esm-dynamic-loader
- Path: `functions/otel-esbuild-esm-dynamic-loader`
- Setup: npm, ESM module, esbuild, dynamic import, experimental loader
- Observation: Closest to CommonJS; still missing `dns` traces.
- Run: `functions/otel-esbuild-esm-dynamic-loader/run.sh`

## otel-esbuild-esm-static-loader-import
- Path: `functions/otel-esbuild-esm-static-loader-import`
- Setup: npm, ESM module, esbuild, experimental loader, import
- Observation: No traces despite similar config to `otel-esm`.
- Run: `functions/otel-esbuild-esm-static-loader-import/run.sh`

## otel-esm
- Path: `functions/otel-esm`
- Setup: npm, ESM module
- Observation: Duplicate HTTP traces for external API vs. CommonJS.
- Run: `functions/otel-esm/run.sh`

## otel-esm-kv4_8
- Path: `functions/otel-esm-kv4_8`
- Setup: npm, ESM module, @azure/keyvault-secrets@4.8.0
- Observation: Faster initial request; duplicate HTTP traces for external API vs. CommonJS.
- Run: `functions/otel-esm-kv4_8/run.sh`

## otel-esm-patch
- Path: `functions/otel-esm-patch`
- Setup: npm, ESM module, Azure instrumentation patch
- Run: `functions/otel-esm-patch/run.sh`
