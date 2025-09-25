import { app } from '@azure/functions';
import axios from 'axios';
import otelAPI from '@opentelemetry/api';

app.http('http-external-api', {
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
      const response = await axios.get('https://www.microsoft.com/en-us/');

      // Return the response
      return {
        status: 200,
        body: 'Success - fetched data from Microsoft',
        headers: {
          'Content-Type': 'text/plain',
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
