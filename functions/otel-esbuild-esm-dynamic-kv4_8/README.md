# Experiment

The purpose of the experiment is to test configuration for OTEL support.

Function setup:
- npm
- ESM module
- dynamic import
- esbuild
- KV Library 4.8

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
@msft-azure-test-functions/otel-esbuild-esm-dynamic-kv4_8@1.0.0 /Users/kamil/repo/ge/msft-azure-test-functions/functions/otel-esbuild-esm-dynamic-kv4_8
├── @azure/functions-opentelemetry-instrumentation@0.2.0 overridden
├── @azure/functions@4.8.0
├── @azure/identity@4.12.0
├── @azure/keyvault-secrets@4.8.0
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
Uploading 3.66 MB
```

## Request Timing

| Time | Function | Traceparent | Response (seconds) |
|---|---|---|---|
| Fri Sep 26 15:53:40 BST 2025 | http | 00-c81d3abd87e43ede0f91a3a0fac81797-bcbce45cae1b797b-01 | 0.254242 |
| Fri Sep 26 15:53:41 BST 2025 | http-with-keyvault | 00-4b1a3e1c4d3631a4dba45d5ba4c7b8de-82942c096917c0dd-01 | 0.543304 |
| Fri Sep 26 15:53:41 BST 2025 | http-external-api | 00-1c2d31400bb3c1af4ede42ba6bfc2262-b14207695b6bb1d4-01 | 0.242019 |

## Trace

## HTTP Trace

![HTTP](assets/http.png)

## HTTP Key Vault Trace

![HTTP Key Vault](assets/http-with-keyvault.png)

## HTTP External API Trace

![HTTP External API](assets/http-external-api.png)

## Observation

