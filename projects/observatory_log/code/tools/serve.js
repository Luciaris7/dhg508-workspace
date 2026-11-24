// Local stand-in for the Cloudflare Pages deployment, used by the E2E tests.
// It implements the same /index.wasm -> index.wasm.gz + Content-Encoding rule
// that functions/_middleware.js performs in production.
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || 'dist');
const port = Number(process.argv[3] || 8788);

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.json': 'application/json',
  '.gz': 'application/gzip',
};

function send(res, status, headers, body) {
  res.writeHead(status, headers);
  res.end(body);
}

http
  .createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    let p = decodeURIComponent(url.pathname);
    if (p === '/') p = '/index.html';

    if (p === '/index.wasm') {
      const gz = path.join(root, 'index.wasm.gz');
      if (!fs.existsSync(gz)) return send(res, 500, { 'content-type': 'text/plain' }, 'index.wasm.gz missing');
      const body = fs.readFileSync(gz);
      return send(res, 200, {
        'content-type': 'application/wasm',
        'content-encoding': 'gzip',
        'content-length': body.length,
        'cache-control': 'public, max-age=31536000, immutable',
      }, body);
    }

    const file = path.join(root, p);
    if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      return send(res, 404, { 'content-type': 'text/plain; charset=utf-8' }, `not found: ${p}`);
    }
    const body = fs.readFileSync(file);
    send(res, 200, {
      'content-type': MIME[path.extname(file).toLowerCase()] || 'application/octet-stream',
      'content-length': body.length,
      'cache-control': 'no-store',
    }, body);
  })
  .listen(port, '127.0.0.1', () => console.log(`serving ${root} on http://127.0.0.1:${port}`));
