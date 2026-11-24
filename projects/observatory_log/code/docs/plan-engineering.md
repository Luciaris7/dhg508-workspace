# plan-engineering.md — 第十周的工程计划

> 这是**执行**计划：把已经是成品的游戏搬到公网、配三层测试、把反馈钉住。
> 创作意图、世界边界、据/推断/设来源表在 [`plan.md`](plan.md)；两份不要混读。

## 1. 这一轮要交付什么

| # | 交付物 | 判定标准 |
| --- | --- | --- |
| 1 | `dist/` 可部署 Web 构建 | `npm run build:web` 一键产出，最大单文件 < 25 MiB |
| 2 | Cloudflare Pages 部署链路 | `npm run deploy` 可上线；线上 URL 手机能打开 |
| 3 | 静态门禁 | `npm run check:static` < 1 s，检查 res:// 引用、数据、预设、泄漏 |
| 4 | 单元 / 集成测试 | `npm run test:unit`（vitest）+ `npm run test:game`（Godot 无头） |
| 5 | 浏览器闭环 | `npm run test:e2e`，本地 dist 与线上 URL 同一套用例 |
| 6 | 真实反馈 → 回归测试 | `docs/user-feedback.md`，每条修复对应一个自动化用例 |

## 2. 非目标

- 不做新剧情、新结局、新美术；内容冻结在 1.0.1。
- 不引入后端服务（纯前端状态机，没有网络请求）。
- 不做多人、排行榜、埋点。
- 不提交 `dist/`、`builds/`、`node_modules/`。
- 不为了过 25 MiB 限制去裁剪引擎功能或改分辨率；只改传输方式。

## 3. 执行期问过的四个问题（工程侧）

| # | 问题 | 答复 | 结果 |
| --- | --- | --- | --- |
| Q1 | Cloudflare 部署要账号授权，怎么处理？ | 「你准备 dist + 一键脚本，我自己登录部署」 | `tools/deploy.ps1` + `docs/DEPLOY.md`；不接触 token |
| Q2 | 两位组外朋友实测怎么给？ | 未答复 | 不编造；先做内部自动化试玩并如实记录，朋友那一节留结构待填 |
| Q3 | 用哪个 Godot 版本导出？（本机 4.7.2，README 记的是 4.6.3） | 未答复 | 用 4.7.2 导出并全量测试；差异记进 `questions.md` |
| Q4 | 先交哪一块？ | 「先终止」→ 后「开工」 | 按作业顺序全做 |

## 4. 工作分解

```
D0  仓库卫生      .gitattributes 统一换行；未提交改动做成 checkpoint 提交
D1  导出          Web 预设（关线程）；下载 4.7.2 模板；导出 builds/web
D2  体积          37.7 MB wasm > Pages 25 MiB → dist 放 gzip（9.7 MB）+ _worker.js 解压
D3  测试          静态门禁 / vitest 单元 / Godot 集成 / Playwright E2E
D4  浏览器闭环    E2E 对本地 dist 与线上 URL 同一套用例；wrangler pages dev 验证生产管线
D5  部署          deploy.ps1（wrangler login + pages deploy）+ DEPLOY.md
D6  反馈闭环      user-feedback.md（I1–I6）→ 每条修复对应测试
```

## 5. 测试策略

| 层 | 命令 | 覆盖 | 耗时 |
| --- | --- | --- | --- |
| 静态门禁 | `npm run check:static` | res:// 引用、数据 JSON、Web 预设、本机路径/密钥 | < 1 s |
| 单元 | `npm run test:unit` | 正典常量、摩斯日期推导、双语键覆盖、文案 id、音频总线、dist 契约 | < 1 s |
| 集成 | `npm run test:game` | 星历、三结局、菜单、行走、梦境、UFO、三条完整通关 | 8–12 min |
| E2E | `npm run test:e2e` | 启动零报错、零 404、wasm 合法、输入有反应、手机视口 | ~1.5 min |

## 6. 已知风险

| 风险 | 应对 |
| --- | --- |
| 37.7 MB wasm 超过 Pages 25 MiB | gzip + `_worker.js` 显式解压（已本地验证）；备选 R2 公共桶 |
| `Content-Encoding` 在 wrangler dev 被二次压缩 | 不依赖该头，用 `DecompressionStream('gzip')`；E2E 断言 wasm magic |
| 首次加载 39 MB | 长缓存；README 注明 10–30 秒 |
| 运行时创建的音频总线在 Web 接不到输出 | `default_bus_layout.tres` + 单元测试守住（事故见 `audio-diagnosis.md`） |
| 没有第二位朋友反馈 | 不伪造；内部 QA 先跑，框架就位 |
