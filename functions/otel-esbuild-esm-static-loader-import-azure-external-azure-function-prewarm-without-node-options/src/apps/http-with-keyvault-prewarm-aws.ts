console.log(">>> App loading")
const start = performance.now()
import * as otel from "@opentelemetry/api";
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


          console.log(`ActiveSpan traceId: "${otel.trace.getActiveSpan()}"`);
          console.log(`ActiveSpan spanId: "${otel.context.active()}"`);
          console.log(`Active span context: ${otel.trace.getSpan(otel.context.active())}`)
          console.log(`Active span context: ${otel.trace.getSpan(otel.context.active())?.spanContext()?.traceId}`)
          console.log("Loading HTTP Key Vault API function...");
          // const secretClient = new SecretClient(
          //   "https://really-secret.vault.azure.net/",
          //   new DefaultAzureCredential()
          // );
          // const mySecret = await secretClient.getSecret("my-secret");
          const mySecret = {} as any
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

export const handler = async (event, context) => {
  // TODO implement
  console.log(">>> Request start")
  const startRequest = performance.now()
  // console.log(`Header traceparent: "${event.headers.get("traceparent")}"`);
  //@ts-ignore
  // console.log(`Context traceparent: "${context.traceContext.traceParent}"`);
  console.log(`ActiveSpan traceId: "${otel.trace.getActiveSpan()}"`);
  console.log(`ActiveSpan spanId: "${otel.trace.getActiveSpan()}"`);
  console.log(`ActiveSpan spanId: "${otel.context.active()}"`);
  console.log(`Active span context: ${otel.trace.getSpan(otel.context.active())}`)
  console.log(`Active span context: ${otel.trace.getSpan(otel.context.active())?.spanContext()?.traceId}`)
  console.log(`Local secret: "${localSecret}"`);
  console.log('Received event:', JSON.stringify(event, null, 2));
  console.log('Received context:', JSON.stringify(context, null, 2));
  // fs.readdirSync("/mnt/otel-modules").forEach(file => {
  //   // will also include directory names
  //   console.log(file);
  // });
  try {
    // Make HTTP request to Microsoft
    const secretClient = new SecretClient(
      "https://really-secret.vault.azure.net/",
      new DefaultAzureCredential()
    );
    // const mySecret = await secretClient.getSecret("my-secret");
    const mySecret = {} as any

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
      statusCode: 200,
      body: JSON.stringify({
        secretValue: mySecret?.value ? "it is secret" : "no value",
      }),
      headers: {
        "Content-Type": "application/json",
        traceparent: context.traceContext?.traceParent || ''
      },
    };
  } catch (error) {
    console.log("Error occurred:", error);
    // Handle errors
    return {
      // @ts-ignore
      statusCode: error.response ? error.response.status : 500,
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
}

console.log('>>> App loaded')
const end = performance.now()
console.log(">>> App loaded in:", (end - start))
