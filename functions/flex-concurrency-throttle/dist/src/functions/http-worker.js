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
const promises_1 = require("timers/promises");
const otel = __importStar(require("@opentelemetry/api"));
functions_1.app.http("http-worker", {
    methods: ["GET"],
    authLevel: "anonymous",
    handler: async (request, context) => {
        const startTime = Date.now();
        const delayMs = parseInt(request.query.get("delay") || "2000", 10);
        const requestId = request.query.get("id") || "unknown";
        const batchId = parseInt(request.query.get("batch") || "0", 10);
        const instanceId = process.env.WEBSITE_INSTANCE_ID || "local";
        const tracer = otel.trace.getTracer(process.env.WEBSITE_SITE_NAME || "flex-concurrency-throttle");
        return tracer.startActiveSpan("workerSleep", {
            kind: otel.SpanKind.INTERNAL,
            attributes: {
                "request.id": requestId,
                "batch.id": batchId,
                "request.delay_ms": delayMs,
                "instance.id": instanceId,
                "function.role": "worker",
            },
        }, async (span) => {
            try {
                span.addEvent("worker.start", { delay_ms: delayMs, batch_id: batchId });
                context.log(`[worker][${requestId}] START batch=${batchId} delay=${delayMs}ms instance=${instanceId}`);
                await (0, promises_1.setTimeout)(delayMs);
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
            }
            finally {
                span.end();
            }
        });
    },
});
