# 书目与检索记录 · 观测站日志

本项目的来源分两类，必须分开记：

- **文化来源 = 七款游戏。** 灵感来自玩过的游戏，不是文献。它们是我的**一手参照**。
- **分析工具 = 三篇游戏研究。** 它们不解释灵感从哪来，只解释这些手法**为什么有效**。

未读过的搜索结果只是线索；只有读过的段落才是发现。

检索途径：**OpenAlex works API**（`https://api.openalex.org/works`），按课程
[scholarly-search 技能](../../../../.opencode/skills/scholarly-search/SKILL.md)的要求执行。

---

## 一、七款游戏（文化来源，一手参照）

| 游戏 | 年份 | 开发者 / 平台 | 它给了《观测站日志》什么 | 落在哪个机制 |
| --- | --- | --- | --- | --- |
| **Iron Lung 铁肺** | 2022 | David Szymanski · PC | 低信息获取 + 克苏鲁式恐惧。**直接移植**：拍照 → 星图记录 | ① 低信息 |
| **I Have No Mouth, and I Must Scream 无声狂啸** | 1995 | Cyberdreams · PC（原著 Harlan Ellison） | 无法逃脱的注定：结局已写好，努力从一开始无效 | ② 不可逃脱 |
| **Fears to Fathom 溯源之惧** | 2021–2023 | Rayll · PC | 日常生活里的异常感：普通的一晚，然后有件事开始不对 | ③ 日常的异常 |
| **Firewatch 看火人** | 2016 | Campo Santo · PC | 孤独感与隔离感：独守瞭望塔，人声只从无线电里来 | ④ 孤独 |
| **Chilla's Art 系列** | 2018– | Chilla's Art · PC | 低画质带来的恐怖谷效应 + 日常恐怖（便利店、公寓、夜班） | ⑤ 低画质 |
| **Sally Face** | 2016–2019 | Portable Moose · PC | 屏中屏：角色掏出一台 GameBoy，真的能玩。**直接移植**：我的桌面小游戏 | ⑤ 界面内的小游戏 |
| **Silent Hill 寂静岭系列** | 1999– | Konami · 多平台 | 心理恐怖：怪物长在角色的罪与恐惧上，被审视的是角色 | ⑥ 内在的恐怖 |

**两处直接移植**（不是"受到影响"，是照着做的）：

1. **铁肺的拍照 → 我的星图。** 铁肺用一台老相机拍下外部、只能看模糊照片；我的玩家
   每天把异常画进星图，也只能从这张图上知道它变大了。
2. **Sally Face 的 GameBoy → 我的桌面小游戏。** 我的站内电脑里有一个能真的玩的街机游戏
   *The Gift of X*，第二天凭空出现。

---

## 二、三篇游戏研究（分析工具）

### Kirkland, Ewan. "Gothic Videogames, Survival Horror, and the *Silent Hill* Series." *Gothic Studies* 14, no. 2 (2012): 106–122. DOI [10.7227/gs.14.2.8](https://doi.org/10.7227/gs.14.2.8). OpenAlex [W2021746490](https://openalex.org/W2021746490).

**已读**：完整摘要（第 106 页）。**未读**：正文——付费墙。

**摘要中的实际定位。** 论文考察哥特传统在生存恐怖游戏中的运作，并讨论寂静岭的叙事、
美学与玩法与哥特的关系；摘要列出四个关切：**阴森异世界的侵入**、**碎裂的叙事形式**、
**过去侵入现在的感觉**、以及**精神分析维度**（第 106 页）。

**接在我的哪条机制上。** ③ 日常的异常（异世界侵入日常空间）与 ⑥ 内在的恐怖。

**状态：部分阅读。** 可引摘要；不可对正文做任何论点归属。

### Costikyan, Greg. *Uncertainty in Games*. Cambridge, MA: MIT Press, 2013. OpenAlex [W1585564431](https://openalex.org/W1585564431).

**状态：线索。** 记录已核实（MIT Press, 2013），正文未读。

**为什么列它**：我的机制一（低信息）需要一套关于"不确定性如何产生张力"的说法，这本书是
游戏研究里最直接的一本。

**展示前必须核实**：他对不确定性的分类、以及"信息不足"在其中的位置与页码。
**核实前不引用。**

### Stobbart, Dawn. *Videogames and Horror: From Amnesia to Zombies, Run!* Cardiff: University of Wales Press, 2019. DOI [10.2307/jj.14491610](https://doi.org/10.2307/jj.14491610). OpenAlex [W4396603958](https://openalex.org/W4396603958).

**状态：线索。** 记录已核实（University of Wales Press, 2019），OpenAlex 无摘要，正文未读。

**为什么列它**：机制二（不可逃脱）需要一套关于"玩家的能动性如何被剥夺"的说法。

**展示前必须核实**：她关于能动性与恐怖关系的具体表述与页码。**核实前不引用。**

---

## 三、检索记录

| 日期 | 查询词（原样） | 途径 | 结果 |
| --- | --- | --- | --- |
| 2026-11-04 | `filter=title.search:uncertainty in games` | OpenAlex，2 条 | **命中** Costikyan（MIT Press, 2013）。另一条是 *Library Journal* 的书评。 |
| 2026-11-04 | `filter=title.search:videogames and horror` | OpenAlex，2 条 | **命中** Stobbart（2019）**与** Kirkland 的寂静岭论文（*Gothic Studies* 2012）。一次查询同时拿到两篇。 |
| 2026-11-04 | `works/W2021746490?select=...abstract_inverted_index` | OpenAlex 单条 | **读** Kirkland 摘要全文与页码（106–122）。 |
| 2026-11-04 | `works/W4396603958?select=...abstract_inverted_index` | OpenAlex 单条 | Stobbart 无摘要字段——因此只能标为线索。 |

**此前的失败方向（保留记录）**：我最初用 `scientific objectivity`、`paperwork`、
`the weird and the eerie` 等查询，把项目论证成"官僚客观性"或"宇宙恐怖理论"。
那些文献本身没问题，**是我对项目的判断错了**——真正的来源是游戏，不是文献。
这一段保留在书目里，因为它解释了为什么现在的框架是"游戏为来源、文献为工具"。

---

## 四、引用规范

1. 游戏作为**文化来源**引用时，给出：名称、年份、开发者、以及"它给了我什么"。
   游戏不是学术文献，不与三篇论文混排。
2. 学术文献只对**已读**的段落做引用或论点归属，并给出页码／章节。
3. 未读的工作一律标为 **线索（Lead）**，展示中口头说明。
4. 不编造引文、页码或出版年。
5. 二手转述（如书评）必须标明其为二手。
