# 康乐纪事（kangle-chronicle）

Week 3 作业：**来源 → 文本 → 数据 → 小库 → 一个 skill**。
题目是广州岭南大学（含其前身格致书院、岭南学堂）1888–1952 年的校史大事，
外加其在香港复校/正名（1967、1999）两条线。

| 文件 | 是什么 |
|---|---|
| `records.json` | 从公开史料抽出的 38 条史事；每条带 `year`、`date`、`event`、`place`、`people`、`source`、`note` |
| `build_db.py` | 用 Python 标准库 `sqlite3` 把 `records.json` 建成 `data.db`（仅标准库，无第三方依赖） |
| `data.db` | SQLite 数据库：一张表 `events`，38 行 |
| `SKILL.md` | 给 agent 的说明书：这里有什么 + 五条规矩 + 两种说话方式 |

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
