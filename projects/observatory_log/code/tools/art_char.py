"""The observer, and the hikers of the epilogue.

Observer (v2, after the ending illustrations): a tired man in a long navy
parka with the fur-trimmed hood down on his shoulders, a fitted dark-red knit
beanie, an olive backpack, dark brown work trousers, heavy boots. Selective
dark outline, light from the front-top (he faces right), roughly four heads
tall -- closer to Lone Survivor / The Count Lucanor proportions than the old
chibi block.

24x34 cells, facing right, feet on the bottom row. The engine mirrors for left.
Frame order is fixed (player.json): idle 0-1, walk 2-7, walk_axe 8-13,
kneel 14-15, pour 16-17, pull 18-19, crank 20-23, chop 24-25, reach 26-27,
push 28-29.

Hikers (char/hikers.png): four different young people, idle 0-1 + walk 2-7
each, one row per hiker.
"""
import json
import math
import os

from pix import Canvas

CW, CH = 24, 34

# --------------------------------------------------------------- palettes
OBSERVER = {
    "k": "ink0",                          # outline / darkest
    "h": "blood1", "H": "blood2", "r": "blood0",   # beanie
    "b": "wood0",                          # hair
    "s": "flesh1", "d": "wood3", "e": "ink0", "m": "wood2",   # skin, shade, eye, stubble
    "f": "cold4", "F": "cold2",           # hood fur
    "p": "ink3", "P": "cold0", "q": "ink2", "z": "cold1",       # parka
    "a": "fir1", "A": "fir2", "x": "fir0",                      # backpack
    "t": "wood1", "T": "wood2", "u": "wood0",                   # trousers
    "o": "ink1", "O": "cold0",                                  # boots
    "g": "ink1",                                                # gloves
}

# the head, facing right (11 x 9), placed at (7, 1 + bob)
HEAD = [
    "...hhhh....",
    "..hHHHhh...",
    ".hhHHhhhh..",
    ".rrrrrrrr..",
    ".bbdsssss..",
    ".bbdsssesd.",
    ".bbddsssss.",
    "..bddmmsd..",
    "...dddd....",
]

# the hood, bunched on the shoulders behind the neck (8 x 4), at (5, 8 + bob)
HOOD = [
    "...fF...",
    "..fFfF..",
    ".fFfFfF.",
    "..FfF...",
]


def stamp(c, rows, ox, oy, pal):
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                c.px(ox + x, oy + y, pal[ch])


def torso(c, pal, bob, lean=0, breath=0):
    """Long parka, x 7..16, from the collar to mid-thigh."""
    y0 = 9 + bob
    y1 = 22 + bob - breath
    for y in range(y0, y1 + 1):
        # slight A-line: wider toward the hem
        wid = 0 if y < y0 + 3 else (1 if y < y0 + 9 else 2)
        xl = 8 - wid + lean
        xr = 16 + (wid // 2) + lean
        for x in range(xl, xr + 1):
            k = "p"
            if x <= xl + 1:
                k = "q"
            elif x >= xr - 1:
                k = "P"
            c.px(x, y, pal[k])
        c.px(xr - 2, y, pal["z"]) if y > y0 + 1 else None     # zip line
    # hem and pocket, cuff of the shoulder
    c.hline(8 + lean - 2, 17 + lean, y1, pal["q"])
    c.hline(10 + lean, 13 + lean, y0 + 9, pal["q"])
    c.px(13 + lean, y0 + 10, pal["P"])
    # backpack behind, on the left (his back)
    for y in range(y0 + 1, y0 + 11):
        for x in range(4 + lean, 8 + lean):
            k = "a"
            if x == 4 + lean or y == y0 + 10:
                k = "x"
            elif y == y0 + 1 or x == 7 + lean and y < y0 + 4:
                k = "A"
            c.px(x, y, pal[k])
    c.hline(5 + lean, 6 + lean, y0 + 6, pal["x"])      # flap buckle line
    c.px(7 + lean, y0 + 2, pal["x"])                    # strap
    c.vline(9 + lean, y0 + 1, y0 + 6, pal["x"])          # strap over the shoulder


def leg(c, pal, hx, hy, fx, fy, lift, front):
    kx = (hx + fx) / 2 + (1.5 if lift > 0 else 0.5)
    ky = (hy + fy) / 2 - lift * 0.5
    k = pal["t"] if front else pal["u"]
    c.thick_line(hx, hy, kx, ky, k, 3)
    c.thick_line(kx, ky, fx, fy - 2, k, 3)
    if front:
        c.line(kx + 1, ky, fx + 1, fy - 3, pal["T"])
    bx, by = int(round(fx)), int(round(fy))
    bc = pal["o"]
    c.rect(bx - 1, by - 2, 4, 2, bc)
    c.px(bx + 3, by - 1, bc)
    c.hline(bx - 1, bx + 3, by, pal["k"])
    if front:
        c.hline(bx, bx + 2, by - 2, pal["O"])


def arm(c, pal, bob, hx, hy, front=True, sx=None, sy=None):
    sx = 12 if sx is None else sx
    sy = (12 + bob) if sy is None else sy
    k = pal["P"] if front else pal["q"]
    mx = (sx + hx) / 2
    my = (sy + hy) / 2 + 1
    c.thick_line(sx, sy, mx, my, k, 3)
    c.thick_line(mx, my, hx, hy, k, 3)
    if front:
        c.line(sx + 1, sy, mx + 1, my, pal["z"])
    c.rect(int(round(hx)) - 1, int(round(hy)) - 1, 3, 3, pal["g"])


def finish(c, pal):
    """Selective outline: dark ink around the whole figure."""
    c.outline(pal["k"])
    return c


WALK = [((4, 0), (-3, 0), 1), ((2, 0), (-1, 1), 0), ((0, 0), (1, 2), 0),
        ((-3, 0), (4, 0), 1), ((-1, 1), (2, 0), 0), ((1, 2), (0, 0), 0)]
HIP = (12, 22)


def frame_walk(pal, i, prop=None, head=HEAD, hood=HOOD):
    c = Canvas(CW, CH)
    (fdx, flift), (bdx, blift), bob = WALK[i]
    hx, hy = HIP[0], HIP[1] + bob
    arm(c, pal, bob, 12 - fdx * 0.7, 21 + bob, front=False)
    leg(c, pal, hx - 1, hy, hx + bdx, CH - 2 - blift, blift, False)
    torso(c, pal, bob)
    leg(c, pal, hx + 1, hy, hx + 1 + fdx, CH - 2 - flift, flift, True)
    if hood:
        stamp(c, hood, 5, 8 + bob, pal)
    stamp(c, head, 7, 1 + bob, pal)
    hand = (12 + bdx * 0.8 + 1, 21 + bob)
    if prop == "axe":
        _axe_in_hand(c, hand[0], hand[1])
    arm(c, pal, bob, hand[0], hand[1], front=True)
    return finish(c, pal)


def _axe_in_hand(c, x, y):
    c.line(x - 1, y + 2, x + 3, y - 8, "wood3")
    c.poly([(x + 2, y - 10), (x + 7, y - 9), (x + 6, y - 5), (x + 3, y - 6)], "cold2")
    c.px(x + 6, y - 9, "snow")


def frame_idle(pal, i, head=HEAD, hood=HOOD):
    c = Canvas(CW, CH)
    hx, hy = HIP
    arm(c, pal, 0, 11, 21, front=False)
    leg(c, pal, hx - 1, hy, hx - 1, CH - 2, 0, False)
    torso(c, pal, 0, breath=i)
    leg(c, pal, hx + 1, hy, hx + 2, CH - 2, 0, True)
    if hood:
        stamp(c, hood, 5, 8, pal)
    stamp(c, head, 7, 1, pal)
    arm(c, pal, 0, 14, 22 - i, front=True)
    return finish(c, pal)


def frame_pose(pal, kind, i):
    c = Canvas(CW, CH)
    hx, hy = HIP
    if kind == "kneel":
        bob = 5
        leg(c, pal, hx - 1, hy + bob, hx - 5, CH - 2, 0, False)
        torso(c, pal, bob, breath=2)
        c.thick_line(hx + 1, hy - 1 + bob - 2, hx + 6, hy + bob - 2, pal["t"], 3)
        c.thick_line(hx + 6, hy + bob - 2, hx + 6, CH - 4, pal["t"], 3)
        c.rect(hx + 4, CH - 5, 6, 3, pal["o"])
        stamp(c, HOOD, 5, 8 + bob, pal)
        stamp(c, HEAD, 7, 1 + bob, pal)
        dip = i * 2
        # the sounder's hydrophone: a cable down into the hole
        arm(c, pal, bob, 18, 26 + dip, front=True)
        c.rect(17, 25 + dip, 4, 3, "cold1")
        c.vline(19, 28 + dip, CH - 1, "cold2")
        return finish(c, pal)
    leg(c, pal, hx - 1, hy, hx - 3, CH - 2, 0, False)
    torso(c, pal, 0)
    leg(c, pal, hx + 1, hy, hx + 3, CH - 2, 0, True)
    stamp(c, HOOD, 5, 8, pal)
    stamp(c, HEAD, 7, 1, pal)
    if kind == "pour":
        tilt = i
        cx, cy = 15, 14 - tilt
        c.poly([(cx, cy), (cx + 7, cy + 2 + tilt), (cx + 6, cy + 9 + tilt), (cx - 1, cy + 7)], "blood2")
        c.line(cx, cy + 1, cx + 6, cy + 3 + tilt, "flesh0")
        c.line(cx + 7, cy + 2 + tilt, cx + 10, cy + 1 + tilt * 2, "ink3")
        arm(c, pal, 0, cx + 1, cy + 3, front=True)
    elif kind == "pull":
        hand = [(20, 19), (9, 16)][i]
        arm(c, pal, 0, hand[0], hand[1], front=True)
        c.line(hand[0] + 1, hand[1], 23, 23, "lamp0")
    elif kind == "crank":
        a = i * math.pi / 2
        hand = (19 + math.cos(a) * 3, 18 + math.sin(a) * 3)
        arm(c, pal, 0, hand[0], hand[1], front=True)
    elif kind == "chop":
        if i == 0:
            arm(c, pal, 0, 12, 5, front=True)
            c.line(11, 6, 6, 3, "wood3")
            c.poly([(4, 5), (8, 2), (9, 5), (6, 7)], "cold2")
        else:
            arm(c, pal, 0, 20, 23, front=True)
            c.line(20, 23, 23, 31, "wood3")
            c.poly([(21, 30), (23, 33), (24, 29)], "cold2")
    elif kind == "reach":
        arm(c, pal, 0, 20 + i, 16, front=True)
    elif kind == "push":
        arm(c, pal, 0, 20 + i, 14, front=True)
    return finish(c, pal)


# ------------------------------------------------------------------- hikers
# Thirteen years later: four young people, nobody looks like the observer.
def _hiker_pal(base, lit, dark, hat, hat_lit, legs, legs_lit, pack, pack_lit, hair, skin_d="wood3"):
    p = dict(OBSERVER)
    p.update({"p": base, "P": lit, "q": dark, "z": lit,
              "h": hat, "H": hat_lit, "r": hat,
              "t": legs, "T": legs_lit, "u": "ink1",
              "a": pack, "A": pack_lit, "x": "ink1", "b": hair, "d": skin_d,
              "f": "snow", "F": "cold3", "g": "ink1"})
    return p


HIKERS = [
    # 1 tall, orange shell jacket (the gloved hand in the illustration), big trekking pack, grey beanie
    (_hiker_pal("dusk0", "dusk0", "dusk1", "cold1", "cold2", "ink2", "ink3", "blood1", "blood2", "wood1"),
     ["...hhhh....", "..hHHHhh...", ".hhHHhhhh..", ".rrrrrrrr..", ".bbbdssss..", ".bbbdssess.",
      ".bbddsssss.", "..bdddssk..", "...ddd.....", "...ddd....."], None, 6),
    # 2 short, yellow jacket, pom-pom hat, long hair
    (_hiker_pal("lamp0", "lamp1", "wood2", "crt", "cold4", "cold0", "cold1", "dusk2", "dusk1", "wood2"),
     ["....H.....", "...hhhh....", "..hHHHhh...", ".hhHHhhhh..", ".rrrrrrrr..", ".bbbbssss..",
      ".bbbdssess.", ".bbbdsssss.", ".bbbddssk..", "..bb.dd...."], None, 0),
    # 3 green parka with the hood up, glasses glint
    (_hiker_pal("fir1", "fir2", "fir0", "fir1", "fir2", "wood1", "wood2", "wood2", "wood3", "wood0"),
     ["...hhhh....", "..hHHHhhh..", ".hhHHHhhhh.", ".hhhrrrrhh.", ".hhbdssssh.", ".hhbdsslsh.",
      ".hhbddsssh.", "..hhddsskh.", "...hhddd...", "....hhh...."], None, 0),
    # 4 purple jacket, bare head, short hair, headlamp
    (_hiker_pal("dusk2", "dusk1", "ink3", "wood0", "wood1", "ink2", "ink3", "cold1", "cold2", "wood0"),
     ["...bbbb....", "..bbbbbb...", ".bbbbbbbb..", ".bbbbllbb..", ".bbbdssss..", ".bbbdssess.",
      ".bbddsssss.", "..bddsdsk..", "...ddd.....", "...ddd....."], None, 0),
]


def hiker_frames(n):
    pal, head, hood, _ = HIKERS[n]
    pal = dict(pal)
    pal["l"] = "lamp1" if n == 3 else "cold4"
    out = [frame_idle(pal, 0, head, hood), frame_idle(pal, 1, head, hood)]
    out += [frame_walk(pal, i, None, head, hood) for i in range(6)]
    if n == 1:
        # shorter: shift down two pixels
        for k, f in enumerate(out):
            g = Canvas(CW, CH)
            g.blit(f, 0, 2)
            out[k] = g
    if n == 0:
        # the big trekking pack, rising above the shoulders
        for f in out:
            top = next(y for y in range(CH) if f.a[y, :, 3].any())
            f.rect(3, top + 8, 4, 12, "blood1")
            f.rect(3, top + 6, 3, 3, "blood2")
            f.hline(3, 6, top + 13, "ink1")
            f.outline("ink0")
    return out


def build(save):
    frames = []
    anims = {}
    pal = OBSERVER

    def add(name, cs):
        anims[name] = list(range(len(frames), len(frames) + len(cs)))
        frames.extend(cs)

    add("idle", [frame_idle(pal, 0), frame_idle(pal, 1)])
    add("walk", [frame_walk(pal, i) for i in range(6)])
    add("walk_axe", [frame_walk(pal, i, "axe") for i in range(6)])
    add("kneel", [frame_pose(pal, "kneel", i) for i in range(2)])
    add("pour", [frame_pose(pal, "pour", i) for i in range(2)])
    add("pull", [frame_pose(pal, "pull", i) for i in range(2)])
    add("crank", [frame_pose(pal, "crank", i) for i in range(4)])
    add("chop", [frame_pose(pal, "chop", i) for i in range(2)])
    add("reach", [frame_pose(pal, "reach", i) for i in range(2)])
    add("push", [frame_pose(pal, "push", i) for i in range(2)])
    sheet = Canvas(CW * len(frames), CH)
    for i, f in enumerate(frames):
        sheet.blit(f, i * CW, 0)
    save("char/player", sheet)
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "..", "assets", "art", "char", "player.json"), "w") as fh:
        json.dump({"w": CW, "h": CH, "anims": anims}, fh)
    hk = Canvas(CW * 8, CH * len(HIKERS))
    for n in range(len(HIKERS)):
        for i, f in enumerate(hiker_frames(n)):
            hk.blit(f, i * CW, n * CH)
    save("char/hikers", hk)
