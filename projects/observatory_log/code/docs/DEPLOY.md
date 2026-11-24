# 部署到 Cloudflare Pages

目标：一条命令把 `dist/` 传上去，得到一个 `https://<project>.pages.dev` 链接，手机打开就能玩。

## 0. 一次性准备

| 需要 | 检查 |
| --- | --- |
| Node 20+ | `node --version` |
| Godot **4.7.2**（与导出模板同版本） | `godot --version` |
| Godot 4.7.2 **导出模板** | `%APPDATA%\Godot\export_templates\4.7.2.stable\` 里有 `version.txt`、`web_nothreads_release.zip`、`web_nothreads_debug.zip` |
| Cloudflare 账号（免费） | 浏览器登录一次即可 |

导出模板从 Godot 官方 release 下载（约 1.2 GB，只需要 web 的 no-threads 模板）：

```powershell
# 1) 下载
curl.exe -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
# 2) 解压后把 templates\ 里的三个文件放进（版本目录名必须一致）
#    %APPDATA%\Godot\export_templates\4.7.2.stable\
#    version.txt
#    web_nothreads_release.zip
#    web_nothreads_debug.zip
```

> 本机 `curl` 走 schannel 时可能报 `SEC_E_NO_CREDENTIALS`（沙箱/凭据问题）。用浏览器下载，或 `node tools/download.js <url> <out>` 也行。

## 1. 构建

```powershell
npm install
npm run build:web
```

产物 `dist/`：

| 文件 | 大小 | 说明 |
| --- | --- | --- |
| `index.html` / `index.js` | 273 KB | 引擎外壳 |
| `index.pck` | 9.5 MB | 全部游戏资源 |
| `index.wasm.gz` | 9.7 MB | 引擎本体（压缩后；原始 37.7 MB 会超过 Pages 的 25 MiB 限制） |
| `_worker.js` | 1.5 KB | 把 `.wasm.gz` 还原成 `/index.wasm` |
| `_headers` | 0.4 KB | MIME 之外的缓存与安全头 |

构建脚本最后会打印最大单文件；超过 25 MiB 直接失败，不会让你传到一半才发现。

## 2. 登录

```powershell
npx wrangler login
```

浏览器会打开 Cloudflare 授权页。登录态保存在本机，之后不用重复。

## 3. 部署

```powershell
npm run deploy
# 或换项目名
npm run deploy -- -ProjectName observation-log
```

成功后会打印 `https://<deployment>.pages.dev`。Cloudflare 会在项目名后加一段后缀，稳定的生产地址是 `https://observation-log-9t9.pages.dev`（本项目实际地址，见仪表盘 Workers & Pages）。

## 4. 上线后自查

```powershell
# 同一套浏览器测试跑线上地址
$env:GAME_URL = 'https://observation-log-9t9.pages.dev'
npx playwright test
```

2026-11-17 实测：4 项全过（零控制台错误、零 404、`/index.wasm` 返回 `application/wasm` 39.5 MB、手机视口不裁切）。

2026-11-25 再次实测（v1.7 部署后）：4 项全过；`dist` 12 个文件 19.6 MB、最大 9.68 MB；
线上 `/index.html` 带 About 说明，`/index.wasm` 由 `_worker.js` 解压后返回 `application/wasm`。
注意这次部署用 `node node_modules/wrangler/wrangler-dist/cli.js pages deploy ...` 直接调 CLI——
`npm run deploy` 会经 `npx` 再 spawn 一层，在受限环境里容易先失败。

再看三件事：

1. 手机打开，横屏，确认能进标题、能走、能开电脑；
2. 首次加载约 38 MB，慢网 10–30 秒属正常（之后走长缓存）；
3. 控制台零报错、网络面板零 404。

## 5. 排错

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 上传报 `Pages only supports files up to 25 MiB` | 传了原始 wasm | 重新 `npm run build:web`，确认 `dist/index.wasm` 不存在、`dist/index.wasm.gz` 存在 |
| 页面黑屏，控制台 `expected magic word 00 61 73 6d, found 1f 8b 08` | wasm 被当模块直接喂给引擎（压缩没解开） | 确认 `dist/_worker.js` 是当前版本（含 `DecompressionStream`） |
| `/index.wasm` 返回 200 但内容是 HTML | 没有 `_worker.js` 或它没生效（SPA 回退） | `curl -I https://<project>.pages.dev/index.wasm` 应看到 `content-type: application/wasm` |
| 字体/像素图模糊 | 浏览器缩放 | 游戏是整数倍缩放，窗口取 1280×720 或全屏 |
| 手机上画面两边被裁 | Web 预设的 canvas 策略被改回 Adaptive | `html/canvas_resize_policy=1`，并确认 `dist/index.html` 里有 `viewport-fit` 那段 CSS |
| 存档丢失 | 换了域名或清了站点数据 | 存档在 IndexedDB，随域名走 |

## 6. 更新版本

```powershell
npm run build:web
npm run deploy
```

`_worker.js` 对 wasm 用 `immutable` 长缓存，但文件名固定，所以**改引擎版本时请连带清理浏览器缓存**，或在 Cloudflare 后台做一次 Purge Cache。
只想改游戏内容（`index.pck`）时不受影响：pck 是 `must-revalidate`。
