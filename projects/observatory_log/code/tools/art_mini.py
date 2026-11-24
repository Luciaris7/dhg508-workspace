"""The Gift of X: boat, reefs (stone / blood clot, three lane sizes), the
gothic title, the bone-white start, the close box, and the church
(gothic + flesh-punk, side view, stairs on the left rising to the door)."""
import math
import random

from pix import Canvas, fbm, hash01

# blackletter-ish capitals/lowercase for the title, 9 wide x 13 tall
GOTH = {
    'T': ["#########", "##.###.##", "#..###..#", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "..#####..", ".##...##.", "........."],
    'h': ["##.......", "##.......", "##.......", "##.####..", "####..##.", "###...##.", "##....##.", "##....##.", "##....##.", "##....##.", "##....##.", "##....###", "........#"],
    'e': [".........", ".........", ".........", "..#####..", ".##...##.", "##....##.", "########.", "##.......", "##.......", "##....#..", ".##..##..", "..####...", "........."],
    'G': ["..######.", ".##....##", "##......#", "##.......", "##.......", "##..#####", "##....##.", "##....##.", "##....##.", "##....##.", ".##..###.", "..#####.#", "........."],
    'i': [".##......", ".##......", ".........", "###......", ".##......", ".##......", ".##......", ".##......", ".##......", ".##......", ".##......", ".###.....", "........."],
    'f': ["...####..", "..##..##.", "..##.....", "..##.....", "#######..", "..##.....", "..##.....", "..##.....", "..##.....", "..##.....", "..##.....", "..##.....", ".####...."],
    't': [".........", "..##.....", "..##.....", "..##.....", "######...", "..##.....", "..##.....", "..##.....", "..##.....", "..##.....", "..##..#..", "...###...", "........."],
    'o': [".........", ".........", ".........", "..####...", ".##..##..", "##....##.", "##....##.", "##....##.", "##....##.", "##....##.", ".##..##..", "..####...", "........."],
    'X': ["###...###", ".##...##.", ".##...##.", "..##.##..", "..##.##..", "...###...", "...###...", "..##.##..", "..##.##..", ".##...##.", ".##...##.", "###...###", "........."],
}


def title():
    """HOMEWARD (user, 2026-11-16: the same name in both languages), drawn
    from the game's 5x8 letters at 2x with the old blood outline."""
    from gen_font import GLYPHS
    text = "HOMEWARD"
    S = 2
    W = sum(6 * S for _ in text) + 6
    c = Canvas(W, 20)
    x = 3
    mask = set()
    for ch in text:
        rows = GLYPHS[ch].split("/")
        for yy, row in enumerate(rows[:7]):
            for xx, v in enumerate(row):
                if v == "#":
                    for sy in range(S):
                        for sx in range(S):
                            mask.add((x + xx * S + sx, 3 + yy * S + sy))
        x += 6 * S
    for (px, py) in mask:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if (px + dx, py + dy) not in mask:
                    c.px(px + dx, py + dy, "blood2")
    for (px, py) in mask:
        if (px + 1, py + 1) not in mask and not c.opaque(px + 1, py + 2):
            c.px(px + 1, py + 2, "blood0")
    for (px, py) in mask:
        c.px(px, py, "ink0")
        if (px, py - 1) not in mask:
            c.px(px, py, "ink2")
    return c


def _trail(ch):
    rows = GOTH[ch]
    w = len(rows[0])
    t = 0
    for x in range(w - 1, -1, -1):
        if all(r[x] == "." for r in rows):
            t += 1
        else:
            break
    return t


def start(frame):
    glyph = {
        's': [".###", "#...", ".##.", "...#", "###."],
        't': [".#..", "###.", ".#..", ".#..", "..##"],
        'a': ["....", ".###", "#..#", "#..#", ".###"],
        'r': ["#.##", "##..", "#...", "#...", "#..."],
    }
    c = Canvas(48, 22)
    x = 3
    mask = []
    for ch in "start":
        g = glyph[ch]
        for yy, row in enumerate(g):
            for xx, v in enumerate(row):
                if v == "#":
                    for sy in range(2):
                        for sx in range(2):
                            mask.append((x + xx * 2 + sx, 4 + yy * 2 + sy))
        x += 9
    ms = set(mask)
    for (px, py) in ms:
        c.px(px, py, "bone")
        if (px, py + 1) not in ms:
            c.px(px, py, "flesh1")
    rnd = random.Random(5)
    # blood threads and bits of tissue
    for i in range(14):
        px, py = rnd.choice(mask)
        c.px(px, py, "blood2" if i % 3 else "flesh0")
    bottoms = [(px, py) for (px, py) in ms if (px, py + 1) not in ms]
    for i in range(6):
        px, py = rnd.choice(bottoms)
        L = rnd.randint(1, 3) + (frame if i % 2 == 0 else 0)
        c.vline(px, py + 1, py + L, "blood1")
        c.px(px, py + L + 1, "blood2")
    return c


def close_box():
    c = Canvas(13, 12)
    c.rect(0, 0, 13, 12, "ink2")
    c.rect(1, 1, 11, 10, "blood1")
    for i in range(7):
        c.px(3 + i, 2 + i, "bone")
        c.px(9 - i, 2 + i, "bone")
    return c


def boat(frame):
    c = Canvas(28, 22)
    # hull
    c.poly([(2, 15), (26, 15), (22, 21), (6, 21)], "wood2")
    c.hline(2, 25, 15, "wood3")
    c.hline(4, 24, 17, "bone")
    c.hline(6, 22, 20, "wood1")
    # mast and sail
    c.vline(14, 1, 15, "wood1")
    sway = frame
    c.poly([(15, 2), (24 + sway, 13), (15, 13)], "bone")
    c.poly([(13, 4), (6 - sway, 13), (13, 13)], "cold4")
    c.px(14, 0, "blood2")
    return c


def rock(kind, v, s):
    sizes = [(12, 9), (16, 12), (22, 16)]
    W, H = sizes[s]
    c = Canvas(W + 2, H + 2)
    rnd = random.Random(v * 13 + s * 7 + (100 if kind == "blood" else 0))
    pts = []
    n = 9
    for i in range(n):
        a = math.pi + i * math.pi / (n - 1)
        r = 0.75 + rnd.random() * 0.25
        if v == 1:
            r *= 0.85 + 0.25 * abs(math.cos(a * 2))
        if v == 2:
            r *= 1.1 if i in (3, 4) else 0.8
        x = W / 2 + 1 + math.cos(a) * W / 2 * r
        y = H + 1 + math.sin(a) * H * r
        pts.append((x, y))
    pts.append((W + 1, H + 1))
    pts.append((1, H + 1))
    if kind == "stone":
        base, lit, dark = "cold0", "cold2", "ink3"
    else:
        base, lit, dark = "blood1", "flesh0", "blood0"
    c.poly(pts, base)
    # lighting: lit upper-left
    for y in range(H + 2):
        for x in range(W + 2):
            if c.opaque(x, y):
                n2 = fbm(x * 0.4, y * 0.4, v + s * 3, 2)
                if x < W * 0.45 and y < H * 0.7 and n2 > 0.4:
                    c.px(x, y, lit)
                elif x > W * 0.6 or n2 < 0.3:
                    c.px(x, y, dark)
    if kind == "blood":
        for i in range(2 + s):
            x0 = rnd.randint(2, W - 2)
            y0 = rnd.randint(int(H * 0.4), H)
            for k in range(4 + s * 2):
                x1 = x0 + rnd.randint(-1, 1)
                y1 = y0 - 1
                if c.opaque(x1, y1):
                    c.px(x1, y1, "blood2")
                x0, y0 = x1, y1
        c.px(int(W * 0.35), int(H * 0.5), "flesh1")
    else:
        c.px(int(W * 0.3), int(H * 0.4), "cold3")
    # foam at the waterline
    for x in range(W + 2):
        if c.opaque(x, H):
            c.px(x, H + 1, "cold4" if kind == "stone" else "flesh1")
    return c


def church():
    """200 x 200, seen from the FRONT, matching the ending illustrations: a
    symmetric gothic front with ONE central bell tower and spire, a rose
    window over a deep pointed door, low side aisles with pinnacles, all on a
    tall plinth of tissue rising out of the water. No stairs (user, 2026-11-17).
    Fixed for minigame.gd / ending.gd (local): plinth foot about (36,180);
    door 98..114 x 76..112 (pointed arch from y 70, centre x 106)."""
    W, H = 200, 200
    c = Canvas(W, H)
    stone, stone_l, stone_d = "blood1", "dusk1", "blood0"
    flesh = "flesh0"
    cx = 106
    rnd = random.Random(13)
    # --- tissue base in the water
    c.poly([(0, 182), (200, 178), (192, 193), (150, 200), (40, 200), (6, 192)], stone_d)
    for x in range(0, 200):
        y = 180 + int(3 * math.sin(x * 0.2))
        c.px(x, y, flesh)
        if hash01(x, 2) < 0.3:
            c.vline(x, y + 1, y + 1 + int(hash01(x, 3) * 6), "blood2")
    # --- the plinth: a cliff of flesh and stone the church stands on
    c.poly([(54, 112), (158, 112), (178, 181), (34, 181)], stone_d)
    c.poly([(58, 112), (154, 112), (170, 181), (42, 181)], stone)
    for y in range(116, 180, 7):
        k = (y - 112) / 68.0
        c.hline(int(58 - 16 * k), int(154 + 16 * k), y, stone_d)
    for i in range(22):
        x = rnd.randint(46, 166)
        y0 = rnd.randint(114, 150)
        for k in range(rnd.randint(8, 30)):
            x += rnd.choice([-1, 0, 0, 1])
            if c.opaque(x, y0 + k):
                c.px(x, y0 + k, "blood2" if k % 5 else flesh)
    for side in (-1, 1):
        for j in range(2):
            bx = cx + side * (22 + j * 18)
            c.thick_line(bx, 116, bx + side * (5 + j * 6), 179, "bone" if j == 0 else "lavsnow", 2)
    # --- side aisles, low, with lean-to roofs and pinnacles
    for (ax, d) in ((56, -1), (140, 1)):
        c.rect(ax, 70, 16, 42, stone_d)
        c.rect(ax + 1, 71, 14, 41, stone)
        roof_hi = (ax + 16, 62) if d < 0 else (ax, 62)
        roof_lo = (ax, 72) if d < 0 else (ax + 16, 72)
        c.poly([roof_hi, roof_lo, (roof_lo[0], 74), (roof_hi[0], 74)], stone_d)
        c.rect(ax + 5, 80, 6, 20, "ink0")
        c.poly([(ax + 5, 80), (ax + 8, 75), (ax + 11, 80)], "ink0")
        c.rect(ax + 6, 82, 4, 17, "blood2")
        c.vline(ax + 8, 79, 98, "ink1")
        px_ = ax if d < 0 else ax + 15
        c.rect(px_, 52, 2, 20, stone_d)
        c.poly([(px_ - 1, 53), (px_ + 1, 44), (px_ + 3, 53)], stone_d)
    # --- the nave front and its gable
    c.rect(72, 54, 68, 58, stone_d)
    c.rect(73, 55, 66, 57, stone)
    c.vline(73, 55, 111, stone_l)
    for y in range(62, 112, 6):
        c.hline(73, 138, y, stone_d)
    c.poly([(71, 55), (cx, 34), (141, 55)], stone_d)
    c.poly([(74, 55), (cx, 37), (138, 55)], stone)
    c.line(74, 54, cx, 37, stone_l)
    for px_ in (70, 140):                                   # corner pinnacles
        c.rect(px_, 40, 3, 16, stone_d)
        c.poly([(px_ - 1, 41), (px_ + 1, 30), (px_ + 4, 41)], stone_d)
        c.px(px_ + 1, 29, "bone")
    # --- the central bell tower and spire
    c.rect(95, 14, 23, 32, stone_d)
    c.rect(96, 15, 21, 31, stone)
    c.vline(96, 15, 45, stone_l)
    c.hline(95, 117, 14, stone_l)
    c.rect(101, 20, 11, 16, "ink0")                         # belfry
    c.poly([(101, 20), (cx, 15), (112, 20)], "ink0")
    c.vline(cx, 18, 35, stone_d)
    c.ellipse(cx, 30, 3, 2.5, "lamp0")                      # the bell
    c.hline(cx - 3, cx + 3, 33, "wood2")
    for px_ in (94, 117):
        c.rect(px_, 8, 2, 8, stone_d)
        c.px(px_, 7, "bone")
    c.poly([(95, 15), (cx, -1), (118, 15)], stone_d)        # spire
    c.poly([(97, 15), (cx, 1), (cx, 15)], stone_l)
    c.poly([(cx, 1), (116, 15), (cx, 15)], stone)
    # --- rose window: plain tracery, lit red from within
    c.disc(cx, 60, 9, stone_d)
    c.disc(cx, 60, 8, "blood2")
    for a in range(8):
        ang = a * math.pi / 4
        c.line(cx, 60, cx + math.cos(ang) * 8, 60 + math.sin(ang) * 8, stone_d)
    c.disc(cx, 60, 2.5, stone_d)
    c.disc(cx, 60, 1.2, "flesh0")
    # --- the door: deep pointed arch with receding orders
    for k, colr in enumerate((stone_d, stone_l, stone_d)):
        o = 4 - k * 2
        c.rect(98 - o, 80 - o // 2, 16 + 2 * o, 32 + o // 2, colr)
        c.poly([(98 - o, 80 - o // 2), (cx, 70 - o), (114 + o, 80 - o // 2)], colr)
    c.rect(98, 80, 16, 32, "ink1")
    c.poly([(98, 80), (cx, 70), (114, 80)], "ink1")
    c.rect(99, 82, 14, 30, stone_d)
    c.vline(cx, 76, 111, "ink0")
    c.px(103, 96, "bone")
    c.px(109, 96, "bone")
    # flesh growth and veins, mirrored
    for i in range(14):
        x = rnd.randint(58, 100)
        y = rnd.randint(62, 112)
        r = rnd.randint(2, 4)
        for xx in (x, 2 * cx - x):
            c.ellipse(xx, y, r, r * 0.8, "blood2")
            c.ellipse(xx - 1, y - 1, max(1, r - 2), r * 0.5, flesh)
    for i in range(10):
        x = rnd.randint(60, 100)
        y = rnd.randint(30, 110)
        pts = [(x, y)]
        for k in range(rnd.randint(6, 14)):
            x += rnd.randint(-1, 1)
            y += rnd.choice([-1, 1, 1])
            pts.append((x, y))
        for (a, b) in pts:
            for xx in (a, 2 * cx - a):
                if c.opaque(xx, b):
                    c.px(xx, b, "blood2")
    c.outline("ink0")
    return c


def church_side_unused():
    """The old side view, kept for reference (not saved)."""
    W, H = 200, 170
    c = Canvas(W, H)
    stone, stone_l, stone_d = "blood1", "dusk1", "blood0"
    flesh = "flesh0"
    # floating base of tissue
    c.poly([(0, 150), (200, 146), (190, 162), (150, 170), (40, 170), (8, 160)], stone_d)
    for x in range(0, 200):
        y = 148 + int(3 * math.sin(x * 0.2))
        c.px(x, y, flesh)
        if hash01(x, 2) < 0.3:
            c.vline(x, y + 1, y + 1 + int(hash01(x, 3) * 6), "blood2")
    # the stairs (a ramp of steps rising to the right)
    for i in range(16):
        x0 = 14 + i * 5.2
        y0 = 142 - i * 3.75
        c.rect(int(x0), int(y0), 7, int(150 - y0), stone)
        c.hline(int(x0), int(x0) + 6, int(y0), stone_l)
    # nave
    c.rect(96, 40, 90, 110, stone)
    for y in range(40, 150, 6):
        c.hline(96, 185, y, stone_d)
    for x in range(96, 186, 10):
        for y in range(40, 150, 12):
            c.vline(x + (5 if (y // 12) % 2 else 0), y, y + 5, stone_d)
    # pointed roof of the nave
    c.poly([(92, 42), (141, 10), (190, 42)], stone_d)
    c.poly([(92, 42), (141, 10), (141, 42)], stone)
    # the bell tower / spire on the right
    c.rect(160, 24, 26, 126, stone_d)
    c.rect(162, 26, 22, 124, stone)
    c.poly([(158, 26), (173, -30 + 34), (188, 26)], stone_d)
    c.vline(173, 0, 6, "bone")
    c.hline(171, 175, 2, "bone")
    # flying buttresses
    for bx in (120, 146):
        c.thick_line(bx, 60, bx + 10, 148, stone_d, 3)
    # lancet windows (lit from inside, red)
    for wx in (126, 144, 170):
        c.rect(wx, 64, 8, 22, "ink0")
        c.poly([(wx, 64), (wx + 4, 57), (wx + 8, 64)], "ink0")
        c.rect(wx + 1, 66, 6, 19, "blood2")
        c.vline(wx + 4, 62, 85, "ink1")
    # rose window over the door
    c.disc(106, 30, 8, stone_d)
    c.ellipse(106, 30, 6, 3.5, "bone")
    c.disc(106, 30, 2.6, "blood2")
    c.disc(106, 30, 1.2, "ink0")
    # the door, pointed arch, at the top of the stairs
    c.rect(98, 50, 16, 32, "ink1")
    c.poly([(98, 50), (106, 40), (114, 50)], "ink1")
    c.rect(99, 52, 14, 30, stone_d)
    c.vline(106, 46, 81, "ink0")
    c.px(103, 66, "bone")
    c.px(109, 66, "bone")
    # flesh growth climbing the walls, with veins
    rnd = random.Random(9)
    for i in range(26):
        x = rnd.randint(96, 196)
        y = rnd.randint(70, 150)
        r = rnd.randint(2, 6)
        c.ellipse(x, y, r, r * 0.8, "blood2")
        c.ellipse(x - 1, y - 1, max(1, r - 2), r * 0.5, flesh)
    for i in range(18):
        x = rnd.randint(96, 190)
        y = rnd.randint(30, 150)
        for k in range(rnd.randint(6, 16)):
            x2 = x + rnd.randint(-1, 1)
            y2 = y + rnd.choice([-1, 1, 1])
            if c.opaque(x2, y2):
                c.px(x2, y2, "blood2")
            x, y = x2, y2
    return c


def build(save):
    save("mini/title", title())
    save("mini/start_0", start(0))
    save("mini/start_1", start(1))
    save("mini/close", close_box())
    save("mini/boat_0", boat(0))
    save("mini/boat_1", boat(1))
    for kind in ("stone", "blood"):
        for v in range(4):
            for s in range(3):
                save("mini/rock_%s_%d_%d" % (kind, v, s), rock(kind, v, s))
    save("mini/church", church())
