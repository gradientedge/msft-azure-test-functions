import esbuild from 'esbuild'
import fs from 'node:fs'

const appDir = process.cwd()
const packageDir = appDir

const packageJsonPath = `${packageDir}/package.json`
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'))

const outPackageDir = `${packageDir}/dist`
const outDir = `${outPackageDir}/dist/src`

const externalPackages = []

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
    entryPoints: [`${packageDir}/src/apps/http.ts`],
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
    outfile: `${outDir}/apps/http.mjs`,
  }),
  esbuild.build({
    entryPoints: [`${packageDir}/src/apps/http-external-api.ts`],
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
    outfile: `${outDir}/apps/http-external-api.mjs`,
  }),
  esbuild.build({
    entryPoints: [`${packageDir}/src/apps/http-with-keyvault.ts`],
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
    outfile: `${outDir}/apps/http-with-keyvault.mjs`,
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
      //type: "module",
      main: packageJson.main,
    }),
    { flag: 'w+' }
  )
}

console.log('Code packaging completed')
