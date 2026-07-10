import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

app.http("http-health", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    return {
      status: 200,
      jsonBody: {
        status: "ok",
        timestamp: new Date().toISOString(),
        instanceId: process.env.WEBSITE_INSTANCE_ID || "local",
      },
    };
  },
});
