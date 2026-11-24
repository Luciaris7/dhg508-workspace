// Build helper: replace index.wasm with index.wasm.gz in the deploy folder.
// Cloudflare Pages has a 25 MiB per-asset limit and the raw wasm is ~38 MB.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const src = process.argv[2];
const dst = process.argv[3];
if (!src || !dst) {
  console.error('usage: node tools/gzip.js <in.wasm> <out.wasm.gz>');
  process.exit(2);
}

const raw = fs.readFileSync(src);
const gz = zlib.gzipSync(raw, { level: 9 });
fs.mkdirSync(path.dirname(dst), { recursive: true });
fs.writeFileSync(dst, gz);

const mb = (n) => (n / 1048576).toFixed(2) + ' MB';
console.log(`wasm ${mb(raw.length)} -> gzip ${mb(gz.length)}`);
if (gz.length > 25 * 1024 * 1024) {
  console.error('FAIL: compressed wasm still exceeds the 25 MiB Pages limit');
  process.exit(1);
}
