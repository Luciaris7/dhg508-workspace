// Cloudflare Pages advanced mode worker (_worker.js).
//
// Why this file exists: Cloudflare Pages refuses any single asset larger than
// 25 MiB, and the Godot 4.7 web export ships a ~38 MB index.wasm. The build
// stores the wasm gzipped as index.wasm.gz (~9.7 MB) and this worker inflates
// it back to /index.wasm on the way out.
//
// An earlier version returned the gzip bytes with `Content-Encoding: gzip`.
// That works in theory but broke under `wrangler pages dev`: the runtime could
// compress the response a second time, and the engine then failed with
// "expected magic word 00 61 73 6d, found 1f 8b 08". Decompressing explicitly
// keeps the bytes the browser sees identical in dev and production.
const WASM_PATH = '/index.wasm';
const GZ_PATH = '/index.wasm.gz';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === WASM_PATH) {
      const asset = await env.ASSETS.fetch(new URL(GZ_PATH, url), request);
      if (!asset.ok) {
        return new Response('web build is missing index.wasm.gz', {
          status: 500,
          headers: { 'content-type': 'text/plain; charset=utf-8' },
        });
      }

      const body = asset.body.pipeThrough(new DecompressionStream('gzip'));
      return new Response(body, {
        status: 200,
        headers: {
          'content-type': 'application/wasm',
          'cache-control': 'public, max-age=31536000, immutable',
          'cross-origin-resource-policy': 'same-origin',
        },
      });
    }

    return env.ASSETS.fetch(request);
  },
};
