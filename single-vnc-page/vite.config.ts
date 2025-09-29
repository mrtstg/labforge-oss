import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import topLevelAwait from "vite-plugin-top-level-await";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    svelte(),
    topLevelAwait({
      // The export name of top-level await promise for each chunk module
      promiseExportName: "__tla",
      // The function to generate import names of top-level await promise in each chunk module
      promiseImportName: i => `__tla_${i}`
    })
  ],
  esbuild: {
 //   target: 'es2022',
    supported: { 'top-level-await': true },
  },
  optimizeDeps: {
    include: ["@novnc/novnc"],
    esbuildOptions: {
 //     target: 'es2022',
      supported: { "top-level-await": true },
    },
  },
  build: {
   // target: 'es2022',
    rollupOptions: {
      output: {
        entryFileNames: '[name].js',
        assetFileNames: '[name].css'
      }
    }
  }
})
