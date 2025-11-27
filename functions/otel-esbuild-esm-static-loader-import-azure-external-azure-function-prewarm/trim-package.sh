#!/bin/bash
cd dist
find . -name README.md -type f -delete
find . -name LICENSE -type f -delete
find . -name CONTRIBUTING.md -type f -delete
find . -name NOTICE -type f -delete
find . -name GOVERNANCE.md -type f -delete
find . -name CHANGELOG.md -type f -delete
find . -name SECURITY.md -type f -delete
find . -name .travis.yml -type f -delete
find . -name CODE_OF_CONDUCT.md -type f -delete
find . -name LICENSE.txt -type f -delete
find . -name readme.md -type f -delete
find . -name license.md -type f -delete
find . -name "*.ts" -type f -delete
find . -name "*.mts" -type f -delete
find . -name "*.html" -type f -delete
find . -name "*.txt" -type f -delete
find . -name "*.ts.map" -type f -delete
find . -name "*.map" -type f -delete
find . -name "browser.js" -type f -delete
find . -name .eslintrc -type f -delete
find . -name .nycrc -type f -delete
find . -name .editorconfig -type f -delete
find . -name LICENSE-3rdparty.csv -type f -delete
find . -name tsconfig.json -type f -delete
find . -name .eslintrc.yaml -type f -delete
find . -name .release-please-manifest.json -type f -delete
find . -name test -type d -exec rm -rf {} +
find . -name bin -type d -exec rm -rf {} +
find . -name .github -type d -exec rm -rf {} +
rm -rf node_modules/@azure/functions
rm -rf node_modules/@typespec/ts-http-runtime/dist/browser
rm -rf node_modules/@typespec/ts-http-runtime/dist/commonjs
rm -rf node_modules/@typespec/ts-http-runtime/dist/react-native
rm -rf node_modules/@opentelemetry/sdk-metrics/build/esm/
rm -rf node_modules/@opentelemetry/sdk-metrics/build/esnext/
rm -rf node_modules/@opentelemetry/api/build/esm
rm -rf node_modules/@opentelemetry/api/build/esnext
rm -rf node_modules/@opentelemetry/sdk-trace-base/build/esm
rm -rf node_modules/@opentelemetry/sdk-trace-base/build/esnext
rm -rf node_modules/@opentelemetry/instrumentation/build/esm
rm -rf node_modules/@opentelemetry/instrumentation/build/esnext
rm -rf node_modules/@opentelemetry/resources/build/esm
rm -rf node_modules/@opentelemetry/resources/build/esnext
rm -rf node_modules/@opentelemetry/semantic-conventions/build/esm
rm -rf node_modules/@opentelemetry/semantic-conventions/build/esnext
rm -rf node_modules/@opentelemetry/api-logs/build/esm
rm -rf node_modules/@opentelemetry/api-logs/build/esnext
rm -rf node_modules/@opentelemetry/core/build/esm
rm -rf node_modules/@opentelemetry/core/build/esnext
rm -rf node_modules/@opentelemetry/sdk-logs/build/esm
rm -rf node_modules/@opentelemetry/sdk-logs/build/esnext
rm -rf node_modules/@opentelemetry/resource-detector-azure/build/esm
rm -rf node_modules/long/src
rm -rf node_modules/undici/docs
rm -rf node_modules/undici/types
rm -rf node_modules/function-bind/.github
rm -rf node_modules/resolve/example
rm -rf node_modules/resolve/.github
rm -rf node_modules/@azure/core-rest-pipeline/dist/react-native
rm -rf node_modules/@azure/core-rest-pipeline/dist/browser
# rm -rf node_modules/@azure/core-rest-pipeline/dist/esm
rm -rf node_modules/@azure/functions-opentelemetry-instrumentation/esm
rm -rf node_modules/@azure/functions-opentelemetry-instrumentation/types
rm -rf node_modules/@azure/core-tracing/dist/browser
rm -rf node_modules/@azure/core-tracing/dist/react-native
# rm -rf node_modules/@azure/core-tracing/dist/esm
rm -rf node_modules/@azure/core-auth/dist/react-native
rm -rf node_modules/@azure/core-auth/dist/browser
# rm -rf node_modules/@azure/core-auth/dist/esm
rm -rf node_modules/@azure/core-client/dist/react-native
rm -rf node_modules/@azure/core-client/dist/browser
# rm -rf node_modules/@azure/core-client/dist/esm
# rm -rf node_modules/@azure/core-client/dist/commonjs
rm -rf node_modules/@azure/logger/dist/react-native
rm -rf node_modules/@azure/logger/dist/browser
rm -rf node_modules/@azure/logger/dist/commonjs
rm -rf node_modules/@azure/abort-controller/dist/react-native
rm -rf node_modules/@azure/abort-controller/dist/browser
# rm -rf node_modules/@azure/abort-controller/dist/esm
rm -rf node_modules/@azure/core-util/dist/react-native
rm -rf node_modules/@azure/core-util/dist/browser
# rm -rf node_modules/@azure/core-util/dist/esm
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/resources/build/commonjs
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/resources/build/esnext
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/api-logs/build/commonjs
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/api-logs/build/esnext
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/core/build/esnext
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/core/build/commonjs
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/sdk-logs/build/commonjs
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/node_modules/@opentelemetry/sdk-logs/build/esnext
rm -rf node_modules/@azure/monitor-opentelemetry-exporter/dist/commonjs
