# Architecture

Three views: what runs on screen, what runs the story, and what turns this folder into a public URL.
The same diagrams exist as a standalone page in [`architecture-explainer.html`](architecture-explainer.html).

## 1. Render stack

One `Node` owns everything; every view is its own `SubViewport` so the pixel art and the shaders never argue about resolution.

```mermaid
flowchart TB
  subgraph main["scenes/main.tscn → scripts/main.gd (root Node)"]
    L0["CanvasLayer 0 · world<br/>SubViewport 320×180 → ×2<br/>post.gdshader: 32-colour palette + dither"]
    L1["CanvasLayer 1 · desktop<br/>SubViewport 640×360<br/>crt.gdshader (first-person monitor)"]
    L2["CanvasLayer 2 · minigame<br/>SubViewport 320×180 → ×2<br/>post.gdshader (+ CRT when on the monitor)"]
    L3["CanvasLayer 3 · ending<br/>SubViewport 640×360<br/>post.gdshader"]
    L5["CanvasLayer 5 · overlay<br/>monologue · prompts · day card · red text · fades"]
    L8["CanvasLayer 8 · fx<br/>fx.gdshader: tear + shake, reads the composited screen"]
    L10["CanvasLayer 10 · menu<br/>title / pause / settings (never distorted)"]
  end
  G["Autoloads: G (state, save, settings, fonts) · Txt (EN/ZH copy) · Sfx (audio)"]
  F["Flow (director): day script, interactions, cutscenes"]
  M["Main: input router by mode"]
  G --> M
  M --> F
  F --> L0
  F --> L1
  F --> L3
  M --> L5
  M --> L8
  M --> L10
```

Project settings that make this work: `640×360` viewport, stretch `viewport` + `keep` + integer scale, `gl_compatibility` renderer (so the same build runs on the web), nearest-neighbour texture filtering, 2D pixel snapping.

## 2. Mode router

`Main._input()` is the only place that decides who gets a key.

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> world: 新游戏 / 继续
  world --> desktop: 走到电脑按 E
  world --> cutscene: 脚本演出（序章、第 4 天擦屏、第 7 天）
  desktop --> world: Esc 离开
  desktop --> dream: 第 5 天睡觉
  cutscene --> world: 演出结束
  dream --> ending: 教堂门后
  world --> ending: 湖边行进
  ending --> menu: 名单 / CG / 重来
```

| mode | 拿到输入的模块 | 说明 |
| --- | --- | --- |
| `menu` | `menu.gd` | Esc 暂停、设置、语言 |
| `world` | `world.gd` / `flow.gd` | A/D 走，E 交互，Esc 暂停（面板打开时 Esc 归面板） |
| `desktop` | `desktop.gd` | XP 桌面：双击图标、拖动窗口、键盘输入汇报 |
| `dream` | `minigame.gd` | 第 5 天梦境里的 The Gift of X |
| `cutscene` / `ending` | `flow.gd` | 只响应「加速独白」 |

## 3. Day loop (director)

`Flow.start_day(n)` builds the day; every interaction is a `match` on the step, so the story cannot skip a beat.

```mermaid
stateDiagram-v2
  [*] --> day_start
  day_start --> tasks
  tasks --> hilltop: 上山（天黑在途中完成）
  hilltop --> tasks: 下山
  tasks --> report: 电脑 → 汇报页
  report --> night: 提交 Yes / No
  night --> dream: 第 5 天睡觉
  dream --> ending: 梦境推门
  night --> sleep: 其他天
  sleep --> day_start: 次日
  report --> day7: 第 7 天汇报后
  day7 --> ending: 强制走向湖边
  ending --> [*]
```

Interactables that feed the mystery (all optional, none blocking): 告示牌、设备登记簿、书架、衣架、冰洞、回波测绘（`_open_sonar`）、摩斯电台（`_use_radio`）、档案（`app_archive.gd`）。
Endings are decided in one place: `G.can_escape()` = 摩斯编号已解 **且** 线索 ≥ 8/10；第 5 天被机房人影抓到则走 `assimilate`，其余到岸者 `sacrifice`。

## 4. State and save

Single slot, written atomically (`save.json.tmp` → `save.bak` → `save.json`), version 2.

```mermaid
flowchart LR
  S["G.persist (persisted)<br/>answers · clues · marks_hit · records<br/>surveys · morse_solved · has_receiver<br/>start_unix · best · finished"]
  F["G.f (per day, cleared each morning)<br/>antenna_target · antenna_start · once_* flags"]
  SV["user://settings.json<br/>lang · volumes · flash · tear · fullscreen · assist"]
  B["G.day · G.tod · G.clock_min (in-game clock)"]
  S --> Save["user://save.json (v2)"]
  SV --> SaveS["user://settings.json"]
  B --> Save
  Save --> Load["load_game() clamps day to 1..7<br/>falls back to save.bak"]
```

On the web these land in the browser's IndexedDB via Godot's `user://` mount — no server, no account.

## 5. Build → deploy pipeline

```mermaid
flowchart LR
  A["Godot 4.7.2<br/>export_presets.cfg: Web<br/>thread_support=false"] --> B["builds/web/<br/>index.html · index.js<br/>index.pck 9.5 MB · index.wasm 37.7 MB"]
  B --> C{"37.7 MB ><br/>Pages 25 MiB?"}
  C -- yes --> D["tools/gzip.js<br/>index.wasm → index.wasm.gz 9.7 MB"]
  D --> E["dist/<br/>+ _headers + _worker.js"]
  C -- no --> E
  E --> F["npx wrangler pages deploy dist"]
  F --> G["https://&lt;project&gt;.pages.dev"]
  G --> H["_worker.js: GET /index.wasm<br/>ASSETS.fetch(index.wasm.gz)<br/>DecompressionStream('gzip')<br/>→ application/wasm"]
  E --> I["patch_shell.js: canvas_resize_policy=1<br/>+ CSS object-fit:contain<br/>(phones see the whole 16:9 frame)"]
```

Why a worker at all: **Pages caps a single stored asset at 25 MiB**; the engine wasm is 37.7 MB and cannot be split. Serving it gzipped keeps every stored file under the limit, and the worker inflates it for the browser. The first attempt returned the gzip bytes with `Content-Encoding: gzip`; `wrangler pages dev` compressed them a second time and the engine failed with `expected magic word 00 61 73 6d, found 1f 8b 08`, so the worker now decompresses explicitly — see `docs/user-feedback.md` issue I2.

## 6. Test layers

```mermaid
flowchart TB
  S["静态门禁 · npm run check:static<br/>res:// 引用 · JSON · Web 预设 · 泄漏"] --> U
  U["单元 · npm test (node:test)<br/>正典常量 · 双语键 · 文案 id · dist 契约"] --> I
  I["集成 · npm run test:game (Godot --headless)<br/>星历 · 结局 · 菜单 · 行走 · 三条通关"] --> E
  E["E2E · npm run test:e2e (Playwright)<br/>本地 dist 与线上 URL 同一套用例"]
```

The dependency arrow is the point: a broken `res://` path fails in under a second, long before a 12-minute playthrough would.
