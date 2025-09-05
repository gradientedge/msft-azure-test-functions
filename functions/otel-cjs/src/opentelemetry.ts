import { AzureFunctionsInstrumentation } from '@azure/functions-opentelemetry-instrumentation'
import { AzureMonitorLogExporter, AzureMonitorMetricExporter, AzureMonitorTraceExporter } from '@azure/monitor-opentelemetry-exporter';
import { DnsInstrumentation } from '@opentelemetry/instrumentation-dns';
import { FsInstrumentation } from '@opentelemetry/instrumentation-fs';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { NetInstrumentation } from '@opentelemetry/instrumentation-net';
import { RuntimeNodeInstrumentation } from '@opentelemetry/instrumentation-runtime-node';
import { UndiciInstrumentation } from '@opentelemetry/instrumentation-undici';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { detectResources, envDetector, hostDetector, osDetector, processDetector } from '@opentelemetry/resources';
import { azureFunctionsDetector } from '@opentelemetry/resource-detector-azure';
import { metrics } from '@opentelemetry/api'
import { W3CTraceContextPropagator } from '@opentelemetry/core'
import { LoggerProvider, BatchLogRecordProcessor } from '@opentelemetry/sdk-logs';
import { NodeTracerProvider, BatchSpanProcessor } from '@opentelemetry/sdk-trace-node';
import { MeterProvider, PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics'

const resource = detectResources({ detectors: [azureFunctionsDetector, envDetector, hostDetector, osDetector, processDetector] });

const tracerProvider = new NodeTracerProvider({
  resource,
  spanProcessors: [new BatchSpanProcessor(new AzureMonitorTraceExporter())]
});

// this is default
tracerProvider.register({
  propagator: new W3CTraceContextPropagator(),
});

const loggerProvider = new LoggerProvider({
  resource,
  processors: [new BatchLogRecordProcessor(new AzureMonitorLogExporter())]
});

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
    azureInstrumentationInstance
  ],
});

//const azAppFunction = await import('@azure/functions')
//azureInstrumentationInstance.registerAzFunc(azAppFunction);

console.log(">>> Index OTEL loaded")
