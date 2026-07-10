import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { setTimeout } from "timers/promises";
import * as otel from "@opentelemetry/api";

app.http("http-worker", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    const startTime = Date.now();
    const delayMs = parseInt(request.query.get("delay") || "3000", 10);
    const requestId = request.query.get("id") || "unknown";
    const batchId = parseInt(request.query.get("batch") || "0", 10);
    const instanceId = process.env.WEBSITE_INSTANCE_ID || "local";
    const tracer = otel.trace.getTracer(process.env.WEBSITE_SITE_NAME || "flex-per-instance-concurrency");

    return tracer.startActiveSpan(
      "workerSleep",
      {
        kind: otel.SpanKind.INTERNAL,
        attributes: {
          "request.id": requestId,
          "batch.id": batchId,
          "request.delay_ms": delayMs,
          "instance.id": instanceId,
          "function.role": "worker",
        },
      },
      async (span) => {
        try {
          span.addEvent("worker.start", { delay_ms: delayMs, batch_id: batchId });
          context.log(`[worker][${requestId}] START batch=${batchId} delay=${delayMs}ms instance=${instanceId}`);

          await setTimeout(delayMs);

          const duration = Date.now() - startTime;
          span.addEvent("worker.end", { duration_ms: duration });
          span.setAttribute("request.actual_duration_ms", duration);

          context.log(`[worker][${requestId}] END batch=${batchId} duration=${duration}ms instance=${instanceId}`);

          return {
            status: 200,
            jsonBody: {
              requestId,
              batchId,
              startTime: new Date(startTime).toISOString(),
              endTime: new Date().toISOString(),
              durationMs: duration,
              delayMs,
              overheadMs: duration - delayMs,
              instanceId,
              traceId: span.spanContext().traceId,
            },
          };
        } finally {
          span.end();
        }
      }
    );
  },
});
