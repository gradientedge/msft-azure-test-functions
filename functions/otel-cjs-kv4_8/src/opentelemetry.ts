console.log(">>> OTEL loading")
const start = performance.now()
// Enable Diagnostic for OpenTelemetry 
// import { diag, DiagConsoleLogger, DiagLogLevel } from '@opentelemetry/api'; 
import { AzureFunctionsInstrumentation } from '@azure/functions-opentelemetry-instrumentation'
import { createAzureSdkInstrumentation } from "@azure/opentelemetry-instrumentation-azure-sdk";
import {
  AzureMonitorLogExporter,
  AzureMonitorMetricExporter,
  AzureMonitorTraceExporter,
} from '@azure/monitor-opentelemetry-exporter'
import { DnsInstrumentation } from '@opentelemetry/instrumentation-dns'
import { FsInstrumentation } from '@opentelemetry/instrumentation-fs'
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http'
import { NetInstrumentation } from '@opentelemetry/instrumentation-net'
import { RuntimeNodeInstrumentation } from '@opentelemetry/instrumentation-runtime-node'
import { UndiciInstrumentation } from '@opentelemetry/instrumentation-undici'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { detectResources, envDetector, hostDetector, osDetector, processDetector, resourceFromAttributes } from '@opentelemetry/resources'
// commented to prevent leaking subscription id to public repo
// import { azureFunctionsDetector } from '@opentelemetry/resource-detector-azure'
import { metrics } from '@opentelemetry/api'
import { LoggerProvider, BatchLogRecordProcessor } from '@opentelemetry/sdk-logs'
import { ExportResult, ExportResultCode, hrTimeToMicroseconds } from '@opentelemetry/core'
import {
  NodeTracerProvider,
  BatchSpanProcessor,
  SimpleSpanProcessor,
  SpanExporter,
  ReadableSpan,
} from '@opentelemetry/sdk-trace-node'
import { MeterProvider, PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics'

// Enable OpenTelemetry diagnostics logging (optional, but useful for debugging)
//
//diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);
//

// allows easier debugging of spans in azure appinsights
/* eslint-disable no-console */
export class ConsoleSpanExporter implements SpanExporter {
  /**
   * Export spans.
   * @param spans
   * @param resultCallback
   */
  export(spans: ReadableSpan[], resultCallback: (result: ExportResult) => void): void {
    return this._sendSpans(spans, resultCallback)
  }

  /**
   * Shutdown the exporter.
   */
  shutdown(): Promise<void> {
    this._sendSpans([])
    return this.forceFlush()
  }

  /**
   * Exports any pending spans in exporter
   */
  forceFlush(): Promise<void> {
    return Promise.resolve()
  }

  /**
   * converts span info into more readable format
   * @param span
   */
  private _exportInfo(span: ReadableSpan) {
    return {
      //resource: {
      //  attributes: span.resource.attributes,
      //},
      instrumentationScope: span.instrumentationScope,
      traceId: span.spanContext().traceId,
      parentSpanContext: span.parentSpanContext,
      traceState: span.spanContext().traceState?.serialize(),
      name: span.name,
      id: span.spanContext().spanId,
      kind: span.kind,
      timestamp: hrTimeToMicroseconds(span.startTime),
      duration: hrTimeToMicroseconds(span.duration),
      attributes: span.attributes,
      status: span.status,
      events: span.events,
      links: span.links,
    }
  }

  /**
   * Showing spans in console
   * @param spans
   * @param done
   */
  private _sendSpans(spans: ReadableSpan[], done?: (result: ExportResult) => void): void {
    for (const span of spans) {
      console.log(JSON.stringify(this._exportInfo(span)))
    }
    if (done) {
      return done({ code: ExportResultCode.SUCCESS })
    }
  }
}

let resource = detectResources({ detectors: [envDetector, hostDetector, osDetector, processDetector] });

resource = resource.merge(
  resourceFromAttributes({
    ['service.name']: process.env.WEBSITE_SITE_NAME,
  }),
)

const tracerProvider = new NodeTracerProvider({
  resource,
  // spanProcessors: [new BatchSpanProcessor(new AzureMonitorTraceExporter())]
  spanProcessors: [
    new BatchSpanProcessor(new AzureMonitorTraceExporter()),
    new SimpleSpanProcessor(new ConsoleSpanExporter()),
  ],
})

tracerProvider.register()

const loggerProvider = new LoggerProvider({
  resource,
  processors: [new BatchLogRecordProcessor(new AzureMonitorLogExporter())],
})

const meterProvider = new MeterProvider({
  resource,
  readers: [
    new PeriodicExportingMetricReader({
      exporter: new AzureMonitorMetricExporter(),
      exportIntervalMillis: 5_000,
    }),
  ],
})
metrics.setGlobalMeterProvider(meterProvider)

const azureInstrumentationInstance = new AzureFunctionsInstrumentation()

registerInstrumentations({
  tracerProvider,
  loggerProvider,
  meterProvider,
  instrumentations: [
    new DnsInstrumentation(),
    new FsInstrumentation(),
    new HttpInstrumentation(),
    new NetInstrumentation(),
    new RuntimeNodeInstrumentation(),
    new UndiciInstrumentation(),
    azureInstrumentationInstance,
    createAzureSdkInstrumentation()
  ],
})
console.log('>>> OTEL loaded')
const end = performance.now()
console.log(">>> OTEL loaded in:", (end - start))
