// Two things happen to the stock Godot web shell here.
//
// 1. The shell leaves #canvas at its pixel size (640x360), so on a 390 px wide
//    phone the page is wider than the screen and the warning text is clipped.
//    One stylesheet letterboxes the canvas into the viewport (issue I5).
// 2. Week 11 asks for a 2-4 sentence note on the live page stating the
//    historical context, the 据 / 推断 / 设 split and the AI tools used. It goes
//    here rather than in a game scene, so that freezing game content does not
//    mean freezing the disclosure.
//
// Idempotent: running twice changes nothing.
const fs = require('fs');

const file = process.argv[2];
if (!file) {
  console.error('usage: node tools/patch_shell.js <dist/index.html>');
  process.exit(2);
}

const MARK = 'observation-log/light:viewport-fit';
const CSS = `<style id="viewport-fit">
/* ${MARK} */
html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
#canvas {
  display: block;
  width: 100vw !important;
  height: 100vh !important;
  object-fit: contain;
  image-rendering: pixelated;
}
</style>`;

const ABOUT_MARK = 'observation-log/light:about-note';
// The wrapper is anchored to the bottom-right corner and laid out as a normal
// column: the note sits above, the toggle stays pinned to the corner. Done the
// other way round, opening the note drags the button into the middle of the screen.
const ABOUT = `<style id="about-note-css">
/* ${ABOUT_MARK} */
#about-note { position: fixed; right: 10px; bottom: 10px; z-index: 2147483000;
  display: flex; flex-direction: column; align-items: flex-end; gap: 8px;
  font: 13px/1.55 "Segoe UI", "Microsoft YaHei", system-ui, sans-serif; color: #e8e8e8; }
#about-note > button { font: inherit; color: #e8e8e8; background: rgba(20,20,20,.82);
  border: 1px solid #6a6a6a; border-radius: 4px; padding: 5px 10px; cursor: pointer; flex: none; }
#about-note > button:hover { background: rgba(40,40,40,.95); }
#about-note > section { display: none; width: min(520px, calc(100vw - 40px));
  padding: 14px 16px; border-radius: 6px;
  background: rgba(12,12,12,.94); border: 1px solid #5a5a5a;
  max-height: 58vh; overflow: auto; }
#about-note.open > section { display: block; }
#about-note p { margin: 0 0 9px; }
#about-note p:last-child { margin-bottom: 0; }
#about-note em { color: #d98f8f; font-style: normal; }
</style>
<div id="about-note">
  <section role="note">
    <p>A fiction: Birch Lake, its Site 7 watching post, the thirteen-year cycle
    and all three endings are invented (<em>设</em>). What comes from history is
    the <em>form</em> — a paper duty log and a 2001–2006 desktop, rebuilt from
    period interface conventions (<em>据</em>), while the planet positions on the
    star chart are real ephemerides (Astronomy Engine, 36 dates, error under
    0.1°, also <em>据</em>) and the daily routine of a remote post with its aurora
    legend is <em>推断</em>, inference rather than an archival record.</p>
    <p>本作为虚构作品：白桦湖第七站、十三年周期与三种结局均为<em>设</em>；据实者是形式——纸质值班日志与 2001–2006 年的个人电脑界面，星图行星位置取自真实星历，远程观测站的日常流程与极光传说属<em>推断</em>。</p>
    <p>AI tools: Claude Opus 5.5 (opencode) wrote the first build; GLM 5.3 Flash,
    DeepSeek V4.1 Flash and ChatGPT 6.1 Sol revised it. Every design decision and
    every rejection was made by the author.</p>
  </section>
  <button type="button" id="about-toggle" aria-expanded="false">About / 关于</button>
</div>
<script>
(function () {
  var box = document.getElementById('about-note');
  var btn = document.getElementById('about-toggle');
  if (!box || !btn) return;
  btn.addEventListener('click', function () {
    var open = box.classList.toggle('open');
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  });
})();
</script>`;

let html = fs.readFileSync(file, 'utf8');
let changed = false;

if (!html.includes(MARK)) {
  if (!html.includes('</head>')) {
    console.error('FAIL: no </head> in the exported shell');
    process.exit(1);
  }
  html = html.replace('</head>', `${CSS}\n\t</head>`);
  changed = true;
  console.log('patched dist/index.html: canvas letterboxes to the viewport');
} else {
  console.log('viewport-fit already present');
}

if (!html.includes(ABOUT_MARK)) {
  if (!html.includes('</body>')) {
    console.error('FAIL: no </body> in the exported shell');
    process.exit(1);
  }
  html = html.replace('</body>', `${ABOUT}\n\t</body>`);
  changed = true;
  console.log('patched dist/index.html: About note (context / 据推断设 / AI tools)');
} else {
  console.log('about-note already present');
}

if (changed) fs.writeFileSync(file, html);
