/**
 * Fastify-based HTTP handler — mirrors the exact retail-platform-global-services
 * architecture:
 *
 *   Azure Functions HTTP trigger
 *     → fastifyAzureFunction adapter (inject-based)
 *       → Fastify route handler (returns JSON object)
 *         → onSend compress plugin (gzips if ≥ 1MB + client accepts)
 *           → rawPayload Buffer back to Azure Functions runtime
 *
 * This endpoint is registered at /api/fastify-payload/{size} so it can be tested
 * alongside the direct-buffer endpoint at /api/payload/{size}.
 */
import { app } from '@azure/functions';
import Fastify from 'fastify';
import compressPlugin from '../fastify/compress.js';
import { fastifyAzureFunction } from '../fastify/azure-fastify.js';
const PAYLOAD_TARGET_BYTES = {
    small: 10_000,
    medium: 500_000,
    large: 2_000_000,
    xlarge: 5_000_000,
    xxlarge: 21_000_000,
};
function generatePayload(targetBytes) {
    const items = [];
    let currentSize = 2;
    let id = 0;
    while (currentSize < targetBytes) {
        const item = {
            id,
            key: `item-${String(id).padStart(8, '0')}`,
            value: `data-${'x'.repeat(80)}-${String(id).padStart(8, '0')}`,
            nested: { a: id * 7, b: id * 13 },
        };
        const itemJson = JSON.stringify(item);
        currentSize += itemJson.length + (items.length > 0 ? 1 : 0);
        items.push(item);
        id++;
    }
    return items;
}
// Pre-generate payloads
const payloadCache = new Map();
for (const [size, targetBytes] of Object.entries(PAYLOAD_TARGET_BYTES)) {
    const items = generatePayload(targetBytes);
    payloadCache.set(size, items);
    console.log(`[fastify-payload] ${size}: ~${JSON.stringify(items).length} bytes uncompressed`);
}
// ---------------------------------------------------------------------------
// Fastify app setup — mirrors retail configureRootApp()
// ---------------------------------------------------------------------------
const fastifyApp = Fastify({ logger: false });
// Register compress plugin (same as retail when it was ENABLED)
await fastifyApp.register(compressPlugin);
// Route handler — returns a plain object, just like retail route handlers
fastifyApp.get('/api/fastify-payload/:size', async (request, reply) => {
    const { size } = request.params;
    if (!(size in PAYLOAD_TARGET_BYTES)) {
        reply.code(400).header('cache-control', 'no-store');
        return {
            error: `Invalid size parameter. Use one of: ${Object.keys(PAYLOAD_TARGET_BYTES).join(', ')}`,
        };
    }
    const items = payloadCache.get(size);
    const uncompressedSize = JSON.stringify(items).length;
    // Cache bypass: if client sends Cache-Control: no-cache, respond with no-store
    const requestCacheControl = (request.headers['cache-control'] ?? '').toLowerCase();
    const bypassCache = requestCacheControl.includes('no-cache');
    const cacheControl = bypassCache ? 'no-store' : 'public, max-age=300';
    reply
        .header('content-type', 'application/json')
        .header('cache-control', cacheControl)
        .header('x-response-timestamp', new Date().toISOString())
        .header('x-payload-size', size)
        .header('x-payload-uncompressed-size', String(uncompressedSize))
        .header('x-payload-compressed', 'pending') // will be updated or overridden after compress hook
        .header('x-cache-bypass', String(bypassCache));
    // Return a plain array — Fastify serializes it via JSON.stringify, then the
    // compress onSend hook sees the serialized string and gzips if ≥ threshold.
    // This is EXACTLY what retail does.
    return items;
});
// Also register the no-gzip control endpoint on the Fastify app
fastifyApp.get('/api/fastify-payload-no-gzip/:size', async (request, reply) => {
    const { size } = request.params;
    if (!(size in PAYLOAD_TARGET_BYTES)) {
        reply.code(400).header('cache-control', 'no-store');
        return {
            error: `Invalid size parameter. Use one of: ${Object.keys(PAYLOAD_TARGET_BYTES).join(', ')}`,
        };
    }
    const items = payloadCache.get(size);
    const uncompressedSize = JSON.stringify(items).length;
    const requestCacheControl = (request.headers['cache-control'] ?? '').toLowerCase();
    const bypassCache = requestCacheControl.includes('no-cache');
    const cacheControl = bypassCache ? 'no-store' : 'public, max-age=300';
    // Set content-encoding to 'identity' to prevent the compress plugin from gzipping
    reply
        .header('content-type', 'application/json')
        .header('content-encoding', 'identity')
        .header('cache-control', cacheControl)
        .header('x-response-timestamp', new Date().toISOString())
        .header('x-payload-size', size)
        .header('x-payload-uncompressed-size', String(uncompressedSize))
        .header('x-payload-compressed', 'false')
        .header('x-cache-bypass', String(bypassCache));
    return items;
});
await fastifyApp.ready();
// ---------------------------------------------------------------------------
// Azure Functions registration — mirrors retail index.ts pattern
// ---------------------------------------------------------------------------
const funcHandler = fastifyAzureFunction(fastifyApp);
app.http('fastify-payload', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'fastify-payload/{size}',
    handler: funcHandler,
});
app.http('fastify-payload-no-gzip', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'fastify-payload-no-gzip/{size}',
    handler: funcHandler,
});
