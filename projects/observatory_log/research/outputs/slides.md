---
framework: react
theme: exhibit
title: "观测站日志 — 恐怖的机制，与它来自哪些游戏"
routerMode: hash
layout: cover
kicker: DAIHUM · 第九週 · 將你的 AI 設計放進學術討論
meta: 十分鐘展示
duration: 10min
timer: countdown
---

# 恐怖的机制，与它来自哪些游戏

七款游戏给了我六种制造恐惧的办法。

::by::

单人 · 2D 横版 · 像素 · 七日 · 一个结局

<!--
0:00–0:40 · 40 秒

先纠正一件事，也是我这次重做的原因：

我最初的灵感不是来自文献，是来自我玩过的游戏。
所以这场展示的顺序是——先讲我从哪七款游戏里各拿了一样什么，
再讲它们怎么变成六个机制，最后用三篇游戏研究解释这些机制为什么有效。
-->

---
kicker: 来源
---

# 七款游戏，各给了一样东西。

| 游戏 | 年份 | 它给了我什么 | 落在哪个机制 |
|---|---|---|---|
| **铁肺 Iron Lung** | 2022 | 低信息获取 + 克苏鲁式恐惧 | ① 低信息 |
| **无声狂啸** | 1995 | 无法逃脱的注定 | ② 不可逃脱 |
| **Fears to Fathom** | 2021–23 | 日常生活里的异常感 | ③ 日常的异常 |
| **看火人 Firewatch** | 2016 | 孤独感与隔离感 | ④ 孤独 |
| **Chilla's Art** | 2018– | 低画质的恐怖谷 + 日常恐怖 | ⑤ 低画质 |
| **Sally Face** | 2016–19 | 游戏机里的游戏（屏中屏） | ⑤ 界面内的小游戏 |
| **寂静岭 Silent Hill** | 1999– | 心理恐怖 | ⑥ 内在的恐怖 |

::foot::

三篇学术文献不解释"灵感从哪来"，它们解释**这些手法为什么有效**。

<!--
0:40–1:30 · 50 秒

这一页是整场展示的地基。

注意两件事：
第一，这不是"我喜欢这些游戏"，每一款都对应一个具体机制，右边那列就是对应关系。
第二，文献的位置变了。文献不是我的灵感来源，它们是我用来解释这些手法为什么有效的工具。
所以下面每一页我会先讲游戏，再讲我怎么改，最后才提文献。
-->

---
kicker: 机制一 · 低信息
---

# 你只能通过一台很差的仪器看世界。

<div class="body col">
<img src="/obs/starchart.png" alt="星图" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">① 从哪来</span><p><b>铁肺</b>：你在一艘铁皮潜艇里，看不见外面，只能靠一台老相机拍照，然后看那张模糊的照片判断外面有什么。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">② 为什么有效</span><p>恐惧来自<b>信息不足</b>，而不是来自看见怪物。你永远只能拿到一点点证据，剩下全靠自己想。</p></div>
<div class="row hot" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">③ 我怎么改</span><p>我把"拍照"换成了<b>星图</b>：异常从不画在天空里，只作为星图上的一个圆存在，第 3 天 6 px，第 7 天 160 px。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">④ 文献</span><p><b>Costikyan</b>：游戏之所以有意思，是因为它制造并管理<b>不确定性</b>。<i>（线索）</i></p></div>
</div>
</div>

<!--
1:30–2:30 · 60 秒

铁肺是影响最大的一款。

它的做法是：你在潜艇里，什么都看不见。外面有没有东西，你只能靠拍照。
照片模糊、只有一张、拍完还要等。你拿到的是极少量、极不可靠的信息。

我把它直接换成了星图：天空永远只画星星和月亮，异常只存在于你自己画的星图上。
你每天拿到的是"它变大了"这个事实，但你永远不知道它是什么。

文献上，Costikyan 的不确定性理论正好解释这件事：
游戏的张力来自被管理的不确定性，而不是来自画面。
这本书我还没读到正文，是线索，我明说。
-->

---
kicker: 机制二 · 不可逃脱
---

# 结局已经写好了，你只是不知道什么时候。

<div class="body col">
<img src="/obs/redline.png" alt="第七天红字" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">① 从哪来</span><p><b>无声狂啸</b>：一个全能的 AI 把人类最后的几个人留下来，永远折磨。它不给出口，也不给死。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">② 为什么有效</span><p>恐怖不是"我会不会死"，而是<b>"我知道不会结束"</b>。玩家的努力从一开始就是无效的。</p></div>
<div class="row hot" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">③ 我怎么改</span><p>七天循环本身就是那个牢笼。第六天起表格<b>拒绝 Yes 以外的答案</b>；第七天床失效，玩家被押着走向湖边。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">④ 文献</span><p><b>Stobbart</b>：恐怖游戏把"玩家能动性"本身当作可被剥夺的东西。<i>（线索）</i></p></div>
</div>
</div>

<!--
2:30–3:30 · 60 秒

无声狂啸给我的是一句话：你逃不掉。

那个游戏里，AI 不杀你，它留着你，永远折磨。玩家做的所有事都改变不了这件事。

我的对应做法：七天循环就是牢笼。你每天做同样的事，第六天表格开始拒绝你，
第七天床不让你睡，最后你连走路都不能自己控制，角色被押着走向湖边。

注意这里的恐怖不是"我会不会死"，而是"我知道这事不会结束"。
-->

---
kicker: 机制三 · 日常的异常
---

# 恐怖发生在你还得继续过日子的时候。

<div class="body col">
<img src="/obs/day1_outdoor.png" alt="观测站外景" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">① 从哪来</span><p><b>Fears to Fathom</b>：每一集都是普通人的普通一晚——独自在家、搭车、送外卖——然后有一件事开始不对。<b>Chilla's Art</b>：便利店、公寓、夜班，同样的路子。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">② 为什么有效</span><p>不是"你被扔进了鬼屋"，而是<b>"你的日常还在继续，只是多了一点东西"</b>。日常的持续让异常显得更不对。</p></div>
<div class="row hot" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">③ 我怎么改</span><p>游戏里<b>没有任何一场战斗、追逐或跳吓</b>。你照常加油、打水、调天线、填表——异常只是每天多几个像素。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">④ 文献</span><p><b>Kirkland</b>：日常空间被改写成哥特式空间，是这类作品的核心手法。</p></div>
</div>
</div>

<!--
3:30–4:30 · 60 秒

Fears to Fathom 和 Chilla's Art 教我的同一件事：恐怖不用发生在鬼屋。

Fears to Fathom 每一集都是一个普通人的普通晚上——一个人在家、搭顺风车、送外卖。
Chilla's Art 是便利店、公寓、夜班。

关键不是"你被扔进了一个恐怖的地方"，而是"你的日常还在继续，只是多了一点东西"。
你要接着上班，接着填表，接着睡觉。

我的做法：整款游戏没有战斗、没有追逐、没有跳吓。你就是在过日子。
-->

---
kicker: 机制四 · 孤独
---

# 有人说话，但那个人不在。

<div class="body col">
<img src="/obs/storm.png" alt="暴雨" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">① 从哪来</span><p><b>看火人</b>：一个人守一座瞭望塔，整款游戏只有一个声音——无线电另一头的人。你看不见她。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">② 为什么有效</span><p>声音让孤独变得<b>可测量</b>：你知道有人在，但她不在。孤独不是"没有人"，是"只有声音"。</p></div>
<div class="row hot" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">③ 我怎么改</span><p>全游戏<b>零 NPC</b>。唯一的人声是开场时前任看守的四条语音留言——而那个人已经走了。之后只有字。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">④ 我的取舍</span><p>看火人给了玩家一个活着的对话者；我把她换成了<b>一个已经离职的人</b>。声音还在，人不在。</p></div>
</div>
</div>

<!--
4:30–5:30 · 60 秒

看火人和我的结构几乎同源：一个人守一座塔，整局只有一个声音从机器里出来。

但它给了玩家一个活着的对话者——你可以跟她说话，她每天在。
我做了一个更狠的版本：那个人已经离职了。你听到的是**留言**，不是对话。
四条，讲完就没了。之后全游戏再没有第二个人声。

这个改动让孤独从"有人在但我见不到"变成"那个人已经不在了"。
-->

---
kicker: 机制五 · 低画质与屏中屏
---

# 粗糙的画面本身，和屏幕里的屏幕。

<div class="body col">
<img src="/obs/gift.png" alt="桌面里的小游戏" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">① 从哪来</span><p><b>Chilla's Art</b>：低多边形、低分辨率、VHS 质感——<b>画质本身就是恐怖的一部分</b>。<b>Sally Face</b>：角色在游戏里掏出一台 GameBoy，真的能玩。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">② 为什么有效</span><p>低画质让细节消失，玩家必须自己填补——和机制一同一原理。屏中屏则让恐怖发生在<b>最日常的界面上</b>。</p></div>
<div class="row hot" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">③ 我怎么改</span><p>320×180 固定分辨率。桌面是仿 XP 的，第二天凭空多出一个<b>沾血羊头骨的图标</b>，点开真的能玩。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">④ 我的取舍</span><p>Chilla's Art 的粗糙是"做旧"，我的粗糙是<b>像素尺度的限制</b>——320×180 下每个元素都必须落在网格上。</p></div>
</div>
</div>

<!--
5:30–6:30 · 60 秒

Chilla's Art 教我一件事：画质本身可以是恐怖的一部分。
低多边形、低分辨率、VHS 噪点，让细节消失，玩家只能自己想象。

Sally Face 教的是另一件事：屏中屏。角色在游戏里掏出一台 GameBoy，真的能玩。

我的做法：整个世界 320×180。电脑是仿 XP 的桌面，第二天多出一个图标——一枚沾血的羊头骨，
点开是一个真的能玩的街机游戏。

屏中屏为什么有效：恐怖发生在最日常的界面上。你熟悉那个桌面，所以多出来的东西才不对。
-->

---
kicker: 机制六 · 内在的恐怖
---

# 怪物在外面，问题在里面。

<div class="body col">
<img src="/obs/flesh.png" alt="第六天" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows">
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">① 从哪来</span><p><b>寂静岭</b>：雾、废弃小镇、另一个世界。怪物不是随机的，它们长在角色的罪与恐惧上。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">② 为什么有效</span><p>真正被审视的不是怪物，<b>是角色</b>。玩家的不安来自"这些东西指涉的是我"。</p></div>
<div class="row hot" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">③ 我怎么改</span><p>观测站没有罪案，但有一个<b>一直在记录、却从不判断</b>的人。恐怖不是"我做错了什么"，而是"我什么都没做，只是把它写下来了"。</p></div>
<div class="row" style="grid-template-columns: 150px 1fr; padding: 6px 0"><span class="label">④ 文献</span><p><b>Kirkland</b>：寂静岭把哥特传统里的"过去侵入现在"改写成可玩的形式——罪恶感变成可探索的空间。</p></div>
</div>
</div>

<!--
6:30–7:20 · 50 秒

寂静岭给的是心理恐怖：怪物长在角色的罪与恐惧上。看的不是怪物，是这个人。

我的版本里没有罪案。观测站没有谁做错了事。
恐怖的位置换了一下：不是"我做错了什么"，而是"我什么都没做，我只是把它写下来了"。

这一点和机制二、机制三合起来才是完整的：
你逃不掉，你在照常过日子，而你每天都在为那个东西做记录。

Kirkland 那篇论文讲的就是寂静岭怎么把哥特传统改写成可玩的形式。
摘要我读了，正文在付费墙后。
-->

---
kicker: 学术对话
---

# 三篇游戏研究，各解释一个"为什么有效"。

| 文献 | 它的论点 | 解释我的哪条机制 | 阅读状态 |
|---|---|---|---|
| **Kirkland**,〈Gothic Videogames, Survival Horror, and the *Silent Hill* Series〉, *Gothic Studies* 14:2 (2012), 106–122 | 哥特传统（过去侵入现在、碎裂叙事、另一个世界）在生存恐怖游戏里被改写成可玩的形式 | ③ 日常的异常 · ⑥ 内在的恐怖 | **已读摘要**（第 106 页），正文付费墙 |
| **Costikyan**, *Uncertainty in Games*, MIT Press (2013) | 游戏的趣味来自由规则管理的不确定性 | ① 低信息 | **线索**，正文未读 |
| **Stobbart**, *Videogames and Horror*, Univ. of Wales Press (2019) | 恐怖游戏把玩家的能动性、身体与视角当作可被剥夺的对象 | ② 不可逃脱 | **线索**，正文未读 |

::foot::

它们不解释灵感来源——灵感来源是上面那七款游戏。它们解释这些手法为什么有效。

<!--
7:20–8:10 · 50 秒

三篇的位置要说清楚：它们不是我的灵感来源，是我用来解释为什么有效的工具。

Kirkland 解释寂静岭和哥特传统——我读了摘要，第 106 页，正文在付费墙后，可以引摘要。
Costikyan 解释低信息——不确定性是游戏张力的来源。这本书我没读到正文，是线索。
Stobbart 解释能动性被剥夺——正是无声狂啸给我的那条。也是线索。

我明说：三篇里只有一篇读了摘要，两篇是线索。
-->

---
kicker: 我的贡献
---

# 把"低信息"从观看变成劳动。

<div class="body col">
<div class="frame hot"><span class="label">这些游戏还没做的一件事</span><div class="text">铁肺让你<b>拍一张照片</b>去看外面——你仍然是观察者，只是工具很差。<br />Chilla's Art 让你<b>在店里打工</b>——日常是背景，恐怖是插入的事件。</div></div>
<div class="frame"><span class="label red">我的设计做了什么</span><div class="text">在这款游戏里，<b>记录本身就是劳动</b>：你每天亲手把那个东西画进星图，然后给它填一个 Yes。恐怖不来自"我没看清"，而来自<b>"我看清了，而且我签字了"</b>。</div></div>
</div>

<!--
8:10–8:50 · 40 秒

如果只讲一句贡献，就是这一句。

铁肺里你仍然是观察者，只是工具很差——你拍一张照片，看不清。
Chilla's Art 里日常是背景，恐怖是插进来的事件。

我的版本把这两件事合起来了：记录本身是劳动。你每天画星图，然后填表签字。
恐怖不来自"我没看清"，来自"我看清了，而且我签字了"。

这就是我和那七款游戏的分界线。
-->

---
kicker: 技术栈
---

# 这些机制是怎么被做出来的。

| 技术 | 作用 | 为什么 | 局限 |
|---|---|---|---|
| **Godot 4.7.2 / GDScript** | 引擎与全部逻辑 | 免费、可脚本化、2D 强，有**无头模式**可不开窗口测试 | 边界处类型松散，部分错误只在运行时暴露 |
| **程序化绘制** | 几乎全部美术 | 320×180 每个元素锁在像素网格上；每个元素都是带参数的函数，可测 | 无着色器 → 第四天「模糊」是撕裂拖影 |
| **固定虚拟分辨率** 320×180 / 桌面 640×360 | 低画质与屏中屏 | 「玩家居中」「地面行固定」成为构造保证；桌面是第二个分辨率层 | 10 px 以下文字不可读 |
| **门控状态机 + 无头测试** | 保证七天完全一致 | 机制一/三依赖节奏，节奏依赖顺序：414 项模块检查 + 112 项完整七日通关 | 读回像素的两道门禁必须开窗口 |
| **缺失：音频** | — | — | 全程无声；是缺口，不是选择 |

<!--
8:50–9:30 · 40 秒

用自己的话讲。

为什么 Godot：免费、可脚本化，无头模式让我不开窗口就能证明七天顺序不能被打乱——
因为我这套恐怖是建立在"每天完全一样"上的，顺序错一次，机制一就失效。

为什么程序化：320×180 下每个元素都要落在像素网格上，用代码画就没有素材管线；
而且 Chilla's Art 那种低画质的粗糙感，在代码里是精确可控的——我能决定每一棵树的位置。

诚实的局限：没有着色器，第四天不是真模糊；完全没有音频。
-->

---
kicker: 收尾
---

# 恐怖不需要怪物，它需要一个你每天都要做的动作。

<div class="body col">
<div class="frame"><span class="label">我还欠这次拆解的两件事</span><div class="text">① 读完 Costikyan 与 Stobbart，各找到一段带页码的原文。<br />② 验证沉默：是气氛还是没做完——这决定机制四成不成立。</div></div>
</div>

::foot::

谢谢，欢迎提问。

<!--
9:30–10:00 · 30 秒

用这句话收尾：恐怖不需要怪物，它需要一个你每天都要做的动作。

然后主动说出两件没做完的事。

可能的问题：
1「这些游戏你只是参考，不算研究吧？」——对，它们是**文化来源**，不是学术讨论。学术讨论是三篇游戏研究，用来说明这些手法为什么有效。
2「小游戏是玩笑吗？」——不是，Sally Face 的 GameBoy 是我的直接参照，屏中屏是机制五的一半。
3「最强的影响是哪一款？」——铁肺。低信息这一条决定了整个星图设计。
4「为什么撤掉了 Daston 和 Gitelman？」——因为我最初的框架错了，把项目当成官僚故事论证；真正的来源是游戏。
-->
