---
framework: react
theme: exhibit
title: "观测站日志 — 表格比观察活得更久"
routerMode: hash
layout: cover
kicker: DAIHUM · 第九週 · 將你的 AI 設計放進學術討論
meta: 十分鐘展示
duration: 10min
timer: countdown
---

# 观测站日志

表格比观察活得更久。

::by::

一款七日制像素恐怖游戏：你在给一片正在变化的天空填表。

<!--
0:00–0:40 · 40 秒

一句话讲完，不要念幻灯片。

「我做了一款七日制游戏。你是偏远观测站的新看守。每天加油、打水、调天线、
记录星图、填一张汇报表。天空在变，表格没变。」

然后把问题抛出来：当一份记录所记录的东西不再可被记录时，这份记录会怎样？
-->

---
kicker: 问题
---

# 当一份记录所记录的东西不再可被记录时，这份记录会怎样？

<div class="body col">
<div class="frame hot"><span class="label">我要论证的主张</span><div class="text">表格比观察活得更久。玩家已经无法诚实观看，而机构的仪器照样收下 <mark>Yes</mark>，日子照样推进，记录照样看起来完整。</div></div>
</div>

::foot::

设计五个部分 · 三项学术文献 · 一个主张 · 技术栈

<!--
0:40–1:00 · 20 秒

这就是论点，后面全部是它的证据。
现在把结构讲清楚：设计五个部分、三篇文献、一个主张，最后讲技术栈。
-->

---
kicker: 一 · 情节 — 七日循环
---

# 例行公事本身就是内容。

<div class="body col">
<img src="/obs/antenna.png" alt="调整天线" style="height: 225px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">① 设计是什么</span><p>每天五个节点，强制按序：加油 → 打水 → 调天线 → 记录星图 → 提交汇报。完成前两道分别转黄昏、转夜晚。<b>观测永远在天黑之后。</b></p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">② 意义</span><p>奇观被刻意扣留。重复到某一天，重复本身成为内容——异常不是事件，是文档里的一处漂移。</p></div>
<div class="row hot" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">③ 学者</span><p><b>Daston</b>：观察是「被创造并维持的本体论」，是维持，不是接收。</p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">④ 我的贡献</span><p>把「维持」做成可操作的东西：玩家每天亲手重画同一片天空。</p></div>
</div>
</div>

::foot::

接口刻意不戏剧化：加油是长按，打水是单次按键，调天线只有 ±3 度容差和 `SEARCHING / LOCKED` 两种读数。

<!--
0:40–2:00 · 80 秒

是什么：北方针叶林里的观测站。雪、树、湖、碟形天线、一间小屋、一个人。
能做什么：几乎没有戏剧性动作。长按加油、按键打水、把天线转到 LOCKED、看一张星图、填一张表。
为什么：扣留奇观，让重复被感受为劳动。
意义：异常不是事件，是文档里的一处漂移。
学者：Daston。
贡献：把「维持」做成可操作的动作。
-->

---
kicker: 二 · 机制 — 汇报表格
---

# 表格不是菜单，是一台有偏好的仪器。

<div class="body col">
<img src="/obs/report.png" alt="汇报表格" style="height: 225px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">① 设计是什么</span><p>一个问题、两个按钮。第一至五天：两个答案都推进，但 <b>No 会多出工作</b>——第三天出门检修天线，第四天擦屏幕、吃安眠药。</p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label red">第六至七天</span><p>输入框拒绝 Yes 以外的一切，红字 <mark>Type Yes</mark>，并把被拒的答案<b>留在框里</b>。</p></div>
<div class="row hot" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">③ 学者</span><p><b>Gitelman</b>：文件是有自身历史的媒介类型，而不是知识的容器。<i>（线索：记录已核实，正文未读）</i></p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">④ 我的贡献</span><p>表格不是通往异常的窗口，而是决定「什么才算异常」的东西；当观察失效，它仍在工作。</p></div>
</div>
</div>

<!--
2:00–4:00 · 2 分钟 —— 最长也最重要的一页。

这是我最有把握的设计，也是论点所在。
1–5 天：两个答案都能推进，但不是同一天。No 要付出劳动。
6–7 天：表格有了偏好。它不接受 No，还把被拒的文字留在框里，你得先删掉才能再答。

学者：Gitelman。必须明说「这是线索，我核实了记录，还没读到正文」。
然后给出我要拿它检验的主张：表格不是窗口，而是决定什么算异常的装置。

现在把贡献讲掉：表格比观察活得更久。
不是「机构是盲的」（那是主题），而是「仪器在操作者停下之后仍然工作」（这是玩家亲手操作的机制）。
-->

---
kicker: 三 · 画面 — 星图是唯一证据
---

# 天上什么都看不见。异常只出现在星图里。

<div class="body col">
<img src="/obs/starchart.png" alt="星图" style="height: 225px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">① 设计是什么</span><p>固定星场、一条地平线、一颗逐日变化的星体：第 3 天 6 px，第 4 天 10 px，第 5 天 28 px，第 6 天 60 px，<b>第 7 天 160 px</b>。天空里从不渲染它。</p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">② 意义</span><p>记录不是天空的替代品，而是<b>唯一让异常可见的装置</b>。</p></div>
<div class="row hot" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">③ 学者</span><p><b>Daston</b>（摘要，第 97 页）：「ontologies created and sustained by observation」。</p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">④ 我的贡献</span><p>坦白说：这最初是 320×180 画不出天体的偷懒，后来发现它才是对的设计。</p></div>
</div>
</div>

::foot::

Daston 2008，*Isis* 99(1): 97–110，摘要第 97 页。正文在付费墙后，未读。

<!--
4:00–5:40 · 100 秒

先坦白来源：我画不出可信的星体，所以把异常放进了星图。然后这个偷懒变成了更好的设计。
玩家确实看见了异常——只是在自己画的星图上，作为工作的一部分。他们做不到的是在别处看见。
Daston：观察是被维持的；星图就是这种维持的可见形式。原句念一遍，页码说出口：第 97 页。
偏离之处：Daston 讲的是共同体训练一只集体的眼睛；我的站里只有一个人，训练手册是一个 txt。
-->

---
kicker: 四 · 环境 — eerie
---

# 恐怖是结构性的，不是怪物性的。

<div class="body col">
<img src="/obs/flesh.png" alt="第六天的血肉" style="height: 225px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">① 设计是什么</span><p>雪、针叶林、湖、一间小屋、一只碟形天线。没有别人。一个离开的前任。一份内容就是等待的工作。第五天暴雨，第六至七天血肉覆盖全世界。</p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">② 意义</span><p>本该有人的地方空着。恐怖来自缺席，而不是来自某个不该存在的东西。</p></div>
<div class="row hot" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">③ 学者</span><p><b>Fisher</b>：eerie 是「本该空无之处却有东西，或本该有东西之处却空无」。<i>（线索：正文未读，措辞待核）</i></p></div>
<div class="row" style="grid-template-columns: 165px 1fr; padding: 8px 0"><span class="label">④ 我的贡献</span><p>这里的 eerie 由例行公事产生：真正让人不安的，是一张仍在运作的表格。</p></div>
</div>
</div>

::foot::

Fisher 2016，*The Weird and the Eerie*，Repeater。OpenAlex 记录标 2017，引用前须核实年份。

<!--
5:40–7:00 · 80 秒

这座站几乎完全由缺席搭成。这是 Fisher 的 eerie，不是 weird：没有不该存在的怪物，
只有一个本该有人的位置，空着。
必须把阅读状态说出口：「Fisher 对我仍是线索。」这比被问出来强。
贡献：恐怖来自例行公事——玩家害怕的是那张表格还在工作。
-->

---
kicker: 五 · 角色 — 反形式
---

# 游戏性是表格记录不了的东西。

<div class="body col">
<div class="route">
<div class="step"><span class="yr">第一天</span><p class="what">三个图标</p><p class="how">须知 · 星图 · 汇报</p></div>
<div class="arrow">→</div>
<div class="step red"><span class="yr">第二天</span><p class="what">第四个凭空出现</p><p class="how">沾血的羊头骨 · 没有安装过程 · 没有解释</p></div>
</div>
<div style="display: flex; gap: 56px; flex: 1; min-height: 0; align-items: center;">
<img src="/obs/gift.png" alt="The Gift of X" style="height: 290px; width: auto; image-rendering: pixelated; border: 1px solid #333;" />
<div class="frame" style="flex: 1;"><span class="label">THE GIFT OF X</span><div class="text">桌面里可玩的街机小游戏：一条船、礁石、分数。它是全游戏唯一会给玩家一个<b>他想要的</b>数字的界面。</div></div>
</div>
</div>

<!--
7:00–8:00 · 60 秒

第二天，一个图标凭空出现，没有安装、没有解释、没有人评论。它是个可玩的街机游戏。
游戏里其他每个数字都是替别人记的：多少升油、天线几度、一张星图。只有这个数字是给玩家的。
贡献：它不是彩蛋，而是反形式——衡量汇报的那把尺子。
如果被问是否叙事内：是，它就跑在桌面窗口里。
-->

---
kicker: 学术对话的位置
---

# 三项文献，各自给了设计什么。

| 文献 | 它的论点 | 对我的设计做了什么 | 阅读状态 |
|---|---|---|---|
| **Daston**，〈On Scientific Observation〉，*Isis* 99:1 (2008), 97–110 | 观察在维持一套本体；此前的争论是探究中主观与客观因素的互动 | 星图：观察是被维持的实践，不是接收 | **已读摘要**（第 97 页），正文付费墙 |
| **Gitelman**，*Paper Knowledge*，Duke UP (2014) | 文件是一种媒介类型，不是中立的容器 | 汇报表格决定「什么才算异常」 | **线索**，记录已核实，正文未读 |
| **Fisher**，*The Weird and the Eerie*，Repeater (2016) | eerie：本该空无之处却有东西，或反之 | 恐怖来自例行公事，而非怪物 | **线索**，记录已核实，正文未读 |

::foot::

检索途径与逐条查询词见 `research/references/bibliography.md`。

<!--
8:00–8:40 · 40 秒

不要念表格。指着第三列说：一篇给我实践，一篇给我仪器，一篇给我气氛——
而我的机制就压在这三者之间的接缝上。
阅读状态要说清楚，这是诚实，也是准备充分的表现。
-->

---
kicker: 我的贡献
---

# 是机制，不是主题。

<div class="body col">
<div class="frame hot"><span class="label">三项文献还没解释的</span><div class="text">Daston 与 Gitelman 都把观察与记录描述为<b>集体</b>成就。我的观测站只有一个人。当维持这些实践的人只剩一张表格时，它们会变成什么？</div></div>
<div class="frame"><span class="label red">设计给出的回答</span><div class="text">玩家把答案体验为一个<b>不肯接受 No 的按钮</b>。这不是「机构是盲的」的陈述，而是「仪器在操作者停下之后仍然工作」的演示。</div></div>
</div>

<!--
8:40–9:00 · 20 秒

留给教室的那句话：「表格比观察活得更久。」
如果有人问「这不就是个主题吗？」——答案是机制。主题是被陈述的，这个是被操作的。
按下 Yes 成为唯一按钮的那一刻，鼠标在玩家手里。
-->

---
kicker: 研究方法
---

# 检索记录本身也是论证的一部分。

| 查询 | 结果 |
|---|---|
| `scientific objectivity atlas observation` | **命中** Daston（*Isis*, 2008） |
| `bureaucratic documents forms knowledge paperwork` | **失败**：返回移民与殖民行政的人类学，不是「文件作为媒介」 |
| `title.search:paper knowledge` | **命中** Gitelman（Duke, 2014） |
| `title.search:the weird and the eerie` | **命中** Fisher（Repeater, 2016） |

> 检索**一个概念**给的是语境；检索**一部已知著作**给的是论证。第二次查询失败，第三次成功——这个差别我写进了研究日志。

::foot::

全部经 OpenAlex works API 完成；未使用简单网页检索。逐条查询与可获取性核查见书目。

<!--
9:00–9:30 · 30 秒

这一页是方法，不是设计。保留它是因为它诚实地展示了课程要求的研究流程：
检索、记录、失败、修正。失败的查询我没有删掉。
-->

---
kicker: 技术栈
---

# 用了什么，能做什么，卡在哪里。

| 技术 | 作用 | 为什么选它 | 局限 |
|---|---|---|---|
| **Godot 4.7.2 / GDScript** | 引擎与全部逻辑 | 免费、可脚本化、2D 强，且有**无头模式**可不开窗口跑测试 | 边界处类型松散，部分错误只在运行时暴露 |
| **程序化绘制** | 几乎全部美术 | 像素锁在 320×180 网格上；每个元素都是带参数的函数，因此可测 | 无着色器管线 → 第四天的「模糊」其实是撕裂拖影 |
| **固定虚拟分辨率** 320×180 / 桌面 640×360 | 构图 | 让「玩家居中」「地面行固定」成为**构造保证**而非事后检查 | 10 px 以下文字不可读；桌面须切换视口 |
| **测试门禁** | 正确性 | 414 项模块检查 + 112 项完整七日通关 + 像素级移动规则测试 | 读回像素的两道门禁必须开窗口 |
| **缺失：音频** | — | — | 全程无声；是缺口，不是选择 |

<!--
9:30–9:50 · 20 秒

用自己的话讲，不要念表。
为什么 Godot：免费、可脚本化，而且无头模式让我能不开窗口证明整个七日循环的门控顺序不能被打乱。
为什么程序化美术：320×180 下每个元素都要落在像素网格上，用代码画就没有素材管线、没有滤波伪影，而且每个元素都是可测的函数。
诚实的局限：没有着色器，所以第四天不是真模糊；完全没有音频——记成缺口，不当艺术选择讲。
-->

---
kicker: 收尾
---

# 表格比观察活得更久。

<div class="body col">
<div class="frame"><span class="label">我还欠这个论证的三件事</span><div class="text">① 把 Gitelman 与 Fisher 真正读完，各找到一段带页码的原文。<br />② 验证沉默是气氛，还是只是没做完。<br />③ 搞清楚玩家会把「强制 Yes」读成<mark>论点</mark>，还是读成 bug。</div></div>
</div>

::foot::

谢谢，欢迎提问。

<!--
9:50–10:00

用那句话收尾，然后立刻主动说出三件没做完的事。自己认领缺口，比被问出来强。

可能的问题：
1「为什么做游戏不做论文？」——因为这个主张讲的是被操作的仪器。论文能告诉读者表格拒绝 No，游戏让玩家自己撞上它。
2「小游戏是玩笑吗？」——不是，它是反形式，是唯一给玩家他想要的数字的界面。
3「强制 Yes 不就是糟糕 UX？」——有可能，而且这是设计文档里的未决问题。如果它被读成 bug，论证就失败，那我就得让「拒绝」可读，而不是靠解释。
-->
