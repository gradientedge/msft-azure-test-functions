import { promisify } from 'node:util';
import { gzip } from 'node:zlib';
import { app } from '@azure/functions';
const gzipAsync = promisify(gzip);
const PAYLOAD_TARGET_BYTES = {
    small: 10_000, // ~10 KB
    medium: 500_000, // ~500 KB
    large: 2_000_000, // ~2 MB
    xlarge: 5_000_000, // ~5 MB
    xxlarge: 21_000_000, // ~21 MB
};
const COMPRESS_THRESHOLD = 1_048_576; // 1 MB — matches production
/**
 * Generate a deterministic JSON string of approximately `targetBytes` size.
 * The payload is an array of objects so it looks realistic.
 */
function generatePayload(targetBytes) {
    const items = [];
    let currentSize = 2; // account for opening `[` and closing `]`
    let id = 0;
    while (currentSize < targetBytes) {
        const item = {
            id,
            key: `item-${String(id).padStart(8, '0')}`,
            value: `data-${'x'.repeat(80)}-${String(id).padStart(8, '0')}`,
            nested: { a: id * 7, b: id * 13 },
        };
        const itemJson = JSON.stringify(item);
        // +1 for comma separator (except first item)
        currentSize += itemJson.length + (items.length > 0 ? 1 : 0);
        items.push(item);
        id++;
    }
    return JSON.stringify(items);
}
// Pre-generate payloads at module load so Content-Length is stable across requests
const payloadCache = new Map();
async function initPayloads() {
    for (const [size, targetBytes] of Object.entries(PAYLOAD_TARGET_BYTES)) {
        const json = generatePayload(targetBytes);
        const compressed = await gzipAsync(Buffer.from(json));
        payloadCache.set(size, { json, compressed });
        console.log(`[payload] ${size}: uncompressed=${json.length} bytes, compressed=${compressed.length} bytes`);
    }
}
await initPayloads();
// ---------------------------------------------------------------------------
// Accept-Encoding negotiation (matches production compress.ts)
// ---------------------------------------------------------------------------
function clientAcceptsGzip(acceptEncoding) {
    if (!acceptEncoding)
        return false;
    let gzipQ = null;
    let wildcardQ = null;
    for (const token of acceptEncoding.split(',')) {
        const [encoding, ...params] = token.trim().split(';');
        const name = encoding.trim().toLowerCase();
        if (name !== 'gzip' && name !== '*')
            continue;
        const qPart = params.find((p) => p.trim().toLowerCase().startsWith('q='));
        const q = parseQValue(qPart);
        if (name === 'gzip') {
            gzipQ = q;
        }
        else {
            wildcardQ = q;
        }
    }
    if (gzipQ !== null)
        return gzipQ > 0;
    if (wildcardQ !== null)
        return wildcardQ > 0;
    return false;
}
function parseQValue(qPart) {
    if (!qPart)
        return 1;
    const eqIdx = qPart.indexOf('=');
    if (eqIdx === -1)
        return 1;
    const q = Number(qPart.slice(eqIdx + 1).trim());
    return Number.isNaN(q) ? 1 : q;
}
// ---------------------------------------------------------------------------
// HTTP handler
// ---------------------------------------------------------------------------
async function handler(request, _context) {
    const sizeParam = request.params.size;
    if (!sizeParam || !(sizeParam in PAYLOAD_TARGET_BYTES)) {
        return {
            status: 400,
            headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
            body: JSON.stringify({
                error: `Invalid size parameter. Use one of: ${Object.keys(PAYLOAD_TARGET_BYTES).join(', ')}`,
            }),
        };
    }
    const size = sizeParam;
    const entry = payloadCache.get(size);
    // Cache bypass: if client sends Cache-Control: no-cache, respond with no-store
    const requestCacheControl = request.headers.get('cache-control') ?? '';
    const bypassCache = requestCacheControl.toLowerCase().includes('no-cache');
    const cacheControl = bypassCache ? 'no-store' : 'public, max-age=300';
    const acceptEncoding = request.headers.get('accept-encoding');
    const shouldCompress = entry.json.length >= COMPRESS_THRESHOLD && clientAcceptsGzip(acceptEncoding);
    const headers = {
        'Content-Type': 'application/json',
        'Cache-Control': cacheControl,
        'Vary': 'Accept-Encoding',
        'X-Response-Timestamp': new Date().toISOString(),
        'X-Payload-Size': size,
        'X-Payload-Uncompressed-Size': String(entry.json.length),
        'X-Payload-Compressed-Size': String(entry.compressed.length),
        'X-Payload-Compressed': String(shouldCompress),
        'X-Cache-Bypass': String(bypassCache),
    };
    if (shouldCompress) {
        headers['Content-Encoding'] = 'gzip';
        headers['Content-Length'] = String(entry.compressed.length);
        return { status: 200, headers, body: entry.compressed };
    }
    headers['Content-Length'] = String(Buffer.byteLength(entry.json));
    return { status: 200, headers, body: entry.json };
}
app.http('payload', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'api/payload/{size}',
    handler,
});
