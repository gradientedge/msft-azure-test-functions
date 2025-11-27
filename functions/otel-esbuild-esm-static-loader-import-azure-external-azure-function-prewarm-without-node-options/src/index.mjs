const start = performance.now()
import fs from 'node:fs'
console.log(">>> Index Start")

import { register } from 'node:module';
import { pathToFileURL } from 'node:url';

console.log(">>> Index OTEL hook registering")
const startRegister = performance.now()
register("import-in-the-middle/hook.mjs", import.meta.url)
// register("@opentelemetry/instrumentation/hook.mjs", pathToFileURL('./'))
const endRegister = performance.now()
console.log(">>> Index OTEL hook registered", (endRegister - startRegister))

console.log(">>> Index OTEL loading")
const startOTEL = performance.now()
await import('./opentelemetry.mjs')
const endOTEL = performance.now()
console.log(">>> Index OTEL loaded", (endOTEL - startOTEL))

console.log(">>> Loading application")
const startApplication = performance.now()

const { handler } = await import('./apps/http-with-keyvault-prewarm.mjs')
const endApplication = performance.now()
console.log(">>> Loaded application", (endApplication - startApplication))

export { handler }
const end = performance.now()
console.log(">>> Total time", (end - start))
console.log(">>> Index End")
