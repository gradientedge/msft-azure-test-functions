#!/bin/bash
#
# otel-cjs-kv4_8
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-cjs-kv4_8/src/opentelemetry.ts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-cjs-kv4_8/src/functions/http-external-api.ts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-cjs-kv4_8/src/functions/http-with-keyvault.ts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-cjs-kv4_8/src/functions/http.ts
cp -r functions/otel-cjs/run.sh functions/otel-cjs-kv4_8/run.sh

perl -pi -e 's/  echo "- CommonJS module"/  echo "- CommonJS module"\n  echo "- KV Library 4.8"/g' functions/otel-cjs-kv4_8/run.sh

#
# otel-esm
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esm/src/opentelemetry.mts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esm/src/functions/http-external-api.mts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esm/src/functions/http-with-keyvault.mts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esm/src/functions/http.mts
cp -r functions/otel-cjs/run.sh functions/otel-esm/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esm/src/opentelemetry.mts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esm/src/opentelemetry.mts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs --enable-source-maps"/g' functions/otel-esm/run.sh
perl -pi -e 's/  echo "- CommonJS module"/  echo "- ESM module"/g' functions/otel-esm/run.sh

#
# otel-esm-kv4_8
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esm-kv4_8/src/opentelemetry.mts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esm-kv4_8/src/functions/http-external-api.mts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esm-kv4_8/src/functions/http-with-keyvault.mts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esm-kv4_8/src/functions/http.mts
cp -r functions/otel-cjs/run.sh functions/otel-esm-kv4_8/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esm-kv4_8/src/opentelemetry.mts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esm-kv4_8/src/opentelemetry.mts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs --enable-source-maps"/g' functions/otel-esm-kv4_8/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- KV Library 4.8"/g' functions/otel-esm-kv4_8/run.sh

#
# otel-esm-patch
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esm-patch/src/opentelemetry.mts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esm-patch/src/functions/http-external-api.mts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esm-patch/src/functions/http-with-keyvault.mts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esm-patch/src/functions/http.mts
cp -r functions/otel-cjs/run.sh functions/otel-esm-patch/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esm-patch/src/opentelemetry.mts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esm-patch/src/opentelemetry.mts

perl -pi -e "s/console.log\('>>> Index OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> Index OTEL loaded'\)/g" functions/otel-esm-patch/src/opentelemetry.mts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs --enable-source-maps"/g' functions/otel-esm-patch/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- instrumentation registerAzFunc patch"/g' functions/otel-esm-patch/run.sh

#
# otel-esbuild-esm-dynamic
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-dynamic/src/opentelemetry.ts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esbuild-esm-dynamic/src/apps/http-external-api.ts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esbuild-esm-dynamic/src/apps/http-with-keyvault.ts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esbuild-esm-dynamic/src/apps/http.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-dynamic/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-dynamic/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-dynamic/src/opentelemetry.ts
perl -pi -e "s/console.log\('>>> Index OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> Index OTEL loaded'\)/g" functions/otel-esbuild-esm-dynamic/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--enable-source-maps"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-dynamic/run.sh

#
# otel-esbuild-esm-dynamic-kv4_8
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-dynamic-kv4_8/src/opentelemetry.ts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esbuild-esm-dynamic-kv4_8/src/apps/http-external-api.ts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esbuild-esm-dynamic-kv4_8/src/apps/http-with-keyvault.ts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esbuild-esm-dynamic-kv4_8/src/apps/http.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-dynamic-kv4_8/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-dynamic-kv4_8/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-dynamic-kv4_8/src/opentelemetry.ts
perl -pi -e "s/console.log\('>>> Index OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> Index OTEL loaded'\)/g" functions/otel-esbuild-esm-dynamic-kv4_8/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--enable-source-maps"/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic-kv4_8 import"\n  echo "- esbuild"/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh

#
# otel-esbuild-esm-dynamic-loader
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-dynamic-loader/src/opentelemetry.ts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esbuild-esm-dynamic-loader/src/apps/http-external-api.ts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esbuild-esm-dynamic-loader/src/apps/http-with-keyvault.ts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esbuild-esm-dynamic-loader/src/apps/http.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-dynamic-loader/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-dynamic-loader/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-dynamic-loader/src/opentelemetry.ts
perl -pi -e "s/console.log\('>>> Index OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> Index OTEL loaded'\)/g" functions/otel-esbuild-esm-dynamic-loader/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --enable-source-maps"/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic-loader import"\n  echo "- esbuild"/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-dynamic-loader/run.sh

#
# otel-esbuild-esm-static-loader-import
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-static-loader-import/src/opentelemetry.ts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esbuild-esm-static-loader-import/src/apps/http-external-api.ts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esbuild-esm-static-loader-import/src/apps/http-with-keyvault.ts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esbuild-esm-static-loader-import/src/apps/http.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-static-loader-import/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-static-loader-import/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-static-loader-import/src/opentelemetry.ts
perl -pi -e "s/console.log\('>>> Index OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> Index OTEL loaded'\)/g" functions/otel-esbuild-esm-static-loader-import/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs
 --enable-source-maps"/g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- static-loader-import import"\n  echo "- esbuild"/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-static-loader-import/run.sh

node sync-packages.js
# cp -r functions/otel-cjs/src/functions/* functions/otel-esm-patch/src/functions/*
# cp -r functions/otel-cjs/src/functions/* functions/otel-esm-kv4_8/src/functions/*
# cp -r functions/otel-cjs/src/functions/* functions/otel-esm/src/functions/*
# cp -r functions/otel-cjs/src/functions/* functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/apps/
# cp -r functions/otel-cjs/src/functions/* functions/otel-esbuild-esm-dynamic/src/apps/
# cp -r functions/otel-cjs/src/functions/* functions/otel-esbuild-esm-dynamic-kv4_8/src/apps/
# cp -r functions/otel-cjs/src/functions/* functions/otel-esbuild-esm-dynamic-loader/src/apps/
# cp -r functions/otel-cjs/src/functions/* functions/otel-esbuild-esm-static-loader-import/src/apps/
