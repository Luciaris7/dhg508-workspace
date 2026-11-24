# questions.md — 未决问题

按作业要求，未解决的问题记在这里，而不是埋在提交里。

## 需要用户决定

1. **I1 的英文文案语气**（`docs/user-feedback.md` §2）：补的是 `"THE AUDIENCE IS NOT YET GRANTED."`，对应设计文档的「觐见之时未至」。如果要更冷、更短（比如 `NOT YET.`），说一声即可，中文保持「觐见之时未至。」
2. **两位组外朋友实测**：需要真实的人在自己设备上玩，并把原话给我。填进 `docs/user-feedback.md` §3，我按 §4 转成测试。
3. **Cloudflare 项目名**：默认 `observation-log`，会得到 `https://observation-log.pages.dev`。想换就在部署时 `npm run deploy -- -ProjectName <名字>`。
4. **Godot 版本**：本机只有 4.7.2，README 里记的实测版本是 4.6.3。全部测试在 4.7.2 上跑通；若课堂演示必须用 4.6.3，需要另装引擎与同版本导出模板再跑一遍。
5. **`docs/user-feedback.md` 里 I1 的修复**是否要同步回主工程（非副本那个文件夹）？目前只改了副本。

## 已知限制（不是 bug，但要知道）

1. **首次加载 38 MB**：引擎 wasm 无法再切小；已用长缓存 + gzip 上传，慢网 10–30 秒。
2. **wasm 用 `immutable` 长缓存且文件名固定**：换引擎版本后建议在 Cloudflare 后台 Purge Cache，否则老访客可能拿到旧 wasm（pck 是 `must-revalidate`，内容更新不受影响）。
3. **`ui()` 有英文回退**：中文模式下 BIOS 自检、`Yes/No`、`HOMEWARD` 图标标签仍是英文，这是有意为之（`tests/unit/copy.test.js` 允许并设了数量上限）。
4. **移动端只保证能开、能看**：游戏设计是键盘（A/D/E、Esc），触屏没有虚拟按键；课堂演示请用笔记本。
5. **存档在浏览器 IndexedDB**：清站点数据 = 丢档；换域名也是新档。

## 已解决，留档备查

1. **25 MiB 限制** → gzip + `_worker.js` 解压（`docs/DEPLOY.md` §5）。
2. **`Content-Encoding` 被二次压缩** → 改显式 `DecompressionStream`（`docs/user-feedback.md` I2）。
3. **导出模板缺失** → 已下载 4.7.2 模板到 `%APPDATA%\Godot\export_templates\4.7.2.stable\`。
4. **`dist/` 混入 `.import`** → 构建脚本排除（I4）。
