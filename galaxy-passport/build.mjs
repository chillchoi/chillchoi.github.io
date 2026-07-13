// Zero-dependency static build → produces dist/ ready for any static host.
// Run with: node build.mjs   (no npm install required)
import { mkdirSync, copyFileSync, existsSync, rmSync, statSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(fileURLToPath(import.meta.url));
const dist = join(root, 'dist');

if (existsSync(dist)) rmSync(dist, { recursive: true, force: true });
mkdirSync(dist, { recursive: true });

// The app is a self-contained static file (only external is the Klleon SDK CDN),
// so the "build" is a clean copy of the deployable assets into dist/.
const files = ['index.html', 'v1-prototype.html'];
const built = [];
for (const f of files) {
  const src = join(root, f);
  if (existsSync(src)) { copyFileSync(src, join(dist, f)); built.push(`${f} (${(statSync(src).size / 1024).toFixed(0)} KB)`); }
}

const assetsSrc = join(root, 'assets');
if (existsSync(assetsSrc)) {
  const assetsDist = join(dist, 'assets');
  mkdirSync(assetsDist, { recursive: true });
  for (const f of readdirSync(assetsSrc)) {
    copyFileSync(join(assetsSrc, f), join(assetsDist, f));
    built.push(`assets/${f} (${(statSync(join(assetsSrc, f)).size / 1024).toFixed(0)} KB)`);
  }
}

console.log('✅ Built static site → dist/');
built.forEach((b) => console.log('   -', b));
console.log('\nDeploy the dist/ folder to any static host (Netlify / Vercel / S3 / GitHub Pages).');
console.log('Preview locally:  node serve.mjs   → http://localhost:8080');
