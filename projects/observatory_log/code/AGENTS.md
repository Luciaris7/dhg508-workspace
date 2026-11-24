# AGENTS.md

给任何接手这个仓库的 agent 或人：先读这一页，再动代码。

## 一句话

Godot 4.7.2 的 2D 像素恐怖游戏《OBSERVATION LOG》，源码在根目录，Web 构建发到 Cloudflare Pages。
游戏内容冻结在 1.0.1：**没有明确的用户指示，不要改剧情、文案、美术。**

## 命令

| 目的 | 命令 | 期望 |
| --- | --- | --- |
| 静态门禁（<1 s） | `npm run check:static` | `CHECK: 52 passed, 0 failed` |
| 单元测试（<1 s） | `npm run test:unit`（= `npx vitest run`） | `32 passed` |
| 单元测试（备用，零依赖） | `npm run test:unit:node`（= `node --test`） | `pass 32`, `fail 0` |
| Godot 集成测试（8–12 min） | `npm run test:game` | `TEST RUN PASS` |
| 浏览器 E2E（~1.5 min） | `npm run test:e2e` | `4 passed` |
| 本地跑 Web 构建 | `npm run build:web` 然后 `npm run serve` → http://127.0.0.1:8788 | 标题画面 |
| 本地模拟 Cloudflare | `npx wrangler pages dev dist --port 8789` | `/index.wasm` 是 `application/wasm` |
| 部署 | `npm run deploy` | 打印 `https://<project>.pages.dev` |
| 桌面版运行 | 双击 `play.bat`（需要本机 Godot 4.6+） | 直接开游戏 |

改完任何东西，至少跑 `npm run check:static && npm test`；动到状态机、文案或资源再跑 `npm run test:game`；动到导出/部署再跑 `npm run test:e2e`。

## 约定

- **不要提交** `dist/`、`builds/`、`node_modules/`、`test-results/`、`.wrangler/`、`engine/`、`*.lnk`（`.gitignore` 已覆盖）。
- **不要提交** API key、Cloudflare token。部署用 `npx wrangler login` 的本地登录态，不放仓库。
- 换行统一 LF（`.gitattributes` 的 `* text=auto eol=lf`）。
- 文案只从 `scripts/autoload/txt.gd`（英）和 `txt_zh.gd`（中）取：`Txt.mono/ui/red/doc/clue_note/doc_title`。**不要在调用点写字面量**；未知 id 返回空串，会静默变空白。
- 中英两份表必须同步：`MONO`/`RED`/`DOCS` 缺键 **不会** 回退英文（直接空），`UI` 会回退英文。`tests/unit/copy.test.js` 守着这条。
- 星历数据由 `tools/ephem_export.py` 预计算，不要手改 `assets/data/*.json`；改了就重跑 `python tools/ephem_export.py` 并跑 `ephem` 测试。
- 美术/音频是程序生成的（`tools/gen_*.py`），改生成器而不是改 PNG。

## 开发者捷径（F1–F7）

`scripts/main.gd` 顶部 `const CHEATS := true`：运行中按 **F1–F7** 会重开一局并从第 1–7 天直接开始（`flow.debug_jump(n)`），清空当前存档、关掉菜单/桌面/梦境。
改 `false` 即彻底移除按键。`tests/cheat_test.tscn` 守着它（`npm run test:game` 里的 `cheat` 关卡）：能跳、会重置、第 7 天入夜、暂停菜单里按键也会先关菜单。
**发版前想关掉就把那个常量改成 false**；已发布的 Web 构建同样有这个键。

## 三条"别踩"的坑

1. **Pages 单文件 25 MiB**。`index.wasm` 37.7 MB，永远以 `index.wasm.gz` + `_worker.js` 解压的形式发布。不要"顺手"把它解压回 `dist/`。
2. **不要用 `Content-Encoding: gzip` 回传 wasm**。`wrangler pages dev` 会二次压缩，引擎报 `expected magic word 00 61 73 6d found 1f 8b 08`。用 `DecompressionStream('gzip')` 显式解压。
3. **Web 预设必须 `variant/thread_support=false`**。开线程就要 COOP/COEP 头，云端和本地行为都更复杂，这个游戏不需要。
4. **`html/canvas_resize_policy` 保持 `1`（Project），不要改回 `2`（Adaptive）**。Adaptive 会把 canvas 设成视口大小（如 390×844），而游戏按 640 宽绘制、整数缩放在窄窗口下夹到 1，画面两侧被裁（整件事见 `docs/user-feedback.md` I5）。`tools/patch_shell.js` 负责把定尺寸画布等比塞进视口。
5. **音频总线必须写在 `default_bus_layout.tres` 里**，不要在运行时靠 `AudioServer.add_bus()` 才是唯一来源。Web 导出的音频驱动在初始化时按布局建图，运行期新建的总线在浏览器里接不到输出——整局游戏会静音，桌面版却完全正常。`tests/unit/audio.test.js` 守着这条（事故记录见 `docs/audio-diagnosis.md`）。

## 加一个新测试的规矩

1. 能静态查出来的，写进 `tools/check_static.js`（<1 s 的层）。
2. 能对文件/常量/双语文案下结论的，写进 `tests/unit/*.test.mjs`（ESM；vitest 与 node:test 都能跑）。
3. 只有真跑游戏才看得出的，写进 Godot 的 `tests/*.tscn`（跑 `npm run test:game`）。
4. 只有真跑浏览器才看得出的，写进 `tests/e2e/smoke.spec.js`。
5. 任何一条都必须在失败时给出**可读的原因**，而不是只报 false。

## 为什么同一套测试两个运行器都能跑

`tests/unit/*.test.mjs` 是 ESM：从 `node:test` 取 `test`，从 `node:assert/strict` 取 `assert`。

- `npm run test:unit` = `npx vitest run`（课程要求的命令）；`vitest.config.mjs` 把 `node:test` 别名到 `vitest`，断言代码一行都不用改；
- `npm run test:unit:node` = `node --test`，零依赖，适合冷启动与 CI 兜底。

两条都跑通、结果一致（32 项）。新增测试照这个写法，不要在文件里用 `require`。
