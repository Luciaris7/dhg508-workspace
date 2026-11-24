"""Outdoor art: far backdrop, firs, ground, lookout tower, generator shed,
antenna, junction box, pickup truck, sign, shore, bucket, ice.

Drawn in neutral daylight colours; time of day comes from the engine's
CanvasModulate + 2D lights, and the post shader quantises to the palette.
"""
import math
import random

from pix import Canvas, col, mix, shade, fbm, vnoise, hash01, BAYER4

SNOW = "snow"
INK = "ink0"


# ------------------------------------------------------------------ firs
def fir(h, seed, snow=True, bare=False):
    w = int(h * 0.62) | 1
    c = Canvas(w + 4, h + 4)
    cx = (w + 4) // 2
    rng = random.Random(seed)
    trunk_h = max(3, h // 9)
    top = 2
    base = h + 2 - trunk_h
    c.rect(cx - 1, base - 2, 3, trunk_h + 2, "wood1")
    if bare:
        # dead spruce: a spine and short black twigs
        c.vline(cx, top, h + 1, "ink2")
        c.vline(cx + 1, top + 4, h + 1, "ink1")
        y = top + 3
        while y < base:
            half = int((y - top) / (base - top) * (w * 0.42)) + 1
            L = rng.randint(max(1, half // 2), half)
            dirn = -1 if (y // 3) % 2 == 0 else 1
            c.line(cx, y, cx + dirn * L, y + rng.randint(-2, 1), "ink2")
            if rng.random() < 0.5:
                c.line(cx, y + 1, cx - dirn * (L - 1), y + rng.randint(-1, 2), "ink1")
            y += rng.randint(2, 4)
        return c
    # tiers of drooping boughs
    tiers = max(4, h // 7)
    for i in range(tiers):
        t = i / (tiers - 1)
        ty = top + int(t * (base - top - 4))
        half = 1.5 + t * (w * 0.5 - 1)
        th = max(4, int(h / tiers * 1.7))
        pts = [(cx, ty), (cx + half, ty + th), (cx + half * 0.55, ty + th - 1),
               (cx + half * 0.2, ty + th + 1), (cx - half * 0.2, ty + th + 1),
               (cx - half * 0.55, ty + th - 1), (cx - half, ty + th)]
        c.poly(pts, "fir0")
        # lit left flank
        pts2 = [(cx, ty), (cx - half, ty + th), (cx - half * 0.55, ty + th - 1), (cx - half * 0.2, ty + th + 1), (cx, ty + th)]
        c.poly(pts2, "fir1")
        for k in range(int(half * 1.2)):
            x = cx - half + rng.random() * half * 2
            yy = ty + th * (0.5 + rng.random() * 0.5)
            c.px(x, yy, "fir2" if x < cx else "fir1")
        if snow:
            # snow sits on top of each bough
            for x in range(int(cx - half), int(cx + half) + 1):
                d = abs(x - cx) / max(1.0, half)
                yy = ty + int(d * th) - 1
                if rng.random() < 0.75 - d * 0.3:
                    c.px(x, yy, "cold4" if x > cx else SNOW)
                    if rng.random() < 0.35:
                        c.px(x, yy + 1, "cold3")
    c.px(cx, top - 1, "fir0")
    return c


def firs():
    out = {}
    for i, h in enumerate([98, 82, 66, 54, 44, 34, 26]):
        out["fir_%d" % i] = fir(h, 100 + i)
        out["fir_bare_%d" % i] = fir(h, 200 + i, bare=True)
    return out


# ------------------------------------------------------------- backdrop
def backdrop():
    """Fixed far layer: two mountain ridges and a distant treeline, 320x70."""
    W, H = 320, 72
    c = Canvas(W, H)
    rnd = random.Random(7)
    # far ridge
    pts = [(0, H)]
    for x in range(0, W + 1, 4):
        y = 22 + 14 * math.sin(x * 0.019 + 1.0) + 9 * math.sin(x * 0.051) + fbm(x * 0.05, 0, 3) * 10
        pts.append((x, y))
    pts.append((W, H))
    c.poly(pts, "cold1")
    # snow caps on far ridge
    for x in range(W):
        y = 22 + 14 * math.sin(x * 0.019 + 1.0) + 9 * math.sin(x * 0.051) + fbm(x * 0.05, 0, 3) * 10
        depth = int(3 + 4 * fbm(x * 0.09, 3, 2))
        for d in range(depth):
            if BAYER4[int(y + d) % 4, x % 4] < 0.9 - d * 0.17:
                c.px(x, y + d, "cold3")
    # near ridge
    pts = [(0, H)]
    for x in range(0, W + 1, 3):
        y = 40 + 8 * math.sin(x * 0.027 + 2.3) + 5 * math.sin(x * 0.083 + 0.5) + fbm(x * 0.07, 9, 3) * 6
        pts.append((x, y))
    pts.append((W, H))
    c.poly(pts, "cold0")
    # distant treeline: tiny spikes
    for x in range(-2, W + 2, 2):
        base = 58 + int(3 * math.sin(x * 0.05))
        hh = 4 + int(hash01(x, 3) * 7)
        for k in range(hh):
            half = int(k / 3)
            c.hline(x - half, x + half, base - hh + k, "ink3")
    c.rect(0, 60, W, H - 60, "ink3")
    return c


# ---------------------------------------------------------------- ground
def ground(width=1500, slush=False):
    H = 27
    c = Canvas(width, H)
    for y in range(H):
        for x in range(width):
            n = fbm(x * 0.06, y * 0.25, 5, 3)
            if slush:
                base = "cold2" if n > 0.52 else "cold1"
                if y < 2:
                    base = "cold3"
            else:
                base = SNOW if y < 2 else ("cold4" if n > 0.36 else "cold3")
                if y > 18 and n < 0.32:
                    base = "cold2"
            c.px(x, y, base)
    # trodden path: darker compacted snow, footprints
    for x in range(width):
        py = 7 + int(2 * math.sin(x * 0.013))
        for y in range(py, py + 5):
            if hash01(x, y, 11) < 0.8:
                c.px(x, y, "cold2" if not slush else "cold0")
        if x % 9 == 0:
            c.px(x, py + 1, "cold1")
            c.px(x + 4, py + 3, "cold1")
    # scattered stones / tufts
    rnd = random.Random(3)
    for i in range(width // 18):
        x = rnd.randint(0, width - 1)
        y = rnd.randint(12, H - 2)
        c.px(x, y, "ink3")
        c.px(x + 1, y, "cold0")
    return c


# ----------------------------------------------------------- lookout tower
def tower():
    """Fire-lookout style: a cab on a braced timber frame, zig-zag stairs.
    92 x 146, bottom = ground. The cab windows are left as 'glass' colour
    so the engine can light them at night."""
    W, H = 96, 148
    c = Canvas(W, H)
    gx = H - 1
    cab_l, cab_r = 16, 80
    cab_b = 52
    cab_t = 24
    # legs
    for lx in (22, 74):
        c.rect(lx - 2, cab_b, 4, gx - cab_b, "wood1")
        c.vline(lx - 2, cab_b, gx, "wood2")
    # cross bracing
    for (y0, y1) in [(cab_b + 4, cab_b + 34), (cab_b + 34, cab_b + 64), (cab_b + 64, gx - 4)]:
        c.thick_line(22, y0, 74, y1, "wood0", 2)
        c.thick_line(74, y0, 22, y1, "wood0", 2)
        c.rect(20, y1 - 1, 56, 2, "wood1")
    # concrete footings
    for lx in (22, 74):
        c.rect(lx - 4, gx - 3, 8, 4, "cold1")
        c.hline(lx - 4, lx + 3, gx - 3, "cold2")
    # stairs on the right side: zig-zag flights
    flights = [(gx - 2, gx - 26, 86, 60), (gx - 26, gx - 50, 60, 86), (gx - 50, gx - 74, 86, 60), (gx - 74, cab_b + 2, 60, 84)]
    for (ya, yb, xa, xb) in flights:
        c.thick_line(xa, ya, xb, yb, "wood1", 2)
        steps = 8
        for s in range(steps + 1):
            t = s / steps
            x = xa + (xb - xa) * t
            y = ya + (yb - ya) * t
            c.hline(int(x) - 2, int(x) + 2, int(y) - 1, "wood2")
        c.line(xa, ya - 7, xb, yb - 7, "wood2")
        c.vline(xa, ya - 7, ya, "wood1")
        c.vline(xb, yb - 7, yb, "wood1")
        c.rect(min(xa, xb) - 1 if xb < xa else xb - 3, yb - 1, 6, 2, "wood2")
    # landing + entrance gate at the bottom of the stairs
    c.rect(82, gx - 18, 12, 18, "wood1")
    c.rect(84, gx - 16, 8, 16, "wood0")
    c.hline(82, 93, gx - 18, "wood3")
    # catwalk
    c.rect(cab_l - 6, cab_b, cab_r - cab_l + 12, 3, "wood2")
    c.hline(cab_l - 6, cab_r + 5, cab_b, "wood3")
    c.hline(cab_l - 6, cab_r + 5, cab_b - 8, "wood2")
    for x in range(cab_l - 6, cab_r + 7, 5):
        c.vline(x, cab_b - 8, cab_b, "wood1")
    # cab body
    c.rect(cab_l, cab_t, cab_r - cab_l, cab_b - cab_t, "wood2")
    for y in range(cab_t, cab_b, 3):
        c.hline(cab_l, cab_r - 1, y, "wood1")
    # windows band (glass)
    c.rect(cab_l + 3, cab_t + 4, cab_r - cab_l - 6, 13, "ink2")
    for x in range(cab_l + 3, cab_r - 3, 10):
        c.vline(x, cab_t + 4, cab_t + 16, "wood1")
    c.hline(cab_l + 3, cab_r - 4, cab_t + 4, "wood3")
    # glass reflection streaks
    for x in range(cab_l + 5, cab_r - 5, 10):
        c.line(x, cab_t + 14, x + 4, cab_t + 6, "cold0")
    # pyramid roof with snow
    c.poly([(cab_l - 8, cab_t + 1), (48, cab_t - 16), (cab_r + 8, cab_t + 1)], "ink3")
    c.poly([(cab_l - 8, cab_t + 1), (48, cab_t - 16), (48, cab_t + 1)], "cold0")
    for x in range(cab_l - 8, cab_r + 9):
        d = abs(x - 48) / 56.0
        y = int(cab_t + 1 - (1 - d) * 17)
        c.px(x, y, SNOW)
        c.px(x, y + 1, "cold4")
        if hash01(x, 1) < 0.5:
            c.px(x, y + 2, "cold3")
    c.rect(cab_l - 8, cab_t + 1, cab_r - cab_l + 16, 2, "ink2")
    # little antenna whip + stovepipe
    c.vline(30, cab_t - 14, cab_t - 4, "cold1")
    c.rect(62, cab_t - 12, 3, 8, "ink3")
    return c


# ------------------------------------------------------------ the shed
def shed():
    W, H = 76, 50
    c = Canvas(W, H)
    top_l, top_r = 6, 14
    # back roof slope
    for x in range(2, W - 2):
        roof = int(top_l + (top_r - top_l) * (x - 2) / (W - 4))
        for y in range(roof, H):
            ridge = (x % 4)
            base = ["cold1", "cold2", "cold2", "cold0"][ridge]
            n = fbm(x * 0.2, y * 0.15, 8, 3)
            if n > 0.64:
                base = "wood1" if n > 0.7 else "wood2"  # rust
            c.px(x, y, base)
    # roof sheet
    c.poly([(0, top_l + 1), (W, top_r - 1), (W, top_r + 3), (0, top_l + 5)], "cold0")
    for x in range(W):
        y = int(top_l + 1 + (top_r - top_l - 2) * x / W)
        c.px(x, y, SNOW)
        c.px(x, y + 1, "cold4")
        if hash01(x, 5) < 0.4:
            c.px(x, y - 1, SNOW)
    # door
    c.rect(26, 24, 18, H - 24, "cold0")
    c.rect(27, 25, 16, H - 25, "ink3")
    for y in range(26, H, 3):
        c.hline(27, 42, y, "cold0")
    c.px(40, 37, "cold3")
    c.px(40, 38, "cold3")
    # little window
    c.rect(53, 22, 12, 9, "ink2")
    c.rect(53, 22, 12, 1, "cold3")
    c.vline(59, 22, 30, "cold1")
    # exhaust pipe
    c.rect(W - 9, 0, 3, top_r + 4, "ink3")
    c.px(W - 9, 0, "cold1")
    # base snow drift
    for x in range(W):
        h = 2 + int(2 * fbm(x * 0.1, 2, 2))
        c.vline(x, H - h, H - 1, SNOW if hash01(x, 9) > 0.3 else "cold4")
    return c


# --------------------------------------------------------------- antenna
def antenna_mast():
    W, H = 30, 64
    c = Canvas(W, H)
    cx = 15
    # lattice mast
    for y in range(18, H):
        c.px(cx - 3, y, "cold1")
        c.px(cx + 3, y, "cold1")
    for y in range(18, H - 4, 6):
        c.line(cx - 3, y, cx + 3, y + 6, "cold0")
        c.line(cx + 3, y, cx - 3, y + 6, "cold0")
    # base plinth
    c.rect(cx - 7, H - 4, 15, 4, "cold1")
    c.hline(cx - 7, cx + 7, H - 4, "cold3")
    # head / gearbox
    c.rect(cx - 4, 14, 9, 6, "cold0")
    c.hline(cx - 4, cx + 4, 14, "cold2")
    return c


def antenna_dish(az_deg):
    """Dish seen from the side at azimuth az (0 = facing the viewer's right)."""
    W, H = 44, 36
    c = Canvas(W, H)
    cx, cy = 22, 18
    a = math.radians(az_deg)
    facing = math.cos(a)        # +1 right, -1 left
    depth = math.sin(a)         # toward / away from viewer
    rx = max(2.0, abs(facing) * 5 + abs(depth) * 15)
    ry = 15
    # rim ellipse (dish face)
    face_col = "cold3" if depth < 0 else "cold1"
    back_col = "cold0"
    # back of the dish (bowl)
    bowl = 6 * abs(facing) + 2
    off = -bowl if facing > 0 else bowl
    c.ellipse(cx + off * 0.6, cy, max(2, rx * 0.8), ry * 0.9, back_col)
    c.ellipse(cx, cy, rx, ry, face_col)
    if depth < 0:
        c.ellipse(cx + 1, cy - 1, max(1, rx - 3), ry - 3, "cold4")
        c.ellipse(cx + 2, cy, max(1, rx - 6), ry - 7, "cold3")
    # feed arm + horn
    fx = cx + (12 * facing) + (2 if facing >= 0 else -2)
    c.line(cx, cy - ry + 2, fx, cy, "cold0")
    c.line(cx, cy + ry - 2, fx, cy, "cold0")
    c.rect(int(fx) - 1, cy - 1, 3, 3, "ink3")
    # yoke
    c.rect(cx - 2, cy + 6, 4, H - cy - 6, "cold0")
    # snow on the rim
    c.px(cx, cy - ry, SNOW)
    c.px(cx - 1, cy - ry + 1, SNOW)
    c.px(cx + 1, cy - ry + 1, "cold4")
    return c


def junction_box():
    c = Canvas(14, 30)
    c.rect(6, 10, 2, 20, "cold0")
    c.rect(1, 2, 12, 11, "cold1")
    c.rect(2, 3, 10, 9, "cold2")
    c.hline(1, 12, 2, SNOW)
    c.rect(3, 5, 2, 2, "lamp0")
    c.line(12, 8, 13, 16, "ink3")
    c.line(13, 16, 13, 29, "ink3")
    return c


# ------------------------------------------------------------ the truck
def truck():
    W, H = 70, 32
    c = Canvas(W, H)
    body = "dusk1"
    dark = "blood1"
    # bed + cab
    c.rect(2, 12, 66, 12, body)
    c.rect(2, 12, 66, 1, "flesh1")
    c.rect(36, 3, 20, 10, body)
    c.poly([(56, 3), (64, 12), (56, 12)], body)
    c.rect(38, 5, 7, 6, "ink2")   # rear window
    c.poly([(47, 5), (55, 5), (61, 11), (47, 11)], "ink2")  # side window
    c.line(48, 6, 51, 9, "cold1")
    c.rect(2, 22, 66, 2, dark)
    c.rect(62, 14, 6, 4, "lamp1")  # headlight
    c.rect(2, 14, 3, 3, "blood2")  # tail light
    c.rect(4, 11, 30, 2, dark)     # bed rail
    # wheels
    for wx in (14, 54):
        c.disc(wx, 25, 6, "ink1")
        c.disc(wx, 25, 3, "cold1")
        c.disc(wx, 25, 1.2, "ink2")
    # snow on the roof and hood
    c.hline(36, 56, 2, SNOW)
    c.hline(57, 64, 11, SNOW)
    c.hline(6, 32, 11, "cold4")
    return c


def sign():
    c = Canvas(34, 30)
    c.rect(4, 10, 2, 20, "wood1")
    c.rect(28, 10, 2, 20, "wood1")
    c.rect(1, 2, 32, 12, "wood2")
    c.rect(2, 3, 30, 10, "wood3")
    c.hline(1, 32, 2, SNOW)
    # letters "SITE 7" painted in tiny glyphs
    glyph = {
        'S': ["111", "100", "111", "001", "111"],
        'I': ["1", "1", "1", "1", "1"],
        'T': ["111", "010", "010", "010", "010"],
        'E': ["111", "100", "110", "100", "111"],
        '7': ["111", "001", "010", "010", "010"],
    }
    x = 5
    for ch in "SITE7":
        g = glyph[ch]
        for yy, row in enumerate(g):
            for xx, v in enumerate(row):
                if v == "1":
                    c.px(x + xx, 5 + yy, "bone")
        x += len(g[0]) + 1
        if ch == 'E':
            x += 2
    return c


# ----------------------------------------------------------- the shore
def shore():
    """Rocks and a little wooden stand at the water point, 70 x 26."""
    W, H = 80, 28
    c = Canvas(W, H)
    rnd = random.Random(5)
    for i in range(16):
        x = rnd.randint(0, W - 8)
        y = rnd.randint(10, H - 4)
        r = rnd.randint(2, 5)
        c.ellipse(x + r, y + r * 0.6, r, r * 0.7, "cold0")
        c.ellipse(x + r - 1, y + r * 0.6 - 1, r - 1, r * 0.5, "cold1")
        c.px(x + r - 1, y + 1, SNOW)
    # wooden post with a hook
    c.rect(24, 0, 3, 22, "wood1")
    c.hline(24, 31, 1, "wood2")
    c.px(31, 2, "cold2")
    c.px(31, 3, "cold2")
    return c


def bucket(full=False, red=0.0):
    c = Canvas(12, 12)
    c.poly([(1, 3), (11, 3), (9, 11), (3, 11)], "cold1")
    c.poly([(1, 3), (5, 3), (5, 11), (3, 11)], "cold2")
    c.hline(1, 10, 3, "cold3")
    c.line(1, 3, 6, 0, "cold0")
    c.line(10, 3, 6, 0, "cold0")
    if full:
        water = mix("cold0", "blood2", red)
        c.hline(2, 9, 4, water)
    return c


def ice_patch():
    c = Canvas(60, 10)
    for x in range(60):
        for y in range(10):
            d = abs(x - 30) / 30.0 + y / 14.0
            if d < 1.0:
                c.px(x, y, "cold3" if hash01(x, y, 2) > 0.2 else "cold4")
    for i in range(10):
        x = 6 + i * 5
        c.line(x, 1, x + 3, 6, "cold2")
    return c


def ice_cracked():
    c = ice_patch()
    c.ellipse(30, 5, 7, 3, "ink2")
    c.ellipse(30, 5, 5, 2, "ink3")
    for a in range(0, 360, 45):
        r = math.radians(a)
        c.line(30 + math.cos(r) * 7, 5 + math.sin(r) * 3, 30 + math.cos(r) * 14, 5 + math.sin(r) * 4, "cold1")
    return c


# ------------------------------------------------------------ frozen lake
LAKE_X0 = 940          # world x of the lake sprite's left edge
LAKE_TOP = 142         # world y of its top row


def lake_ice(width=820, blood=False):
    """The frozen lake seen from its west shore: a far shore with a low dark
    treeline (rows 0..9), then the ice -- dark wind-polished bands, thin
    streaks of blown snow, a pale sheen where it catches the sky, pressure
    cracks with a bright lip. The left edge dithers out behind the trees."""
    FAR = 10
    H = 54
    c = Canvas(width, H)
    rnd = random.Random(21)
    # far shore treeline
    for x in range(width):
        h = 3 + int(hash01(x // 2, 4) * 5) + int(2 * math.sin(x * 0.03))
        for y in range(FAR - h, FAR):
            if abs((x % 4) - 1.5) <= (y - (FAR - h)) * 0.6:
                c.px(x, y, "ink2")
        c.px(x, FAR - 1, "ink3")
        c.px(x, FAR, "cold2" if hash01(x, 9) > 0.3 else "cold3")
    for y in range(FAR + 1, H):
        k = (y - FAR) / (H - FAR - 1)        # 0 far .. 1 near
        sx = 0.005 + 0.02 * (1 - k)
        sheen = math.exp(-((k - 0.35) / 0.2) ** 2) * 0.8
        for x in range(width):
            band = fbm(x * sx * 0.5 + 9, y * 0.2, 37, 3)
            drift = fbm(x * sx * 2.4, y * 0.8, 31, 3)
            col = "cold0" if band < 0.40 - 0.1 * k else ("cold1" if band < 0.53 - 0.1 * k else "cold2")
            if blood and band < 0.40:
                col = "blood1" if band < 0.34 else "blood0"
            if sheen > 0.5 and band >= 0.42 and hash01(x, y, 6) < sheen * 0.8:
                col = "cold3"
            if drift > 0.66 - 0.1 * k:
                col = SNOW if drift > 0.72 - 0.1 * k else "cold4"
            elif drift > 0.6 and col == "cold2":
                col = "cold3"
            if hash01(x, y, 5) < 0.01:
                col = "cold3"
            c.px(x, y, col)
    for i in range(22):
        x = rnd.uniform(0, width)
        y = rnd.uniform(FAR + 4, H - 2)
        L = rnd.randint(40, 180)
        dirx = 1 if rnd.random() < 0.5 else -1
        for st in range(L):
            x += dirx
            if rnd.random() < 0.15:
                y += rnd.choice([1, -1])
            if FAR + 3 <= y < H - 1:
                c.px(x, y, "ink3")
                c.px(x, y + 1, "cold3")
    # dither the left edge away so it never reads as a block
    for x in range(70):
        for y in range(H):
            if BAYER4[y % 4, x % 4] > x / 70.0:
                c.a[y, x, 3] = 0
    return c


def lake_shore():
    """Where the land gives way to the ice: a snowbank that sags in one long
    curve down onto the lake, rocks through the snow, dead reeds, and a short
    wooden jetty out to the water hole. 200 x 44, top-left at world (940, 142);
    row 11 is the ground line (world y 153)."""
    W, H = 200, 44
    c = Canvas(W, H)
    rnd = random.Random(8)

    def top_at(x):
        t = x / (W - 1)
        return 11 + int(34 * (t ** 1.7) + 2.5 * math.sin(x * 0.19) * t + 2 * fbm(x * 0.15, 0, 4, 2))

    for x in range(W):
        top = top_at(x)
        for y in range(top, H):
            n = fbm(x * 0.09, y * 0.3, 12, 3)
            col = SNOW if y < top + 2 else ("cold4" if n > 0.42 else "cold3")
            if y > top + 9 and n < 0.36:
                col = "cold2"
            c.px(x, y, col)
        if hash01(x, 7) < 0.5 and top - 1 < H:
            c.px(x, top - 1, "cold4")
        if top + 1 < H:                      # where the snow meets the ice
            c.px(x, H - 1, "cold2")
    for i in range(10):
        x = rnd.randint(20, W - 30)
        y = top_at(x) + rnd.randint(1, 7)
        if y >= H - 2:
            continue
        r = rnd.randint(2, 6)
        c.ellipse(x, y, r + 1, r * 0.7, "ink3")
        c.ellipse(x - 1, y - 1, r, r * 0.55, "cold0")
        c.hline(int(x - r * 0.6), int(x + r * 0.4), int(y - r * 0.6), SNOW)
    for i in range(30):
        x = rnd.randint(4, W - 50)
        base = top_at(x) + 1
        h = rnd.randint(5, 13)
        lean = rnd.choice([-1, 0, 1, 1])
        col = rnd.choice(["wood2", "wood3", "wood1"])
        c.line(x, base, x + lean * 2, base - h, col)
        if rnd.random() < 0.35:
            c.px(x + lean * 2, base - h - 1, "wood1")
    jx0, jx1, jy = 10, 52, 11
    c.rect(jx0, jy, jx1 - jx0, 3, "wood2")
    c.hline(jx0, jx1 - 1, jy, "wood3")
    for x in range(jx0, jx1, 6):
        c.vline(x, jy, jy + 2, "wood1")
    for px in (jx0 + 4, jx0 + 24, jx1 - 3):
        c.rect(px, jy + 3, 2, 16, "wood1")
        c.px(px, jy + 18, SNOW)
    c.hline(jx0, jx1 - 1, jy - 1, SNOW)
    c.rect(jx1 - 6, jy - 14, 2, 14, "wood1")
    c.hline(jx1 - 6, jx1 - 2, jy - 14, "wood2")
    return c


def ice_hole(state):
    """The water hole beside the jetty. 'open' rim only (water is drawn by
    the engine), 'frozen' skinned over, 'broken' cracked open."""
    W, H = 30, 9
    c = Canvas(W, H)
    cx, cy = 15, 4.5
    if state == "open" or state == "broken":
        # broken ice chunks around the rim
        for a in range(0, 360, 18):
            r = math.radians(a)
            x = cx + math.cos(r) * 13
            y = cy + math.sin(r) * 3.6
            c.rect(int(x) - 1, int(y), 3, 2, SNOW if a % 36 else "cold4")
        if state == "broken":
            for i in range(6):
                a = random.Random(i).uniform(0, 6.28)
                c.rect(int(cx + math.cos(a) * 6), int(cy + math.sin(a) * 1.8), 3, 1, "cold4")
    else:
        c.ellipse(cx, cy, 12, 3.6, "cold3")
        c.ellipse(cx - 2, cy - 1, 7, 1.6, "cold4")
        for a in range(0, 360, 18):
            r = math.radians(a)
            c.px(cx + math.cos(r) * 12.5, cy + math.sin(r) * 3.8, SNOW)
    return c


def build(save):
    for k, v in firs().items():
        save("world/" + k, v)
    save("world/backdrop", backdrop())
    save("world/ground", ground())
    save("world/ground_slush", ground(slush=True))
    save("world/tower", tower())
    save("world/shed", shed())
    save("world/mast", antenna_mast())
    for i in range(16):
        save("world/dish_%02d" % i, antenna_dish(i * 22.5))
    save("world/junction", junction_box())
    save("world/truck", truck())
    save("world/sign", sign())
    save("world/shore", shore())
    save("world/bucket", bucket())
    save("world/bucket_full", bucket(True))
    save("world/lake_ice", lake_ice())
    save("world/lake_ice_blood", lake_ice(blood=True))
    save("world/lake_shore", lake_shore())
    for st in ("open", "frozen", "broken"):
        save("world/hole_" + st, ice_hole(st))
