console.log(">>> App loading")
const start = performance.now()
import * as otel from "@opentelemetry/api";
import { propagation } from "@opentelemetry/api";
import { app } from "@azure/functions";
import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import axios from 'axios';
import { setTimeout } from "timers/promises";
import { logger } from "./logger.js"

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
    // Manually extract traceparent from header and create OpenTelemetry context
    const traceparentHeader = request.headers.get("traceparent");
    console.log(">>> Traceparent header value:", traceparentHeader);
    console.log(">>> Context trace value:", context.traceContext);

    // Extract the parent context from traceparent header
    const parentContext = traceparentHeader
      ? propagation.extract(otel.context.active(), { traceparent: traceparentHeader })
      : otel.context.active();
    console.log('what is parent context', parentContext);

    // Create a span with the extracted parent context
    return await otel.trace
      .getTracer(process.env.WEBSITE_SITE_NAME ?? "")
      .startActiveSpan(
        "http-with-keyvault-prewarm-handler",
        { kind: otel.SpanKind.SERVER },
        // parentContext, // unless we inject the parent context extracted from the header
        async (span) => {
          const startRequest = performance.now();

          logger.debug("log debug");
          logger.info("log info");
          logger.warn("log warn");
          logger.error("log error");

          console.log("OpenTelemetry span context:", {
            traceId: span.spanContext().traceId,
            spanId: span.spanContext().spanId,
            traceFlags: span.spanContext().traceFlags,
            parentSpanId: traceparentHeader?.split('-')[2]
          });

          context.log(`Header traceparent: "${traceparentHeader}"`);
          //@ts-ignore
          context.log(`Context traceparent: "${context.traceContext.traceParent}"`);
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

            // Create a child span for the 100ms wait
            await otel.trace
              .getTracer(process.env.WEBSITE_SITE_NAME ?? "")
              .startActiveSpan(
                "100msWait",
                { kind: otel.SpanKind.INTERNAL, attributes: { "custom-attribute": "100ms" } },
                async (waitSpan) => {
                  try {
                    waitSpan.addEvent("Start 100ms wait");
                    await setTimeout(100)
                  } finally {
                    waitSpan.addEvent("End 100ms wait");
                    waitSpan.end();
                  }
                }
              )

            // Build traceparent from OpenTelemetry span context
            const responseTraceparent = `00-${span.spanContext().traceId}-${span.spanContext().spanId}-0${span.spanContext().traceFlags}`;
            console.log('Response traceparent:', responseTraceparent);
            console.log('Context:', context.traceContext?.traceParent);

            const carrier = {}
            const otelCtx = otel.context.active();
            propagation.inject(otelCtx, carrier)
            console.log('Injected carrier:', carrier);
            // Return the response
            return {
              status: 200,
              body: JSON.stringify({
                secretValue: mySecret.value ? "it is secret" : "no value",
              }),
              headers: {
                "Content-Type": "application/json",
                ...carrier
                // traceparent: responseTraceparent
              },
            };
          } catch (error) {
            context.log("Error occurred:", error);
            span.recordException(error);
            span.setStatus({ code: otel.SpanStatusCode.ERROR, message: String(error) });

            // Build traceparent for error response
            const responseTraceparent = `00-${span.spanContext().traceId}-${span.spanContext().spanId}-0${span.spanContext().traceFlags}`;

            // Handle errors
            return {
              // @ts-ignore
              status: error.response ? error.response.status : 500,
              body: "Failed to fetch data from Microsoft",
              headers: {
                "Content-Type": "text/plain",
                traceparent: responseTraceparent
              },
            };
          } finally {
            const endRequest = performance.now();
            console.log(">>> Request end", (endRequest - startRequest));
            span.end();
          }
        }
      );
  },
});
console.log('>>> App loaded')
const end = performance.now()
console.log(">>> App loaded in:", (end - start))
