"""The single 32-colour palette for the world layer and the minigame.

Direction A (The Coma framing + FAITH restraint + Darkwood darkness):
cold and dark base, warm values reserved for artificial light, a separate
ramp for blood/flesh. The in-game post shader quantises every world frame to
exactly these colours with 4x4 Bayer dithering, so art does not have to be
pre-quantised -- but drawing close to these values keeps the dither calm.

Run:  python palette.py     -> writes ../assets/art/palette.png (32x1)
"""
import os

PALETTE = [
    # inks
    ("ink0", "#08090c"),
    ("ink1", "#12151c"),
    ("ink2", "#1c2230"),
    ("ink3", "#283245"),
    # cold ramp (snow, metal, night)
    ("cold0", "#3a4a63"),
    ("cold1", "#546a85"),
    ("cold2", "#7890ab"),
    ("cold3", "#a3b7cc"),
    ("cold4", "#d2dde6"),
    ("snow", "#f2f5f7"),
    # day sky
    ("sky0", "#4d7fb3"),
    ("sky1", "#8fb6d9"),
    # dusk
    ("dusk0", "#e3895a"),
    ("dusk1", "#b8566a"),
    ("dusk2", "#6b3f6e"),
    ("lavsnow", "#b9a3b8"),
    # firs
    ("fir0", "#1b2e2a"),
    ("fir1", "#2b4538"),
    ("fir2", "#46624a"),
    # wood
    ("wood0", "#2a1c16"),
    ("wood1", "#45302a"),
    ("wood2", "#6b4a38"),
    ("wood3", "#9a6e4e"),
    # artificial light
    ("lamp1", "#f5dca0"),
    ("lamp0", "#c98a3e"),
    # screen
    ("crt", "#6fc2c9"),
    # blood / flesh
    ("blood0", "#2e0b10"),
    ("blood1", "#6a1420"),
    ("blood2", "#a82a33"),
    ("flesh0", "#d9646a"),
    ("flesh1", "#e8a59c"),
    # paper / bone
    ("bone", "#e6dccb"),
]
assert len(PALETTE) == 32

NAMES = [n for n, _ in PALETTE]


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


RGB = {n: hex2rgb(h) for n, h in PALETTE}


def c(name, a=255):
    r, g, b = RGB[name]
    return (r, g, b, a)


if __name__ == "__main__":
    from PIL import Image
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "..", "assets", "art", "palette.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im = Image.new("RGBA", (32, 1))
    for i, (_, h) in enumerate(PALETTE):
        im.putpixel((i, 0), hex2rgb(h) + (255,))
    im.save(out)
    print("wrote", out)
