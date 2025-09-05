console.log('***** Starting OTEL loading *****')
console.time('OTEL Load Time')
try {
  await import('../opentelemetry.mjs')
  console.timeEnd('OTEL Load Time')
  console.log('***** Finished loading OTEL *****')
} catch (err) {
  console.timeEnd('OTEL Load Time')
  console.error('***** Failed to load OTEL *****', err)
}

await import('../apps/http-external-api.mjs')
// import '../apps/http-external-api.mjs'
