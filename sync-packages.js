import { createRequire } from "module";
import fs from 'node:fs';

const require = createRequire(import.meta.url);

const directories = {
  'otel-cjs-kv4_8': {
    dependencies: {
      "@azure/keyvault-secrets": "4.8.0",
    },
  },
  // 'otel-esbuild-esm-dynamic',
  // 'otel-esbuild-esm-dynamic-kv4_8',
  // 'otel-esbuild-esm-dynamic-loader',
  // 'otel-esbuild-esm-static-loader-import',
  // 'otel-esbuild-esm-static-loader-import-azure-external-azure-function',
  // 'otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm',
  // 'otel-esbuild-esm-static-loader-import-azure-external-azure-function-prewarm-without-node-options',
  'otel-esm': {
    type: "module",
    main: "dist/src/functions/*.mjs",
  },
  'otel-esm-kv4_8': {
    type: "module",
    main: "dist/src/functions/*.mjs",
    dependencies: {
      "@azure/keyvault-secrets": "4.8.0",
    },
  },
  'otel-esm-patch': {
    type: "module",
    main: "dist/src/functions/*.mjs",
  },
  'otel-esbuild-esm-dynamic': {
    type: "module",
    main: "dist/src/functions/*.mjs",
    scripts: {
      build: "rm -rf dist && node esbuild.js && cp -r src/functions dist/dist/src",
    },
    devDependencies: {
      "esbuild": "0.25.1"
    }
  },
  'otel-esbuild-esm-dynamic-kv4_8': {
    type: "module",
    main: "dist/src/functions/*.mjs",
    scripts: {
      build: "rm -rf dist && node esbuild.js && cp -r src/functions dist/dist/src",
    },
    dependencies: {
      "@azure/keyvault-secrets": "4.8.0",
    },
    devDependencies: {
      "esbuild": "0.25.1"
    }
  },
  'otel-esbuild-esm-dynamic-loader': {
    type: "module",
    main: "dist/src/functions/*.mjs",
    scripts: {
      build: "rm -rf dist && node esbuild.js && cp -r src/functions dist/dist/src",
    },
    devDependencies: {
      "esbuild": "0.25.1"
    }
  },
  'otel-esbuild-esm-static-loader-import': {
    type: "module",
    main: "dist/src/apps/*.mjs",
    scripts: {
      build: "rm -rf dist && node esbuild.js",
    },
    devDependencies: {
      "esbuild": "0.25.1"
    }
  },
  // 'otel-esm-patch',
}


for (const dir of Object.keys(directories)) {
  const packageJsonContent = fs.readFileSync('./functions/otel-cjs/package.json', 'utf8')
  const packageJson = JSON.parse(packageJsonContent)
  console.log(`Syncing dependencies to ${dir}/package.json`)
  const dirPackageJsonPath = `./functions/${dir}/package.json`

  // write packageJSon to dirPackageJsonPath with updated dependencies
  packageJson.name = `@msft-azure-test-functions/${dir}`
  const overrides = directories[dir]

  if (overrides.type) {
    packageJson.type = overrides.type
  }

  if (overrides.main) {
    packageJson.main = overrides.main
  }

  if (overrides.dependencies) {
    packageJson.dependencies = { ...packageJson.dependencies, ...overrides.dependencies }
  }

  if (overrides.devDependencies) {
    packageJson.devDependencies = { ...packageJson.devDependencies, ...overrides.devDependencies }
  }

  if (overrides.scripts) {
    packageJson.scripts = { ...packageJson.scripts, ...overrides.scripts }
  }
  fs.writeFileSync(dirPackageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
}
