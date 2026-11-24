"""Desktop art: a Bliss-like wallpaper (original, not the photo), icons, the
start flag, and the first-person hand for the Day 4 screen wipe."""
import math
import os

import numpy as np
from PIL import Image

from pix import Canvas, fbm, hash01

HERE = os.path.dirname(os.path.abspath(__file__))


def wallpaper(dread=False):
    W, H = 640, 360
    y = np.arange(H)[:, None].repeat(W, 1).astype(np.float32)
    x = np.arange(W)[None, :].repeat(H, 0).astype(np.float32)
    k = y / H
    sky_top = np.array([22, 84, 190], np.float32)
    sky_bot = np.array([150, 196, 238], np.float32)
    img = sky_top[None, None, :] * (1 - k[..., None]) + sky_bot[None, None, :] * k[..., None]
    # clouds: soft blobs
    rng = np.random.default_rng(4)
    cloud = np.zeros((H, W), np.float32)
    for i in range(16):
        cx, cy = rng.uniform(0, W), rng.uniform(20, 170)
        rx, ry = rng.uniform(40, 110), rng.uniform(10, 24)
        d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
        cloud = np.maximum(cloud, np.clip(1.2 - d, 0, 1) * rng.uniform(0.35, 0.75))
    img = img * (1 - cloud[..., None]) + np.array([250, 252, 255], np.float32) * cloud[..., None]
    # the hill
    hill = 210 + 34 * np.cos((x - 360) / 260.0) - 18 * np.exp(-((x - 120) / 140.0) ** 2)
    hill2 = 250 + 20 * np.cos((x - 80) / 190.0)
    g_top = np.array([120, 200, 60], np.float32)
    g_bot = np.array([40, 120, 30], np.float32)
    m = y >= hill
    t = np.clip((y - hill) / 140.0, 0, 1)
    shade = 0.92 + 0.08 * np.sin(x / 40.0 + y / 23.0)
    grass = (g_top[None, None, :] * (1 - t[..., None]) + g_bot[None, None, :] * t[..., None]) * shade[..., None]
    img[m] = grass[m]
    m2 = y >= hill2
    t2 = np.clip((y - hill2) / 110.0, 0, 1)
    grass2 = (np.array([96, 176, 48], np.float32)[None, None, :] * (1 - t2[..., None]) + np.array([30, 96, 24], np.float32)[None, None, :] * t2[..., None])
    img[m2] = grass2[m2]
    # sunlit crest
    crest = np.abs(y - hill) < 1.5
    img[crest] = img[crest] * 0.6 + np.array([200, 240, 140], np.float32) * 0.4
    if dread:
        lum = img.mean(axis=2, keepdims=True)
        img = img * 0.35 + lum * 0.65
        img = img * np.array([0.92, 0.66, 0.64], np.float32)
        d = (x - 520) ** 2 + (y - 52) ** 2
        red = np.clip(1.0 - d / 16.0, 0, 1)
        img = img * (1 - red[..., None]) + np.array([170, 20, 24], np.float32) * red[..., None]
    img = np.clip(img, 0, 255).astype(np.uint8)
    out = np.concatenate([img, np.full((H, W, 1), 255, np.uint8)], axis=2)
    c = Canvas(W, H)
    c.a = out
    return c


def icon_notice(lines_col="sky0"):
    c = Canvas(32, 32)
    c.rect(6, 3, 21, 27, (120, 120, 120))
    c.rect(7, 4, 19, 25, (255, 255, 255))
    for y in range(9, 27, 3):
        c.hline(9, 23, y, (120, 150, 200))
    for x in range(8, 26, 3):
        c.rect(x, 2, 2, 3, (90, 90, 100))
    c.rect(7, 4, 19, 2, (180, 200, 230))
    return c


def icon_log():
    c = icon_notice()
    c.rect(18, 20, 10, 10, (240, 240, 240))
    c.rect(19, 21, 8, 8, (60, 130, 220))
    c.hline(20, 25, 23, (255, 255, 255))
    c.hline(20, 25, 25, (255, 255, 255))
    return c


def icon_chart():
    c = Canvas(32, 32)
    c.rect(3, 4, 26, 22, (60, 60, 70))
    c.rect(4, 5, 24, 20, (10, 16, 30))
    for r in (4, 7, 10):
        for a in range(0, 360, 12):
            c.px(16 + math.cos(math.radians(a)) * r, 15 + math.sin(math.radians(a)) * r * 0.9, (40, 70, 120))
    c.disc(16, 15, 1.6, (80, 160, 220))
    c.px(23, 9, (255, 210, 120))
    c.px(9, 20, (220, 110, 70))
    c.px(20, 22, (200, 200, 200))
    c.rect(12, 26, 8, 3, (80, 80, 90))
    c.rect(9, 28, 14, 2, (110, 110, 120))
    return c


def icon_report():
    c = Canvas(32, 32)
    c.rect(5, 3, 22, 26, (110, 110, 120))
    c.rect(6, 4, 20, 24, (250, 250, 250))
    c.rect(6, 4, 20, 5, (38, 62, 110))
    c.hline(8, 22, 12, (100, 100, 100))
    c.hline(8, 18, 15, (100, 100, 100))
    c.rect(8, 18, 12, 4, (127, 157, 185))
    c.rect(9, 19, 10, 2, (255, 255, 255))
    c.rect(8, 23, 7, 3, (220, 220, 210))
    # globe badge
    c.disc(24, 24, 6, (40, 110, 210))
    c.disc(23, 23, 3, (90, 190, 90))
    c.px(26, 26, (90, 190, 90))
    return c


def icon_game():
    src = Image.open(os.path.join(HERE, "src", "icon_gift.png")).convert("RGBA")
    im = src.resize((32, 32), Image.LANCZOS)
    a = np.array(im)
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    c = Canvas(32, 32)
    c.a = a.astype(np.uint8)
    return c


def icon_mycomputer():
    c = Canvas(32, 32)
    c.rect(3, 4, 22, 17, (200, 196, 180))
    c.rect(5, 6, 18, 13, (40, 110, 200))
    c.rect(5, 6, 18, 4, (90, 160, 230))
    c.rect(11, 21, 6, 3, (170, 166, 150))
    c.rect(6, 24, 18, 3, (200, 196, 180))
    c.rect(24, 10, 6, 18, (210, 206, 190))
    c.hline(25, 28, 13, (120, 120, 110))
    c.px(27, 24, (60, 200, 60))
    return c


def icon_bin():
    c = Canvas(32, 32)
    c.poly([(8, 9), (24, 9), (22, 29), (10, 29)], (140, 170, 200))
    c.poly([(8, 9), (14, 9), (13, 29), (10, 29)], (190, 210, 230))
    for y in range(12, 28, 3):
        c.hline(9, 22, y, (110, 140, 170))
    c.ellipse(16, 9, 9, 2.5, (100, 130, 160))
    c.ellipse(16, 9, 7, 1.5, (60, 80, 100))
    return c


def icon_mydocs():
    c = Canvas(32, 32)
    c.rect(4, 9, 24, 18, (220, 170, 50))
    c.rect(4, 7, 10, 3, (220, 170, 50))
    c.rect(8, 5, 16, 16, (255, 255, 255))
    for y in range(8, 18, 3):
        c.hline(10, 21, y, (150, 150, 160))
    c.rect(4, 13, 24, 14, (245, 200, 80))
    c.hline(4, 27, 13, (255, 230, 140))
    return c


def icon_drive():
    c = Canvas(32, 32)
    c.rect(3, 12, 26, 10, (170, 170, 175))
    c.rect(3, 12, 26, 2, (210, 210, 215))
    c.rect(5, 18, 3, 2, (60, 200, 60))
    c.rect(18, 16, 8, 2, (120, 120, 125))
    return c


def icon_floppy():
    c = Canvas(32, 32)
    c.rect(6, 6, 20, 20, (40, 60, 120))
    c.rect(10, 6, 12, 7, (180, 180, 190))
    c.rect(18, 7, 3, 5, (40, 60, 120))
    c.rect(9, 16, 14, 10, (240, 240, 240))
    return c


def icon_image():
    c = Canvas(32, 32)
    c.rect(4, 6, 24, 20, (140, 140, 150))
    c.rect(5, 7, 22, 18, (10, 16, 30))
    c.disc(16, 16, 5, (40, 70, 120))
    c.disc(16, 16, 1.5, (80, 160, 220))
    c.px(21, 11, (220, 60, 60))
    return c


def flag():
    c = Canvas(16, 16)
    cols = [(240, 80, 40), (120, 200, 60), (40, 120, 230), (250, 200, 40)]
    for i, (ox, oy) in enumerate([(1, 1), (8, 0), (1, 8), (8, 7)]):
        for y in range(6):
            for x in range(6):
                c.px(ox + x, oy + y + int(math.sin((ox + x) * 0.5) * 1.2), cols[i])
    return c


def hand():
    """First-person right hand reaching up to wipe the monitor glass."""
    c = Canvas(120, 110)
    skin = (232, 170, 150)
    skin_d = (196, 130, 112)
    sleeve = (40, 50, 72)
    sleeve_l = (64, 80, 110)
    # forearm in the parka sleeve, from the bottom right
    c.poly([(70, 110), (120, 110), (120, 76), (64, 58), (44, 70)], sleeve)
    c.poly([(70, 110), (84, 110), (54, 66), (44, 70)], sleeve_l)
    c.poly([(40, 60), (66, 52), (70, 64), (46, 74)], (210, 210, 220))  # cuff
    # palm
    c.ellipse(40, 50, 20, 16, skin)
    c.ellipse(46, 56, 14, 10, skin_d)
    # fingers, pressed flat against the glass
    for i, (fx, fy, L) in enumerate([(22, 40, 20), (30, 34, 24), (40, 32, 24), (50, 34, 20)]):
        c.thick_line(fx + 6, fy + 10, fx, fy - L + 10, skin, 7)
        c.thick_line(fx + 7, fy + 10, fx + 2, fy - L + 12, skin_d, 2)
    c.thick_line(56, 54, 70, 40, skin, 7)  # thumb
    return c


def build(save):
    save("desk/wallpaper", wallpaper())
    save("desk/wallpaper_6", wallpaper(True))
    save("desk/icon_notice", icon_notice())
    save("desk/icon_log", icon_log())
    save("desk/icon_chart", icon_chart())
    save("desk/icon_report", icon_report())
    save("desk/icon_game", icon_game())
    save("desk/icon_mycomputer", icon_mycomputer())
    save("desk/icon_bin", icon_bin())
    save("desk/icon_mydocs", icon_mydocs())
    save("desk/icon_drive", icon_drive())
    save("desk/icon_floppy", icon_floppy())
    save("desk/icon_image", icon_image())
    save("desk/icon_flag", flag())
    save("desk/hand", hand())
