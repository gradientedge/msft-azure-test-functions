console.log("Loading HTTP Key Vault API function...");
import * as otel from "@opentelemetry/api";
import { app } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import otelAPI from "@opentelemetry/api";

let localSecret = "Local secret";
async function prewarm() {
  const context = otel.context.active();
  await otel.trace
    .getTracer(process.env.WEBSITE_SITE_NAME ?? "")
    .startActiveSpan(
      "prewarm",
      { kind: otel.SpanKind.INTERNAL },
      context,
      async (span) => {
        try {
          // Make HTTP request to Microsoft
          const start = performance.now();
          span.addEvent("Start prewarm");

          console.log("Loading HTTP Key Vault API function...");
          const secretClient = new SecretClient(
            "https://really-secret.vault.azure.net/",
            new DefaultAzureCredential()
          );
          const mySecret = await secretClient.getSecret("my-secret");
          localSecret = localSecret + (mySecret?.value ?? "not-found");
          const end = performance.now();
          console.log("Secret loaded", localSecret, end - start);
        } catch (error) {
          span.addEvent(`Error ${error}`);
          span.setStatus({
            code: otel.SpanStatusCode.ERROR,
            message: `${error}`,
          });
          throw error;
        } finally {
          span.addEvent("End prewarm");
          span.end();
        }
      }
    )
    .then((r) => r)
    .catch((error) => {
      throw error;
    });
}

await prewarm();

app.http("http-with-keyvault-prewarm", {
  methods: ["GET", "POST"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    context.log(`Header traceparent: "${request.headers.get("traceparent")}"`);
    //@ts-ignore
    context.log(`Context traceparent: "${context.traceContext.traceParent}"`);
    context.log(`ActiveSpan traceId: "${otelAPI.trace.getActiveSpan()}"`);
    context.log(`ActiveSpan spanId: "${otelAPI.trace.getActiveSpan()}"`);
    context.log(`Local secret: "${localSecret}"`);

    try {
      // Make HTTP request to Microsoft
      const secretClient = new SecretClient(
        "https://really-secret.vault.azure.net/",
        new DefaultAzureCredential()
      );
      const mySecret = await secretClient.getSecret("my-secret");

      // Return the response
      return {
        status: 200,
        body: JSON.stringify({
          secretValue: mySecret.value ? "it is secret" : "no value",
        }),
        headers: {
          "Content-Type": "application/json",
        },
      };
    } catch (error) {
      context.log("Error occurred:", error);
      // Handle errors
      return {
        // @ts-ignore
        status: error.response ? error.response.status : 500,
        body: "Failed to fetch data from Microsoft",
        headers: {
          "Content-Type": "text/plain",
        },
      };
    }
  },
});
