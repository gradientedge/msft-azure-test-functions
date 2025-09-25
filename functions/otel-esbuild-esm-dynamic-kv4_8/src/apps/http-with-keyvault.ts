import { app } from '@azure/functions';
import { DefaultAzureCredential } from '@azure/identity'
import { SecretClient } from '@azure/keyvault-secrets';
import otelAPI from '@opentelemetry/api';

app.http('http-with-keyvault', {
  methods: ['GET', 'POST'],
  authLevel: 'anonymous',
  handler: async (request, context) => {

    context.log(`Header traceparent: "${request.headers.get('traceparent')}"`);
    //@ts-ignore
    context.log(`Context traceparent: "${context.traceContext.traceParent}"`);
    context.log(`ActiveSpan traceId: "${otelAPI.trace.getActiveSpan()}"`);
    context.log(`ActiveSpan spanId: "${otelAPI.trace.getActiveSpan()}"`);

    try {
      // Make HTTP request to Microsoft
      // @ts-ignore
      const secretClient = new SecretClient(process.env.VAULT_ENDPOINT, new DefaultAzureCredential());
      const mySecret = await secretClient.getSecret("my-secret")

      // Return the response
      return {
        status: 200,
        body: JSON.stringify({
          secretValue: mySecret.value ? 'it is secret' : 'no value'
        }),
        headers: {
          'Content-Type': 'application/json',
          traceparent: context.traceContext?.traceParent || ''
        }
      };
    } catch (error) {
      context.log('Error occurred:', error);
      // Handle errors
      return {
        // @ts-ignore
        status: error.response ? error.response.status : 500,
        body: 'Failed to fetch data from Microsoft',
        headers: {
          'Content-Type': 'text/plain',
          traceparent: context.traceContext?.traceParent || ''
        }
      };
    }
  }
});
