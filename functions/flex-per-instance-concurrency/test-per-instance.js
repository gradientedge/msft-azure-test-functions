#!/usr/bin/env node

/**
 * Per-instance concurrency test script.
 *
 * Triggers the caller function once. The caller then generates concurrent
 * HTTP calls to the worker function in the same app.
 *
 * Usage:
 *   node test-per-instance.js [endpoint] [concurrency] [delayMs] [batches]
 */

const BASE_URL = process.argv[2] || "http://localhost:7071/api/http-slow";
const CONCURRENCY = parseInt(process.argv[3] || "5", 10);
const DELAY_MS = parseInt(process.argv[4] || "3000", 10);
const BATCHES = parseInt(process.argv[5] || "5", 10);

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
  for (const batch of report.batchResults || []) {
    console.log(`\n${"=".repeat(70)}`);
    console.log(`BATCH ${batch.batchId}`);
    console.log(`${"=".repeat(70)}`);
    console.log(`  ${"ID".padEnd(16)} ${"Status".padEnd(8)} ${"Elapsed".padEnd(10)} ${"Instance".padEnd(24)} Notes`);
    console.log(`  ${"-".repeat(66)}`);

    for (const r of batch.results || []) {
      let notes = "";
      if (r.status === 200 && r.elapsedMs > DELAY_MS * 2) {
        notes = `⚠️  SLOW (+${r.elapsedMs - DELAY_MS}ms)`;
      } else if (r.status === 429 || r.status === 503) {
        notes = `🚫 ${r.status === 429 ? "THROTTLED" : "UNAVAILABLE"}`;
      } else if (r.status !== 200) {
        notes = r.error || `HTTP ${r.status}`;
      }

      console.log(
        `  ${(r.id || "-").padEnd(16)} ${String(r.status).padEnd(8)} ${(`${r.elapsedMs}ms`).padEnd(10)} ${String(r.instanceId || "-").substring(0, 22).padEnd(24)} ${notes}`
      );
    }

    console.log(`  ${"-".repeat(66)}`);
    console.log(
      `  Summary: ✅ ${batch.summary?.successCount || 0} success, 🚫 ${batch.summary?.throttledCount || 0} throttled, ❌ ${batch.summary?.errorCount || 0} errors`
    );
  }
}

async function main() {
  console.log(`\nPer-Instance Concurrency Scaling Test`);
  console.log(`=====================================`);
  console.log(`Endpoint:        ${BASE_URL}`);
  console.log(`Concurrency:     ${CONCURRENCY} requests per batch`);
  console.log(`Batches:         ${BATCHES}`);
  console.log(`Delay per req:   ${DELAY_MS}ms`);
  console.log(`\nPlatform setting (set via Azure CLI):`);
  console.log(`  perInstanceConcurrency: 2`);
  console.log(`\nExpected behavior:`);
  console.log(`  - With ${CONCURRENCY} concurrent reqs and perInstanceConcurrency=2,`);
  console.log(`    platform should scale to ceil(${CONCURRENCY}/2) = ${Math.ceil(CONCURRENCY / 2)} instances`);
  console.log(`  - Each instance handles max 2 requests concurrently`);
  console.log(`  - Observe instance IDs to verify distribution`);

  console.log(`\nTriggering caller function...`);
  const runResult = await triggerCaller();
  if (runResult.status !== 200) {
    console.error(`❌ Caller function failed with status ${runResult.status}:`, runResult.body?.error || runResult.error);
    process.exit(1);
  }

  const report = runResult.body;
  printWorkerResults(report);

  // Final summary
  console.log(`\n\n${"═".repeat(70)}`);
  console.log(`FINAL SUMMARY`);
  console.log(`${"═".repeat(70)}`);

  const totalRequests = report.summary?.totalRequests || CONCURRENCY * BATCHES;
  const totals = report.summary || { successCount: 0, throttledCount: 0, uniqueWorkerInstances: 0 };

  console.log(`Total requests sent: ${totalRequests}`);
  console.log(`  ✅ Success:    ${totals.successCount}`);
  console.log(`  🚫 Throttled:  ${totals.throttledCount}`);
  console.log(`  ❌ Errors:     ${totals.errorCount || 0}`);
  console.log(`  🧭 Caller duration: ${report.totalDurationMs}ms`);

  console.log(`\nTotal unique instances observed: ${totals.uniqueWorkerInstances || 0}`);
  console.log(`Expected instances (ceil(${CONCURRENCY}/2)): ${Math.ceil(CONCURRENCY / 2)}`);

  if ((totals.uniqueWorkerInstances || 0) > 1) {
    console.log(`\n  📊 Platform DID scale out to ${totals.uniqueWorkerInstances} instances!`);
    console.log(`     perInstanceConcurrency is working — requests distributed across instances.`);
  } else if ((totals.uniqueWorkerInstances || 0) === 1) {
    console.log(`\n  ⚠️  Only 1 instance observed.`);
    console.log(`     Possible reasons:`);
    console.log(`     - Running locally (no platform scaling)`);
    console.log(`     - Platform hasn't scaled yet (try more batches/longer delay)`);
    console.log(`     - perInstanceConcurrency setting not applied`);
  }

  // Check for delays indicating queuing
  const allResults = (report.batchResults || []).flatMap((b) => b.results || []);
  const queuedRequests = allResults.filter(
    (r) => r.status === 200 && r.elapsedMs > DELAY_MS * 1.8
  );
  if (queuedRequests.length > 0) {
    console.log(`\n  ⏳ ${queuedRequests.length} request(s) took significantly longer than ${DELAY_MS}ms,`);
    console.log(`     indicating they were queued before being processed.`);
  }

  console.log();
}

main().catch(console.error);
