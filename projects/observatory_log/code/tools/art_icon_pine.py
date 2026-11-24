"""Shortcut icon: a mini pixel pine in the snow, 16 x 16, scaled up crisply.

    python art_icon_pine.py   -> assets/art/pine_icon.png, pine_icon.ico
"""
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "art")

# . empty  D dark needles  G needles  L lit needles  S snow  s snow shade  T trunk  R red (the beanie-red star of light)
ART = [
    ".......SS.......",
    "......SGGs......",
    ".....SGLGGs.....",
    "......DGGD......",
    "....SSGLGGss....",
    "...SGGLGGGDGs...",
    ".....DGLGGD.....",
    "...SSGGLGGGDss..",
    "..SGGGLGGGGGDGs.",
    "....DDGLGGGDD...",
    "..SSGGGLGGGGDss.",
    ".SGGGGLGGGGGGDGs",
    "..DDDGGGGGGDDD..",
    ".......TT.......",
    "....ssSTTSSss...",
    "..sSSSSSSSSSSs..",
]
COL = {
    "D": (27, 46, 42, 255), "G": (43, 69, 56, 255), "L": (70, 98, 74, 255),
    "S": (242, 245, 247, 255), "s": (163, 183, 204, 255), "T": (69, 48, 42, 255),
    "R": (168, 42, 51, 255),
}


def build():
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y, row in enumerate(ART):
        assert len(row) == 16, row
        for x, ch in enumerate(row):
            if ch in COL:
                im.putpixel((x, y), COL[ch])
    big = im.resize((256, 256), Image.NEAREST)
    big.save(os.path.join(OUT, "pine_icon.png"))
    big.save(os.path.join(OUT, "pine_icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("pine icon ok")


if __name__ == "__main__":
    build()
