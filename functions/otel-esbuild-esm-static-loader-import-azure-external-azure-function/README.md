# Experiment

The purpose of the experiment is to test configuration for OTEL support.

Function setup:
- npm
- ESM module
- dynamic import
- esbuild
- KV Library 4.8
- experimental loader
- static import from package.json
- external @azure/functions

To execute experiment run below script:
```shell
./run.sh
```

## Environment

```text
NODE:
v22.13.1

NPM:
10.9.2

FUNC:
4.2.2

AZ:
{
  "azure-cli": "2.77.0",
  "azure-cli-core": "2.77.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {
    "account": "0.2.5",
    "application-insights": "1.2.3",
    "containerapp": "1.2.0b2"
  }
}
```

## Dependencies

```text
@msft-azure-test-functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function@1.0.0 /Users/kamil/repo/ge/msft-azure-test-functions/functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function
├── @azure/functions-opentelemetry-instrumentation@0.2.0 overridden
├── @azure/functions@4.8.0
├── @azure/identity@4.12.0
├── @azure/keyvault-secrets@4.10.0
├── @azure/monitor-opentelemetry-exporter@1.0.0-beta.32
├── @azure/opentelemetry-instrumentation-azure-sdk@1.0.0-beta.9
├── @opentelemetry/api-logs@0.205.0
├── @opentelemetry/api@1.9.0
├── @opentelemetry/instrumentation-dns@0.49.0
├── @opentelemetry/instrumentation-fs@0.25.0
├── @opentelemetry/instrumentation-http@0.205.0
├── @opentelemetry/instrumentation-net@0.49.0
├── @opentelemetry/instrumentation-runtime-node@0.19.0
├── @opentelemetry/instrumentation-undici@0.16.0
├── @opentelemetry/instrumentation@0.205.0
├── @opentelemetry/resource-detector-azure@0.12.0
├── @opentelemetry/resources@2.1.0
├── @opentelemetry/sdk-logs@0.205.0
├── @opentelemetry/sdk-metrics@2.1.0
├── @opentelemetry/sdk-trace-node@2.1.0
├── @types/node@22.18.0
├── axios@1.12.2
├── azure-functions-core-tools@4.2.2
├── esbuild@0.25.1
├── rimraf@6.0.1
└── typescript@5.9.2

```
## Package size

```text
Uploading 10.43 MB
```

## Request Timing

| Time | Function | Traceparent | Response (seconds) |
|---|---|---|---|
| Fri Sep 26 16:09:15 BST 2025 | http | 00-c0b298722c129fa7d6957af03879555d-b7dec024cf11aa66-01 | 0.263981 |
| Fri Sep 26 16:09:16 BST 2025 | http-with-keyvault | 00-4b9a655167c8318edba3c078f47882fb-73f7d7b4ca09f827-01 | 0.624651 |
| Fri Sep 26 16:09:16 BST 2025 | http-external-api | 00-9767da757dca0f2167e7bdb6b8b32b15-a24ab1b6fa964ef3-01 | 0.508005 |

## Trace

## HTTP Trace

![HTTP](assets/http.png)

## HTTP Key Vault Trace

![HTTP Key Vault](assets/http-with-keyvault.png)

## HTTP External API Trace

![HTTP External API](assets/http-external-api.png)

## Observation

Traces matching `otel-esm`.
