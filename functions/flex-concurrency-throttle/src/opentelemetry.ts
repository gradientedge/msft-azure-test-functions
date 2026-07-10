console.log(">>> OTEL loading");
const start = performance.now();

import { AzureFunctionsInstrumentation } from "@azure/functions-opentelemetry-instrumentation";
import {
  AzureMonitorLogExporter,
  AzureMonitorTraceExporter,
} from "@azure/monitor-opentelemetry-exporter";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import { UndiciInstrumentation } from "@opentelemetry/instrumentation-undici";
import { registerInstrumentations } from "@opentelemetry/instrumentation";
import {
  detectResources,
  envDetector,
  hostDetector,
  osDetector,
  processDetector,
  resourceFromAttributes,
} from "@opentelemetry/resources";
import { LoggerProvider, BatchLogRecordProcessor } from "@opentelemetry/sdk-logs";
import {
  NodeTracerProvider,
  BatchSpanProcessor,
  SimpleSpanProcessor,
  SpanExporter,
  ReadableSpan,
} from "@opentelemetry/sdk-trace-node";
import { ExportResultCode } from "@opentelemetry/core";
import type { ExportResult } from "@opentelemetry/core";

// Console exporter for debugging — prints spans to stdout
export class ConsoleSpanExporter implements SpanExporter {
  export(spans: ReadableSpan[], resultCallback: (result: ExportResult) => void): void {
    for (const span of spans) {
      console.log(
        `[SPAN] ${span.name} | duration=${(span.duration[0] * 1000 + span.duration[1] / 1e6).toFixed(1)}ms | status=${span.status.code} | traceId=${span.spanContext().traceId}`
      );
    }
    resultCallback({ code: ExportResultCode.SUCCESS });
  }
  async shutdown(): Promise<void> {}
}

let resource = detectResources({
  detectors: [envDetector, hostDetector, osDetector, processDetector],
});
resource = resource.merge(
  resourceFromAttributes({ ["service.name"]: process.env.WEBSITE_SITE_NAME || "flex-concurrency-throttle" })
);

const tracerProvider = new NodeTracerProvider({
  resource,
  spanProcessors: [
    new BatchSpanProcessor(new AzureMonitorTraceExporter()),
    new SimpleSpanProcessor(new ConsoleSpanExporter()),
  ],
});
tracerProvider.register();

const loggerProvider = new LoggerProvider({
  resource,
  processors: [new BatchLogRecordProcessor(new AzureMonitorLogExporter())],
});

registerInstrumentations({
  tracerProvider,
  loggerProvider,
  instrumentations: [
    new HttpInstrumentation(),
    new UndiciInstrumentation(),
    new AzureFunctionsInstrumentation(),
  ],
});

console.log(`>>> OTEL loaded in ${(performance.now() - start).toFixed(0)}ms`);
