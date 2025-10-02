# Request Time Analysis

## Overview

A total of 69 samples were collected for each case, covering a 1 hour 30 minute period. The samples were gathered during a continuous deployment while a sequential request repeatedly hit the service throughout the deployment which either represent a cold start of scalling out.

See [deploy.sh](../deploy.sh) and [request.sh](../request.sh) for details.

## Data Generation

Filter requests longer than 2 seconds:

```shell
filter.sh
```

Create markdown datasets with Azure Duration added:

```shell
node azure-analytics.js filtered/requests-node-arguments-off.log filtered/requests-node-arguments-off.md
node azure-analytics.js filtered/requests-node-arguments-on.log filtered/requests-node-arguments-on.md
```

Generate statistical data:

```shell
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

./analyze_azure_function_requests.py --off-md filtered/requests-node-arguments-off.md --on-md filtered/requests-node-arguments-on.md --plots assets --out-md analysis.md

```

Generate PDF file:

```shell
pandoc README.md -o README.pdf
```


## Datasets

- **on_node_arguments**: requests where `languageWorker_arguments_node` is **present**.
- **off_node_arguments**: requests where `languageWorker_arguments_node` is **absent**.

Each dataset includes:

- **Date and Time**: execution date
- **Trace Id** – OpenTelemetry trace identifier  
- **Wall Duration** – end-to-end time measured by `curl` (client-side)  
- **Azure Duration** – execution time reported by Azure metrics (server-side)  
- **Diff Duration**: `Wall Duration - Azure Duration` (approximate overhead outside function execution: network, cold start gaps, platform, etc.).

## Summary Statistics

### Wall Duration (seconds)

![Wall Duration](./assets/wall_duration.png)


| group             |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments   |      69 |  4.074 | 0.845 | 2.567 | 3.919 | 5.246 | 7.49  | 8.539 |
| on_node_arguments |      69 |  4.547 | 0.823 | 2.021 | 4.704 | 5.399 | 6.197 | 6.353 |


### Azure Duration (seconds)

![Azure Duration](./assets/azure_duration.png)


| group             |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments   |      69 |  2.421 | 0.787 | 0.24  | 2.316 | 2.862 | 6.265 | 7.027 |
| on_node_arguments |      69 |  2.954 | 0.419 | 1.865 | 2.898 | 3.531 | 3.921 | 4.41  |


### Diff Duration (seconds)

![Diff Duration](./assets/diff_duration.png)


| group             |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments   |      69 |  1.653 | 0.794 | 0.112 | 1.554 | 2.049 | 4.415 | 6.757 |
| on_node_arguments |      69 |  1.593 | 0.584 | 0.103 | 1.637 | 2.1   | 2.746 | 3.573 |


## Key Observations

1. **Performance Difference**
   - On average, **off_node_arguments** is about **12% faster** (4.07 vs 4.55 mean).  
   - Median values also confirm this trend (3.92 vs 4.70).  

2. **Stability**
   - Both cases show similar variability (std ~0.82–0.85).
   - **off_node_arguments** shows higher extreme spikes (max 8.54 vs 6.35).  

3. **High Percentiles**
   - At **p95**, both are similar (~5.3–5.4).
   - At **p99**, *off_node_arguments* performs worse (7.49 vs 6.20), indicating occasional high-latency outliers.  

4. **Distribution**
   - **on_node_arguments**: more consistent, clustered around ~4.5–5.0.  
   - **off_node_arguments**: generally faster but with a longer tail (rare spikes).  

## Conclusion

- **off_node_arguments** → Lower average latency, but occasional severe spikes.  
  Penalty of having `languageWorker_arguments_node` is approximately:  
  - **~+500 ms** at p50  
  - **~+1 s** at p95  
  - **~+2.7 s** at p99  

- **on_node_arguments** → Slightly slower overall, but more predictable and stable.  

- **Azure Duration vs Wall Duration** → Azure-reported execution time is consistently lower than Wall Duration, leaving an unexplained penalty of almost **2 seconds at p95**.  

