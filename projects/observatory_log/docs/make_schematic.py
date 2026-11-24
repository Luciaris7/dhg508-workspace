#!/usr/bin/env python3
"""Draw docs/schematic.png, the architecture figure used in paper/main.tex.

Run:  python docs/make_schematic.py
Out:  docs/schematic.png  (1800 x 1000)

Kept in the repo so the figure can be rebuilt rather than re-drawn by hand.
Latin text uses Segoe UI; the handful of CJK glyphs (据 / 推断 / 设, 中文) use
Microsoft YaHei, because Segoe UI has no CJK coverage.
"""
import math
import pathlib

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "schematic.png"
# The paper needs the image beside main.tex (that is also what gets uploaded to
# Overleaf), so the figure is written in both places from one source.
PAPER_COPY = HERE.parent / "paper" / "schematic.png"

W, H = 1800, 1000
INK = (26, 26, 26)
MUTED = (90, 98, 110)
BOX = (245, 247, 250)
EDGE = (74, 85, 104)
ACCENT = (139, 26, 26)
BAND = (236, 239, 243)

FONTS = pathlib.Path("C:/Windows/Fonts")


def font(name, size, fallback="segoeui.ttf"):
    for cand in (name, fallback, "arial.ttf"):
        p = FONTS / cand
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


F_TITLE = font("seguisb.ttf", 38)
F_SUB = font("segoeui.ttf", 19)
F_LABEL = font("seguisb.ttf", 21)
F_BOX = font("seguisb.ttf", 21)
F_BODY = font("segoeui.ttf", 18)
F_SMALL = font("segoeui.ttf", 16)
F_CJK = font("msyh.ttc", 17)

img = Image.new("RGB", (W, H), (255, 255, 255))
d = ImageDraw.Draw(img)


def center_text(x, y, text, f, fill=INK):
    d.text((x - d.textlength(text, font=f) / 2, y), text, font=f, fill=fill)


def box(x0, y0, x1, y1, title, lines=(), fill=BOX, edge=EDGE,
        title_font=F_BOX, title_fill=INK, radius=10, width=2):
    d.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill, outline=edge, width=width)
    cx = (x0 + x1) / 2
    block = title_font.size + len(lines) * (F_SMALL.size + 6) + (8 if lines else 0)
    y = (y0 + y1) / 2 - block / 2 + 2
    center_text(cx, y, title, title_font, title_fill)
    y += title_font.size + 8
    for ln in lines:
        if isinstance(ln, tuple):
            center_text(cx, y, ln[0], ln[1], MUTED)
        else:
            center_text(cx, y, ln, F_SMALL, MUTED)
        y += F_SMALL.size + 6


def arrow(x0, y0, x1, y1, color=EDGE, w=3):
    d.line([x0, y0, x1, y1], fill=color, width=w)
    a = math.atan2(y1 - y0, x1 - x0)
    L, S = 14, 7
    for s in (+1, -1):
        d.line([x1, y1,
                x1 - L * math.cos(a - s * 0.45),
                y1 - L * math.sin(a - s * 0.45)], fill=color, width=w)


def chain(items, x, y, h, w, gap, title_font=F_BOX):
    for i, (t, ls) in enumerate(items):
        x0 = x + i * (w + gap)
        box(x0, y, x0 + w, y + h, t, ls, title_font=title_font)
        if i < len(items) - 1:
            arrow(x0 + w + 7, y + h / 2, x0 + w + gap - 7, y + h / 2)
    return x + len(items) * w + (len(items) - 1) * gap


# ---------------------------------------------------------------- header
d.text((60, 30), "OBSERVATION LOG — architecture, evidence and delivery", font=F_TITLE, fill=INK)
d.text((62, 80),
       "Godot 4.7.2  ·  320x180 world at 32 colours  ·  no server, no account, no runtime network call",
       font=F_SUB, fill=MUTED)

# ---------------------------------------------------------------- band A
d.rounded_rectangle([50, 122, 1750, 322], radius=14, fill=BAND)
d.text((74, 136), "A · BUILD AND DELIVERY", font=F_LABEL, fill=MUTED)
chain([
    ("tools/*.py", ["art · audio · fonts", "palette · ephemeris"]),
    ("assets/", ["vsop.json  20 KB", "moon.bin  412 KB"]),
    ("Godot project", ["320x180 world", "scripts · shaders"]),
    ("Web export", ["threads off", "wasm  37.7 MB"]),
    ("gzip + worker", ["wasm.gz  9.7 MB", "25 MiB per-file cap"]),
    ("Cloudflare Pages", ["https://…pages.dev", "browser · IndexedDB"]),
], x=74, y=176, h=112, w=250, gap=35)

# ---------------------------------------------------------------- band B
d.rounded_rectangle([50, 342, 1750, 692], radius=14, fill=BAND)
d.text((74, 356), "B · INSIDE THE PROJECT — ONE ROOT NODE, ONE INPUT ROUTER, ONE DIRECTOR",
       font=F_LABEL, fill=MUTED)

chain([
    ("world", ["320x180  x2", "32-colour post"]),
    ("desktop", ["640x360", "CRT shader"]),
    ("minigame", ["320x180  x2", "HOMEWARD"]),
    ("ending", ["640x360", "own palette"]),
    ("overlay", ["monologue", "red text"]),
    ("menu", ["never", "distorted"]),
], x=74, y=396, h=104, w=250, gap=34, title_font=F_BODY)

box(74, 536, 678, 646, "Autoloads", [
    "G  state · save · settings · language",
    "Txt  English / Chinese copy tables",
    "Sfx  music · effects · ambience",
], title_font=F_BODY)
box(714, 536, 1318, 646, "Flow  (director)", [
    "day script · gating · every cutscene",
    "G.can_escape() decides all three endings",
    "clues >= 8/10  and  the sealed number",
], title_font=F_BODY)
box(1354, 536, 1750 - 26, 646, "Tests", [
    "static · unit",
    "headless Godot · Playwright",
], title_font=F_BODY)

# ---------------------------------------------------------------- band C
d.rounded_rectangle([50, 712, 1750, 962], radius=14, fill=BAND)
d.text((74, 726),
       "C · FOUR GATES, CHEAPEST FIRST — A BROKEN RES:// PATH FAILS IN UNDER A SECOND",
       font=F_LABEL, fill=MUTED)
chain([
    ("check:static", ["52 checks · 62 files", "< 1 s"]),
    ("unit", ["33 assertions", "< 1 s"]),
    ("test:game", ["ephem 0.006 deg", "277 / 270 / 296 asserts", "8–12 min"]),
    ("test:e2e", ["4 cases · live URL too", "~1.5 min"]),
], x=74, y=766, h=124, w=360, gap=60, title_font=F_BODY)

# ---------------------------------------------------------------- footer
d.text((74, 922), "Evidence tiers used throughout:", font=F_SMALL, fill=MUTED)
tw = d.textlength("Evidence tiers used throughout:  ", font=F_SMALL)
x = 74 + tw
for label, note in (("据", "documented"), ("推断", "inferred"), ("设", "invented")):
    d.text((x, 921), label, font=F_CJK, fill=ACCENT)
    x += d.textlength(label, font=F_CJK) + 8
    d.text((x, 922), note + "      ", font=F_SMALL, fill=MUTED)
    x += d.textlength(note + "      ", font=F_SMALL)
d.text((1330, 922), "Generated by docs/make_schematic.py", font=F_SMALL, fill=MUTED)

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT, "PNG", optimize=True)
if PAPER_COPY.parent.is_dir():
    img.save(PAPER_COPY, "PNG", optimize=True)
    print(f"wrote {PAPER_COPY} (copy for the LaTeX build)")
print(f"wrote {OUT} ({img.size[0]}x{img.size[1]})")
