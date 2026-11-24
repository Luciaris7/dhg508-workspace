"""Generate every PNG under assets/art. Usage: python gen_art.py [module ...]

Modules: world interior char desk mini end
Also writes previews to tools/_preview/*.png for review.
"""
import os
import sys

from pix import Canvas, sheet

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "assets", "art")
PREV = os.path.join(HERE, "_preview")

_saved = {}


def save(name, canvas):
    canvas.save(os.path.join(ART, name + ".png"))
    _saved[name] = canvas


def preview(prefix, cols=6, scale=2):
    items = [v for k, v in _saved.items() if k.startswith(prefix)]
    if not items:
        return
    os.makedirs(PREV, exist_ok=True)
    sheet(items, cols, pad=3, scale=scale).save(os.path.join(PREV, prefix.replace("/", "_") + ".png"))


if __name__ == "__main__":
    mods = sys.argv[1:] or ["world", "props", "interior", "char", "desk", "mini", "end"]
    for m in mods:
        mod = __import__("art_" + m)
        mod.build(save)
        preview(m + "/")
        print("built", m)
