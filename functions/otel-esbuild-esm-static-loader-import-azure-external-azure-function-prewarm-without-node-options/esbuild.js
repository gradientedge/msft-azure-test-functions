import esbuild from 'esbuild'
import fs from 'node:fs'

const appDir = process.cwd()
const packageDir = appDir

const packageJsonPath = `${packageDir}/package.json`
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'))

const outPackageDir = `${packageDir}/dist`
const outDir = `${outPackageDir}/dist/src`

function createExternalPackages() {
  const externalPackagesBeforeResolution = [
    '@azure/functions-opentelemetry-instrumentation',
    '@azure/monitor-opentelemetry-exporter',
    '@opentelemetry/instrumentation-dns',
    '@opentelemetry/core',
    '@opentelemetry/api',
    '@opentelemetry/resource-detector-azure',
    '@opentelemetry/resources',
    '@opentelemetry/instrumentation',
    '@opentelemetry/instrumentation-undici',
    '@opentelemetry/instrumentation-runtime-node',
    '@opentelemetry/instrumentation-net',
    '@opentelemetry/instrumentation-http',
    '@opentelemetry/instrumentation-fs',
    '@opentelemetry/sdk-logs',
    '@opentelemetry/sdk-trace-node',
    '@opentelemetry/sdk-metrics',
    // why are they missing?
    'semver',
    'shimmer',
    // My believe is that we have to use external for this to work - we will review later why
    '@azure/functions',
    'source-map-support', // because we can't use NODE_OPTIONS
    //'@azure/keyvault-secrets',
  ]

  const resolvedPackages = new Set()

  const resolvePackage = pkg => {
    const path = `node_modules/${pkg}/package.json`
    const packageJson = JSON.parse(fs.readFileSync(path, 'utf8'))
    resolvedPackages.add(pkg)
    if (packageJson.dependencies) {
      console.log(`Externalizing package ${pkg} with dependencies:`, Object.keys(packageJson.dependencies))
      Object.keys(packageJson.dependencies).forEach(dep => {
        if (!resolvedPackages.has(dep)) {
          resolvePackage(dep)
        }
      })
    } else {
      console.log(`Externalizing package ${pkg} with no dependencies:`)
    }
  }

  externalPackagesBeforeResolution.forEach(resolvePackage)
  console.log('Resolved external packages:', Array.from(resolvedPackages))

  return Array.from(resolvedPackages)
}

const externalPackages = createExternalPackages()

const bannerJs = [
  // 'const __dirname = import.meta.dirname;',
  'const __filename=(await import("node:url")).fileURLToPath(import.meta.url);',
  'import { createRequire as topLevelCreateRequire } from "module";',
  'const require = topLevelCreateRequire(import.meta.url);',
].join('')

await Promise.all([
  esbuild.build({
    entryPoints: [`${packageDir}/src/opentelemetry.ts`],
    bundle: true,
    sourcemap: true,
    sourcesContent: true,
    minify: false,
    keepNames: true,
    platform: 'node',
    target: 'node22',
    format: 'esm',
    banner: {
      js: bannerJs,
    },
    external: ['@azure/functions-core', ...externalPackages],
    outfile: `${outDir}/opentelemetry.mjs`,
  }),
  esbuild.build({
    entryPoints: [`${packageDir}/src/apps/http-with-keyvault-prewarm.ts`],
    bundle: true,
    sourcemap: true,
    sourcesContent: true,
    minify: false,
    keepNames: true,
    platform: 'node',
    target: 'node22',
    format: 'esm',
    banner: {
      js: bannerJs,
    },
    external: ['@azure/functions-core', ...externalPackages],
    outfile: `${outDir}/apps/http-with-keyvault-prewarm.mjs`,
  }),
])

if (fs.existsSync(`${packageDir}/host.json`)) {
  fs.cpSync(`${packageDir}/host.json`, `${outPackageDir}/host.json`, {
    force: true,
    preserveTimestamps: true,
  })
  fs.writeFileSync(
    `${outPackageDir}/package.json`,
    JSON.stringify({
      name: packageJson.name,
      version: packageJson.version,
      type: "module",
      main: "dist/src/index.mjs",
    }),
    { flag: 'w+' }
  )
}

externalPackages.forEach(pkg => {
  const src = `node_modules/${pkg}`
  const dest = `${outPackageDir}/node_modules/${pkg}`
  console.log(`Copying package ${pkg} to deployment folder...`)
  fs.cpSync(src, dest, { recursive: true })
})

console.log('Code packaging completed')
