# flex-per-instance-concurrency

Tests the **Flex Consumption platform-level** `perInstanceConcurrency` setting (configured via Azure CLI, not host.json) and observes whether the platform scales out instances correctly.

## Background

In Flex Consumption, HTTP concurrency is controlled at the platform level:

```bash
az functionapp scale config set \
  --resource-group $RG \
  --name $FUNC \
  --trigger-type http \
  --trigger-settings perInstanceConcurrency=2
```

This tells the platform: "each instance handles max 2 HTTP requests concurrently". When more requests arrive, the platform should scale out to additional instances.

## Experiment Design

- **perInstanceConcurrency = 2**
- Send 5 concurrent requests (each sleeps 3s)
- Expected: platform scales to `ceil(5/2) = 3` instances
- Observe: instance IDs, response times, any delays

## Key Differences from `flex-concurrency-throttle`

| Setting | Where | Behavior |
|---------|-------|----------|
| `maxConcurrentRequests` | host.json | Rejects requests (429) when limit hit |
| `maxOutstandingRequests` | host.json | Queue size before rejection |
| `perInstanceConcurrency` | Platform (CLI) | Triggers scale-out to more instances |

## Local Test

Locally, scaling won't happen (single instance), but you can verify the function works:

```bash
npm ci && npm run build
npm start
# In another terminal:
node test-per-instance.js http://localhost:7071/api/http-slow 5 3000 3
```

## Azure Deploy & Test

```bash
export RESOURCE_GROUP_NAME=your-rg
export FUNCTION_NAME=your-flex-func
export ENDPOINT=https://your-flex-func.azurewebsites.net
./run.sh
```

## What to Observe

1. **Multiple instance IDs**: Confirms platform scaled out
2. **Response time ~ delay (3s)**: No queuing, instances handled load
3. **Response time >> delay**: Scaling was slow, requests queued
4. **Cold start penalty**: First requests to new instances may be slower

## Questions to Answer

- How fast does Flex Consumption scale out when `perInstanceConcurrency` is exceeded?
- Is there a visible cold-start delay on new instances?
- With `perInstanceConcurrency=2` and 5 requests, do we actually get 3 instances?
- What happens during scale-in — do we see the same timing issues as in QA2?
