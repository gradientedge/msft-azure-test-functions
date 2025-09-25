import { app } from "@azure/functions";
import { setTimeout } from "timers/promises";
import * as otel from "@opentelemetry/api";

app.http('http', {
  methods: ['GET', 'POST'],
  authLevel: 'anonymous',
  handler: async (request, context) => {
    context.log(`Http function processed request for url "${request.url}"`);

    const name = request.query.get('name') || await request.text() || 'world';

    const traceContext = otel.context.active();
    await otel.trace
      .getTracer(process.env.WEBSITE_SITE_NAME ?? "")
      .startActiveSpan(
        "100msWait",
        { kind: otel.SpanKind.INTERNAL, attributes: { "custom-attribute": "100ms" } },
        traceContext,
        async (span) => {
          try {
            span.addEvent("Start 100ms wait");

            await setTimeout(100)
          } finally {
            span.addEvent("End 100ms wait");
            span.end();
          }
        }
      )

    return {
      status: 200,
      body: `Hello, ${name}!`,
      headers: {
        'Content-Type': 'text/plain',
        traceparent: context.traceContext?.traceParent || ''
      }
    };
  }
});
