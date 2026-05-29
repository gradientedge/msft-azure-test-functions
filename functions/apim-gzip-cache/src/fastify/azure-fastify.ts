/**
 * Azure Functions → Fastify adapter — exact copy of the retail azure-fastify.ts
 * from retail-platform-global-services/application/common/packages/fastify/azure/src/azure-fastify.ts
 *
 * Uses fastify.inject() (light-my-request) to process requests in-memory,
 * then returns the result as an HttpResponseInit.
 */
import type * as http from 'node:http'
import type { HttpHandler, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions'
import type { FastifyInstance } from 'fastify'
import type { Response as LightMyRequestResponse } from 'light-my-request'

const EMTPY_CONTENT_STATUS_CODES = [101, 204, 205, 304] as const

export function fastifyAzureFunction(fastifyApp: FastifyInstance): HttpHandler {
  return async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    const method = toHttpMethod(request.method)

    const url = new URL(request.url)
    const searchParams = url.searchParams

    const path = url.pathname.length < 2 || !url.pathname.endsWith('/') ? url.pathname : url.pathname.slice(0, -1)
    const query: Record<string, string | string[]> = {}
    for (const [key, val] of searchParams.entries()) {
      if (key.endsWith('[]')) {
        if (!query[key]) {
          query[key] = []
        }
        ;(query[key] as string[]).push(val)
      } else {
        query[key] = val
      }
    }

    const headers: http.IncomingHttpHeaders = {}
    for (const [key, value] of request.headers.entries()) {
      headers[key] = value
    }
    let incomingPayload: string | undefined = undefined
    if (request.body) {
      incomingPayload = await request.text()
    }

    return new Promise<HttpResponseInit>((resolve) => {
      fastifyApp.inject(
        {
          method,
          url: path,
          query,
          payload: incomingPayload,
          headers,
        },
        (err, res) => {
          if (err) {
            context.log(err)
            resolve({
              status: 500,
              body: 'Error processing request',
              headers: {},
            })
          } else {
            // Compressed responses must use rawPayload (the raw bytes) rather than payload
            // (the string representation). Decoding compressed binary as a UTF-8 string and
            // re-encoding it produces more bytes than declared in content-length, causing a
            // Kestrel content-length mismatch error.
            let outgoingPayload: Buffer | string | undefined = isCompressedResponse(res)
              ? res?.rawPayload
              : res?.payload
            const outgoingHeaders = extractHeaders(res)

            // Undici throws an error if any body is passed when responding with a null body status
            if (isEmptyContentStatusCode(res?.statusCode)) {
              outgoingPayload = undefined
            }

            resolve({
              status: res?.statusCode,
              body: outgoingPayload,
              headers: outgoingHeaders,
            })
          }
        },
      )
    })
  }
}

function isEmptyContentStatusCode(statusCode: number | undefined): boolean {
  return (
    statusCode !== undefined &&
    EMTPY_CONTENT_STATUS_CODES.includes(statusCode as (typeof EMTPY_CONTENT_STATUS_CODES)[number])
  )
}

type OurHTTPMethods =
  | 'DELETE' | 'delete'
  | 'GET' | 'get'
  | 'HEAD' | 'head'
  | 'PATCH' | 'patch'
  | 'POST' | 'post'
  | 'PUT' | 'put'
  | 'OPTIONS' | 'options'

function toHttpMethod(value: string): OurHTTPMethods | undefined {
  return ['DELETE', 'delete', 'GET', 'get', 'HEAD', 'head', 'PATCH', 'patch', 'POST', 'post', 'PUT', 'put', 'OPTIONS', 'options'].includes(value)
    ? (value as OurHTTPMethods)
    : undefined
}

function isCompressedResponse(res: LightMyRequestResponse | undefined): boolean {
  return res?.headers['content-encoding'] !== undefined
}

function extractHeaders(res: LightMyRequestResponse | undefined): Record<string, string> {
  const headers: Record<string, string> = {}
  for (const [k, v] of Object.entries(res?.headers ?? {})) {
    if (v) {
      headers[k] = typeof v === 'number' ? String(v) : Array.isArray(v) ? v.join(', ') : v
    }
  }
  return headers
}
