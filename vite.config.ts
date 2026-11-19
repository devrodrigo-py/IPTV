import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import legacy from '@vitejs/plugin-legacy';

// TV WebViews can be years old (Chrome 64+ on un-updated Fire TV / Android TV
// boxes). Syntax is lowered and only the polyfills the code needs are added
// to the modern bundle; every supported WebView already runs ES modules.
export default defineConfig({
  plugins: [
    react(),
    legacy({
      modernTargets: ['chrome>=64', 'safari>=12'],
      modernPolyfills: true,
      renderLegacyChunks: false,
    }),
  ],
  build: {
    target: ['chrome64', 'safari12'],
    cssTarget: ['chrome64', 'safari12'],
  },
  worker: {
    // Classic worker: module workers need Chrome 80+.
    format: 'iife',
  },
  server: {
    host: '0.0.0.0',
    port: 3000,
  },
});
