"""Interiors: the lookout cab (living room) and the generator shed.

Room shells have their windows punched out (transparent) so the engine's sky
shows through them. Every prop is its own sprite so it can carry the flesh
material and its own light.
"""
import math
import random

from pix import Canvas, col, mix, fbm, hash01, BAYER4

CAB_W = 560
SHED_W = 420
FLOOR = 153
WINDOWS = [(300, 60, 62, 50), (96, 70, 28, 34)]   # x, y, w, h  (cab)


def cab_shell():
    W, H = CAB_W, 180
    c = Canvas(W, H)
    # wall: horizontal half-logs
    for y in range(26, FLOOR):
        band = (y - 26) % 7
        for x in range(W):
            n = fbm(x * 0.05, y * 0.4, 21, 3)
            if band == 0:
                k = "wood0"
            elif band == 1:
                k = "wood3" if n > 0.55 else "wood2"
            elif band in (5, 6):
                k = "wood1"
            else:
                k = "wood2" if n > 0.32 else "wood1"
            c.px(x, y, k)
    # knots / grain
    rnd = random.Random(4)
    for i in range(80):
        x = rnd.randint(0, W - 1)
        y = rnd.randint(28, FLOOR - 4)
        c.px(x, y, "wood0")
        c.px(x + 1, y, "wood1")
    # wainscot: darker boards below y=124
    for y in range(124, FLOOR):
        for x in range(W):
            if x % 9 == 0:
                c.px(x, y, "wood0")
            elif c.get(x, y)[0] > 0:
                p = c.get(x, y)
                c.px(x, y, (int(p[0] * 0.75), int(p[1] * 0.72), int(p[2] * 0.7), 255))
    c.hline(0, W - 1, 124, "wood3")
    c.hline(0, W - 1, 125, "wood0")
    # ceiling and beams
    c.rect(0, 0, W, 26, "ink1")
    c.rect(0, 22, W, 5, "wood1")
    c.hline(0, W - 1, 26, "wood0")
    for x in range(10, W, 64):
        c.rect(x, 0, 8, 27, "wood1")
        c.vline(x, 0, 26, "wood2")
        c.rect(x - 2, 24, 12, 4, "wood0")
    # floor boards
    for y in range(FLOOR, H):
        t = (y - FLOOR) / (H - FLOOR)
        for x in range(W):
            seam = (x + (y - FLOOR) * 3) % 23 == 0
            k = "wood1" if seam else ("wood2" if hash01(x // 23, y // 3, 5) > 0.4 else "wood1")
            if y == FLOOR:
                k = "wood3"
            c.px(x, y, k)
        if t > 0.35:
            for x in range(W):
                if BAYER4[y % 4, x % 4] < (t - 0.35) * 1.4:
                    c.px(x, y, "wood0")
    # corner posts at both ends
    for x0 in (0, W - 10):
        c.rect(x0, 20, 10, FLOOR - 20, "wood0")
        c.vline(x0 + (9 if x0 == 0 else 0), 20, FLOOR, "wood1")
    # windows: frame + punched glass
    for (wx, wy, ww, wh) in WINDOWS:
        c.rect(wx - 4, wy - 4, ww + 8, wh + 8, "wood1")
        c.rect(wx - 3, wy - 3, ww + 6, wh + 6, "wood3")
        c.rect(wx - 2, wy - 2, ww + 4, wh + 4, "wood1")
        c.a[wy:wy + wh, wx:wx + ww] = 0
        # mullions
        c.rect(wx + ww // 2 - 1, wy, 2, wh, "wood1")
        c.rect(wx, wy + wh // 2 - 1, ww, 2, "wood1")
        # sill
        c.rect(wx - 6, wy + wh + 3, ww + 12, 4, "wood3")
        c.hline(wx - 6, wx + ww + 5, wy + wh + 6, "wood0")
    return c


def frost_overlay(level):
    """Frost creeping in from the corners of the big window (transparent elsewhere)."""
    wx, wy, ww, wh = WINDOWS[0]
    c = Canvas(ww, wh)
    for y in range(wh):
        for x in range(ww):
            d = min(math.hypot(x, y), math.hypot(ww - x, y), math.hypot(x, wh - y), math.hypot(ww - x, wh - y))
            n = fbm(x * 0.3, y * 0.3, 9, 3) * 10
            if d + n < level * 26:
                c.px(x, y, (230, 240, 248, 200 if d + n < level * 18 else 120))
    return c


def door(w=20, h=44, metal=False):
    c = Canvas(w + 6, h + 4)
    c.rect(0, 0, w + 6, h + 4, "wood0" if not metal else "cold0")
    c.rect(3, 3, w, h + 1, "wood2" if not metal else "cold1")
    for y in range(6, h, 9):
        c.rect(5, y, w - 4, 6, "wood1" if not metal else "cold0")
        c.hline(5, w, y, "wood3" if not metal else "cold2")
    c.rect(w - 2, h // 2 + 2, 2, 3, "lamp0" if not metal else "cold3")
    return c


def stove():
    c = Canvas(26, 128)
    # pipe up to the ceiling
    c.rect(10, 0, 6, 100, "ink2")
    c.vline(11, 0, 100, "ink3")
    c.rect(8, 40, 10, 3, "ink3")
    # body
    c.rect(2, 100, 22, 24, "ink2")
    c.rect(3, 101, 20, 2, "ink3")
    c.rect(6, 106, 14, 10, "ink1")
    c.rect(8, 108, 10, 6, "lamp0")   # fire window (lit by a light)
    c.rect(9, 110, 8, 3, "lamp1")
    c.hline(8, 17, 107, "ink3")
    c.rect(3, 124, 3, 4, "ink1")
    c.rect(20, 124, 3, 4, "ink1")
    return c


def bed():
    c = Canvas(56, 26)
    c.rect(0, 4, 4, 22, "wood1")          # headboard
    c.rect(52, 10, 4, 16, "wood1")        # footboard
    c.rect(0, 14, 56, 6, "wood1")
    c.rect(4, 10, 48, 6, "cold4")          # mattress
    # plaid blanket
    for x in range(14, 52):
        for y in range(8, 16):
            k = "blood2" if (x // 3 + y // 3) % 2 == 0 else "blood1"
            if x % 6 == 0 or y % 6 == 0:
                k = "ink2"
            c.px(x, y, k)
    c.hline(14, 51, 8, "flesh0")
    c.rect(5, 7, 10, 5, "bone")            # pillow
    c.hline(5, 14, 7, "snow")
    c.rect(2, 22, 52, 4, "wood0")
    return c


def desk():
    c = Canvas(52, 26)
    c.rect(0, 0, 52, 4, "wood3")
    c.hline(0, 51, 0, "lamp0")
    c.rect(0, 4, 52, 2, "wood1")
    c.rect(2, 6, 4, 20, "wood1")
    c.rect(46, 6, 4, 20, "wood1")
    c.rect(30, 6, 16, 12, "wood2")         # drawers
    c.hline(30, 45, 11, "wood1")
    c.px(37, 8, "lamp0")
    c.px(37, 14, "lamp0")
    return c


def computer(on=True):
    c = Canvas(30, 28)
    # CRT monitor (beige) on the desk, keyboard in front
    c.rect(4, 0, 22, 20, "bone")
    c.rect(5, 1, 20, 18, "cold4")
    c.rect(7, 3, 16, 12, "crt" if on else "ink2")
    if on:
        c.rect(7, 3, 16, 2, "sky0")
        c.rect(7, 13, 16, 2, "sky0")
        c.rect(8, 6, 4, 4, "fir2")
    c.rect(10, 20, 10, 3, "cold3")
    c.rect(1, 24, 28, 4, "cold3")
    c.hline(1, 28, 24, "bone")
    for x in range(3, 27, 2):
        c.px(x, 26, "cold1")
    return c


def desk_lamp():
    c = Canvas(14, 20)
    c.rect(3, 18, 8, 2, "ink3")
    c.line(6, 18, 4, 9, "ink3")
    c.line(4, 9, 9, 4, "ink3")
    c.poly([(6, 2), (13, 4), (11, 9), (5, 6)], "fir1")
    c.px(11, 8, "lamp1")
    return c


def pills():
    c = Canvas(6, 9)
    c.rect(1, 2, 4, 7, "lamp0")
    c.rect(1, 3, 4, 3, "bone")
    c.rect(1, 0, 4, 2, "snow")
    return c


def mug():
    c = Canvas(6, 6)
    c.rect(0, 1, 4, 5, "cold3")
    c.px(4, 2, "cold3")
    c.px(4, 4, "cold3")
    c.px(5, 3, "cold3")
    c.hline(0, 3, 1, "cold4")
    return c


def chair():
    c = Canvas(18, 34)
    c.rect(1, 0, 3, 34, "wood1")
    c.rect(1, 18, 16, 3, "wood2")
    c.rect(14, 21, 3, 13, "wood1")
    for y in (4, 10):
        c.hline(1, 4, y, "wood3")
    return c


def bookshelf():
    c = Canvas(34, 66)
    c.rect(0, 0, 34, 66, "wood1")
    c.rect(2, 2, 30, 62, "wood0")
    rnd = random.Random(8)
    for sy in (2, 18, 34, 50):
        c.rect(2, sy + 13, 30, 3, "wood2")
        x = 3
        while x < 30:
            w = rnd.randint(2, 4)
            h = rnd.randint(8, 13)
            k = rnd.choice(["blood1", "fir1", "cold1", "wood3", "dusk2", "bone", "sky0"])
            if rnd.random() < 0.15:
                c.line(x, sy + 13, x + 5, sy + 13 - h + 2, k)
                x += 6
                continue
            c.rect(x, sy + 13 - h, w, h, k)
            c.vline(x, sy + 13 - h, sy + 12, "ink1")
            x += w
    return c


def kitchen():
    c = Canvas(64, 92)
    # shelf with jars
    c.rect(2, 10, 60, 3, "wood3")
    rnd = random.Random(2)
    for i in range(7):
        x = 4 + i * 8
        h = rnd.randint(6, 9)
        c.rect(x, 10 - h, 6, h, rnd.choice(["cold3", "lamp0", "wood3", "cold2"]))
        c.rect(x, 10 - h, 6, 1, "snow")
    # counter
    c.rect(0, 64, 64, 4, "wood3")
    c.rect(2, 68, 60, 24, "wood1")
    c.vline(32, 68, 91, "wood0")
    c.px(29, 78, "lamp0")
    c.px(35, 78, "lamp0")
    # kettle + pot
    c.ellipse(14, 58, 7, 6, "cold1")
    c.rect(8, 52, 12, 3, "cold2")
    c.line(21, 58, 25, 54, "cold1")
    c.rect(40, 56, 14, 8, "ink3")
    c.hline(38, 55, 56, "cold1")
    return c


def coats():
    c = Canvas(26, 60)
    c.rect(0, 0, 26, 3, "wood3")
    for x in (5, 19):
        c.px(x, 3, "ink3")
        c.px(x, 4, "ink3")
    # hanging parka (orange shell) and a hat
    c.poly([(2, 5), (10, 5), (12, 38), (0, 38)], "lamp0")
    c.poly([(2, 5), (6, 5), (6, 38), (0, 38)], "dusk0")
    c.hline(0, 12, 38, "wood1")
    c.ellipse(19, 9, 5, 4, "blood2")
    c.rect(14, 11, 10, 2, "blood1")
    # boots under
    c.rect(4, 52, 7, 8, "wood0")
    c.rect(13, 53, 7, 7, "wood0")
    c.rect(4, 58, 9, 2, "ink1")
    c.rect(13, 58, 9, 2, "ink1")
    return c


def radio():
    c = Canvas(16, 10)
    c.rect(0, 0, 16, 10, "cold0")
    c.rect(1, 1, 7, 8, "ink2")
    for y in range(2, 8, 2):
        c.hline(1, 7, y, "cold1")
    c.disc(11.5, 5, 2.3, "cold2")
    c.px(14, 1, "blood2")
    return c


def calendar():
    c = Canvas(18, 24)
    c.rect(0, 0, 18, 24, "bone")
    c.rect(0, 0, 18, 9, "fir1")          # photo: a lake
    c.rect(0, 6, 18, 3, "sky0")
    c.rect(0, 0, 18, 1, "wood0")
    for r in range(4):
        for k in range(5):
            c.px(2 + k * 3, 12 + r * 3, "cold1")
    return c


def chart_paper():
    """Pinned printout of a star chart on the wall."""
    c = Canvas(26, 20)
    c.rect(0, 0, 26, 20, "bone")
    c.disc(13, 10, 7, "cold4")
    for r in (3, 5, 7):
        for a in range(0, 360, 10):
            c.px(13 + math.cos(math.radians(a)) * r, 10 + math.sin(math.radians(a)) * r * 0.9, "cold2")
    c.px(13, 10, "sky0")
    c.px(8, 6, "ink2")
    c.px(18, 13, "ink2")
    c.px(1, 1, "blood2")
    return c


def rug():
    c = Canvas(70, 6)
    for x in range(70):
        for y in range(6):
            if y == 0 or y == 5:
                k = "dusk2"
            else:
                k = "blood1" if ((x // 4) % 2 == 0) ^ (y % 2 == 0) else "wood1"
            c.px(x, y, k)
    return c


def plant(state):
    """0 healthy, 1 drooping, 2 dead, 3 dead + black."""
    c = Canvas(14, 20)
    c.rect(3, 13, 8, 7, "lamp0")
    c.rect(2, 13, 10, 2, "wood3")
    rnd = random.Random(12)
    leaf = ["fir2", "fir2", "wood3", "ink2"][state]
    leaf2 = ["fir1", "fir1", "wood2", "ink1"][state]
    for i in range(7):
        a = -math.pi / 2 + (i - 3) * 0.42
        if state >= 1:
            a += (0.6 if i > 3 else -0.6) * (1 if state == 1 else 1.6)
        L = 9 if state == 0 else 7
        x0, y0 = 7, 13
        x1 = x0 + math.cos(a) * L
        y1 = y0 + math.sin(a) * L
        if state >= 1:
            y1 = max(y1, 6 + i % 3) if state == 1 else 12 + i % 4
        c.line(x0, y0, x1, y1, leaf if i % 2 else leaf2)
    return c


def stain(level):
    """Dark seep spreading down the wall behind the bed."""
    W, H = 70, 70
    c = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            n = fbm(x * 0.09, y * 0.05, 31, 4)
            d = abs(x - W / 2) / (W / 2)
            v = n - d * 0.45 - (y / H) * (1.0 - level) * 0.8
            if v > 0.48 - level * 0.12:
                c.px(x, y, (40, 14, 14, 170 if v < 0.56 else 210))
    # drip streaks
    rnd = random.Random(17)
    for i in range(int(4 + level * 8)):
        x = rnd.randint(8, W - 8)
        L = rnd.randint(10, int(20 + level * 45))
        for y in range(rnd.randint(10, 30), min(H, 10 + L)):
            c.px(x, y, (50, 10, 12, 200))
    return c


def drip():
    c = Canvas(3, 5)
    c.px(1, 0, "blood1")
    c.rect(0, 1, 3, 3, "blood2")
    c.px(1, 4, "blood1")
    return c


# --------------------------------------------------------------- the shed
def shed_shell():
    W, H = SHED_W, 180
    c = Canvas(W, H)
    for y in range(34, FLOOR):
        for x in range(W):
            r = x % 6
            k = ["cold1", "cold2", "cold2", "cold1", "cold0", "cold0"][r]
            n = fbm(x * 0.07, y * 0.05, 41, 3)
            if n > 0.63:
                k = "wood1" if n > 0.7 else "wood2"
            c.px(x, y, k)
    # horizontal girts and rivets
    for gy in (60, 104):
        c.rect(0, gy, W, 4, "ink3")
        c.hline(0, W - 1, gy, "cold2")
        for x in range(3, W, 12):
            c.px(x, gy + 2, "cold3")
    c.rect(0, 0, W, 34, "ink1")
    c.rect(0, 30, W, 4, "ink3")
    for x in range(20, W, 70):
        c.rect(x, 0, 5, 34, "ink3")
    # concrete floor
    for y in range(FLOOR, H):
        t = (y - FLOOR) / (H - FLOOR)
        for x in range(W):
            n = fbm(x * 0.1, y * 0.3, 43, 3)
            k = "cold1" if n > 0.45 else "cold0"
            if y == FLOOR:
                k = "cold2"
            if BAYER4[y % 4, x % 4] < t * 0.9:
                k = "ink3"
            c.px(x, y, k)
    # oil stain under the generator
    c.ellipse(232, FLOOR + 4, 34, 3, "ink2")
    for x0 in (0, W - 10):
        c.rect(x0, 28, 10, FLOOR - 28, "ink2")
    return c


def generator(running=False):
    c = Canvas(64, 44)
    # skid
    c.rect(0, 38, 64, 6, "ink3")
    c.hline(0, 63, 38, "cold1")
    # engine block (green paint, chipped)
    c.rect(6, 12, 34, 26, "fir1")
    c.rect(6, 12, 34, 2, "fir2")
    for i in range(14):
        x = 7 + (i * 7) % 32
        y = 15 + (i * 5) % 20
        c.px(x, y, "cold1")
    # cooling fins
    for y in range(16, 36, 3):
        c.hline(8, 22, y, "fir0")
    # tank on top
    c.rect(4, 4, 38, 9, "blood1")
    c.rect(4, 4, 38, 2, "blood2")
    c.rect(8, 1, 6, 4, "ink3")      # fuel cap
    c.rect(9, 0, 4, 2, "cold2")
    # alternator
    c.rect(40, 16, 20, 20, "cold1")
    c.rect(40, 16, 20, 2, "cold2")
    for x in range(42, 58, 3):
        c.vline(x, 20, 33, "cold0")
    # control panel with the lamp
    c.rect(44, 4, 16, 11, "ink3")
    c.rect(45, 5, 14, 9, "ink2")
    c.disc(49, 9, 2.2, "blood2" if running else "blood0")
    if running:
        c.px(48, 8, "flesh1")
    c.rect(53, 7, 4, 4, "cold2")
    c.px(54, 8, "ink1")
    # pull cord handle on the side
    c.rect(1, 22, 5, 3, "ink2")
    c.hline(0, 6, 23, "lamp0")
    # exhaust
    c.rect(28, 0, 3, 12, "ink2")
    return c


def jerrycan():
    c = Canvas(14, 18)
    c.rect(1, 3, 12, 15, "blood2")
    c.rect(1, 3, 12, 2, "flesh0")
    c.line(2, 6, 11, 16, "blood1")
    c.line(11, 6, 2, 16, "blood1")
    c.rect(4, 0, 6, 3, "ink3")
    c.rect(10, 1, 3, 3, "cold1")
    return c


def axe():
    c = Canvas(10, 24)
    c.rect(4, 2, 2, 22, "wood3")
    c.vline(4, 2, 23, "wood2")
    c.poly([(5, 0), (10, 1), (10, 7), (5, 6)], "cold2")
    c.vline(9, 1, 7, "snow")
    c.px(4, 0, "ink3")
    return c


def workbench():
    c = Canvas(80, 60)
    # pegboard with tools
    c.rect(4, 0, 72, 30, "wood2")
    for y in range(3, 30, 5):
        for x in range(7, 76, 5):
            c.px(x, y, "wood1")
    c.line(14, 6, 14, 24, "cold1")      # saw
    c.poly([(16, 6), (26, 8), (26, 22), (16, 24)], "cold2")
    c.rect(34, 5, 2, 14, "wood3")       # hammer
    c.rect(31, 5, 8, 4, "ink3")
    c.disc(54, 15, 7, "lamp0")          # coil of rope
    c.disc(54, 15, 4, "wood2")
    c.rect(64, 6, 3, 16, "blood1")      # wrench
    # bench
    c.rect(0, 36, 80, 5, "wood3")
    c.rect(2, 41, 5, 19, "wood1")
    c.rect(73, 41, 5, 19, "wood1")
    c.rect(10, 30, 12, 6, "cold1")      # vise
    c.rect(50, 31, 18, 5, "fir1")       # toolbox
    return c


def shelves():
    c = Canvas(70, 90)
    for sy in (10, 40, 70):
        c.rect(0, sy, 70, 3, "cold2")
        c.hline(0, 69, sy, "cold3")
    c.rect(2, 0, 3, 90, "cold0")
    c.rect(65, 0, 3, 90, "cold0")
    rnd = random.Random(31)
    for sy in (10, 40, 70):
        x = 6
        while x < 62:
            w = rnd.randint(6, 12)
            h = rnd.randint(6, 16)
            k = rnd.choice(["blood1", "cold1", "wood2", "fir1", "lamp0", "ink3"])
            c.rect(x, sy - h, w, h, k)
            c.hline(x, x + w - 1, sy - h, "cold3")
            x += w + rnd.randint(1, 4)
    return c


def bulb():
    c = Canvas(8, 40)
    c.vline(3, 0, 32, "ink3")
    c.rect(1, 31, 6, 3, "ink3")
    c.ellipse(4, 36, 3, 3, "lamp1")
    return c


def ceiling_lamp():
    c = Canvas(16, 12)
    c.vline(7, 0, 4, "ink3")
    c.poly([(2, 10), (7, 4), (9, 4), (14, 10)], "fir1")
    c.hline(2, 13, 10, "lamp1")
    return c


def build(save):
    save("interior/cab", cab_shell())
    for i, lv in enumerate([0.35, 0.6, 0.85, 1.0]):
        save("interior/frost_%d" % i, frost_overlay(lv))
    save("interior/door", door())
    save("interior/door_metal", door(metal=True))
    save("interior/stove", stove())
    save("interior/bed", bed())
    save("interior/desk", desk())
    save("interior/computer", computer(True))
    save("interior/computer_off", computer(False))
    save("interior/lamp", desk_lamp())
    save("interior/pills", pills())
    save("interior/mug", mug())
    save("interior/chair", chair())
    save("interior/bookshelf", bookshelf())
    save("interior/kitchen", kitchen())
    save("interior/coats", coats())
    save("interior/radio", radio())
    save("interior/calendar", calendar())
    save("interior/chart_paper", chart_paper())
    save("interior/rug", rug())
    for s in range(4):
        save("interior/plant_%d" % s, plant(s))
    for i, lv in enumerate([0.3, 0.65, 1.0]):
        save("interior/stain_%d" % i, stain(lv))
    save("interior/drip", drip())
    save("interior/ceiling_lamp", ceiling_lamp())
    save("interior/shed", shed_shell())
    save("interior/generator", generator(False))
    save("interior/generator_on", generator(True))
    save("interior/jerrycan", jerrycan())
    save("interior/axe", axe())
    save("interior/workbench", workbench())
    save("interior/shelves", shelves())
    save("interior/bulb", bulb())
