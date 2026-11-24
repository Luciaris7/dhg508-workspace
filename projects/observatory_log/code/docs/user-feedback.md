# 用户反馈 → 永久回归测试

> 这份文件是「真实反馈 → 修复 → 测试」的记录。**没有真实发生过的试玩，不会写在这里。**
> 目前有内部自动化试玩（agent 自己跑）＋ 两份来自组外真人玩家的书面反馈（§3）。两份都收了；
> 其中 A 的那 6 条我只拿到书面稿，没有旁观全程，所以下面的"试到哪"按稿子能证明的范围写，不替她补。

## 1. 内部 QA 怎么做的

| 手段 | 覆盖 | 产物 |
| --- | --- | --- |
| Playwright 无头浏览器（Edge/Chromium） | 启动、控制台、网络、输入、手机视口 | `tests/e2e/smoke.spec.js`、`test-results/*.png` |
| Godot 无头跑真游戏 | 星历、结局、菜单、行走、三条完整通关 | `tests/*.tscn`、`tests/_logs/*.log` |
| 静态/单元检查 | 引用、正典常量、双语文案、产物契约 | `tools/check_static.js`、`tests/unit/*.test.js` |
| 人工看截图 | 像素缩放、字体、调色板是否在浏览器里走样 | `test-results/boot.png`、`after-input.png`、`mobile.png` |

## 2. 发现并已修复的问题

### I1 · 神庙门口的红字是空白的

- **怎么发现的**：单元测试「every copy id used in a script exists in the English table」第一次跑就红。
- **证据**：`scripts/minigame/minigame.gd:375` 调 `Txt.red("reject")`，但 `txt.gd` / `txt_zh.gd` 的 `RED` 表里都没有 `reject` 键；`red()` 对未知 id 返回空串（`txt.gd:428`），所以玩家拿到 5000 分、走进神殿、推门，期待的是「觐见之时未至」，实际什么都不显示。
- **修复**：两语言各补一条（`txt.gd` / `txt_zh.gd` 的 `RED`）：
  - en `"reject": "THE AUDIENCE IS NOT YET GRANTED."`
  - zh `"reject": "觐见之时未至。"`
  - 英文措辞沿用设计文档的「觐见之时未至」，若用户想改口吻随时可换；中文按 `docs/plan.md` 的冷感基调。
- **回归测试**：`tests/unit/copy.test.js` 的两条——「zh covers every key of RED」与「every copy id used in a script exists in the English table」。前者保证两边同步，后者保证脚本里不会再出现未定义 id。

### I2 · 线上 wasm 被解压两次，游戏黑屏

- **怎么发现的**：Playwright 对 `wrangler pages dev`（生产同款管线）跑冒烟测试，4 条全红。
- **证据**：`CompileError: WebAssembly.instantiateStreaming(): expected magic word 00 61 73 6d, found 1f 8b 08 @+0` —— 浏览器拿到的是 gzip 头（`1f 8b`），说明响应被再压了一层。
- **根因**：第一版 `_worker.js` 把 `.wasm.gz` 的字节原样回传并加 `Content-Encoding: gzip`；本地 wrangler 运行时会再压缩一次，于是浏览器解一层后仍是 gzip。
- **修复**：worker 改用 `DecompressionStream('gzip')` 显式解压，返回 `application/wasm` 的原始字节，不依赖任何 `Content-Encoding` 语义。
- **回归测试**：`tests/e2e/smoke.spec.js`「the wasm is served as a real WebAssembly module」断言 `\0asm` 魔数与 `application/wasm`；`tests/unit/build.test.js` 断言 `_worker.js` 里确实是 `DecompressionStream('gzip')`。

### I3 · 37.7 MB 的 wasm 根本传不上 Cloudflare Pages

- **怎么发现的**：构建后量尺寸 + 查 Pages 文档（单文件上限 25 MiB）。
- **证据**：`index.wasm` 37.68 MB；gzip 后 9.68 MB，brotli 6.77 MB。
- **修复**：`dist/` 只放 `index.wasm.gz`（9.7 MB），由 `_worker.js` 还原；构建脚本把 25 MiB 写成硬性检查，超了直接失败。
- **回归测试**：`tests/unit/build.test.js`「dist is smaller than the Pages per-asset limit and ships no raw wasm」；E2E 从 HTTP 层再验证一次。

### I4 · `dist/` 里混进了 Godot 的 `.import` 边车文件

- **怎么发现的**：构建完成后列目录，发现 `index.icon.png.import`、`index.png.import` 等被一起复制。
- **影响**：不影响运行，但会把没用的文件传上去，也让人误以为 dist 里有源工程残留。
- **修复**：`tools/build_web.ps1` 复制时排除 `*.import`。
- **回归测试**：`tests/unit/build.test.js` 断言 `dist/` 内不存在 `.import`。

### I5 · 手机上画面右边被裁掉

- **怎么发现的**：Playwright 的 390×844 手机视口用例截图，警告页文字「distortion and / reduced」右侧被切断。
- **证据**：canvas 的 bitmap 尺寸等于视口（390×844），但游戏是以 640×360 逻辑宽度绘制的，`window/stretch/scale_mode="integer"` 在 390 宽度下 `floor(390/640)=0`、被夹到 1，于是 640 宽的画面塞进 390 宽的画布，左右各裁掉一截。
- **修复**：Web 预设的 `html/canvas_resize_policy` 从 `2`（Adaptive）改为 `1`（Project），画布固定按工程尺寸渲染完整 16:9 画面；`tools/patch_shell.js` 在导出的 `index.html` 里注入一段 CSS，把画布等比缩放到视口（`object-fit: contain` + `image-rendering: pixelated`）。
- **回归测试**：`tests/e2e/smoke.spec.js`「renders on a phone-sized screen without clipping or crashing」断言页不横向溢出、canvas 不超宽、bitmap 宽度 ≥ 640 且保持 16:9；`tests/unit/build.test.js` 断言 `dist/index.html` 里有 `viewport-fit` 那套 CSS。
- **仍未解决**：手机上能看不能玩——游戏是键盘操作（A/D/E/Esc），没有做触屏虚拟按键。课堂演示请用笔记本。

### I6 · 网页版没有声音（已修复）

- **怎么发现的**：用户和一位朋友实测都报「网页版没声音」。
- **根因**：`Sfx._ready()` 在运行时才 `AudioServer.add_bus()` 建出 `Music / SFX / Amb`；Web 导出的音频驱动在初始化时只按布局建了 `Master`，之后新建的总线在浏览器里没有接到输出。游戏所有声音都走这三条总线，于是全程静音；桌面版因为原生音频服务器会自动接好，所以一切正常。
- **怎么定位的**：页面内 AnalyserNode 测到 RMS 0.128（图里有声音），**同时**从 Windows 音频会话读到 `msedge` 峰值 0.0000；在同一 AudioContext 里塞一个 660 Hz 测试音，系统峰值立刻 0.30 —— 把范围压到「总线没接输出」。
- **修复**：新增 `default_bus_layout.tres`（Master / Music / SFX / Amb，子总线 send 到 Master）并在 `project.godot` 注册；`Sfx` 的兜底创建保留。
- **验证**：修复后 Windows 混音器峰值 **0.306（本地）/ 0.334（线上）**；线上 E2E 4/4；Godot 门禁 42 文件 0 失败。
- **回归测试**：`tests/unit/audio.test.js`（5 条）守住布局文件、总线名、send 关系与脚本引用。
- **详细记录**：[`audio-diagnosis.md`](audio-diagnosis.md)。

## 3. 两位组外真人实测（已收）

两位都不是写代码的人：A 是组外朋友，在不知道设定的情况下玩；B 是本作的委托人（主玩家），
两份都是**书面稿**，不是我在旁边看着记的。原话保留，不替他们改口。

### A · 组外朋友，2026-11-17，稿子 `修改建议和方案.docx`（6 条）

她把建议写成 Word 交给我，我转述进 `docs/plan.md` §6。**没有全程旁观**，所以下表只写
稿子能证明的东西；"设备 / 浏览器"她没写，我不编。

| # | 她的原话（摘要） | 我改成什么 | 守它的测试 |
| --- | --- | --- | --- |
| 1 | 瞭望台进 CG 后没有提示怎么退出 | 山顶栅栏远景底部加「点击屏幕退出」；点击 / E / Esc 关闭，离开再回来重现 | `playthrough.gd` 山顶段的断言 |
| 2 | 船坞储物柜文本换成「7 号观测站并非为了观测夜空，而是（吸引血祭品的陷阱）……」 | 已换；括号内关键词显示为**等长乱码**，不给提示 | `playthrough.gd` 储物柜分支 |
| 3 | 封存文档隐藏文本换成乔瑟夫那段（13 年、车被动手脚、船坞有备用零件） | 已换，成为好结局的唯一书面依据 | `ending_test.gd` |
| 4 | 日期只保留前三任（2013 / 2000 / 1987），我们是第四个；封存档案是 13 年前的今天；摩斯密码做对应改变 | 档案只列三个周期；**编号改为推导**（13 年前本周期第 7 天 + 23:40），不再写死常量 | `ending_test.gd` 的编号推导与存档往返 |
| 5 | （来稿编号从 4 跳到 6，第 5 条缺） | 未处理，已在这一行记明 | — |
| 6 | 除第七日外可随时与床互动；任务没做完时先问「还有没做完的事，现在就要睡觉吗？」；这样睡过的天数 ≥4（含第 6 天）→ 第六日入睡后进 UFO 彩蛋结局，两张 CG | 已实现：床随时可用、未完成先问、彩蛋结局与两张 CG | `ufo_test.gd`、`dream_test.gd` |

她没有报任何崩溃或报错。**她最直接改变的是正典**：日期、档案、摩斯三件事一起动，
这也是后来把编号改成推导的原因——写死的常量会在下一次改日期时悄悄错掉。

### B · 委托人（主玩家），2026-11-16，稿子《游玩报告与改进》24 条

24 条里影响最大的四条：

| 她的原话（摘要） | 我改成什么 | 守它的测试 |
| --- | --- | --- |
| 「你搞混了后几天中汇报答 yes/no 的含义……哪怕你确认回答 yes，在后面也会被红字强制改为 no」 | **整个汇报弧线是反的**：站点要的是 No，Yes 被感谢后改写为 No，Day 6 起只接受 No | `tests/unit/canon.test.mjs`（回答语义）+ `ending_test.gd` |
| 「第七日流程有些引导不明」 | 第七日强制行走原按速度累加位置，长帧会越过目标反复折返、永久卡住（`REPAIR_LOG.md`）。改 `move_toward` | `motion_test.gd`，24 项，6 种帧间隔 |
| 「去掉所有有关"眼睛"的设计，包括结局 cg 图」 | 全部删除，血色教堂改为正视中央单塔 | 视觉审阅（无自动断言，已知） |
| 「我要玩家几乎不可能拿到 5000 分」 | HOMEWARD 改为 2000 分到教堂，5000 分那条线删除 | `tools/sim_minigame.py` 平衡模拟 |

另有一条不是稿子里的、而是**线上实测**报的：网页版全程没有声音（本文件 I6）。
定位过程是页面内 AnalyserNode 读到 RMS 0.128，而 Windows 混音器读 `msedge` 峰值 0.0000，
两边夹出「运行时新建的音频总线没接输出」；修复后峰值 0.306（本地）/ 0.334（线上）。

> 两条限制，写在这里免得后来自我美化：
> ① A 的稿子**没有**设备 / 浏览器 / 试到哪一天的记录，我只有文字建议；
> ② B 是我的委托人，不是陌生人——她最熟悉本作，所以"第二次游玩会不会仍然恐怖"这件事，
> 这两份材料都回答不了。

## 4. 把一条反馈变成永久测试

1. **先复现**：用朋友的原话在本地重放（同分辨率、同浏览器、同语言）。
2. **归类**：是逻辑（状态机/判定）、文案（缺键/语气）、还是部署（缓存/加载）？
3. **落层**：
   - 逻辑 → `tests/*.tscn`（Godot 无头，能直接断言游戏状态）或 `tests/unit/*.test.js`（常量/交叉引用）；
   - 文案 → `tests/unit/copy.test.js`（键覆盖、双语同步）；
   - 部署/加载 → `tests/e2e/smoke.spec.js`（真浏览器）；
   - 只对构建产物成立 → `tests/unit/build.test.js`。
4. **先让测试红**：确认它能抓住这个 bug（把修复临时撤掉跑一次）。
5. **再修**，跑绿，提交时把「反馈原话 + 测试名」写进 commit message。

## 5. 还没解决 / 需要用户确认

- A 的稿子只有文字建议，没有设备、浏览器与试玩时长记录（她本人没写，我不补）。
- I1 的英文文案是我按设计文档补的，需要用户确认语气。
- 第 5 天机房人影、第 7 天行进这两段在低帧率设备上的手感，只有真人玩才能判断，自动化只能保证「不卡死」。
- 两位都不算陌生人：A 认识委托人，B 就是委托人。**真正的陌生玩家测试仍然没有做**，这是本作最后一块空白。
