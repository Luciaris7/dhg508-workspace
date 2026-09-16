# 康乐纪事（kangle-chronicle）

Week 3 作业：**来源 → 文本 → 数据 → 小库 → 一个 skill**。
题目是广州岭南大学（含其前身格致书院、岭南学堂）1888–1952 年的校史大事，
外加其在香港复校/正名（1967、1999）两条线。

| 文件 | 是什么 |
|---|---|
| `records.json` | 从公开史料抽出的 38 条史事；每条带 `year`、`date`、`event`、`place`、`people`、`source`、`note` |
| `build_db.py` | 用 Python 标准库 `sqlite3` 把 `records.json` 建成 `data.db`（仅标准库，无第三方依赖） |
| `data.db` | SQLite 数据库：一张表 `events`，38 行 |
| `SKILL.md` | 给 agent 的说明书：这里有什么 + 六条规矩 + 两种说话方式 |
| `trial.md` | 挑战 4 的试跑记录：四种问法（有据、异说、拒绝、人物模拟）的实际问答 |

## 怎么用

数据库就是一个 SQLite 文件。不用装工具，让 agent 用 Python 读它：

```bash
python build_db.py          # 由 records.json 重建 data.db
python -c "import sqlite3; c=sqlite3.connect('data.db'); print(c.execute('SELECT COUNT(*) FROM events').fetchone())"
```

然后把这个目录交给 agent，让它读 `SKILL.md`。

## 课堂线索（两种说话方式）

- 史家：**「粤北复校是哪一年，在哪里？」** → 应给 `[id 33]`，并复述出处。
- 史家：**「1903 年康乐买地是二百亩还是三十英亩？」** → 应并列两说、指向 `note`，不替材料选一个。
- 史家：**「岭南大学哪一年开办医学院？」** → 按库给 `[id 27][id 29]`；年份有异说时说明。
- 史家：**「1936 年校长是谁？」** → 库里没有这一行，应拒绝或标注「这不是库里的内容」。
- 人物：**「请以钟荣光的口吻讲讲 1927 年接办那天」** → 只能用库里与钟荣光相关的行，并注明「模拟语气」。

## 每条数据的出处（`source` 字段）

- 岭南大学官网《历史和发展》 https://www.ln.edu.hk/chs/about-lu/milestones-and-history/history-and-development
- 岭南大学官网《大事纪要》 https://www.ln.edu.hk/chs/milestones
- 维基百科「岭南大学 (广州)」 https://zh.wikipedia.org/wiki/岭南大学_(广州)
- Wikipedia, "Lingnan University (Guangzhou)" https://en.wikipedia.org/wiki/Lingnan_University_(Guangzhou)
- 广州市人民政府门户网站《广州最早一批西式学堂》 https://www.gz.gov.cn/zlgz/whgz/content/post_8292405.html
- Digital Commons @ Lingnan University, *Lingnan University, 1888 to Present: a Pictorial History* https://commons.ln.edu.hk/luar_pic
- 华南理工大学《学校沿革简介》 https://www2.scut.edu.cn/archives/2026/0529/c1577a628239/page.htm
- 中山大学新闻网《穿越百年，一图读懂中大前世今生》 https://www.sysu.edu.cn/news/info/2171/518731.htm

## 存疑说明

史料对校名沿革、若干年份互有出入（例如 1912/1916/1918/1927 的改名次序、
钟荣光出任校长的 7 月 1 日与 8 月 1 日两说、岭大并入中山大学的 1952/1953）。
凡有异说，已写入对应行的 `note`，agent 应如实转述而不代选。

## 抽样回查（挑战 2：「check a few rows back against the original」）

回查日期 2026-09-16。方法：打开最常被引用的两份来源——岭南大学官网《历史和发展》
与中文维基「岭南大学 (广州)」——逐条比对下列行的原文。只记两页上亲眼见到的文字；
两页都没有的细节标「两页未见」。

| id | 行内要点 | 回查结果 |
|---|---|---|
| 3 | 1888-03-28 授课、录取 30 人、沙基金利埠 | 与官网一致（官网作「3月28日……第一批学生只有三十人」）；「八十人报名」两页未见 |
| 4 | 1890-08-20 因哈巴夫妇病重关闭 | 与中文维基一致 |
| 12 | 1903 更名岭南学堂、英文 Canton Christian College | 与两页一致（「5月」见维基，官网未记月份） |
| 13 | 1903 康乐村购地 200 亩 / 30 多英亩 | 维基作 200 亩、官网作「三十多英亩」，`note` 两说并陈属实；但官网把购地系于 **1904** 年，行记 1903，`note` 未提这一年份差 |
| 19 | 1912-09 中文名改岭南学校 | 与两页一致 |
| 23 | 1927-01 推钟荣光为校长、李应林为副校长 | 与官网一致 |
| 25 | 1927-07-01 正名岭南大学、钟荣光首任华人校长 | 与中文维基一致 |
| 33 | 1942 曲江大村复校、命名岭大村 | 与官网一致；中文维基作「1942 年於韶關仙人廟大村復課」 |
| 34 | 1945-10-31 回康乐复课 | 与两页一致 |
| 36 | 1952 院系调整、康乐校园归中山大学 | 与两页一致 |
| 38 | 1999-07 取得自我评审资格、正名岭南大学 | **与官网不符**：官网记「1998 年，岭南获得自我评审资格，并于 1999 年正名为岭南大学」；行内「1999 年 7 月取得自我评审资格」把两年并作一年，待核对原始 Digital Commons 页 |

- 抽样 11 行中 10 行与来源一致；`[38]` 与官网不符。
- 已据此订正 `records.json` 并重建 `data.db`：`[38]` 事件改为「岭南学院正名为岭南大学（香港）」，`note` 记下 1998 年自我评审资格一说，并把官网补入 `source`；`[13]` 的 `note` 补「1903/1904 购地年份两说」，同样补入官网出处。重建后 `records.json` 与 `data.db` 逐字段相同（38 行）。
- 其余 27 行尚未逐条回查。
