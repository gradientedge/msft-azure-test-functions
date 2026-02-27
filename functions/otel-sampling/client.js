// write a client taht calls on  http://localhost:7071/api/http-with-keyvault-pr with otel wrapper 
//
//
import { propagation, trace } from '@opentelemetry/api'
import { W3CTraceContextPropagator } from '@opentelemetry/core'
import { NodeTracerProvider, AlwaysOffSampler } from '@opentelemetry/sdk-trace-node'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http'
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base'
import { detectResources, envDetector, hostDetector, osDetector, processDetector, resourceFromAttributes } from '@opentelemetry/resources'
import { UndiciInstrumentation } from '@opentelemetry/instrumentation-undici'
import {
  AzureMonitorTraceExporter,
} from '@azure/monitor-opentelemetry-exporter'

let resource = detectResources({ detectors: [envDetector, hostDetector, osDetector, processDetector] });
resource = resource.merge(
  resourceFromAttributes({
    ['service.name']: 'otel-sampling-client',
  }),
)

// Set up OpenTelemetry
const provider = new NodeTracerProvider({
  resource,
  sampler: new AlwaysOffSampler(), // You can choose different samplers here
  spanProcessors: [
    new BatchSpanProcessor(new AzureMonitorTraceExporter()),
    // new SimpleSpanProcessor(new ConsoleSpanExporter()),
  ],
})

// add propagation support for fetch so we pass traceparent header to the function

provider.register()

registerInstrumentations({
  instrumentations: [
    new HttpInstrumentation(),
    new UndiciInstrumentation(),
  ],
})

const tracer = trace.getTracer('otel-sampling-client')

async function callFunction() {
  // Use startActiveSpan to set the span as active context for propagation
  await tracer.startActiveSpan('call-http-function', async (span) => {
    try {
      console.log("Client trace context:", {
        traceId: span.spanContext().traceId,
        spanId: span.spanContext().spanId,
        traceFlags: span.spanContext().traceFlags
      })
      // UndiciInstrumentation automatically injects traceparent header from active context
      const response = await fetch('http://localhost:7071/api/http-with-keyvault-prewarm')
      const data = await response.text()
      console.log('Response from function:', data)
      console.log('Response traceparent header:', response.headers.get('traceparent'))
    } catch (error) {
      console.error('Error calling function:', error)
      span.recordException(error)
      span.setStatus({ code: trace.SpanStatusCode.ERROR, message: error.message })
    } finally {
      span.end()
    }
  })
}

callFunction()
