# paper/ — how this was built

Everything here is generated or compiled from four hand-edited files:
`evidence.csv`, `main.tex`, `references.bib`, and `docs/make_schematic.py`
(one level up). Nothing in the table is typed by hand.

## Files

| File | Hand-edited? | What it is |
| --- | --- | --- |
| `evidence.csv` | **yes** | `claim,evidence,locator,level,limit`; `level` is 据 / 推断 / 设 |
| `main.tex` | **yes** | the paper, six sections, biblatex-chicago |
| `references.bib` | **yes** | three scholarly works (with reading status) + seven games + the live build |
| `make_evidence_table.py` | rarely | CSV → LaTeX; column widths tuned so file paths do not overrun the next column |
| `evidence-table.tex` | **no** | generated — `python make_evidence_table.py` |
| `schematic.png` | **no** | generated — `python ../docs/make_schematic.py` |
| `design-paper.pdf` | **no** | compiled |

## On Overleaf

1. **New Project → Upload Project** and upload a zip of this folder.
2. **Menu → Compiler → XeLaTeX**.
3. **Recompile** — Biber runs automatically, then twice more for the page refs.
4. **Download PDF**, save over `design-paper.pdf`; if you edited text there, also
   **Menu → Download → Source** and copy `main.tex` / `references.bib` back.

Those are the steps the course asks for, and they are what produced the PDF here.

## Locally

Needs XeLaTeX plus `biber`, `biblatex-chicago`, `xeCJK`, `csquotes`, `setspace`,
`graphicx`, `booktabs`, `array`.

```bash
cd paper
python make_evidence_table.py
xelatex -interaction=nonstopmode main.tex
biber main
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex   # 3rd pass resolves figure/table refs
cp main.pdf design-paper.pdf
```

The committed PDF was built exactly this way (TeX Live 2026, XeLaTeX, Biber 2.22):
7 pages, no overfull boxes, and it embeds the same pair of faces Overleaf would
pick — Times New Roman for Latin, **Noto Serif CJK SC** for Chinese (subsets, both
embedded).

On a Windows machine that has the Noto Serif CJK SC OTF files but where XeTeX's
font enumeration cannot see them yet, pass the directory on the command line:

```bash
xelatex -interaction=nonstopmode "\def\CJKFontPath{C:/path/to/fonts/}\input{main.tex}"
biber main
xelatex -interaction=nonstopmode "\def\CJKFontPath{C:/path/to/fonts/}\input{main.tex}"
```

`fonts/` only needs `NotoSerifCJKsc-Regular.otf` and `NotoSerifCJKsc-Bold.otf`.
The hook lives in `main.tex` right after the template's font chain and is inert on
Overleaf, where `\CJKFontPath` is undefined and the family resolves by name.
Without the hook a local build still succeeds — it simply falls back to SimSun,
which is what the earlier draft of this PDF used.

## Two things that will bite

- **`\autocite[page]{key}` goes after the punctuation**, not before it. Chicago
  notes style treats a note attached mid-sentence differently.
- **Page locators refer to the version actually read.** Two of the three articles
  were read as preprints / accepted manuscripts, so the page numbers in the text
  are those documents' pages, not the publisher's. `references.bib` records which
  version, per entry.
