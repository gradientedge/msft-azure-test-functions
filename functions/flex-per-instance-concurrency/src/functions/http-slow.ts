import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import * as otel from "@opentelemetry/api";

app.http("http-slow", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    const startedAt = Date.now();
    const concurrency = parseInt(request.query.get("concurrency") || "5", 10);
    const batches = parseInt(request.query.get("batches") || "5", 10);
    const delayMs = parseInt(request.query.get("delay") || "3000", 10);
    const requestPrefix = request.query.get("id") || "run";
    const instanceId = process.env.WEBSITE_INSTANCE_ID || "local";
    const origin = new URL(request.url).origin;
    const workerUrl = `${origin}/api/http-worker`;
    const tracer = otel.trace.getTracer(process.env.WEBSITE_SITE_NAME || "flex-per-instance-concurrency");

    context.log(`[caller] START concurrency=${concurrency} batches=${batches} delay=${delayMs}ms worker=${workerUrl} instance=${instanceId}`);

    const result = await tracer.startActiveSpan(
      "orchestrateWorkerBatches",
      {
        kind: otel.SpanKind.INTERNAL,
        attributes: {
          "request.concurrency": concurrency,
          "request.batches": batches,
          "request.delay_ms": delayMs,
          "instance.id": instanceId,
          "concurrency.test": "perInstanceConcurrency",
          "function.role": "caller",
        },
      },
      async (span) => {
        const batchResults: Array<{
          batchId: number;
          summary: { successCount: number; throttledCount: number; errorCount: number };
          results: Array<{ id: string; status: number | string; elapsedMs: number; instanceId?: string; error?: string }>;
        }> = [];

        let totalSuccess = 0;
        let totalThrottled = 0;
        let totalErrors = 0;
        const workerInstances = new Set<string>();

        try {
          for (let batch = 1; batch <= batches; batch++) {
            const batchStart = Date.now();
            span.addEvent("batch.start", { batch_id: batch, concurrency });
            context.log(`[caller] BATCH ${batch} START concurrency=${concurrency}`);

            const requests = Array.from({ length: concurrency }, (_, idx) => {
              const reqId = `${requestPrefix}-b${batch}-r${idx + 1}`;
              const url = `${workerUrl}?id=${encodeURIComponent(reqId)}&batch=${batch}&delay=${delayMs}`;
              const start = Date.now();

              return fetch(url)
                .then(async (response) => {
                  const elapsedMs = Date.now() - start;
                  if (response.status === 200) {
                    const body = (await response.json()) as { instanceId?: string };
                    if (body.instanceId) {
                      workerInstances.add(body.instanceId);
                    }
                    return { id: reqId, status: 200, elapsedMs, instanceId: body.instanceId };
                  }
                  return { id: reqId, status: response.status, elapsedMs, error: `HTTP ${response.status}` };
                })
                .catch((error: Error) => {
                  const elapsedMs = Date.now() - start;
                  return { id: reqId, status: "ERR", elapsedMs, error: error.message };
                });
            });

            const settled = await Promise.all(requests);
            const batchSuccess = settled.filter((r) => r.status === 200).length;
            const batchThrottled = settled.filter((r) => r.status === 429 || r.status === 503).length;
            const batchErrors = settled.length - batchSuccess - batchThrottled;

            totalSuccess += batchSuccess;
            totalThrottled += batchThrottled;
            totalErrors += batchErrors;

            span.addEvent("batch.end", {
              batch_id: batch,
              duration_ms: Date.now() - batchStart,
              success_count: batchSuccess,
              throttled_count: batchThrottled,
              error_count: batchErrors,
            });

            context.log(
              `[caller] BATCH ${batch} END success=${batchSuccess} throttled=${batchThrottled} errors=${batchErrors} duration=${Date.now() - batchStart}ms`
            );

            batchResults.push({
              batchId: batch,
              summary: { successCount: batchSuccess, throttledCount: batchThrottled, errorCount: batchErrors },
              results: settled,
            });
          }

          const totalDurationMs = Date.now() - startedAt;
          span.setAttribute("total.duration_ms", totalDurationMs);
          span.setAttribute("summary.success_count", totalSuccess);
          span.setAttribute("summary.throttled_count", totalThrottled);
          span.setAttribute("summary.error_count", totalErrors);
          span.setAttribute("summary.unique_worker_instances", workerInstances.size);

          context.log(
            `[caller] END totalDuration=${totalDurationMs}ms success=${totalSuccess} throttled=${totalThrottled} errors=${totalErrors} workerInstances=${workerInstances.size}`
          );

          return {
            status: 200 as const,
            jsonBody: {
              startTime: new Date(startedAt).toISOString(),
              endTime: new Date().toISOString(),
              totalDurationMs,
              scenario: {
                concurrency,
                batches,
                delayMs,
                callerInstanceId: instanceId,
                workerUrl,
              },
              summary: {
                totalRequests: concurrency * batches,
                successCount: totalSuccess,
                throttledCount: totalThrottled,
                errorCount: totalErrors,
                uniqueWorkerInstances: workerInstances.size,
              },
              batchResults,
              callerTraceId: span.spanContext().traceId,
            },
          };
        } finally {
          span.end();
        }
      }
    );

    return result;
  },
});
