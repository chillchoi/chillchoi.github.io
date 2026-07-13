// Zero-dependency static preview server for dist/ (or the project root).
// Run with: node serve.mjs        → serves ./dist on http://localhost:8080
//           node serve.mjs . 9292 → serves ./ on port 9292
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join, extname, normalize } from 'node:path';

const root = dirname(fileURLToPath(import.meta.url));
const dir = join(root, process.argv[2] || 'dist');
const port = Number(process.argv[3]) || 8080;

const MIME = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.json': 'application/json',
  '.ico': 'image/x-icon', '.mp4': 'video/mp4', '.webp': 'image/webp' };

createServer(async (req, res) => {
  try {
    let p = decodeURIComponent(req.url.split('?')[0]);
    if (p === '/') p = '/index.html';
    const file = normalize(join(dir, p));
    if (!file.startsWith(dir)) { res.writeHead(403).end('Forbidden'); return; }
    await stat(file);
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': MIME[extname(file).toLowerCase()] || 'application/octet-stream' });
    res.end(data);
  } catch { res.writeHead(404).end('Not found'); }
}).listen(port, () => console.log(`Serving ${dir} → http://localhost:${port}`));
