# sources/raw — 下载的原始材料清单

按 AGENTS.md 的规定：**大的 PDF 不入 git**，在此登记。文件本身仍在本地磁盘上。

| 文件 | 文献 | 来源 URL | 大小 | 下载日期 | 版本 |
| --- | --- | --- | --- | --- | --- |
| `threat_limbo.pdf` | Kjeldgaard-Christiansen & Clasen, "Threat Simulation in Virtual Limbo", *JGVW* 11:2 (2019) | https://pure.au.dk/ws/files/167515165/Threat_simulation_in_virtual_limbo_preprint.pdf | 944 KB | 2026-11-04 | 作者存放的**预印本**（33 页） |
| `uncanny_survival.pdf` | Tinwell, Grimshaw & Williams, "Uncanny Behaviour in Survival Horror Games", *JGVW* 2:1 (2010), 3–25 | https://ub-ir.bolton.ac.uk/view/delivery/44UOBO_INST/124070000008841/134099100008841 | 2.6 MB | 2026-11-04 | University of Bolton 机构库的**接受稿**（40 页） |

## 阅读方式

`web_fetch` 不支持 PDF，因此用 `Invoke-WebRequest` 下载后用 Python 的 `pypdf` 提取文本阅读。

## 引用注意

两篇都是**作者存放版本**，页码与正式出版版不同。引用时必须在书目中注明读的是哪个版本
（已在 `research/references/bibliography.md` 中注明）。

## 版权

两篇均为开放获取（OpenAlex `oa_status: green`），下载用于课程阅读与研究记录。
---

## 参考截图（游戏画面）

七款游戏的截图取自各自 Steam 商店页面（`storesearch` + `appdetails` 公开 API 取首图或指定图），
存放在 `reslides/examples/starter/public/obs/ref/`，仅用于课堂评论与批判性讨论。

| 文件 | 游戏 | Steam appid |
| --- | --- | --- |
| `ironlung.jpg` | Iron Lung (2022) | 1846170 |
| `ihavenomouth.jpg` | I Have No Mouth, and I Must Scream (1995) | 245390 |
| `fearstofathom.jpg` | Fears to Fathom - Scratch Creek | 4121170 |
| `firewatch.jpg` | Firewatch (2016) | 383870 |
| `chillasart.jpg` | [Chilla's Art] Parasocial | 2314720 |
| `sallyface.jpg` | Sally Face - Episode One（GEAR BOY 画面） | 541570 |
| `sallyface_gear.jpg` | 同上（SUPER GEAR BOY 正在游玩） | 541570 |
| `silenthill.jpg` | SILENT HILL 2 (2024 remake) | 2124490 |

**注意**：Silent Hill 用的是 2024 年重制版的截图，不是 1999 年原版；幻灯片上已注明是系列参照。