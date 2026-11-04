# 书目与检索记录 · 观测站日志

纯 Markdown，不使用文献管理软件。每一条都记录：**怎么找到的**、**实际读了什么**、
**哪些还只是线索**。未读过的搜索结果只是线索；只有读过的段落才是发现。

检索途径：**OpenAlex works API**（`https://api.openalex.org/works`），按课程
[scholarly-search 技能](../../../../.opencode/skills/scholarly-search/SKILL.md)的要求执行。
没有自动化检索 Google Scholar。

---

## 一、检索记录

| 日期 | 查询词（原样） | 途径 | 结果 |
| --- | --- | --- | --- |
| 2026-11-04 | `search=scientific objectivity atlas observation` | OpenAlex API，5 条 | **有效。** 首条即 Daston, "On Scientific Observation"（*Isis*, 2008）。另返回关于彗星 3I/ATLAS 的天文论文——"atlas"一词把实体地图集也拉了进来。 |
| 2026-11-04 | `search=bureaucratic documents forms knowledge paperwork` | OpenAlex API，5 条 | **方向错误。** 返回移民与殖民行政的人类学研究（Sağlam 2024；Geoffrion & Cretton 2021；Ning 2022；Siddique 2016；Abrams 2016）。没有一项讨论"文件作为知识媒介"。仅作为背景线索保留。 |
| 2026-11-04 | `filter=title.search:paper knowledge` | OpenAlex API，2 条 | **命中。** Gitelman, *Paper Knowledge*（Duke UP, 2014），专著与编著两条记录。 |
| 2026-11-04 | `filter=title.search:the weird and the eerie` | OpenAlex API，2 条 | **命中。** Fisher, *The Weird and the Eerie*（Goldsmiths 机构库记录，2017），以及 B. G. Woodard 在 *Textual Practice* 的书评。 |
| 2026-11-04 | `works/W1953000548?select=...,abstract_inverted_index,biblio` | OpenAlex API，单条 | **已读。** Daston 摘要全文，以及卷、期、页码。 |

**没来得及试、下一步该试的**：`scientific observation trained judgement`、
`forms and formalization media`、`idle game labour repetition`、
`walking simulator landscape`、`cosmic horror indifference nature`。

**一条方法论教训。** 概念检索（"paperwork"）给的是语境，书名检索给的是论证。第二次
查询失败，而第三次查询（已知书名）成功——这个差别值得写进展示，因为它说明了"检索"
本身不是中立的。

---

## 二、读过的工作

### Daston, Lorraine. "On Scientific Observation." *Isis* 99, no. 1 (2008): 97–110. DOI [10.1086/587535](https://doi.org/10.1086/587535). OpenAlex [W1953000548](https://openalex.org/W1953000548).

**已读**：完整摘要（第 97 页）。**未读**：正文——文章在付费墙后，我没有取得。

**设计文档中实际使用的定位：**

- "a turn toward ontology — more specifically, toward ontologies created and sustained
  by observation"（摘要，第 97 页）。
- 对四十年来共同关切的概括："interaction of subjective and objective factors in
  scientific inquiry"（摘要，第 97 页）。

**相关性**：星图机制——观察是被维持的，而不是被接收的。

**状态**：**部分阅读**。足以支撑摘要层面的引用；**不足以**对文章正文做任何论点归属。

---

## 三、已确认存在但尚未阅读（线索）

### Gitelman, Lisa. *Paper Knowledge: Toward a Media History of Documents*. Durham, NC: Duke University Press, 2014. DOI [10.1215/9780822376767](https://doi.org/10.1215/9780822376767). OpenAlex [W4245455745](https://openalex.org/W4245455745).

**状态：线索。** 元数据已对 OpenAlex 记录与 DOI 双重核实。正文未读。

**为什么列它**：汇报表格是本作的核心机制，而 Gitelman 是"文件作为媒介而非容器"这一
思路最直接相关的学者。

**展示前必须核实**：关于"表单（forms）"的具体主张，以及章、页。**在核实之前不要引用
这本书。**

### Fisher, Mark. *The Weird and the Eerie*. London: Repeater, 2016. OpenAlex [W2799136475](https://openalex.org/W2799136475)（Goldsmiths 机构库记录标为 2017）。

**状态：线索。** OpenAlex 记录把存放稿标为 2017，而此书通常被引为 2016。**引用前须向
出版社核实年份。** 正文未读。

**为什么列它**：北方观测站作为 eerie 环境；以及"恐怖可以是结构性的而非怪物性的"
这一主张。

**展示前必须核实**：weird / eerie 区分的准确措辞及其页码。**核实之前不要引用。**

### Woodard, Benjamin Graham. "The Weird and the Eerie." *Textual Practice* 31 (2017). DOI [10.1080/0950236X.2017.1358704](https://doi.org/10.1080/0950236X.2017.1358704).

**状态：线索。** 核实 Fisher 时发现。这是对 Fisher 的**书评**，不是第四个立场。如果
原书始终无法取得，它可能是获取该书论证概要最省的途径——但书评是二手转述，引用时必须
说明其性质。

---

## 四、可获取性核查（对应研究日志 2026-11-04「分配阅读」）

| 文献 | 获取途径 | 结果 |
| --- | --- | --- |
| Daston 2008 | 出版商页面 + OpenAlex 摘要索引 | 摘要可得，正文付费墙 |
| Gitelman 2014 | Duke UP；无开放获取版本 | **未取得** |
| Fisher 2016 | Repeater；Goldsmiths 机构库仅封面 | **未取得** |

---

## 五、未采用的背景线索

以下来自第二次（失败的）查询，**不构成本项目论证的一部分**，记录在此是为了让检索历史
保持诚实：

- Sağlam, Erol. "Paperwork as statecraft…" *Third World Quarterly* (2024). DOI [10.1080/01436597.2024.2387817](https://doi.org/10.1080/01436597.2024.2387817)
- Geoffrion, Karine, and Viviane Cretton. "Introduction: Bureaucratic Routes to Migration…" *Anthropologica* 63, no. 1 (2021). DOI [10.18357/anthropologica6312021184](https://doi.org/10.18357/anthropologica6312021184)
- Ning, Rundong. "Bureaucratic valves…" *Africa* (2022). DOI [10.1017/S0001972022000328](https://doi.org/10.1017/S0001972022000328)
- Abrams, Thomas. "Disability and Bureaucratic Forms of Life." *Nordic Journal of Science and Technology Studies* 3, no. 1 (2016). DOI [10.5324/njsts.v3i1.2153](https://doi.org/10.5324/njsts.v3i1.2153)

其中 Abrams 最接近我的问题（表单与生活经验），如果再多一天，我会先读它。

---

## 六、引用规范

1. 只对**已读**的段落做引用或论点归属，并给出页码或章节。
2. 未读的工作一律标为 **线索（Lead）**，在展示中口头说明。
3. 不编造引文、页码或出版年。
4. 二手转述（如书评）必须标明其为二手。
