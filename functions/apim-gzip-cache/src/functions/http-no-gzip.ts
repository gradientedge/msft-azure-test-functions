import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions'

// ---------------------------------------------------------------------------
// Payload generation (identical to http.ts but without compression)
// ---------------------------------------------------------------------------

type PayloadSize = 'small' | 'medium' | 'large' | 'xlarge' | 'xxlarge'

const PAYLOAD_TARGET_BYTES: Record<PayloadSize, number> = {
  small: 10_000,
  medium: 500_000,
  large: 2_000_000,
  xlarge: 5_000_000,
  xxlarge: 21_000_000,
}

function generatePayload(targetBytes: number): string {
  const items: { id: number; key: string; value: string; nested: { a: number; b: number } }[] = []
  let currentSize = 2
  let id = 0

  while (currentSize < targetBytes) {
    const item = {
      id,
      key: `item-${String(id).padStart(8, '0')}`,
      value: `data-${'x'.repeat(80)}-${String(id).padStart(8, '0')}`,
      nested: { a: id * 7, b: id * 13 },
    }
    const itemJson = JSON.stringify(item)
    currentSize += itemJson.length + (items.length > 0 ? 1 : 0)
    items.push(item)
    id++
  }

  return JSON.stringify(items)
}

const payloadCache = new Map<PayloadSize, string>()

function initPayloads(): void {
  for (const [size, targetBytes] of Object.entries(PAYLOAD_TARGET_BYTES) as [PayloadSize, number][]) {
    const json = generatePayload(targetBytes)
    payloadCache.set(size, json)
    console.log(`[payload-no-gzip] ${size}: ${json.length} bytes`)
  }
}

initPayloads()

// ---------------------------------------------------------------------------
// HTTP handler — no compression (control group)
// ---------------------------------------------------------------------------

async function handler(request: HttpRequest, _context: InvocationContext): Promise<HttpResponseInit> {
  const sizeParam = request.params.size as string | undefined

  if (!sizeParam || !(sizeParam in PAYLOAD_TARGET_BYTES)) {
    return {
      status: 400,
      headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
      body: JSON.stringify({
        error: `Invalid size parameter. Use one of: ${Object.keys(PAYLOAD_TARGET_BYTES).join(', ')}`,
      }),
    }
  }

  const size = sizeParam as PayloadSize
  const json = payloadCache.get(size)!

  const requestCacheControl = request.headers.get('cache-control') ?? ''
  const bypassCache = requestCacheControl.toLowerCase().includes('no-cache')
  const cacheControl = bypassCache ? 'no-store' : 'public, max-age=300'

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Cache-Control': cacheControl,
    'Content-Length': String(Buffer.byteLength(json)),
    'X-Response-Timestamp': new Date().toISOString(),
    'X-Payload-Size': size,
    'X-Payload-Uncompressed-Size': String(json.length),
    'X-Payload-Compressed': 'false',
    'X-Cache-Bypass': String(bypassCache),
  }

  return { status: 200, headers, body: json }
}

app.http('payload-no-gzip', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'api/payload-no-gzip/{size}',
  handler,
})
