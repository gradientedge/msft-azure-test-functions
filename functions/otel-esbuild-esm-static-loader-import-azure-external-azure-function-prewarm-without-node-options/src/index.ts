import sourceMapSupport from 'source-map-support'
sourceMapSupport.install()
console.log(">>> Index Start")
const start = performance.now()

import { register } from 'node:module';
import { pathToFileURL } from 'node:url';

console.log(">>> Index OTEL hook registering")
const startRegister = performance.now()
// register("@opentelemetry/instrumentation/hook.mjs", import.meta.url)
register("@opentelemetry/instrumentation/hook.mjs", pathToFileURL('./'))
const endRegister = performance.now()
console.log(">>> Index OTEL hook registered", (endRegister - startRegister))

console.log(">>> Index OTEL loading")
const startOTEL = performance.now()
await import('./opentelemetry.js')
const endOTEL = performance.now()
console.log(">>> Index OTEL loaded", (endOTEL - startOTEL))

console.log(">>> Loading application")
const startApplication = performance.now()
await import('./apps/http-with-keyvault-prewarm.js')
const endApplication = performance.now()
console.log(">>> Loaded application", (endApplication - startApplication))

const end = performance.now()
console.log(">>> Total time", (end - start))
console.log(">>> Index End")
