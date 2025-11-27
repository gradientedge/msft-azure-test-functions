# Azure Function Request Analysis

## What each column means
- **Wall Duration**: end-to-end latency seen by the client (curl).
- **Azure Duration**: time reported by Azure metrics (server-side execution).
- **Diff Duration** = Wall - Azure: overhead outside the function body (network, platform scheduling, cold starts, etc.).

## Data integrity checks
- Rows parsed: **69** (no_node_options), **31** (with_node_options).
- Max absolute error between provided Diff and computed (Wall - Azure): **0.000000000** (≈0 indicates consistent naming).

## Summary statistics
### Wall Duration (seconds)

| group              |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:-------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments |      69 |  4.074 | 0.845 | 2.567 | 3.919 | 5.246 | 7.49  | 8.539 |
| on_node_arguments  |      31 |  3.59  | 0.554 | 2.109 | 3.635 | 4.265 | 4.871 | 5.052 |

### Azure Duration (seconds)

| group              |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:-------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments |      69 |  2.421 | 0.787 | 0.24  | 2.316 | 2.862 | 6.265 | 7.027 |
| on_node_arguments  |      31 |  2.929 | 0.45  | 1.896 | 2.912 | 3.582 | 4.161 | 4.324 |

### Diff Duration (seconds)

| group              |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:-------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| off_node_arguments |      69 |  1.653 | 0.794 | 0.112 | 1.554 | 2.049 | 4.415 | 6.757 |
| on_node_arguments  |      31 |  0.661 | 0.182 | 0.191 | 0.678 | 0.892 | 1.047 | 1.094 |

