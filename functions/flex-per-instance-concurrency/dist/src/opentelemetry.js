"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsoleSpanExporter = void 0;
console.log(">>> OTEL loading");
const start = performance.now();
const functions_opentelemetry_instrumentation_1 = require("@azure/functions-opentelemetry-instrumentation");
const monitor_opentelemetry_exporter_1 = require("@azure/monitor-opentelemetry-exporter");
const instrumentation_http_1 = require("@opentelemetry/instrumentation-http");
const instrumentation_undici_1 = require("@opentelemetry/instrumentation-undici");
const instrumentation_1 = require("@opentelemetry/instrumentation");
const resources_1 = require("@opentelemetry/resources");
const sdk_logs_1 = require("@opentelemetry/sdk-logs");
const sdk_trace_node_1 = require("@opentelemetry/sdk-trace-node");
const core_1 = require("@opentelemetry/core");
// Console exporter for debugging — prints spans to stdout
class ConsoleSpanExporter {
    export(spans, resultCallback) {
        for (const span of spans) {
            console.log(`[SPAN] ${span.name} | duration=${(span.duration[0] * 1000 + span.duration[1] / 1e6).toFixed(1)}ms | status=${span.status.code} | traceId=${span.spanContext().traceId}`);
        }
        resultCallback({ code: core_1.ExportResultCode.SUCCESS });
    }
    async shutdown() { }
}
exports.ConsoleSpanExporter = ConsoleSpanExporter;
let resource = (0, resources_1.detectResources)({
    detectors: [resources_1.envDetector, resources_1.hostDetector, resources_1.osDetector, resources_1.processDetector],
});
resource = resource.merge((0, resources_1.resourceFromAttributes)({ ["service.name"]: process.env.WEBSITE_SITE_NAME || "flex-per-instance-concurrency" }));
const tracerProvider = new sdk_trace_node_1.NodeTracerProvider({
    resource,
    spanProcessors: [
        new sdk_trace_node_1.BatchSpanProcessor(new monitor_opentelemetry_exporter_1.AzureMonitorTraceExporter()),
        new sdk_trace_node_1.SimpleSpanProcessor(new ConsoleSpanExporter()),
    ],
});
tracerProvider.register();
const loggerProvider = new sdk_logs_1.LoggerProvider({
    resource,
    processors: [new sdk_logs_1.BatchLogRecordProcessor(new monitor_opentelemetry_exporter_1.AzureMonitorLogExporter())],
});
(0, instrumentation_1.registerInstrumentations)({
    tracerProvider,
    loggerProvider,
    instrumentations: [
        new instrumentation_http_1.HttpInstrumentation(),
        new instrumentation_undici_1.UndiciInstrumentation(),
        new functions_opentelemetry_instrumentation_1.AzureFunctionsInstrumentation(),
    ],
});
console.log(`>>> OTEL loaded in ${(performance.now() - start).toFixed(0)}ms`);
