# OTEL Azure Function Compatibility Test

## Purpose

This project is designed to **test Azure Function behavior** when making changes to APIs and configuration.  

The goals are to ensure:  

- **Backward compatibility** with existing OTEL (OpenTelemetry) configuration.  
- **No loss of functionality or support** after updates or modifications.  

## Usage

This function is intended to validate:  

1. Changes in API endpoints.  
2. Updates to function configuration.  
3. Compatibility with OTEL tracing, logging, and metrics.  

## Prerequisites

Before deploying, you need to:  

- Create a Function App in the **Azure Portal**.  
- Create a **Key Vault** and a secret named `my-secret`.  
- Configure the Function App to have access permissions to the Key Vault.  

## Running Tests

Each experiment includes a `run.sh` script, which runs the test end-to-end.  

Before running, set the following environment variables:  

```bash
RESOURCE_GROUP_NAME   # The resource group where the Function App is deployed
FUNCTION_NAME         # The name of the Function App used for experiments
ENDPOINT              # The URL of the Function App
VAULT_ENDPOINT        # The URL of the Key Vault
```

Run the script with:

```shell
cd functions/<experiment>
./run.sh
```

## Resources

- [OTEL ESM Support](https://github.com/open-telemetry/opentelemetry-js/blob/main/doc/esm-support.md)
The entire startup command should include the following `NODE_OPTIONS`:

| Node.js Version   | NODE_OPTIONS                                                                              |
| ----------------- | ----------------------------------------------------------------------------------------- |
| 16.x              | `--require ./telemetry.cjs --experimental-loader=@opentelemetry/instrumentation/hook.mjs` |
| >=18.1.0 <18.19.0 | `--require ./telemetry.cjs --experimental-loader=@opentelemetry/instrumentation/hook.mjs` |
| ^18.19.0          | `--import ./telemetry.mjs --experimental-loader=@opentelemetry/instrumentation/hook.mjs`  |
| 20.x              | `--import ./telemetry.mjs --experimental-loader=@opentelemetry/instrumentation/hook.mjs`  |
| 22.x              | `--import ./telemetry.mjs --experimental-loader=@opentelemetry/instrumentation/hook.mjs`  |
