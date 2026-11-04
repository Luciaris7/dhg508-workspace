# 书目与检索记录 · 观测站日志

纯 Markdown，不使用文献管理软件。每条都记录：**怎么找到的**、**实际读了什么**、
**哪些还只是线索**。未读过的搜索结果只是线索；只有读过的段落才是发现。

检索途径：**OpenAlex works API**（`https://api.openalex.org/works`），按课程
[scholarly-search 技能](../../../../.opencode/skills/scholarly-search/SKILL.md)的要求执行。
本项目的第三篇（洛夫克拉夫特）是**公有领域全文**，直接读取，不是检索结果。

---

## 一、三项文献的分工

拆解恐怖需要三种不同的东西，各由一篇承担：

| 需要什么 | 用哪篇 | 作用 |
| --- | --- | --- |
| **文化来源**：这套恐怖从哪个传统来 | 洛夫克拉夫特（1927） | 宇宙恐怖的宣言：恐惧来自未知，气氛重于情节 |
| **机制分析**：恐怖作为类型如何运作 | Carroll（1990） | 艺术恐怖（art-horror）与"不纯"的怪物：类型越界 |
| **当代范畴**：缺席为什么会吓人 | Fisher（2016） | weird 与 eerie 的区分 |

---

## 二、检索记录

| 日期 | 查询词（原样） | 途径 | 结果 |
| --- | --- | --- | --- |
| 2026-11-04 | `filter=title.search:philosophy of horror` | OpenAlex API，3 条 | 只返回对 Carroll 该书的**书评**（*MLN* 1991；*Philosophical Quarterly* 1991）与 Fahy 的编著。专著本身未被索引为独立记录。 |
| 2026-11-04 | `filter=title.search:the weird and the eerie` | OpenAlex API，2 条 | **命中** Fisher（Goldsmiths 机构库，2017）及 Woodard 书评。 |
| 2026-11-04 | 直接读取 `hplovecraft.com/writings/texts/essays/shil.aspx` | 公有领域全文 | **已读全文**（约 2.6 万词）。见下节定位。 |

**此前失败的查询（保留记录）**：`bureaucratic documents forms knowledge paperwork` 返回移民
与殖民行政人类学，与"恐怖机制"无关，已弃用。这个失败促成了本次方向调整——我原来把项目
当成"官僚客观性"来论证，而它其实是**恐怖**。

---

## 三、读过的工作

### Lovecraft, H. P. "Supernatural Horror in Literature." 1927. 全文见 [hplovecraft.com](https://www.hplovecraft.com/writings/texts/essays/shil.aspx)。

**已读**：全文。**定位方式**：该文分节（I. Introduction；II. The Dawn of the Horror-Tale……），
以下引文均出自**第一节（I. Introduction）**，按段落顺序标注。

**设计文档中实际使用的段落：**

- **第 1 段**：「The oldest and strongest emotion of mankind is fear, and the oldest and
  strongest kind of fear is fear of the unknown.」
- **第 6 段**：「A certain atmosphere of breathless and unexplainable dread of outer,
  unknown forces must be present; and there must be a hint … of that most terrible
  conception of the human brain—a malign and particular suspension or defeat of those
  fixed laws of Nature which are our only safeguard against the assaults of chaos and
  the daemons of unplumbed space.」
- **第 7 段**：「Atmosphere is the all-important thing, for the final criterion of
  authenticity is not the dovetailing of a plot but the creation of a given sensation.」
- **第 7 段**：「The one test of the really weird is simply this—whether or not there be
  excited in the reader a profound sense of dread, and of contact with unknown spheres
  and powers; a subtle attitude of awed listening…」

**相关性**：机制二（不可知）与整款游戏的"不解释"原则。

---

## 四、已确认存在但尚未阅读（线索）

### Carroll, Noël. *The Philosophy of Horror, or Paradoxes of the Heart*. New York: Routledge, 1990.

**状态：线索。** OpenAlex 只索引到两篇书评（W1983208800, *MLN* 1991；W3216584098,
*Philosophical Quarterly* 1991），专著本身未作为独立记录收录。书名、作者、年份经两篇书评
交叉确认；**正文未读**。

**预期取用**：Carroll 把恐怖定义为一种由「不纯的」怪物——同时属于两个互斥范畴的存在——
所引发的「艺术恐怖（art-horror）」。我的「血肉教堂」（建筑 + 血肉）与血星（天体 + 神性）
正是这种范畴越界。

**展示前必须核实**：这个定义的具体表述与页码。**核实前不要引用。**

### Fisher, Mark. *The Weird and the Eerie*. London: Repeater, 2016. OpenAlex [W2799136475](https://openalex.org/W2799136475)（Goldsmiths 记录标 2017）。

**状态：线索。** 年份存疑（Repeater 版通常引作 2016，机构库记录为 2017），引用前须核实。
正文未读。

**预期取用**：weird = 本不该存在的东西；eerie = 本该空无之处却有东西，或本该有东西之处
却空无。我的观测站属于后者。

**展示前必须核实**：区分的准确措辞与页码。

### Woodard, Benjamin Graham. "The Weird and the Eerie." *Textual Practice* 31 (2017). DOI [10.1080/0950236X.2017.1358704](https://doi.org/10.1080/0950236X.2017.1358704).

**状态：线索。** 对 Fisher 的书评，不是第四个立场。若原书无法取得，可作为二手概要——
引用时必须标明其性质。

---

## 五、文化来源（非学术文献，但构成设计的历史语境）

这些不是学术论证，而是设计时明确参照的文化材料，单独列出以免与学术文献混淆：

| 材料 | 对设计的作用 |
| --- | --- |
| 《启示录》8:10–11（苦艾星从天上坠落）、6:12（月变血） | 结局的血星与「BEHOLD HER THRONE, LAMB」的末世图像 |
| 北极／孤岛恐怖传统：*The Thing*（1982）、*The Shining*（1980）、*The Lighthouse*（2019） | 观测站的空间设定：被隔绝的设施、一个人、外部威胁 |
| 哥特小说传统（Walpole 以降的"闹鬼城堡"） | 观测站是当代版本的哥特城堡：一座有历史、有前任、有秘密的建筑 |
| Analog horror／家用电脑恐怖 | XP 桌面作为恐怖发生的界面 |
| 规则怪谈（rules-based internet horror） | 「工作须知」作为一套必须遵守、但无法完全遵守的规则 |

---

## 六、引用规范

1. 只对**已读**的段落做引用或论点归属，并给出页码／章节／段落定位。
2. 未读的工作一律标为 **线索（Lead）**，在展示中口头说明。
3. 不编造引文、页码或出版年。
4. 二手转述（如书评）必须标明其为二手。
