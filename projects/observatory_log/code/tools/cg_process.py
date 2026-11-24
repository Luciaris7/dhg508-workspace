"""Ending CGs: tools/src/cg/cg_<kind>_raw.* -> assets/art/cg/cg_<kind>.png
Hilltop views: tools/src/cg/vista_<n>_raw.* -> assets/art/cg/vista_<n>.png
(1: Days 1-4, 2: Days 5-6, 3: Day 7 -- the same view, the lake changing)

The raw illustrations (made with an image model, see CREDITS.md) are cut to
16:9, reduced to the game's 640x360 canvas with an area filter and limited
to a small adaptive palette with no dithering, so they read as pixel art at
the same pixel size as the rest of the game -- but in their own, richer
palette (the user asked for the CGs to be finer than the game itself).

    python cg_process.py
"""
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src", "cg")
OUT = os.path.join(HERE, "..", "assets", "art", "cg")
W, H = 640, 360
COLOURS = 96


def _raw(name):
    for ext in (".png", ".jpg", ".jpeg", ".webp"):
        p = os.path.join(SRC, name + "_raw" + ext)
        if os.path.exists(p):
            return p
    raise FileNotFoundError(name)


def process(kind):
    # kind: an ending ("sacrifice" -> cg_sacrifice) or a hilltop view ("vista_1")
    name = kind if kind.startswith("vista") else "cg_" + kind
    im = Image.open(_raw(name)).convert("RGB")
    w, h = im.size
    # centre crop to exactly 16:9
    if w * 9 > h * 16:
        nw = h * 16 // 9
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = w * 9 // 16
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize((W, H), Image.BOX)
    im = im.quantize(colors=COLOURS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + ".png"))
    print("cg", name, im.size)


if __name__ == "__main__":
    for k in ("sacrifice", "assimilate", "escape", "ufo_1", "ufo_2", "vista_1", "vista_2", "vista_3"):
        try:
            process(k)
        except FileNotFoundError:
            print("missing raw for", k)
