// write a client taht calls on  http://localhost:7071/api/http-with-keyvault-pr with otel wrapper 
//
//
import { propagation, trace } from '@opentelemetry/api'
import { W3CTraceContextPropagator } from '@opentelemetry/core'
import { NodeTracerProvider, AlwaysOffSampler, AlwaysOnSampler, ParentBasedSampler } from '@opentelemetry/sdk-trace-node'
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
  sampler: new ParentBasedSampler({
    // root: new AlwaysOffSampler(), // Root spans not sampled
    root: new AlwaysOnSampler(), // Root spans not sampled
  }),
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

      // Manually construct expected traceparent to verify what should be sent
      const expectedTraceparent = `00-${span.spanContext().traceId}-${span.spanContext().spanId}-0${span.spanContext().traceFlags}`
      console.log("Expected traceparent header:", expectedTraceparent)

      // UndiciInstrumentation automatically injects traceparent header from active context
      const response = await fetch('http://localhost:7071/api/http-with-keyvault-prewarm')
      const data = await response.text()
      console.log('Response from function:', data)
      console.log('Response traceparent header:', response.headers.get('traceparent'))

      // Check if sampling was respected
      const responseTraceparent = response.headers.get('traceparent')
      if (responseTraceparent) {
        const parts = responseTraceparent.split('-')
        const responseFlags = parts[3]
        console.log(`Sampling preserved: ${responseFlags === '00' ? 'YES ✓' : 'NO ✗ (expected 00, got ' + responseFlags + ')'}`)
      }
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
