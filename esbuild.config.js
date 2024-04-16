require('esbuild').build({
  entryPoints: ['app/javascript/application.js'],
  bundle: true,
  outdir: 'app/assets/builds',
  watch: process.argv.includes('--watch'),
  plugins: [
    require('esbuild-plugin-tailwind')({
      tailwindConfig: './tailwind.config.js'
    }),
  ]
}).catch(() => process.exit(1))
