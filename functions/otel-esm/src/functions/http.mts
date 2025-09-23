import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

export async function example(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log(`Http function processed request for url "${request.url}"`);

  const name = request.query.get('name') || await request.text() || 'world';

  return {
    status: 200,
    body: `Hello, ${name}!`,
    headers: {
      'Content-Type': 'text/plain',
      traceparent: context.traceContext?.traceParent || ''
    }
  };
};

app.http('http', {
  methods: ['GET', 'POST'],
  authLevel: 'anonymous',
  handler: example
});
