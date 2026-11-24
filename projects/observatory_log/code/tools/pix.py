"""Tiny pixel-art drawing library on top of numpy.

Everything works on an RGBA uint8 canvas at 1:1 pixel scale. Colours are
(r, g, b[, a]) tuples or palette names. Deterministic: all randomness goes
through seeded generators so re-running the tools reproduces the same art.
"""
import math
import os
import numpy as np
from PIL import Image

from palette import RGB

BAYER4 = np.array([[0, 8, 2, 10],
                   [12, 4, 14, 6],
                   [3, 11, 1, 9],
                   [15, 7, 13, 5]], dtype=np.float32) / 16.0 + 1.0 / 32.0


def col(c, a=None):
    if isinstance(c, str):
        r, g, b = RGB[c]
        return (r, g, b, 255 if a is None else a)
    if len(c) == 3:
        return (c[0], c[1], c[2], 255 if a is None else a)
    if a is not None:
        return (c[0], c[1], c[2], a)
    return tuple(c)


def mix(a, b, t):
    a = col(a)
    b = col(b)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(4))


def shade(c, k):
    c = col(c)
    return (max(0, min(255, int(c[0] * k))), max(0, min(255, int(c[1] * k))),
            max(0, min(255, int(c[2] * k))), c[3])


class Canvas:
    def __init__(self, w, h, fill=None):
        self.w = w
        self.h = h
        self.a = np.zeros((h, w, 4), dtype=np.uint8)
        if fill is not None:
            self.a[:, :] = col(fill)

    # ---------------------------------------------------------------- basics
    def px(self, x, y, c):
        x = int(x)
        y = int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            c = col(c)
            if c[3] == 255:
                self.a[y, x] = c
            elif c[3] > 0:
                t = c[3] / 255.0
                d = self.a[y, x].astype(np.float32)
                out = d[:3] * (1 - t) + np.array(c[:3], np.float32) * t
                self.a[y, x, :3] = out.astype(np.uint8)
                self.a[y, x, 3] = max(int(d[3]), c[3])

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return tuple(int(v) for v in self.a[y, x])
        return (0, 0, 0, 0)

    def opaque(self, x, y):
        x = int(x)
        y = int(y)
        return 0 <= x < self.w and 0 <= y < self.h and self.a[y, x, 3] > 0

    def rect(self, x, y, w, h, c):
        x0, y0 = max(0, int(x)), max(0, int(y))
        x1, y1 = min(self.w, int(x + w)), min(self.h, int(y + h))
        if x1 <= x0 or y1 <= y0:
            return
        c = col(c)
        if c[3] == 255:
            self.a[y0:y1, x0:x1] = c
        else:
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    self.px(xx, yy, c)

    def hline(self, x0, x1, y, c):
        if x1 < x0:
            x0, x1 = x1, x0
        self.rect(x0, y, x1 - x0 + 1, 1, c)

    def vline(self, x, y0, y1, c):
        if y1 < y0:
            y0, y1 = y1, y0
        self.rect(x, y0, 1, y1 - y0 + 1, c)

    def line(self, x0, y0, x1, y1, c):
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def thick_line(self, x0, y0, x1, y1, c, w=2):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            t = i / max(1, n)
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            self.disc(x, y, w / 2.0, c)

    def disc(self, cx, cy, r, c):
        r2 = r * r
        for y in range(int(math.floor(cy - r)), int(math.ceil(cy + r)) + 1):
            for x in range(int(math.floor(cx - r)), int(math.ceil(cx + r)) + 1):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r2:
                    self.px(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(math.floor(cy - ry)), int(math.ceil(cy + ry)) + 1):
            for x in range(int(math.floor(cx - rx)), int(math.ceil(cx + rx)) + 1):
                if ((x + 0.5 - cx) / max(rx, 0.01)) ** 2 + ((y + 0.5 - cy) / max(ry, 0.01)) ** 2 <= 1.0:
                    self.px(x, y, c)

    def poly(self, pts, c):
        """Scanline polygon fill (even-odd)."""
        if len(pts) < 3:
            return
        ys = [p[1] for p in pts]
        y0 = int(math.floor(min(ys)))
        y1 = int(math.ceil(max(ys)))
        n = len(pts)
        for y in range(y0, y1 + 1):
            yc = y + 0.5
            xs = []
            for i in range(n):
                ax, ay = pts[i]
                bx, by = pts[(i + 1) % n]
                if (ay <= yc < by) or (by <= yc < ay):
                    xs.append(ax + (yc - ay) * (bx - ax) / (by - ay))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                xa = int(math.floor(xs[i] + 0.5))
                xb = int(math.floor(xs[i + 1] + 0.5))
                if xb > xa:
                    self.rect(xa, y, xb - xa, 1, c)

    def vgrad(self, x, y, w, h, c0, c1, dither=True):
        """Vertical gradient with ordered dithering between two colours."""
        c0 = col(c0)
        c1 = col(c1)
        for yy in range(int(h)):
            t = yy / max(1, h - 1)
            for xx in range(int(w)):
                X = int(x + xx)
                Y = int(y + yy)
                if dither:
                    th = BAYER4[Y % 4, X % 4]
                    self.px(X, Y, c1 if t > th else c0)
                else:
                    self.px(X, Y, mix(c0, c1, t))

    def dither_rect(self, x, y, w, h, c, density):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                if BAYER4[yy % 4, xx % 4] < density:
                    self.px(xx, yy, c)

    def outline(self, c, only_outside=True):
        """1px outline around opaque pixels."""
        a = self.a[:, :, 3] > 0
        ring = np.zeros_like(a)
        ring[1:, :] |= a[:-1, :]
        ring[:-1, :] |= a[1:, :]
        ring[:, 1:] |= a[:, :-1]
        ring[:, :-1] |= a[:, 1:]
        ring &= ~a
        self.a[ring] = col(c)

    def blit(self, other, x, y, flip=False):
        src = other.a[:, ::-1] if flip else other.a
        h, w = src.shape[:2]
        for yy in range(h):
            Y = y + yy
            if not (0 <= Y < self.h):
                continue
            for xx in range(w):
                X = x + xx
                if 0 <= X < self.w:
                    p = src[yy, xx]
                    if p[3] == 255:
                        self.a[Y, X] = p
                    elif p[3] > 0:
                        self.px(X, Y, tuple(int(v) for v in p))

    def recolor(self, mapping):
        for src, dst in mapping.items():
            s = np.array(col(src)[:3])
            m = np.all(self.a[:, :, :3] == s, axis=2) & (self.a[:, :, 3] > 0)
            self.a[m, :3] = col(dst)[:3]

    def crop(self, x, y, w, h):
        out = Canvas(w, h)
        out.a = self.a[y:y + h, x:x + w].copy()
        return out

    def flip(self):
        out = Canvas(self.w, self.h)
        out.a = self.a[:, ::-1].copy()
        return out

    def scaled(self, k):
        out = Canvas(self.w * k, self.h * k)
        out.a = self.a.repeat(k, axis=0).repeat(k, axis=1)
        return out

    def image(self):
        return Image.fromarray(self.a, "RGBA")

    def save(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.image().save(path)


# ------------------------------------------------------------------- noise
def hash01(*args):
    h = 2166136261
    for a in args:
        h ^= int(a) & 0xffffffff
        h = (h * 16777619) & 0xffffffff
    h ^= h >> 13
    h = (h * 1274126177) & 0xffffffff
    h ^= h >> 16
    return (h & 0xffffff) / float(0x1000000)


def vnoise(x, y, seed=0):
    xi, yi = int(math.floor(x)), int(math.floor(y))
    xf, yf = x - xi, y - yi
    u = xf * xf * (3 - 2 * xf)
    v = yf * yf * (3 - 2 * yf)
    a = hash01(xi, yi, seed)
    b = hash01(xi + 1, yi, seed)
    c = hash01(xi, yi + 1, seed)
    d = hash01(xi + 1, yi + 1, seed)
    return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v


def fbm(x, y, seed=0, octaves=4):
    s = 0.0
    amp = 0.5
    f = 1.0
    for i in range(octaves):
        s += amp * vnoise(x * f, y * f, seed + i * 31)
        amp *= 0.5
        f *= 2.0
    return s


def sheet(canvases, cols, pad=2, bg=(30, 30, 34, 255), scale=1):
    """Contact sheet for previews."""
    cw = max(c.w for c in canvases)
    ch = max(c.h for c in canvases)
    rows = (len(canvases) + cols - 1) // cols
    out = Canvas(cols * (cw + pad) + pad, rows * (ch + pad) + pad, bg)
    for i, c in enumerate(canvases):
        out.blit(c, pad + (i % cols) * (cw + pad), pad + (i // cols) * (ch + pad))
    return out.scaled(scale) if scale > 1 else out
