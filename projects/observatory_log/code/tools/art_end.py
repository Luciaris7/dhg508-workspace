"""Application icon: the lookout tower at night with a red point above it."""
from pix import Canvas


def icon():
    from PIL import Image
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    tower = Image.open(os.path.join(here, "..", "assets", "art", "world", "tower.png")).convert("RGBA")
    c = Canvas(64, 64, (8, 10, 16, 255))
    for y in range(64):
        c.hline(0, 63, y, (8 + y // 6, 10 + y // 5, 18 + y // 3, 255))
    c.disc(46, 12, 5, (120, 14, 20, 120))
    c.disc(46, 12, 3, (200, 30, 34, 255))
    t = tower.resize((tower.width * 40 // 148, 40), Image.NEAREST)
    import numpy as np
    a = np.array(t)
    a[..., :3] = (a[..., :3] * 0.35).astype(np.uint8)
    tc = Canvas(a.shape[1], a.shape[0])
    tc.a = a
    c.blit(tc, 32 - tc.w // 2, 64 - tc.h - 4)
    c.rect(0, 60, 64, 4, (14, 16, 22, 255))
    c.rect(26, 34, 12, 3, (240, 190, 110, 255))
    return c


def build(save):
    save("icon", icon())
