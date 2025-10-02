# Azure Function Request Time Analysis

## Datasets

- **with_node_options**: requests where `languageWorker_arguments_node` is present.
- **no_node_options**: requests where it is absent.

Each dataset includes:
- **Wall Duration**: end-to-end time measured by curl (client-side).
- **Azure Duration**: execution time reported by Azure metrics (server-side).
- **Diff Duration**: `Wall Duration - Azure Duration` (approximate overhead outside function execution: network, cold start gaps, platform, etc.).

## Data integrity checks

- Parsed rows: **69** (no_node_options), **69** (with_node_options).
- Max absolute error between provided `Diff Duration` and recomputed `Wall - Azure`: **0.000000** (should be ~0).

## Summary statistics

### Wall Duration (seconds)

| group             |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| no_node_options   |      69 |  4.074 | 0.845 | 2.567 | 3.919 | 5.246 | 7.49  | 8.539 |
| with_node_options |      69 |  4.547 | 0.823 | 2.021 | 4.704 | 5.399 | 6.197 | 6.353 |

### Azure Duration (seconds)

| group             |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| no_node_options   |      69 |  2.421 | 0.787 | 0.24  | 2.316 | 2.862 | 6.265 | 7.027 |
| with_node_options |      69 |  2.954 | 0.419 | 1.865 | 2.898 | 3.531 | 3.921 | 4.41  |

### Diff Duration (seconds)

| group             |   count |   mean |   std |   min |   p50 |   p95 |   p99 |   max |
|:------------------|--------:|-------:|------:|------:|------:|------:|------:|------:|
| no_node_options   |      69 |  1.653 | 0.794 | 0.112 | 1.554 | 2.049 | 4.415 | 6.757 |
| with_node_options |      69 |  1.593 | 0.584 | 0.103 | 1.637 | 2.1   | 2.746 | 3.573 |


## Notes
- Units are treated as **seconds** based on magnitudes observed.
- Timestamps show experiments ran on different days (Sep 30 and Oct 1, 2025), which may reflect slightly different platform conditions.
- Distributions are visualized below (KDE).
