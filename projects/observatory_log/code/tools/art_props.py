"""Set dressing (art pass 2): the site should look lived in and then left.

Outdoor: telephone poles, birches (it is Birch Lake), oil drums, a woodpile
and chopping block, an empty kennel with its chain, a mailbox, a fuel tank,
crates, a snowmobile under a tarp, fence, a thin-ice sign, rocks, drifts,
dry grass, ravens. Foreground pieces drawn in front of the player.
Interior: lake map with a circle on it, clock, photo, shelf of tins, boots,
radiator, snowshoes, pinned papers; shed: tyres, chain, shovel, tarp, toolbox.

All bottoms sit on the ground row unless noted. Daylight colours; the engine
lights them and the post shader quantises.
"""
import math
import random

from pix import Canvas, hash01, fbm


# ================================================================ outdoor
def pole():
    """Telephone pole, 13 x 112. Wire attachment at local (6, 6)."""
    c = Canvas(13, 112)
    c.rect(5, 4, 3, 108, "wood1")
    c.vline(5, 4, 111, "wood2")
    for y in range(10, 108, 9):
        c.px(6, y, "wood0")
    c.rect(0, 8, 13, 2, "wood1")              # crossarm
    c.hline(0, 12, 8, "wood2")
    for x in (1, 6, 11):
        c.rect(x, 5, 1, 3, "cold3")           # insulators
        c.px(x, 5, "snow")
    c.hline(4, 8, 4, "snow")                  # snow on the cap
    c.hline(0, 12, 7, "cold4")
    c.rect(4, 90, 5, 3, "cold1")              # tag plate
    return c


def birch(h, seed):
    """Bare birch: white trunk with black lenticels, fine dark twigs."""
    rnd = random.Random(seed)
    w = 30
    c = Canvas(w, h)
    cx = w // 2
    # crown of twigs first (behind)
    for i in range(14):
        y0 = rnd.randint(4, int(h * 0.55))
        L = rnd.randint(5, 12)
        d = rnd.choice([-1, 1])
        x, y = cx, y0
        for k in range(L):
            x += d * (1 if rnd.random() < 0.8 else 0)
            y -= 1 if rnd.random() < 0.6 else 0
            c.px(x, y, "ink2" if k < L // 2 else "ink3")
            if rnd.random() < 0.25:
                c.px(x, y - 1, "cold1")
    lean = rnd.uniform(-0.06, 0.06)
    for y in range(2, h):
        x = cx + int((h - y) * lean)
        tw = 1 if y < h * 0.2 else (2 if y < h * 0.5 else 3)
        for k in range(tw + 1):
            c.px(x + k, y, "bone" if k < tw else "cold2")
        if hash01(y, seed) < 0.22:
            c.hline(x, x + tw - 1, y, "ink1")
    c.hline(cx - 2, cx + 3, h - 1, "cold3")
    return c


def drum(rust=0):
    c = Canvas(12, 16)
    base = "wood2" if rust else "cold0"
    c.rect(1, 2, 10, 14, base)
    c.vline(1, 2, 15, "ink2")
    c.vline(9, 2, 15, "cold1" if not rust else "wood3")
    for y in (5, 11):
        c.hline(1, 10, y, "ink3")
    c.ellipse(6, 2.5, 5, 1.6, "snow")
    if rust:
        for i in range(10):
            c.px(2 + int(hash01(i, 7) * 8), 3 + int(hash01(i, 8) * 12), "blood1")
    c.hline(1, 10, 15, "ink1")
    return c


def woodpile():
    c = Canvas(40, 22)
    rnd = random.Random(4)
    # lean-to roof
    c.poly([(0, 3), (40, 0), (40, 3), (0, 6)], "wood1")
    c.hline(0, 39, 2, "snow")
    c.hline(0, 39, 1, "snow")
    c.vline(1, 5, 21, "wood0")
    c.vline(38, 2, 21, "wood0")
    for row in range(5):
        y = 20 - row * 3
        for k in range(12 - (row % 2)):
            x = 3 + k * 3 + (1 if row % 2 else 0)
            c.disc(x + 1.5, y - 0.5, 1.6, "wood2")
            c.px(x + 1, y - 1, "wood3")
            if rnd.random() < 0.3:
                c.px(x + 2, y, "wood1")
    c.hline(2, 37, 6, "cold4")
    return c


def block():
    c = Canvas(12, 10)
    c.rect(1, 3, 10, 7, "wood1")
    c.ellipse(6, 3, 5, 1.6, "wood3")
    c.line(4, 3, 8, 2, "wood1")
    c.hline(1, 10, 9, "ink2")
    c.px(3, 1, "snow")
    c.px(9, 2, "snow")
    return c


def boathouse():
    """The abandoned boathouse on the north shore, 128 x 84. Gable roof sagging
    under snow, grey boards with gaps, a boarded window, a side door with a
    rusted locker beside it (left), the open bay toward the ice (right)."""
    rnd = random.Random(21)
    W, H = 128, 84
    c = Canvas(W, H)
    # stilts under the lake end
    for x in (92, 108, 122):
        c.rect(x, 70, 3, 14, "wood0")
    # walls: vertical boards, weathered grey-brown, some gaps; the gable filled
    for x in range(6, 122, 4):
        k = rnd.choice(["wood1", "wood1", "wood2", "cold0"])
        top = 37 - (64 - abs(x + 2 - 64)) * 26 // 64
        c.rect(x, top, 4, 72 - top, k)
        c.vline(x, top, 71, "wood0")
        if rnd.random() < 0.18:
            c.vline(x + 2, top + rnd.randint(4, 20), top + rnd.randint(24, 36), "ink0")
    # roof: low gable, sagging in the middle, snow on it, icicles
    c.poly([(0, 34), (64, 6), (128, 34), (128, 38), (64, 12), (0, 38)], "wood0")
    c.poly([(2, 33), (64, 5), (66, 8), (4, 36)], "snow")
    c.poly([(64, 5), (126, 33), (124, 36), (62, 8)], "cold4")
    for x in range(4, 124, 5):
        y = int(38 - (64 - abs(x - 64)) * 26 / 64) + 1
        c.vline(x, y, y + rnd.randint(1, 4), "cold3")
    # boarded window
    c.rect(26, 44, 16, 12, "ink1")
    c.line(25, 45, 43, 54, "wood2")
    c.line(25, 53, 43, 46, "wood2")
    # side door, and the locker on the wall beside it
    c.rect(48, 46, 14, 26, "ink2")
    c.rect(49, 47, 12, 24, "wood1")
    c.px(59, 59, "lamp0")
    c.rect(12, 56, 9, 14, "cold1")
    c.rect(13, 57, 7, 12, "cold0")
    c.hline(13, 19, 62, "ink2")
    c.px(18, 60, "wood3")                          # rust on the latch
    # the bay toward the ice: a black opening, a frozen slip
    c.rect(78, 40, 44, 32, "ink0")
    c.rect(80, 64, 40, 8, "cold2")
    c.hline(80, 119, 64, "cold4")
    c.line(78, 40, 121, 40, "wood0")
    # snow banked against the shore side
    c.poly([(0, 84), (0, 70), (20, 66), (46, 72), (60, 84)], "snow")
    c.poly([(0, 84), (0, 74), (30, 72), (56, 84)], "cold4")
    return c


def rowboat():
    """An overturned rowboat frozen into the shore ice, 50 x 16."""
    c = Canvas(50, 16)
    c.poly([(2, 12), (6, 5), (18, 2), (34, 2), (46, 5), (49, 12)], "wood2")
    c.poly([(6, 5), (18, 2), (34, 2), (34, 4), (18, 5), (8, 7)], "wood3")
    for x in range(8, 46, 6):
        c.line(x, 4, x + 1, 12, "wood1")
    c.hline(2, 49, 12, "wood0")
    c.poly([(10, 3), (22, 1), (38, 1), (44, 4), (30, 3)], "snow")
    c.rect(0, 12, 50, 4, "cold3")                  # the ice it is frozen into
    c.hline(0, 49, 12, "cold4")
    for x in (6, 17, 29, 41):
        c.px(x, 13, "cold1")
    return c


def trail_sign(flip=False, dish=True):
    """Post with a pointer board (no words); the antenna trail's has a dish burnt in."""
    c = Canvas(22, 30)
    c.rect(10, 6, 2, 24, "wood1")
    c.vline(10, 6, 29, "wood2")
    pts = [(2, 4), (17, 4), (21, 8), (17, 12), (2, 12)]
    if flip:
        pts = [(22 - x, y) for (x, y) in pts]
    c.poly(pts, "wood2")
    c.hline(3, 18, 4, "snow") if not flip else c.hline(4, 19, 4, "snow")
    if dish:
        # a small mast-and-dish pictogram burnt into the board
        bx = 7 if not flip else 11
        c.vline(bx + 2, 6, 10, "wood0")
        c.line(bx, 6, bx + 4, 8, "wood0")
        c.px(bx, 7, "wood0")
    return c


def kennel():
    c = Canvas(26, 20)
    c.poly([(1, 8), (13, 1), (25, 8)], "wood1")
    c.line(1, 8, 13, 1, "snow")
    c.line(13, 1, 25, 8, "cold4")
    c.rect(3, 8, 20, 12, "wood2")
    for x in range(3, 23, 3):
        c.vline(x, 8, 19, "wood1")
    c.rect(9, 11, 8, 9, "ink0")
    c.poly([(9, 11), (13, 8), (17, 11)], "ink0")
    # the chain, running out of the door and lying empty in the snow
    for i in range(10):
        c.px(16 + i, 18 + (i % 2), "cold2")
    c.ellipse(24, 18.5, 2, 1, "cold1")         # bowl
    return c


def mailbox():
    c = Canvas(10, 24)
    c.rect(4, 8, 2, 16, "wood1")
    c.rect(0, 2, 10, 7, "blood1")
    c.ellipse(5, 2.5, 5, 2, "blood1")
    c.hline(0, 9, 1, "snow")
    c.hline(1, 8, 0, "snow")
    c.rect(8, 3, 1, 4, "lamp0")                # the flag, still up
    c.rect(8, 3, 2, 1, "lamp0")
    return c


def fuel_tank():
    c = Canvas(44, 26)
    for x in (6, 36):
        c.rect(x, 16, 3, 10, "ink3")
    c.rect(2, 4, 40, 13, "cold1")
    c.ellipse(3, 10.5, 2.5, 6.5, "cold0")
    c.ellipse(41, 10.5, 2.5, 6.5, "cold2")
    c.hline(3, 41, 5, "cold2")
    c.hline(3, 41, 16, "ink3")
    c.hline(4, 40, 3, "snow")
    c.hline(6, 38, 2, "snow")
    for i in range(18):
        c.px(4 + int(hash01(i, 3) * 36), 6 + int(hash01(i, 4) * 10), "wood2")
    c.rect(18, 9, 10, 3, "lamp0")              # hazard band
    c.rect(20, 0, 3, 3, "ink3")
    return c


def crates():
    c = Canvas(26, 22)
    for (x, y, w, h) in ((0, 10, 14, 12), (13, 12, 12, 10), (4, 0, 12, 10)):
        c.rect(x, y, w, h, "wood2")
        c.rect(x, y, w, 1, "wood3")
        c.rect(x, y + h - 1, w, 1, "wood1")
        c.line(x, y, x + w - 1, y + h - 1, "wood1")
        c.hline(x, x + w - 1, y - 1, "snow")
    return c


def snowmobile():
    c = Canvas(40, 18)
    c.poly([(2, 8), (10, 2), (30, 1), (38, 6), (38, 14), (2, 14)], "cold1")   # tarp over it
    c.poly([(2, 8), (10, 2), (30, 1), (30, 4), (10, 5), (3, 10)], "cold2")
    c.line(10, 2, 30, 1, "snow")
    c.line(2, 8, 10, 2, "snow")
    for x in range(4, 38, 6):
        c.line(x, 6, x + 2, 14, "cold0")       # folds
    c.rect(0, 14, 40, 2, "ink2")               # skis
    c.px(39, 13, "ink2")
    c.hline(0, 39, 16, "cold3")
    c.rect(33, 9, 4, 3, "blood2")              # a red corner of the hood showing
    return c


def fence(broken=False):
    c = Canvas(44, 16)
    for x in (2, 21, 40):
        c.rect(x, 2, 2, 14, "wood1")
        c.px(x, 1, "snow")
        c.px(x + 1, 1, "snow")
    for y in (5, 10):
        if broken and y == 5:
            c.line(3, y, 20, y, "wood2")
            c.line(22, y, 34, y + 8, "wood2")
        else:
            c.hline(3, 41, y, "wood2")
        c.hline(3, 41, y - 1, "cold4")
    return c


def ice_sign():
    """No words: a triangle with a figure falling through a crack."""
    c = Canvas(16, 26)
    c.rect(7, 12, 2, 14, "wood1")
    c.poly([(8, 0), (16, 13), (0, 13)], "blood2")
    c.poly([(8, 3), (13, 11), (3, 11)], "bone")
    c.line(5, 10, 11, 10, "ink2")
    c.px(8, 6, "ink1")
    c.line(8, 7, 8, 9, "ink1")
    c.hline(0, 16, 14, "snow")
    return c


def rock(seed, w=18, h=10):
    c = Canvas(w, h)
    rnd = random.Random(seed)
    pts = [(0, h), (2, h - 4 - rnd.randint(0, 2)), (w * 0.35, 1 + rnd.randint(0, 2)),
           (w * 0.7, 2 + rnd.randint(0, 2)), (w - 1, h - 3), (w, h)]
    c.poly(pts, "ink3")
    c.poly([(2, h - 4), (w * 0.35, 1), (w * 0.5, 3), (w * 0.3, h - 3)], "cold0")
    for x in range(w):
        for y in range(h):
            if c.opaque(x, y) and not c.opaque(x, y - 1) and rnd.random() < 0.85:
                c.px(x, y, "snow")
                c.px(x, y + 1, "cold4")
                break
    return c


def drift(w, h, seed):
    c = Canvas(w, h)
    for x in range(w):
        t = x / (w - 1)
        top = h - h * math.sin(t * math.pi) ** 0.7 * (0.85 + 0.15 * fbm(x * 0.1, seed, 2))
        for y in range(int(top), h):
            k = "snow" if y < top + 2 else ("cold4" if x < w * 0.6 else "cold3")
            c.px(x, y, k)
    return c


def grass(seed, h=10, w=10, dark=False):
    c = Canvas(w, h)
    rnd = random.Random(seed)
    for i in range(w + 4):
        x = rnd.uniform(1, w - 2)
        L = rnd.randint(h // 2, h - 1)
        bend = rnd.uniform(-2, 2)
        for k in range(L):
            yy = h - 1 - k
            xx = x + bend * (k / L) ** 2
            c.px(xx, yy, ("wood1" if k < L * 0.4 else "wood2") if dark else ("wood2" if k < L * 0.5 else "wood3"))
    return c


def raven(frame):
    c = Canvas(8, 6)
    c.rect(2, 2, 4, 3, "ink0")
    c.rect(5, 1, 2, 2, "ink0")
    c.px(7, 2, "ink2")                         # beak
    c.px(6, 1, "ink0")
    c.line(0, 4, 2, 3, "ink0")                 # tail
    c.px(3, 5, "ink1")
    c.px(4, 5, "ink1")
    if frame == 1:
        c.px(5, 0, "ink0")                     # head turned
    return c


# ------------------------------------------------------------- foreground
def fg_branch(seed):
    """A snowy spruce bough hanging into the top of the frame, 80 x 44."""
    rnd = random.Random(seed)
    c = Canvas(80, 44)
    c.thick_line(0, 2, 78, 20, "wood0", 3)
    for i in range(70):
        t = i / 70
        x = t * 78
        y = 2 + t * 18
        L = rnd.randint(5, 14) * (1 - t * 0.4)
        a = rnd.uniform(1.2, 2.2)
        x2, y2 = x + math.cos(a) * L, y + math.sin(a) * L
        c.line(x, y, x2, y2, "fir0")
        c.line(x + 1, y, x2 + 1, y2, "fir1" if rnd.random() < 0.5 else "fir0")
        if rnd.random() < 0.6:
            c.px(x, y - 1, "snow")
            c.px(x + 1, y - 1, "cold4")
    return c


def fg_reeds(seed):
    return grass(seed, 30, 34, dark=True)


# =============================================================== interior
def lake_map():
    """Survey map of the lake pinned to the wall: a red circle in the middle."""
    c = Canvas(32, 22)
    c.rect(0, 0, 32, 22, "bone")
    c.rect(0, 21, 32, 1, "wood1")
    c.ellipse(16, 11, 12, 8, "sky1")
    c.ellipse(16, 11, 9, 6, "sky0")
    for r in (4, 7):
        for a in range(24):
            ang = a / 24 * math.tau
            c.px(16 + math.cos(ang) * r * 1.3, 11 + math.sin(ang) * r * 0.8, "cold3")
    for a in range(28):
        ang = a / 28 * math.tau
        c.px(16 + math.cos(ang) * 3, 11 + math.sin(ang) * 2, "blood2")
    c.px(16, 11, "blood1")
    c.px(3, 2, "blood2")
    c.px(28, 2, "blood2")
    return c


def clock():
    c = Canvas(11, 11)
    c.disc(5.5, 5.5, 5.5, "wood1")
    c.disc(5.5, 5.5, 4.3, "bone")
    c.line(5, 5, 5, 2, "ink0")
    c.line(5, 5, 8, 6, "ink0")
    return c


def photo():
    c = Canvas(9, 11)
    c.rect(0, 0, 9, 11, "wood2")
    c.rect(1, 1, 7, 9, "cold2")
    c.rect(3, 3, 3, 3, "flesh1")               # a face
    c.rect(2, 6, 5, 4, "ink3")
    c.rect(3, 2, 3, 1, "blood1")               # the red beanie
    return c


def shelf_tins():
    c = Canvas(28, 16)
    c.rect(0, 7, 28, 2, "wood2")
    c.rect(0, 15, 28, 1, "wood2")
    cols = ["blood2", "cold2", "lamp0", "cold2", "fir2", "blood2", "cold1"]
    for i, k in enumerate(cols):
        x = 1 + i * 4
        c.rect(x, 2, 3, 5, k)
        c.px(x, 2, "bone")
        if i % 2 == 0:
            c.rect(x, 10, 3, 5, cols[(i + 3) % len(cols)])
    return c


def boots():
    c = Canvas(14, 7)
    for x in (0, 7):
        c.rect(x, 1, 4, 6, "ink1")
        c.rect(x + 3, 4, 3, 3, "ink1")
        c.hline(x, x + 5, 6, "ink0")
        c.px(x + 1, 2, "cold1")
    return c


def radiator():
    c = Canvas(22, 14)
    for x in range(0, 22, 3):
        c.rect(x, 1, 2, 12, "cold1")
        c.px(x, 1, "cold3")
    c.hline(0, 21, 12, "cold0")
    c.rect(0, 13, 1, 1, "ink2")
    return c


def snowshoes():
    c = Canvas(14, 26)
    for x in (2, 8):
        c.ellipse(x + 2, 13, 2.6, 12, "wood2")
        c.ellipse(x + 2, 13, 1.6, 10.5, "wood0")
        for y in range(4, 24, 3):
            c.hline(x + 1, x + 3, y, "bone")
    c.px(7, 0, "cold2")
    return c


def papers():
    c = Canvas(16, 18)
    c.rect(0, 2, 9, 12, "bone")
    c.rect(6, 5, 10, 13, "cold4")
    for y in range(5, 13, 2):
        c.hline(1, 7, y, "cold2")
    for y in range(8, 17, 2):
        c.hline(7, 14, y, "cold2")
    c.px(4, 2, "blood2")
    c.px(11, 5, "blood2")
    return c


def tyres():
    c = Canvas(20, 16)
    for i, y in enumerate((11, 6, 1)):
        c.ellipse(10, y + 2.5, 9 - i, 2.6, "ink1")
        c.ellipse(10, y + 2.2, 5 - i, 1.2, "ink3")
    return c


def chain():
    c = Canvas(4, 34)
    for y in range(0, 32, 2):
        c.px(1 + (y // 2) % 2, y, "cold2")
        c.px(1 + (y // 2) % 2, y + 1, "cold1")
    c.rect(0, 31, 4, 3, "cold1")                # hook
    return c


def shovel():
    c = Canvas(8, 34)
    c.rect(3, 0, 2, 22, "wood2")
    c.rect(1, 0, 6, 2, "ink2")
    c.poly([(0, 22), (8, 22), (7, 33), (1, 33)], "cold1")
    c.vline(1, 22, 32, "cold2")
    return c


def tarp_box():
    c = Canvas(30, 16)
    c.poly([(0, 16), (2, 3), (14, 0), (28, 2), (30, 16)], "fir1")
    c.poly([(2, 3), (14, 0), (15, 6), (4, 9)], "fir2")
    for x in range(4, 28, 7):
        c.line(x, 2, x + 2, 15, "fir0")
    c.line(0, 9, 30, 8, "lamp0")               # rope
    return c


def toolbox():
    c = Canvas(14, 8)
    c.rect(0, 2, 14, 6, "blood2")
    c.rect(0, 2, 14, 1, "flesh0")
    c.rect(5, 0, 4, 2, "ink2")
    c.hline(0, 13, 7, "blood0")
    return c


def build(save):
    save("props/pole", pole())
    for i, (h, s) in enumerate([(64, 11), (80, 12), (94, 13)]):
        save("props/birch_%d" % i, birch(h, s))
    save("props/drum_0", drum(0))
    save("props/drum_1", drum(1))
    save("props/woodpile", woodpile())
    save("props/block", block())
    save("props/boathouse", boathouse())
    save("props/rowboat", rowboat())
    save("props/trail_sign", trail_sign(False))
    save("props/trail_sign_down", trail_sign(True))
    save("props/path_sign", trail_sign(False, False))
    save("props/path_sign_back", trail_sign(True, False))
    save("props/mailbox", mailbox())
    save("props/fuel_tank", fuel_tank())
    save("props/crates", crates())
    save("props/snowmobile", snowmobile())
    save("props/fence_0", fence(False))
    save("props/fence_1", fence(True))
    save("props/ice_sign", ice_sign())
    for i in range(3):
        save("props/rock_%d" % i, rock(30 + i, 14 + i * 6, 8 + i * 2))
    save("props/drift_0", drift(48, 9, 1))
    save("props/drift_1", drift(70, 12, 2))
    for i in range(3):
        save("props/grass_%d" % i, grass(40 + i))
    save("props/raven_0", raven(0))
    save("props/raven_1", raven(1))
    save("props/fg_branch_0", fg_branch(1))
    save("props/fg_branch_1", fg_branch(2))
    save("props/fg_reeds", fg_reeds(5))
    save("props/lake_map", lake_map())
    save("props/clock", clock())
    save("props/photo", photo())
    save("props/shelf_tins", shelf_tins())
    save("props/boots", boots())
    save("props/radiator", radiator())
    save("props/snowshoes", snowshoes())
    save("props/papers", papers())
    save("props/tyres", tyres())
    save("props/chain", chain())
    save("props/shovel", shovel())
    save("props/tarp_box", tarp_box())
    save("props/toolbox", toolbox())
