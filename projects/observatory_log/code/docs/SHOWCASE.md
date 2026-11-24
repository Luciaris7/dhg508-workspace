# SHOWCASE — 课堂现场按这张单子走

> 六项要求逐条对应到「打开哪个文件 / 跑哪条命令 / 说什么」。
> 时间不够时，优先跑 3 和 4（那两项要现场演示），1 和 2 展示页面即可。

## 0. 开场 20 秒

> 「《OBSERVATION LOG》是一款 Godot 4.7 的 2D 像素恐怖游戏，中英双语，一周目 40–60 分钟。这周我把它从 `play.bat` 搬到了公网，并用三层自动化测试和一次真实的朋友实测把它钉住。」

## 1. 线上网址（展示）

**https://observation-log-9t9.pages.dev**

- 现场在浏览器打开，按 Enter 过警告页，New Game 走两步
- 说：「Cloudflare Pages，单文件限制 25 MiB，而 Godot 的 wasm 有 37.7 MB——所以 dist 里放的是 9.7 MB 的 gzip，`_worker.js` 出口解压」
- 手机可以打开，但游戏是键盘操作，别用手机演示

## 2. 构思闭环 + 示意图（展示文件）

| 打开 | 说 |
| --- | --- |
| `docs/plan.md` §2–§4 | 「灵感来自七款游戏，各给我一种机制：铁肺（低信息）、无声狂啸（不可逃脱）、Fears to Fathom（日常的异常）、看火人（孤独）、Chilla's Art 与 Sally Face（低画质 + 屏中屏）、寂静岭（内在的恐怖）」 |
| 同上 §4 | 「我的贡献是把『低信息』从观看变成劳动：你亲手把那个东西画进星图，然后给它填一个 Yes——恐怖不是『我没看清』，是『我看清了，而且我签字了』」 |
| 同上 §6 | 「早期脚本 → 两轮驳回：脚印看不见、Yes/No 语义反了、眼睛全删、血星占比过大……每条都写回正典再改代码」 |
| 同上 §9 | 「`/goal` 的判据不可自欺：三条结局能到达、线索同名同义、双语键对应、星历 <0.1°、六种机制各有可指认的实现点」 |
| `docs/sources/恐怖的机制·灵感来源.pdf` | 需要时翻到第 2、10 页：七款游戏对照表与三篇文献 |
| `docs/architecture-explainer.html` | 双击打开，讲渲染层栈 / 日循环 / 部署管线 / 测试分层四块 |

## 3. 自动化测试（现场跑）

```powershell
cd <仓库根目录>          # 就是包含 project.godot 与 package.json 的那一层
npm run check:static     # 51 项  <1s
npx vitest run           # 32 项  <1s   ← 课程要的 vitest
npm run test:game        # TEST RUN PASS  8–12 min（可提前跑好，现场说明）
npx playwright test      # 4 passed  ~1.5 min
```

说明每层测什么：

- **静态门禁**：每个 `res://` 引用真的存在、数据 JSON 可解析、Web 预设关线程、仓库里没有本机路径/密钥
- **单元（vitest）**：正典常量（10 条线索、8/10 门槛、13 年周期）、摩斯日期**推导**逻辑、中英键覆盖、文案 id 全部有定义、音频总线布局、dist 产物契约
- **集成（Godot 无头）**：星历精度 0.006°、三结局判定、菜单、强制行走、梦境、UFO 彩蛋、三条完整通关（277/270/295 项）
- **E2E（Playwright）**：真浏览器启动零报错、零 404、wasm 是合法模块、输入有反应、手机视口不裁切

## 4. 自动浏览器闭环（现场看配置）

```powershell
type opencode.json     # @playwright/mcp 的配置
npx playwright test    # 保存好的检查，自动跑、自动截图，不需要人肉看
```

- `opencode.json` 里配了 `@playwright/mcp`（`--browser msedge --headless --isolated --viewport-size 1280,720`），agent 可以直接读 DOM/控制台/404/截图
- `tests/e2e/smoke.spec.js` 是同一套检查的固化版本，`test-results/` 里有每次的截图

## 5. 外部实测 → 永久测试（展示文件）

- 打开 `docs/audio-diagnosis.md`：朋友报「网页版没声音」，我先量错节点、再只看页面信号，最后靠「Windows 混音器 + 同一 AudioContext 塞测试音」定位到「运行时新建的音频总线没接输出」
- 打开 `tests/unit/audio.test.mjs`：5 条测试锁住总线布局
- 打开 `docs/user-feedback.md`：I1–I6，每条都有对应测试
- **坦白**：目前只有一位朋友的反馈，第二位还没回收（表格空着），不编

## 6. 真实困难（口述 60 秒）

> 「最难的不是写测试，是确定『到底有没有声音』。我第一次挂在了采集节点上，读到全 0，判断『引擎不混音』——错。第二次只测页面内部，看到 RMS 0.128，差点得出『其实有声音』——也错。最后同时读 Windows 混音器（0.0000）并在同一个 AudioContext 里塞一个测试音（0.30），才把范围压到总线。教训写进文档了：页面内 AnalyserNode 只能证明图里有数，不能证明你听得见。」

## 收尾清单（老师最后会看）

- [x] README 有一键测试与运行说明
- [x] 提交记录有意义（内容/测试/文档分开提交）
- [x] 没有 API key、没有 `dist/` 与 `node_modules/`
- [x] `questions.md` 记录未决问题
- [ ] 第二位朋友的实测反馈（空着）
