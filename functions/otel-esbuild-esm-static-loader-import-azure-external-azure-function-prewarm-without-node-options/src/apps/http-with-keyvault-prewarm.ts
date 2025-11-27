console.log(">>> App loading")
const start = performance.now()
import * as otel from "@opentelemetry/api";
import { app } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import axios from 'axios';
import { setTimeout } from "timers/promises";

let initialised = false;
let initialising = false;
let mutexPromise = Promise.resolve();
let localSecret = "Local secret";

async function prewarm(): Promise<void> {
  if (initialised || initialising) {
    return mutexPromise
  }
  console.log(">>> Prewarm start")
  const startPrewarm = performance.now()
  const context = otel.context.active();
  mutexPromise = otel.trace
    .getTracer(process.env.WEBSITE_SITE_NAME ?? "")
    .startActiveSpan(
      "prewarm-with-node-options",
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
    }).finally(() => {
      const endPrewarm = performance.now()
      console.log(">>> Prewarm end", (endPrewarm - startPrewarm))
      initialised = true;
    })

  initialising = true;
  return mutexPromise;
}

await prewarm();

app.http("http-with-keyvault-prewarm", {
  methods: ["GET", "POST"],
  authLevel: "anonymous",
  handler: async (request, context) => {
    console.log(">>> Request start")
    // await prewarm();
    const startRequest = performance.now()
    context.log(`Header traceparent: "${request.headers.get("traceparent")}"`);
    //@ts-ignore
    context.log(`Context traceparent: "${context.traceContext.traceParent}"`);
    context.log(`ActiveSpan traceId: "${otel.trace.getActiveSpan()}"`);
    context.log(`ActiveSpan spanId: "${otel.trace.getActiveSpan()}"`);
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
console.log('>>> App loaded')
const end = performance.now()
console.log(">>> App loaded in:", (end - start))
