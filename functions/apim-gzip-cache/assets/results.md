# APIM gzip cache truncation — test results

Endpoint: `https://apim-gzip-test.azure-api.net/gzip-test`
Date: 2026-05-28 10:34:09 UTC

## Results

| Path | Size | Accept-Enc | Run | HTTP | Content-Length | Content-Encoding | Body bytes | Decompressed bytes | X-Payload-Uncompressed-Size | X-Payload-Compressed | X-Cache | X-Request-Id |
|------|------|------------|-----|------|----------------|-----------------|------------|--------------------|-----------------------------|----------------------|---------|--------------|
| payload | small | gzip | bypass | 200 | - | gzip | 1495 | 10133 | 10133 | false | BYPASS | ff230da6-41b4-4d18-aff4-f9230eb049b2 |
| payload | small | gzip | miss | 200 | - | gzip | 1492 | 10133 | 10133 | false | HIT | c9356bb4-3eed-4cf1-bd58-350175bdc17a |
| payload | small | gzip | hit | 200 | - | gzip | 1492 | 10133 | 10133 | false | HIT | c9356bb4-3eed-4cf1-bd58-350175bdc17a |
| payload | small | none | no-enc | 200 | 10133 | - | 10133 | - | 10133 | false | HIT | c9356bb4-3eed-4cf1-bd58-350175bdc17a |
| payload | medium | gzip | bypass | 200 | - | gzip | 64762 | 500156 | 500156 | false | BYPASS | de4558e1-eaf2-4691-bf59-902330233c88 |
| payload | medium | gzip | miss | 200 | - | gzip | 64780 | 500156 | 500156 | false | HIT | abb4509e-d5f4-4ef8-8c8e-b9072d2c626c |
| payload | medium | gzip | hit | 200 | - | gzip | 64755 | 500156 | 500156 | false | HIT | 1c64bd3a-25a1-4c66-9760-c6eef0534d63 |
| payload | medium | none | no-enc | 200 | 500156 | - | 500156 | - | 500156 | false | HIT | b6e5a929-0109-4ad8-9820-0eb1dc567e32 |
| payload | large | gzip | bypass | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | BYPASS | f47b75cb-5d92-4435-800e-17d37ce542e7 |
| payload | large | gzip | miss | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | HIT | 2779e979-0841-4de7-9d15-fb6dc7d0cff2 |
| payload | large | gzip | hit | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | HIT | 2779e979-0841-4de7-9d15-fb6dc7d0cff2 |
| payload | large | none | no-enc | 200 | 181193 | gzip | 181193 | 2000097 | 2000097 | true | HIT | 2779e979-0841-4de7-9d15-fb6dc7d0cff2 |
| payload | xlarge | gzip | bypass | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | true | BYPASS | 0c25204c-e4c5-4240-8404-870bd972ddc9 |
| payload | xlarge | gzip | miss | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | true | HIT | daa0b78d-316a-4a67-bd6b-10ce98959e2c |
| payload | xlarge | gzip | hit | 200 | 447821 | gzip | 447821 | 5000151 | 5000151 | true | HIT | 99fc0ece-78d7-46eb-9351-1a21d6804f9e |
| payload | xlarge | none | no-enc | 200 | 5000151 | - | 5000151 | - | 5000151 | false | HIT | 8ba87869-a599-4fe4-a4a2-6f20dd2dd4ad |
| payload | xxlarge | gzip | bypass | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | true | BYPASS | 5a04f26f-73fe-426b-9644-9c01604fae6d |
| payload | xxlarge | gzip | miss | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | true | HIT | 90e7737f-17e3-47bd-b8d3-486f5958fa03 |
| payload | xxlarge | gzip | hit | 200 | 1861964 | gzip | 1861964 | 21000168 | 21000168 | true | HIT | e82844aa-5ef6-4d50-9f6b-32521ee9ed69 |
| payload | xxlarge | none | no-enc | 200 | 21000168 | - | 21000168 | - | 21000168 | false | HIT | 42ec2fac-e502-41c6-adaf-147d829aed86 |
| payload-no-gzip | small | gzip | bypass | 200 | - | gzip | 1492 | 10133 | 10133 | false | BYPASS | 6ac9c247-68cc-4fea-8849-aaadeb96d9da |
| payload-no-gzip | small | gzip | miss | 200 | - | gzip | 1492 | 10133 | 10133 | false | HIT | fa29be7a-1d57-49ee-b0f4-0a36695eee45 |
| payload-no-gzip | small | gzip | hit | 200 | - | gzip | 1492 | 10133 | 10133 | false | HIT | 073ec139-f88a-48fd-9d5f-6aa106560158 |
| payload-no-gzip | small | none | no-enc | 200 | 10133 | - | 10133 | - | 10133 | false | HIT | 1a61b772-748e-4c00-9f66-7aa001d4e82c |
| payload-no-gzip | medium | gzip | bypass | 200 | - | gzip | 64749 | 500156 | 500156 | false | BYPASS | f1708b74-6d67-4eee-864b-f38a8dab0ced |
| payload-no-gzip | medium | gzip | miss | 200 | - | gzip | 64750 | 500156 | 500156 | false | HIT | 9a1103e1-b0b4-40ff-80ae-a321351336fb |
| payload-no-gzip | medium | gzip | hit | 200 | - | gzip | 64742 | 500156 | 500156 | false | HIT | 3eb3cf5e-42a6-4326-a4b8-568aa745d15b |
| payload-no-gzip | medium | none | no-enc | 200 | 500156 | - | 500156 | - | 500156 | false | HIT | 45b14516-8412-41a2-8284-a9d4486696c7 |
| payload-no-gzip | large | gzip | bypass | 200 | - | gzip | 256626 | 2000097 | 2000097 | false | BYPASS | 30e86e22-0514-4e47-b15a-260473c1b70b |
| payload-no-gzip | large | gzip | miss | 200 | - | gzip | 256584 | 2000097 | 2000097 | false | HIT | 5dff2e09-076e-4dff-b106-aa0269c1cf05 |
| payload-no-gzip | large | gzip | hit | 200 | - | gzip | 256559 | 2000097 | 2000097 | false | HIT | 6f476d83-7d9c-4c8e-8499-12b850a6dea6 |
| payload-no-gzip | large | none | no-enc | 200 | 2000097 | - | 2000097 | - | 2000097 | false | HIT | 0f2a5a0d-7df2-44ee-ad90-1ade0808c224 |
| payload-no-gzip | xlarge | gzip | bypass | 200 | - | gzip | 635466 | 5000151 | 5000151 | false | BYPASS | f476463b-aac0-45d4-b12b-2eb7e6321b30 |
| payload-no-gzip | xlarge | gzip | miss | 200 | - | gzip | 635441 | 5000151 | 5000151 | false | HIT | 890968c8-e809-4510-908d-91ad2c128929 |
| payload-no-gzip | xlarge | gzip | hit | 200 | - | gzip | 635484 | 5000151 | 5000151 | false | HIT | ae3d6737-b6a6-49dd-9de1-1f611f3c0b93 |
| payload-no-gzip | xlarge | none | no-enc | 200 | 5000151 | - | 5000151 | - | 5000151 | false | HIT | 8ddbae1c-4919-4da8-95eb-3c4a863f9d16 |
| payload-no-gzip | xxlarge | gzip | bypass | 200 | - | gzip | 2651974 | 21000168 | 21000168 | false | BYPASS | bec1cca1-be3f-4f8e-bd2c-25676e7f87ce |
| payload-no-gzip | xxlarge | gzip | miss | 200 | - | gzip | 2651966 | 21000168 | 21000168 | false | HIT | 6f5fa176-953d-4893-887c-72991a033ae7 |
| payload-no-gzip | xxlarge | gzip | hit | 200 | - | gzip | 2651936 | 21000168 | 21000168 | false | HIT | 45d9234a-4b73-4acc-be55-4be8d2aeccdd |
| payload-no-gzip | xxlarge | none | no-enc | 200 | 21000168 | - | 21000168 | - | 21000168 | false | HIT | a8f704e8-1dc3-411d-b7a1-3ec6edfef3da |

## Key observations

Compare **miss** vs **hit** rows for gzip-compressed responses (path=payload, size>=large).
If cache HIT shows smaller body/decompressed bytes than cache MISS, the truncation bug is confirmed.
