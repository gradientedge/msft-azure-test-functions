#!/usr/bin/env node

/**
 * Concurrency throttle test script.
 *
 * Triggers the caller function once. The caller function then generates
 * concurrent HTTP calls to the worker function inside the same Function App.
 * This creates clear function-to-function traces in Application Insights.
 *
 * Usage:
 *   node test-concurrency.js [endpoint] [concurrency] [batches] [delayMs]
 *
 * Examples:
 *   node test-concurrency.js http://localhost:7071/api/http-slow 4 3 2000
 *   node test-concurrency.js https://azfe-concurrency-throttle.azurewebsites.net/api/http-slow 4 3 2000
 */

const BASE_URL = process.argv[2] || "http://localhost:7071/api/http-slow";
const CONCURRENCY = parseInt(process.argv[3] || "4", 10);
const BATCHES = parseInt(process.argv[4] || "3", 10);
const DELAY_MS = parseInt(process.argv[5] || "2000", 10);

async function triggerCaller() {
  const runId = `run-${Date.now()}`;
  const url = `${BASE_URL}?id=${runId}&concurrency=${CONCURRENCY}&batches=${BATCHES}&delay=${DELAY_MS}`;
  const start = Date.now();

  try {
    const response = await fetch(url);
    const elapsed = Date.now() - start;
    const body = response.status === 200 ? await response.json() : { error: await response.text() };

    return {
      status: response.status,
      elapsed,
      body,
      error: null,
    };
  } catch (error) {
    const elapsed = Date.now() - start;
    return {
      status: "ERR",
      elapsed,
      body: null,
      error: error.message,
    };
  }
}

function printWorkerResults(report) {
  const batchResults = report.batchResults || [];

  for (const batch of batchResults) {
    console.log(`\n${"=".repeat(60)}`);
    console.log(`BATCH ${batch.batchId}`);
    console.log(`${"=".repeat(60)}`);
    console.log(`  ${"ID".padEnd(22)} ${"Status".padEnd(8)} ${"Elapsed".padEnd(10)} ${"Instance".padEnd(20)} Notes`);
    console.log(`  ${"-".repeat(60)}`);

    for (const r of batch.results || []) {
      let notes = "";
      if (r.status === 200 && r.elapsedMs > DELAY_MS * 1.5) {
        notes = `⚠️  QUEUED (+${r.elapsedMs - DELAY_MS}ms)`;
      } else if (r.status === 429) {
        notes = "🚫 THROTTLED (429)";
      } else if (r.status === 503) {
        notes = "🚫 UNAVAILABLE (503)";
      } else if (r.status !== 200) {
        notes = r.error || `HTTP ${r.status}`;
      }

      console.log(
        `  ${String(r.id || "-").substring(0, 21).padEnd(22)} ${String(r.status).padEnd(8)} ${(`${r.elapsedMs}ms`).padEnd(10)} ${String(r.instanceId || "-").substring(0, 18).padEnd(20)} ${notes}`
      );
    }

    console.log(`  ${"-".repeat(60)}`);
    console.log(
      `  Summary: ✅ ${batch.summary?.successCount || 0} success, 🚫 ${batch.summary?.throttledCount || 0} throttled, ❌ ${batch.summary?.errorCount || 0} errors`
    );
  }
}

async function main() {
  console.log(`\nConcurrency Throttle Test`);
  console.log(`========================`);
  console.log(`Endpoint:    ${BASE_URL}`);
  console.log(`Concurrency: ${CONCURRENCY} requests per batch`);
  console.log(`Batches:     ${BATCHES}`);
  console.log(`Delay:       ${DELAY_MS}ms per request`);
  console.log(`\nhost.json expected settings:`);
  console.log(`  maxConcurrentRequests: 6`);
  console.log(`  maxOutstandingRequests: 10`);
  console.log(`  dynamicThrottlesEnabled: true`);
  console.log(`\nExpected behavior:`);
  console.log(`  - In this demo, one outer caller request stays active while it calls /api/http-worker`);
  console.log(`  - With 2 warm HTTP instances, a larger "fast" group is expected before queueing starts`);
  console.log(`  - Next group is buffered/queued (longer durations)`);
  console.log(`  - Highest-pressure tail is expected to return HTTP 429 (or 503)`);

  console.log(`\nRecommended run to observe all 3 zones (immediate/queued/429):`);
  console.log(`  node test-concurrency.js ${BASE_URL} 24 1 ${DELAY_MS}`);

  console.log(`\nTriggering caller function...`);
  const runResult = await triggerCaller();
  if (runResult.status !== 200) {
    console.error(`❌ Caller function failed with status ${runResult.status}:`, runResult.body?.error || runResult.error);
    process.exit(1);
  }

  const report = runResult.body;
  printWorkerResults(report);

  // Final summary
  console.log(`\n\n${"═".repeat(60)}`);
  console.log(`FINAL SUMMARY`);
  console.log(`${"═".repeat(60)}`);
  const totals = report.summary || { successCount: 0, throttledCount: 0, errorCount: 0, totalRequests: 0 };
  const totalRequests = totals.totalRequests || CONCURRENCY * BATCHES;
  console.log(`Total requests sent: ${totalRequests}`);
  console.log(`  ✅ Success:    ${totals.successCount} (${((totals.successCount / totalRequests) * 100).toFixed(1)}%)`);
  console.log(`  🚫 Throttled:  ${totals.throttledCount} (${((totals.throttledCount / totalRequests) * 100).toFixed(1)}%)`);
  console.log(`  ❌ Errors:     ${totals.errorCount} (${((totals.errorCount / totalRequests) * 100).toFixed(1)}%)`);
  console.log(`  🧭 Caller duration: ${report.totalDurationMs}ms`);
  console.log(`  🧩 Unique worker instances: ${totals.uniqueWorkerInstances || 0}`);
  console.log(`\nConclusion:`);

  if (totals.throttledCount > 0) {
    console.log(`  ⚠️  Throttling detected! maxConcurrentRequests/maxOutstandingRequests`);
    console.log(`     are ACTIVELY limiting throughput. This confirms the hypothesis that`);
    console.log(`     these settings can cause request queuing/rejection in Flex Consumption.`);
  } else if (totals.successCount === totalRequests) {
    console.log(`  ✅ All requests succeeded — no throttling observed.`);
    console.log(`     Either the settings don't apply as expected or instance count scaled.`);
  }
  console.log();
}

main().catch(console.error);
