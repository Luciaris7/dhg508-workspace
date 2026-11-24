"""Bitmap fonts.

ui.png      1x, white, proportional (5x8 cell). Tinted at draw time.
day1..7.png 3x, the seven escalating "Day x" / GAME OVER treatments:
            1-3 clean white, 4 interference, 5 red, 6 red + veins,
            7 red + veins + eyes.

The glyph table is the 5x8 table from the previous build (tools/export_fonts.js),
extended with a few symbols. Row 7 is the descender row.
"""
import json
import os
import random

from pix import Canvas, col, mix

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "fonts")

GLYPHS = {
    'A': '.###./#...#/#...#/#####/#...#/#...#/#...#/.....',
    'B': '####./#...#/#...#/####./#...#/#...#/####./.....',
    'C': '.###./#...#/#..../#..../#..../#...#/.###./.....',
    'D': '####./#...#/#...#/#...#/#...#/#...#/####./.....',
    'E': '#####/#..../#..../####./#..../#..../#####/.....',
    'F': '#####/#..../#..../####./#..../#..../#..../.....',
    'G': '.###./#...#/#..../#.###/#...#/#...#/.###./.....',
    'H': '#...#/#...#/#...#/#####/#...#/#...#/#...#/.....',
    'I': '###../.#.../.#.../.#.../.#.../.#.../###../.....',
    'J': '..###/...#./...#./...#./...#./#..#./.##../.....',
    'K': '#...#/#..#./#.#../##.../#.#../#..#./#...#/.....',
    'L': '#..../#..../#..../#..../#..../#..../#####/.....',
    'M': '#...#/##.##/#.#.#/#...#/#...#/#...#/#...#/.....',
    'N': '#...#/##..#/#.#.#/#..##/#...#/#...#/#...#/.....',
    'O': '.###./#...#/#...#/#...#/#...#/#...#/.###./.....',
    'P': '####./#...#/#...#/####./#..../#..../#..../.....',
    'Q': '.###./#...#/#...#/#...#/#.#.#/#..#./.##.#/.....',
    'R': '####./#...#/#...#/####./#.#../#..#./#...#/.....',
    'S': '.####/#..../#..../.###./....#/....#/####./.....',
    'T': '#####/..#../..#../..#../..#../..#../..#../.....',
    'U': '#...#/#...#/#...#/#...#/#...#/#...#/.###./.....',
    'V': '#...#/#...#/#...#/#...#/#...#/.#.#./..#../.....',
    'W': '#...#/#...#/#...#/#...#/#.#.#/##.##/#...#/.....',
    'X': '#...#/#...#/.#.#./..#../.#.#./#...#/#...#/.....',
    'Y': '#...#/#...#/.#.#./..#../..#../..#../..#../.....',
    'Z': '#####/....#/...#./..#../.#.../#..../#####/.....',
    'a': '...../...../.###./....#/.####/#...#/.####/.....',
    'b': '#..../#..../####./#...#/#...#/#...#/####./.....',
    'c': '...../...../.###./#..../#..../#..../.###./.....',
    'd': '....#/....#/.####/#...#/#...#/#...#/.####/.....',
    'e': '...../...../.###./#...#/#####/#..../.###./.....',
    'f': '..##./.#.../.#.../###../.#.../.#.../.#.../.....',
    'g': '...../...../.####/#...#/#...#/.####/....#/####.',
    'h': '#..../#..../####./#...#/#...#/#...#/#...#/.....',
    'i': '#..../...../#..../#..../#..../#..../#..../.....',
    'j': '...#./...../..##./...#./...#./...#./...#./.##..',
    'k': '#..../#..../#..#./#.#../##.../#.#../#..#./.....',
    'l': '##.../.#.../.#.../.#.../.#.../.#.../..#../.....',
    'm': '...../...../##.#./#.#.#/#.#.#/#.#.#/#.#.#/.....',
    'n': '...../...../####./#...#/#...#/#...#/#...#/.....',
    'o': '...../...../.###./#...#/#...#/#...#/.###./.....',
    'p': '...../...../####./#...#/#...#/####./#..../#....',
    'q': '...../...../.####/#...#/#...#/.####/....#/....#',
    'r': '...../...../#.##./##.../#..../#..../#..../.....',
    's': '...../...../.####/#..../.###./....#/####./.....',
    't': '.#.../.#.../###../.#.../.#.../.#.../..##./.....',
    'u': '...../...../#...#/#...#/#...#/#...#/.####/.....',
    'v': '...../...../#...#/#...#/#...#/.#.#./..#../.....',
    'w': '...../...../#...#/#...#/#.#.#/#.#.#/.#.#./.....',
    'x': '...../...../#...#/.#.#./..#../.#.#./#...#/.....',
    'y': '...../...../#...#/#...#/#...#/.####/....#/####.',
    'z': '...../...../#####/...#./..#../.#.../#####/.....',
    '0': '.###./#...#/#..##/#.#.#/##..#/#...#/.###./.....',
    '1': '.#.../##.../.#.../.#.../.#.../.#.../###../.....',
    '2': '.###./#...#/....#/...#./..#../.#.../#####/.....',
    '3': '####./....#/....#/.###./....#/....#/####./.....',
    '4': '...#./..##./.#.#./#..#./#####/...#./...#./.....',
    '5': '#####/#..../####./....#/....#/#...#/.###./.....',
    '6': '.###./#..../#..../####./#...#/#...#/.###./.....',
    '7': '#####/....#/...#./..#../.#.../.#.../.#.../.....',
    '8': '.###./#...#/#...#/.###./#...#/#...#/.###./.....',
    '9': '.###./#...#/#...#/.####/....#/....#/.###./.....',
    ' ': '...../...../...../...../...../...../...../.....',
    '.': '...../...../...../...../...../...../#..../.....',
    ',': '...../...../...../...../...../...../#..../#....',
    "'": '#..../#..../...../...../...../...../...../.....',
    '"': '#.#../#.#../...../...../...../...../...../.....',
    '-': '...../...../...../###../...../...../...../.....',
    ':': '...../...../#..../...../...../#..../...../.....',
    ';': '...../...../#..../...../...../#..../#..../.....',
    '!': '#..../#..../#..../#..../#..../...../#..../.....',
    '?': '.###./#...#/....#/...#./..#../...../..#../.....',
    '/': '....#/....#/...#./..#../.#.../#..../#..../.....',
    '\\': '#..../#..../.#.../..#../...#./....#/....#/.....',
    '(': '.#.../#..../#..../#..../#..../#..../.#.../.....',
    ')': '#..../.#.../.#.../.#.../.#.../.#.../#..../.....',
    '[': '##.../#..../#..../#..../#..../#..../##.../.....',
    ']': '##.../.#.../.#.../.#.../.#.../.#.../##.../.....',
    '+': '...../..#../..#../#####/..#../..#../...../.....',
    '=': '...../...../####./...../####./...../...../.....',
    '_': '...../...../...../...../...../...../...../#####',
    '*': '...../#.#../.#.../#.#../...../...../...../.....',
    '%': '##..#/##.#./..#../.#.../#..##/#..##/...../.....',
    '<': '...../..#../.#.../#..../.#.../..#../...../.....',
    '>': '...../#..../.#.../..#../.#.../#..../...../.....',
    '#': '.#.#./.#.#./#####/.#.#./#####/.#.#./.#.#./.....',
    '&': '.##../#.#../#.#../.##../#.#.#/#..#./.##.#/.....',
    '@': '.###./#...#/#.###/#.#.#/#.###/#..../.###./.....',
    '|': '#..../#..../#..../#..../#..../#..../#..../#....',
    '~': '...../...../.#..#/#.##./...../...../...../.....',
    '^': '.#.../#.#../...../...../...../...../...../.....',
    '$': '.###./#.#../.###./..#.#/.###./..#../...../.....',
    '`': '#..../.#.../...../...../...../...../...../.....',
    '{': '..#../.#.../.#.../#..../.#.../.#.../..#../.....',
    '}': '#..../.#.../.#.../..#../.#.../.#.../#..../.....',
}

CELL_W, CELL_H = 5, 8


def rows_of(ch):
    rows = GLYPHS[ch].split('/')
    assert len(rows) == 8 and all(len(r) == 5 for r in rows), ch
    return rows


def ink_bounds(ch):
    rows = rows_of(ch)
    cols = [x for x in range(5) if any(r[x] == '#' for r in rows)]
    if not cols:
        return 0, 2
    return min(cols), max(cols) - min(cols) + 1


def build(scale, pad, painter, name, seed):
    chars = list(GLYPHS.keys())
    gw = CELL_W * scale + pad * 2
    gh = CELL_H * scale + pad * 2
    cols = 16
    rows = (len(chars) + cols - 1) // cols
    atlas = Canvas(cols * gw, rows * gh)
    meta = {"scale": scale, "pad": pad, "cell_h": CELL_H * scale, "base": 7 * scale, "line": (CELL_H + 2) * scale,
            "space": 3 * scale, "glyphs": {}}
    rng = random.Random(seed)
    for i, ch in enumerate(chars):
        ox = (i % cols) * gw
        oy = (i // cols) * gh
        left, width = ink_bounds(ch)
        g = Canvas(gw, gh)
        rows_ = rows_of(ch)
        mask = set()
        for y in range(8):
            for x in range(5):
                if rows_[y][x] == '#':
                    for sy in range(scale):
                        for sx in range(scale):
                            mask.add((pad + (x - left) * scale + sx, pad + y * scale + sy))
        painter(g, mask, scale, pad, rng, ch)
        atlas.blit(g, ox, oy)
        adv = (width + 1) * scale if ch != ' ' else 3 * scale
        meta["glyphs"][ch] = [ox, oy, gw, gh, adv]
    atlas.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=True)
    return atlas


# ------------------------------------------------- Simplified Chinese fonts
# Fusion Pixel Font 12px (SIL OFL 1.1, TakWolf; built on Ark Pixel Font) -- tools/src/font/fusion12/.
ARK = os.path.join(HERE, "src", "font", "fusion12", "fusion-pixel-12px-proportional-zh_hans.otf")
ZH_SRC = os.path.join(HERE, "..", "scripts", "autoload", "txt_zh.gd")
ZH_CELL_H = 14
ZH_BASE = 11


def zh_chars():
    with open(ZH_SRC, encoding="utf-8") as fh:
        txt = fh.read()
    cs = set(ch for ch in txt if ord(ch) > 127)
    cs |= set(chr(c) for c in range(32, 127))
    cs |= set("……，。：；！？、（）《》“”‘’—")
    return sorted(cs)


def zh_red_chars():
    """Every character of the RED block in txt_zh.gd (drawn with the big day fonts)."""
    with open(ZH_SRC, encoding="utf-8") as fh:
        txt = fh.read()
    start = txt.index("const RED := {")
    block = txt[start:txt.index("\n}", start)]
    return set(ch for ch in block if ord(ch) > 127)


def zh_masks(chars):
    from PIL import Image, ImageDraw, ImageFont
    font = ImageFont.truetype(ARK, 12)
    out = {}
    for ch in chars:
        adv = int(round(font.getlength(ch)))
        w = max(adv, 12) + 2
        im = Image.new("L", (w, ZH_CELL_H), 0)
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((0, -2), ch, font=font, fill=255)
        px = im.load()
        m = set((x, y) for y in range(ZH_CELL_H) for x in range(w) if px[x, y] > 127)
        out[ch] = (m, adv if ch != " " else 4, w)
    return out


def build_zh(scale, pad, painter, name, seed, chars):
    masks = zh_masks(chars)
    gw = max(v[2] for v in masks.values()) * scale + pad * 2
    gh = ZH_CELL_H * scale + pad * 2
    cols = 32
    rows = (len(chars) + cols - 1) // cols
    atlas = Canvas(cols * gw, rows * gh)
    meta = {"scale": scale, "pad": pad, "cell_h": ZH_CELL_H * scale, "base": ZH_BASE * scale, "line": (ZH_CELL_H + 1) * scale,
            "space": 4 * scale, "glyphs": {}}
    rng = random.Random(seed)
    for i, ch in enumerate(chars):
        ox = (i % cols) * gw
        oy = (i // cols) * gh
        m, adv, _w = masks[ch]
        mask = set()
        for (x, y) in m:
            for sy in range(scale):
                for sx in range(scale):
                    mask.add((pad + x * scale + sx, pad + y * scale + sy))
        g = Canvas(gw, gh)
        painter(g, mask, scale, pad, rng, ch)
        atlas.blit(g, ox, oy)
        meta["glyphs"][ch] = [ox, oy, gw, gh, (adv + (0 if ord(ch) > 127 else 1)) * scale]
    atlas.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False)


# ----------------------------------------------------------------- painters
def p_white(g, mask, s, pad, rng, ch):
    for (x, y) in mask:
        g.px(x, y, (255, 255, 255, 255))


def p_day_clean(g, mask, s, pad, rng, ch):
    for (x, y) in mask:
        g.px(x, y, "snow")
    # soft bottom-right drop shadow inside the cell
    for (x, y) in mask:
        if (x + 1, y + 1) not in mask and not g.opaque(x + 1, y + 1):
            g.px(x + 1, y + 1, (90, 100, 120, 160))


def p_day_interference(g, mask, s, pad, rng, ch):
    # white, with torn scanlines: some rows shifted sideways, some dropped
    shift = {}
    for y in range(g.h):
        r = rng.random()
        shift[y] = (rng.choice([-2, -1, 1, 2]) if r < 0.18 else 0)
    for (x, y) in mask:
        if rng.random() < 0.04:
            continue
        g.px(x + shift[y], y, "snow")
    for y in range(g.h):
        if shift[y] != 0 and rng.random() < 0.5:
            for (x, yy) in mask:
                if yy == y:
                    g.px(x - shift[y] * 2, y, (160, 200, 210, 120))


def _red_body(g, mask):
    for (x, y) in mask:
        top = (x, y - 1) not in mask
        g.px(x, y, "flesh0" if top else "blood2")
    for (x, y) in mask:
        if (x, y + 1) not in mask:
            g.px(x, y, "blood1")


def p_day_red(g, mask, s, pad, rng, ch):
    _red_body(g, mask)


def _veins(g, mask, rng, n, reach):
    pts = list(mask)
    if not pts:
        return
    for _ in range(n):
        x, y = rng.choice(pts)
        ang = rng.random() * 6.283
        import math
        for step in range(rng.randint(3, 4 + reach)):
            ang += rng.uniform(-0.9, 0.9)
            x2 = x + round(math.cos(ang) * 1.6)
            y2 = y + round(math.sin(ang) * 1.6)
            g.line(x, y, x2, y2, "blood0" if (x2, y2) in mask else "blood1")
            x, y = x2, y2
    # drips
    bottoms = [(x, y) for (x, y) in mask if (x, y + 1) not in mask]
    for _ in range(max(1, len(bottoms) // 18)):
        x, y = rng.choice(bottoms)
        L = rng.randint(1, 3)
        g.vline(x, y + 1, y + L, "blood1")


def p_day_veins(g, mask, s, pad, rng, ch):
    _red_body(g, mask)
    _veins(g, mask, rng, 3, 3)


def p_day_eyes(g, mask, s, pad, rng, ch):
    """Day 7: heavier veins and drips (no eyes -- user, 2026-11-16)."""
    _red_body(g, mask)
    _veins(g, mask, rng, 6, 5)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    build(1, 0, p_white, "ui", 1)
    build(3, 4, p_day_clean, "day1", 11)
    build(3, 4, p_day_clean, "day2", 11)
    build(3, 4, p_day_clean, "day3", 11)
    build(3, 4, p_day_interference, "day4", 44)
    build(3, 4, p_day_red, "day5", 55)
    build(3, 4, p_day_veins, "day6", 66)
    build(3, 4, p_day_eyes, "day7", 77)
    cs = zh_chars()
    build_zh(1, 0, p_white, "ui_zh", 1, cs)
    big = sorted(set("第天游戏结束0123456789 ，。") | set("".join(c for c in cs if ord(c) < 127)) |
                 set("觐见她的王座羔羊已降临我应当献上敬意之时未至输入站点日志") | zh_red_chars())
    for n, (p, seed) in enumerate([(p_day_clean, 11), (p_day_clean, 11), (p_day_clean, 11), (p_day_interference, 44),
                                    (p_day_red, 55), (p_day_veins, 66), (p_day_eyes, 77)], start=1):
        build_zh(2, 4, p, "day%d_zh" % n, seed, big)
    print("zh fonts ok:", len(cs), "glyphs")
    print("fonts ok:", len(GLYPHS), "glyphs")
