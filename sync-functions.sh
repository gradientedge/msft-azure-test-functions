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

perl -pi -e "s/console.log\('>>> OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> OTEL loaded'\)/g" functions/otel-esm-patch/src/opentelemetry.mts
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
perl -pi -e "s/console.log\('>>> OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> OTEL loaded'\)/g" functions/otel-esbuild-esm-dynamic/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--enable-source-maps"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-dynamic/run.sh

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
perl -pi -e "s/console.log\('>>> OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> OTEL loaded'\)/g" functions/otel-esbuild-esm-dynamic-kv4_8/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--enable-source-maps"/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"\n  echo "- KV Library 4.8"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-dynamic-kv4_8/run.sh

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
perl -pi -e "s/console.log\('>>> OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> OTEL loaded'\)/g" functions/otel-esbuild-esm-dynamic-loader/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --enable-source-maps"/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"\n  echo "- KV Library 4.8"\n  echo "- experimental loader"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-dynamic-loader/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-dynamic-loader/run.sh

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
perl -pi -e "s/console.log\('>>> OTEL loaded'\)/const azAppFunction = await import\('\@azure\/functions'\)\nazureInstrumentationInstance.registerAzFunc\(azAppFunction.default\)\n\nconsole.log\('>>> OTEL loaded'\)/g" functions/otel-esbuild-esm-static-loader-import/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs
 --enable-source-maps"/g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"\n  echo "- KV Library 4.8"\n  echo "- experimental loader"\n  echo "- static import from package.json"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-static-loader-import/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-static-loader-import/run.sh

#
# otel-esbuild-esm-static-loader-import-azure-external-azure-function
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/opentelemetry.ts
cp -r functions/otel-cjs/src/functions/http-external-api.ts functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/apps/http-external-api.ts
cp -r functions/otel-cjs/src/functions/http-with-keyvault.ts functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/apps/http-with-keyvault.ts
cp -r functions/otel-cjs/src/functions/http.ts functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/apps/http.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs --enable-source-maps"/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"\n  echo "- KV Library 4.8"\n  echo "- experimental loader"\n  echo "- static import from package.json"\n  echo "- external \@azure\/functions"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function/run.sh

#
# otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/src/opentelemetry.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/src/opentelemetry.ts
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS="--experimental-loader=\@opentelemetry\/instrumentation\/hook.mjs --import .\/dist\/src\/opentelemetry.mjs --enable-source-maps"/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"\n  echo "- KV Library 4.8"\n  echo "- experimental loader"\n  echo "- static import from package.json"\n  echo "- external \@azure\/functions"\n  echo "- prewarm function"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh

perl -pi -e 's/measure "\/api\/http"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/echo "\| \$\(date\) \| http \| \$\{result\[0\]\} \| \$\{result\[1\]\} \|" >>README.md//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/measure "\/api\/http-external-api"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/echo "\| \$\(date\) \| http-external-api \| \$\{result\[0\]\} \| \$\{result\[1\]\} \|" >>README.md//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh

perl -pi -e 's/http-with-keyvault/http-with-keyvault-prewarm/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/HTTP Trace/Full Trace/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/!\[HTTP\]\(assets\/http.png\)/!\[Full Trace\]\(assets\/cold-start.png\)/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/HTTP Key Vault Trace/Pre-warm up Trace/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/!\[HTTP Key Vault\]\(assets\/http-with-keyvault-prewarm.png\)/!\[Pre-warm up\]\(assets\/prewarmup.png\)/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/HTTP External API Trace/Logs/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -pi -e 's/!\[HTTP External API\]\(assets\/http-external-api.png\)/\[Logs\]\(assets\/logs.csv\)/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm/run.sh

#
# otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options
#
cp -r functions/otel-cjs/src/opentelemetry.ts functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/src/opentelemetry.ts
cp -r functions/otel-cjs/run.sh functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh

perl -pi -e "s/import \{ AzureFunctionsInstrumentation \} from '\@azure\/functions-opentelemetry-instrumentation'/import \* as azureInstrumentation from '\@azure\/functions-opentelemetry-instrumentation'/g" functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/src/opentelemetry.ts
perl -pi -e "s/const azureInstrumentationInstance = new AzureFunctionsInstrumentation\(\)/\/\/\@ts-ignore\nconst azureInstrumentationInstance = new azureInstrumentation.default.AzureFunctionsInstrumentationESM\(\)/g" functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/src/opentelemetry.ts

# az functionapp config appsettings delete --name MyFunctionApp --resource-group
# MyResourceGroup --setting-names {setting-names}
perl -pi -e 's/APP_ARGS="-r .\/dist\/src\/opentelemetry.js --enable-source-maps"/APP_ARGS=""/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
# chagne only for the first
perl -pi -e 's/az functionapp config appsettings set --settings "languageWorkers__node__arguments=\$\{APP_ARGS\}"/az functionapp config appsettings delete --setting-names "languageWorkers__node__arguments"/' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/--settings "languageWorkers__node__arguments=\$\{APP_ARGS\}"/--settings "languageWorkers__node__arguments"/' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh

perl -pi -e 's/  echo "- CommonJS module"/   echo "- ESM module"\n  echo "- dynamic import"\n  echo "- esbuild"\n  echo "- KV Library 4.8"\n  echo "- experimental loader"\n  echo "- static import from package.json"\n  echo "- external \@azure\/functions"\n  echo "- prewarm function"\n  echo "- disable languageWorkers__node__arguments"/g' functions/otel-esbuild-esm-dynamic/run.sh
perl -pi -e 's/echo "Installing production deps \(omit dev\)"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/npm ci --omit=dev//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/echo "Deploying application"/echo "Deploying application"\npushd dist/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/echo "Getting actual Function App endpoint"/popd\necho "Getting actual Function App endpoint"/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh

perl -pi -e 's/measure "\/api\/http"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/echo "\| \$\(date\) \| http \| \$\{result\[0\]\} \| \$\{result\[1\]\} \|" >>README.md//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/measure "\/api\/http-external-api"//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/echo "\| \$\(date\) \| http-external-api \| \$\{result\[0\]\} \| \$\{result\[1\]\} \|" >>README.md//g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh

perl -pi -e 's/http-with-keyvault/http-with-keyvault-prewarm/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/HTTP Trace/Full Trace/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/!\[HTTP\]\(assets\/http.png\)/!\[Full Trace\]\(assets\/cold-start.png\)/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/HTTP Key Vault Trace/Pre-warm up Trace/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/!\[HTTP Key Vault\]\(assets\/http-with-keyvault-prewarm.png\)/!\[Pre-warm up\]\(assets\/prewarm-without-node-optionsup.png\)/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/HTTP External API Trace/Logs/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -pi -e 's/!\[HTTP External API\]\(assets\/http-external-api.png\)/\[Logs\]\(assets\/logs.csv\)/g' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh
perl -i -p0e 's/echo "Restoring.*offline//sgm' functions/otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options/run.sh

node sync-packages.js
