const EMTPY_CONTENT_STATUS_CODES = [101, 204, 205, 304];
export function fastifyAzureFunction(fastifyApp) {
    return async (request, context) => {
        const method = toHttpMethod(request.method);
        const url = new URL(request.url);
        const searchParams = url.searchParams;
        const path = url.pathname.length < 2 || !url.pathname.endsWith('/') ? url.pathname : url.pathname.slice(0, -1);
        const query = {};
        for (const [key, val] of searchParams.entries()) {
            if (key.endsWith('[]')) {
                if (!query[key]) {
                    query[key] = [];
                }
                ;
                query[key].push(val);
            }
            else {
                query[key] = val;
            }
        }
        const headers = {};
        for (const [key, value] of request.headers.entries()) {
            headers[key] = value;
        }
        let incomingPayload = undefined;
        if (request.body) {
            incomingPayload = await request.text();
        }
        return new Promise((resolve) => {
            fastifyApp.inject({
                method,
                url: path,
                query,
                payload: incomingPayload,
                headers,
            }, (err, res) => {
                if (err) {
                    context.log(err);
                    resolve({
                        status: 500,
                        body: 'Error processing request',
                        headers: {},
                    });
                }
                else {
                    // Compressed responses must use rawPayload (the raw bytes) rather than payload
                    // (the string representation). Decoding compressed binary as a UTF-8 string and
                    // re-encoding it produces more bytes than declared in content-length, causing a
                    // Kestrel content-length mismatch error.
                    let outgoingPayload = isCompressedResponse(res)
                        ? res?.rawPayload
                        : res?.payload;
                    const outgoingHeaders = extractHeaders(res);
                    // Undici throws an error if any body is passed when responding with a null body status
                    if (isEmptyContentStatusCode(res?.statusCode)) {
                        outgoingPayload = undefined;
                    }
                    resolve({
                        status: res?.statusCode,
                        body: outgoingPayload,
                        headers: outgoingHeaders,
                    });
                }
            });
        });
    };
}
function isEmptyContentStatusCode(statusCode) {
    return (statusCode !== undefined &&
        EMTPY_CONTENT_STATUS_CODES.includes(statusCode));
}
function toHttpMethod(value) {
    return ['DELETE', 'delete', 'GET', 'get', 'HEAD', 'head', 'PATCH', 'patch', 'POST', 'post', 'PUT', 'put', 'OPTIONS', 'options'].includes(value)
        ? value
        : undefined;
}
function isCompressedResponse(res) {
    return res?.headers['content-encoding'] !== undefined;
}
function extractHeaders(res) {
    const headers = {};
    for (const [k, v] of Object.entries(res?.headers ?? {})) {
        if (v) {
            headers[k] = typeof v === 'number' ? String(v) : Array.isArray(v) ? v.join(', ') : v;
        }
    }
    return headers;
}
