# Azure Function Request Analysis

## What each column means
- **Wall Duration**: end-to-end latency seen by the client (curl).
- **Azure Duration**: time reported by Azure metrics (server-side execution).
- **Diff Duration** = Wall - Azure: overhead outside the function body (network, platform scheduling, cold starts, etc.).

## Data integrity checks
- Rows parsed: **69** (no_node_options), **69** (with_node_options).
- Max absolute error between provided Diff and computed (Wall - Azure): **0.000000000** (≈0 indicates consistent naming).

## Summary statistics
### Wall Duration (seconds)

| group              |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:-------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments |      69 |  4.074 | 0.845 | 2.567 | 3.919 | 5.246 | 7.49  | 8.539 |
| on_node_arguments  |      69 |  4.547 | 0.823 | 2.021 | 4.704 | 5.399 | 6.197 | 6.353 |

### Azure Duration (seconds)

| group              |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:-------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments |      69 |  2.421 | 0.787 | 0.24  | 2.316 | 2.862 | 6.265 | 7.027 |
| on_node_arguments  |      69 |  2.954 | 0.419 | 1.865 | 2.898 | 3.531 | 3.921 | 4.41  |

### Diff Duration (seconds)

| group              |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:-------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments |      69 |  1.653 | 0.794 | 0.112 | 1.554 | 2.049 | 4.415 | 6.757 |
| on_node_arguments  |      69 |  1.593 | 0.584 | 0.103 | 1.637 | 2.1   | 2.746 | 3.573 |

