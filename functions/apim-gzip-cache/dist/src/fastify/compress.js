/**
 * Compress plugin — exact copy of the retail compress.ts from
 * retail-platform-global-services/application/common/packages/fastify/fastify/src/plugins/compress.ts
 *
 * Uses node:zlib gzip in an onSend hook with 1 MB threshold.
 */
import { promisify } from 'node:util';
import { gzip } from 'node:zlib';
import fp from 'fastify-plugin';
const gzipAsync = promisify(gzip);
export const COMPRESS_THRESHOLD = 1_048_576;
const compressPlugin = (app, opts, done) => {
    const threshold = opts.threshold ?? COMPRESS_THRESHOLD;
    app.addHook('onSend', async (request, reply, payload) => {
        // Skip if a previous plugin/route already set an encoding (e.g. pre-compressed data)
        if (reply.getHeader('content-encoding')) {
            return payload;
        }
        const byteLength = getByteLength(payload);
        if (byteLength === null || byteLength < threshold) {
            return payload;
        }
        // Always set Vary: accept-encoding so intermediary caches know different
        // clients may receive different representations
        mergeVary(reply, 'accept-encoding');
        // Proper RFC 7231 q-value negotiation
        if (!clientAcceptsGzip(request.headers['accept-encoding'])) {
            return payload;
        }
        const buf = Buffer.isBuffer(payload) ? payload : Buffer.from(payload);
        const compressed = await gzipAsync(buf);
        reply.header('content-encoding', 'gzip');
        reply.header('content-length', String(compressed.length));
        return compressed;
    });
    done();
};
function clientAcceptsGzip(acceptEncoding) {
    if (!acceptEncoding) {
        return false;
    }
    const raw = Array.isArray(acceptEncoding) ? acceptEncoding.join(',') : acceptEncoding;
    let gzipQ = null;
    let wildcardQ = null;
    for (const token of raw.split(',')) {
        const [encoding, ...params] = token.trim().split(';');
        const name = encoding.trim().toLowerCase();
        if (name !== 'gzip' && name !== '*') {
            continue;
        }
        const qPart = params.find((param) => param.trim().toLowerCase().startsWith('q='));
        const q = parseEncodingQValue(qPart);
        if (name === 'gzip') {
            gzipQ = q;
            continue;
        }
        wildcardQ = q;
    }
    if (gzipQ !== null) {
        return gzipQ > 0;
    }
    if (wildcardQ !== null) {
        return wildcardQ > 0;
    }
    return false;
}
function parseEncodingQValue(qPart) {
    if (!qPart) {
        return 1;
    }
    const eqIdx = qPart.indexOf('=');
    if (eqIdx === -1) {
        return 1;
    }
    const q = Number(qPart.slice(eqIdx + 1).trim());
    return Number.isNaN(q) ? 1 : q;
}
function mergeVary(reply, field) {
    const existing = reply.getHeader('vary');
    if (existing === undefined) {
        reply.header('vary', field);
        return;
    }
    const current = String(existing);
    if (current.trim() === '*') {
        return;
    }
    const lcField = field.toLowerCase();
    const already = current.split(',').some((f) => f.trim().toLowerCase() === lcField);
    if (!already) {
        reply.header('vary', `${current}, ${field}`);
    }
}
function getByteLength(payload) {
    if (Buffer.isBuffer(payload)) {
        return payload.length;
    }
    if (typeof payload === 'string') {
        return Buffer.byteLength(payload);
    }
    return null;
}
export default fp(compressPlugin, { fastify: '5.x', name: 'specsavers-fastify-compress' });
