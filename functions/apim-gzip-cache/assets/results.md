# APIM gzip cache truncation — test results

Endpoint: `https://functionapimtest.azure-api.net/gzip-test`
Date: 2026-05-29 09:46:02 UTC

## Results

| Path | Size | Accept-Enc | Run | HTTP | Content-Length | Content-Encoding | Body bytes | Decompressed bytes | X-Payload-Uncompressed-Size | X-Payload-Compressed | X-Response-Timestamp |
|------|------|------------|-----|------|----------------|-----------------|------------|--------------------|-----------------------------|----------------------|----------------------|
| payload | small | gzip | bypass | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:03.259Z |
| payload | small | gzip | miss | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:04.621Z |
| payload | small | gzip | hit | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:04.621Z |
| payload | small | none | no-enc | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:07.297Z |
| payload | medium | gzip | bypass | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:07.621Z |
| payload | medium | gzip | miss | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:09.200Z |
| payload | medium | gzip | hit | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:09.200Z |
| payload | medium | none | no-enc | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:12.315Z |
| payload | large | gzip | bypass | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | 2026-05-29T09:46:12.837Z |
| payload | large | gzip | miss | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | 2026-05-29T09:46:14.340Z |
| payload | large | gzip | hit | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | 2026-05-29T09:46:14.340Z |
| payload | large | none | no-enc | 200 | 2000097 | - | 2000097 | - | 2000097 | false | 2026-05-29T09:46:17.334Z |
| payload | xlarge | gzip | bypass | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | true | 2026-05-29T09:46:18.125Z |
| payload | xlarge | gzip | miss | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | true | 2026-05-29T09:46:19.709Z |
| payload | xlarge | gzip | hit | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | true | 2026-05-29T09:46:19.709Z |
| payload | xlarge | none | no-enc | 200 | 5000151 | - | 5000151 | - | 5000151 | false | 2026-05-29T09:46:22.919Z |
| payload | xxlarge | gzip | bypass | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | true | 2026-05-29T09:46:23.990Z |
| payload | xxlarge | gzip | miss | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | true | 2026-05-29T09:46:25.762Z |
| payload | xxlarge | gzip | hit | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | true | 2026-05-29T09:46:25.762Z |
| payload | xxlarge | none | no-enc | 200 | 21000168 | - | 21000168 | - | 21000168 | false | 2026-05-29T09:46:29.288Z |
| payload-no-gzip | small | gzip | bypass | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:31.922Z |
| payload-no-gzip | small | gzip | miss | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:33.306Z |
| payload-no-gzip | small | gzip | hit | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:33.306Z |
| payload-no-gzip | small | none | no-enc | 200 | 10133 | - | 10133 | - | 10133 | false | 2026-05-29T09:46:36.013Z |
| payload-no-gzip | medium | gzip | bypass | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:36.334Z |
| payload-no-gzip | medium | gzip | miss | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:37.909Z |
| payload-no-gzip | medium | gzip | hit | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:37.909Z |
| payload-no-gzip | medium | none | no-enc | 200 | 500156 | - | 500156 | - | 500156 | false | 2026-05-29T09:46:41.036Z |
| payload-no-gzip | large | gzip | bypass | 200 | 2000097 | - | 2000097 | - | 2000097 | false | 2026-05-29T09:46:41.580Z |
| payload-no-gzip | large | gzip | miss | 200 | 2000097 | - | 2000097 | - | 2000097 | false | 2026-05-29T09:46:43.360Z |
| payload-no-gzip | large | gzip | hit | 200 | 2000097 | - | 2000097 | - | 2000097 | false | 2026-05-29T09:46:46.158Z |
| payload-no-gzip | large | none | no-enc | 200 | 2000097 | - | 2000097 | - | 2000097 | false | 2026-05-29T09:46:46.883Z |
| payload-no-gzip | xlarge | gzip | bypass | 200 | 5000151 | - | 5000151 | - | 5000151 | false | 2026-05-29T09:46:47.670Z |
| payload-no-gzip | xlarge | gzip | miss | 200 | 5000151 | - | 5000151 | - | 5000151 | false | 2026-05-29T09:46:49.796Z |
| payload-no-gzip | xlarge | gzip | hit | 200 | 5000151 | - | 5000151 | - | 5000151 | false | 2026-05-29T09:46:52.856Z |
| payload-no-gzip | xlarge | none | no-enc | 200 | 5000151 | - | 5000151 | - | 5000151 | false | 2026-05-29T09:46:53.850Z |
| payload-no-gzip | xxlarge | gzip | bypass | 200 | 21000168 | - | 21000168 | - | 21000168 | false | 2026-05-29T09:46:54.957Z |
| payload-no-gzip | xxlarge | gzip | miss | 200 | 21000168 | - | 21000168 | - | 21000168 | false | 2026-05-29T09:46:57.867Z |
| payload-no-gzip | xxlarge | gzip | hit | 200 | 21000168 | - | 21000168 | - | 21000168 | false | 2026-05-29T09:47:02.879Z |
| payload-no-gzip | xxlarge | none | no-enc | 200 | 21000168 | - | 21000168 | - | 21000168 | false | 2026-05-29T09:47:04.956Z |
| fastify-payload | small | gzip | bypass | 200 | 10133 | - | 10133 | - | 10133 | pending | 2026-05-29T09:47:07.024Z |
| fastify-payload | small | gzip | miss | 200 | 10133 | - | 10133 | - | 10133 | pending | 2026-05-29T09:47:08.455Z |
| fastify-payload | small | gzip | hit | 200 | 10133 | - | 10133 | - | 10133 | pending | 2026-05-29T09:47:08.455Z |
| fastify-payload | small | none | no-enc | 200 | 10133 | - | 10133 | - | 10133 | pending | 2026-05-29T09:47:11.207Z |
| fastify-payload | medium | gzip | bypass | 200 | 500156 | - | 500156 | - | 500156 | pending | 2026-05-29T09:47:11.564Z |
| fastify-payload | medium | gzip | miss | 200 | 500156 | - | 500156 | - | 500156 | pending | 2026-05-29T09:47:13.267Z |
| fastify-payload | medium | gzip | hit | 200 | 500156 | - | 500156 | - | 500156 | pending | 2026-05-29T09:47:13.267Z |
| fastify-payload | medium | none | no-enc | 200 | 500156 | - | 500156 | - | 500156 | pending | 2026-05-29T09:47:16.535Z |
| fastify-payload | large | gzip | bypass | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | pending | 2026-05-29T09:47:17.099Z |
| fastify-payload | large | gzip | miss | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | pending | 2026-05-29T09:47:18.715Z |
| fastify-payload | large | gzip | hit | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | pending | 2026-05-29T09:47:18.715Z |
| fastify-payload | large | none | no-enc | 200 | 2000097 | - | 2000097 | - | 2000097 | pending | 2026-05-29T09:47:21.756Z |
| fastify-payload | xlarge | gzip | bypass | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | pending | 2026-05-29T09:47:22.528Z |
| fastify-payload | xlarge | gzip | miss | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | pending | 2026-05-29T09:47:24.208Z |
| fastify-payload | xlarge | gzip | hit | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | pending | 2026-05-29T09:47:24.208Z |
| fastify-payload | xlarge | none | no-enc | 200 | 5000151 | - | 5000151 | - | 5000151 | pending | 2026-05-29T09:47:27.457Z |
| fastify-payload | xxlarge | gzip | bypass | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | pending | 2026-05-29T09:47:28.584Z |
| fastify-payload | xxlarge | gzip | miss | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | pending | 2026-05-29T09:47:30.896Z |
| fastify-payload | xxlarge | gzip | hit | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | pending | 2026-05-29T09:47:30.896Z |
| fastify-payload | xxlarge | none | no-enc | 200 | 21000168 | - | 21000168 | - | 21000168 | pending | 2026-05-29T09:47:34.905Z |
| fastify-payload-no-gzip | small | gzip | bypass | 200 | 10133 | identity | 10133 | - | 10133 | false | 2026-05-29T09:47:37.057Z |
| fastify-payload-no-gzip | small | gzip | miss | 200 | 10133 | identity | 10133 | - | 10133 | false | 2026-05-29T09:47:38.452Z |
| fastify-payload-no-gzip | small | gzip | hit | 200 | 10133 | identity | 10133 | - | 10133 | false | 2026-05-29T09:47:38.452Z |
| fastify-payload-no-gzip | small | none | no-enc | 200 | 10133 | identity | 10133 | - | 10133 | false | 2026-05-29T09:47:41.287Z |
| fastify-payload-no-gzip | medium | gzip | bypass | 200 | 500156 | identity | 500156 | - | 500156 | false | 2026-05-29T09:47:41.646Z |
| fastify-payload-no-gzip | medium | gzip | miss | 200 | 500156 | identity | 500156 | - | 500156 | false | 2026-05-29T09:47:43.256Z |
| fastify-payload-no-gzip | medium | gzip | hit | 200 | 500156 | identity | 500156 | - | 500156 | false | 2026-05-29T09:47:43.256Z |
| fastify-payload-no-gzip | medium | none | no-enc | 200 | 500156 | identity | 500156 | - | 500156 | false | 2026-05-29T09:47:46.546Z |
| fastify-payload-no-gzip | large | gzip | bypass | 200 | 2000097 | identity | 2000097 | - | 2000097 | false | 2026-05-29T09:47:47.138Z |
| fastify-payload-no-gzip | large | gzip | miss | 200 | 2000097 | identity | 2000097 | - | 2000097 | false | 2026-05-29T09:47:49.027Z |
| fastify-payload-no-gzip | large | gzip | hit | 200 | 2000097 | identity | 2000097 | - | 2000097 | false | 2026-05-29T09:47:51.838Z |
| fastify-payload-no-gzip | large | none | no-enc | 200 | 2000097 | identity | 2000097 | - | 2000097 | false | 2026-05-29T09:47:52.665Z |
| fastify-payload-no-gzip | xlarge | gzip | bypass | 200 | 5000151 | identity | 5000151 | - | 5000151 | false | 2026-05-29T09:47:53.586Z |
| fastify-payload-no-gzip | xlarge | gzip | miss | 200 | 5000151 | identity | 5000151 | - | 5000151 | false | 2026-05-29T09:47:55.794Z |
| fastify-payload-no-gzip | xlarge | gzip | hit | 200 | 5000151 | identity | 5000151 | - | 5000151 | false | 2026-05-29T09:47:58.926Z |
| fastify-payload-no-gzip | xlarge | none | no-enc | 200 | 5000151 | identity | 5000151 | - | 5000151 | false | 2026-05-29T09:48:00.060Z |
| fastify-payload-no-gzip | xxlarge | gzip | bypass | 200 | 21000168 | identity | 21000168 | - | 21000168 | false | 2026-05-29T09:48:01.269Z |
| fastify-payload-no-gzip | xxlarge | gzip | miss | 200 | 21000168 | identity | 21000168 | - | 21000168 | false | 2026-05-29T09:48:04.417Z |
| fastify-payload-no-gzip | xxlarge | gzip | hit | 200 | 21000168 | identity | 21000168 | - | 21000168 | false | 2026-05-29T09:48:08.689Z |
| fastify-payload-no-gzip | xxlarge | none | no-enc | 200 | 21000168 | identity | 21000168 | - | 21000168 | false | 2026-05-29T09:48:11.384Z |

## Key observations

Compare **miss** vs **hit** rows for gzip-compressed responses (path=payload, size>=large).
If cache HIT shows smaller body/decompressed bytes than cache MISS, the truncation bug is confirmed.
