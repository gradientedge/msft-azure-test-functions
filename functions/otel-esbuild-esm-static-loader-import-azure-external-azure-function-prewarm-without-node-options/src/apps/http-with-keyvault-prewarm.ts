console.log("Loading HTTP Key Vault API function...");
import * as otel from "@opentelemetry/api";
import { app } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import otelAPI from "@opentelemetry/api";
import axios from 'axios';
import { setTimeout } from "timers/promises";

let localSecret = "Local secret";
async function prewarm() {
  console.log(">>> Prewarm start")
  const startPrewarm = performance.now()
  const context = otel.context.active();
  await otel.trace
    .getTracer(process.env.WEBSITE_SITE_NAME ?? "")
    .startActiveSpan(
      "prewarm-without-node-options",
      { kind: otel.SpanKind.INTERNAL },
      context,
      async (span) => {
        try {
          // Make HTTP request to Microsoft
          const start = performance.now();
          span.addEvent("Start prewarm");

          // trace only shows 1.1
          //  2.6761430-d5577a955e7d22d241eaca34803b9b62-673600d43c1542cb-01
          //  trace only shows 1.7
          //   3.248075 00-b196fb2e95ffcf5f6507e14eb674f813-ca0e62f6e3eb69b4-01


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
    })
  const endPrewarm = performance.now()
  console.log(">>> Prewarm end", (endPrewarm - startPrewarm))
}

await prewarm();

app.http("http-with-keyvault-prewarm", {
  methods: ["GET", "POST"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    console.log(">>> Request start")
    const startRequest = performance.now()
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

      // external api 
      await axios.get('https://www.microsoft.com/en-us/');

      // configure trace
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

      // Return the response
      return {
        status: 200,
        body: JSON.stringify({
          secretValue: mySecret.value ? "it is secret" : "no value",
        }),
        headers: {
          "Content-Type": "application/json",
          traceparent: context.traceContext?.traceParent || ''
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
          traceparent: context.traceContext?.traceParent || ''
        },
      };
    } finally {
      const endRequest = performance.now()
      console.log(">>> Request end", (endRequest - startRequest))
    }
  },
});
