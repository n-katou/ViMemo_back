const esbuild = require('esbuild')
const path = require('path')

esbuild.build({
  entryPoints: ['app/javascript/application.js'],
  bundle: true,
  outdir: path.join(process.cwd(), 'app/assets/builds'),
  plugins: [],
  loader: {
    '.js': 'jsx',  // JSXをサポート
    '.css': 'css'  // CSSファイルの取り扱いを追加
  },
  watch: process.argv.includes('--watch'), // 開発時に変更を監視
  sourcemap: true // ソースマップを有効化
}).catch(() => process.exit(1))
