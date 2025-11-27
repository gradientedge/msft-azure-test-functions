// custom-loader.mjs
import { performance } from 'node:perf_hooks';

const timings = new Map();

function logTiming(specifier, phase, timeMs) {
  const key = `${specifier}`;
  let arr = timings.get(key) || [];
  arr.push({ phase, timeMs });
  timings.set(key, arr);
  console.log(`Timing: ${key} [${phase}] took ${timeMs.toFixed(3)} ms`);
}

export async function resolve(specifier, context, defaultResolve) {
  const t0 = performance.now();
  const resolved = await defaultResolve(specifier, context, defaultResolve);
  const t1 = performance.now();
  logTiming(resolved.url || specifier, 'resolve', t1 - t0);
  printTotalForAll()
  return resolved;
}

export async function load(url, context, defaultLoad) {
  const t0 = performance.now();
  // call default loader
  const result = await defaultLoad(url, context, defaultLoad);

  // If source present, we can measure parse/read time roughly by reading file (or rely on result.source)
  const t1 = performance.now();
  logTiming(url, 'load', t1 - t0);

  return result;
}

export function printTotalForAll() {
  let sum = 0
  for (const [, v] of timings.entries()) {
    const total = v.reduce((s, e) => s + e.timeMs, 0).toFixed(3);
    sum += parseFloat(total)
  }
  console.log('...Total time for all modules:', sum.toFixed(3), 'ms');
}

process.on('exit', () => {
  console.log('=== module timings ===');
  for (const [k, v] of timings.entries()) {
    const total = v.reduce((s, e) => s + e.timeMs, 0).toFixed(3);
    console.log(`${k} : ${total} ms  =>`, v);
  }
});
