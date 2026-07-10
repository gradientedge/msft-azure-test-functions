"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const functions_1 = require("@azure/functions");
const otel = __importStar(require("@opentelemetry/api"));
functions_1.app.http("http-slow", {
    methods: ["GET"],
    authLevel: "anonymous",
    handler: async (request, context) => {
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
        const result = await tracer.startActiveSpan("orchestrateWorkerBatches", {
            kind: otel.SpanKind.INTERNAL,
            attributes: {
                "request.concurrency": concurrency,
                "request.batches": batches,
                "request.delay_ms": delayMs,
                "instance.id": instanceId,
                "concurrency.test": "perInstanceConcurrency",
                "function.role": "caller",
            },
        }, async (span) => {
            const batchResults = [];
            let totalSuccess = 0;
            let totalThrottled = 0;
            let totalErrors = 0;
            const workerInstances = new Set();
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
                                const body = (await response.json());
                                if (body.instanceId) {
                                    workerInstances.add(body.instanceId);
                                }
                                return { id: reqId, status: 200, elapsedMs, instanceId: body.instanceId };
                            }
                            return { id: reqId, status: response.status, elapsedMs, error: `HTTP ${response.status}` };
                        })
                            .catch((error) => {
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
                    context.log(`[caller] BATCH ${batch} END success=${batchSuccess} throttled=${batchThrottled} errors=${batchErrors} duration=${Date.now() - batchStart}ms`);
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
                context.log(`[caller] END totalDuration=${totalDurationMs}ms success=${totalSuccess} throttled=${totalThrottled} errors=${totalErrors} workerInstances=${workerInstances.size}`);
                return {
                    status: 200,
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
            }
            finally {
                span.end();
            }
        });
        return result;
    },
});
