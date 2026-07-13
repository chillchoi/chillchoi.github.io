import { defineConfig } from 'vite';

// Optional Vite pipeline (for an optimized/minified build on a machine with npm).
// The app is a self-contained static index.html, so `vite build` emits a hashed,
// minified dist/. `base: './'` keeps asset paths relative so it works from any
// static-host subpath. Run:  npm install && npm run build:vite
export default defineConfig({
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
});
