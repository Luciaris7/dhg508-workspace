"""Star-chart ephemeris data (offline, no runtime dependency).

Exports from Astronomy Engine (MIT, cosinekitty/astronomy):
  assets/data/vsop.json   truncated VSOP87 series, Mercury..Neptune (heliocentric
                          ecliptic J2000), evaluated in GDScript at runtime.
  assets/data/moon.bin    geocentric ecliptic-J2000 longitude (deg) and distance
                          (AU) of the Moon, one sample per day at 00:00 TT,
                          1980-01-01 .. 2120-12-31, float32 little endian pairs.
  assets/data/ephem_check.json  30+ reference positions used by the in-engine
                          accuracy test (geocentric ecliptic J2000 longitude).
"""
import json
import math
import os
import struct

import astronomy as A
import importlib
_AM = importlib.import_module('astronomy.astronomy')

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "data")
os.makedirs(OUT, exist_ok=True)

EPS = math.radians(23.4392911)
BODIES = [A.Body.Mercury, A.Body.Venus, A.Body.Earth, A.Body.Mars, A.Body.Jupiter,
          A.Body.Saturn, A.Body.Uranus, A.Body.Neptune]


def eqj_to_ecl(v):
    x = v.x
    y = v.y * math.cos(EPS) + v.z * math.sin(EPS)
    z = -v.y * math.sin(EPS) + v.z * math.cos(EPS)
    return x, y, z


def export_vsop():
    models = []
    for m in _AM._vsop:
        def formula(f):
            return [[[t[0], t[1], t[2]] for t in s.termList] for s in f.seriesList]
        models.append([formula(m.lon), formula(m.lat), formula(m.rad)])
    with open(os.path.join(OUT, "vsop.json"), "w") as fh:
        json.dump(models, fh, separators=(",", ":"))
    n = sum(len(s) for m in models for f in m for s in f)
    print("vsop terms:", n)


def export_moon():
    t0 = A.Time.Make(1980, 1, 1, 0, 0, 0)
    t1 = A.Time.Make(2121, 1, 1, 0, 0, 0)
    days = int(round(t1.ut - t0.ut))
    buf = bytearray()
    for d in range(days):
        t = t0.AddDays(d)
        v = A.GeoMoon(t)
        x, y, z = eqj_to_ecl(v)
        lon = math.degrees(math.atan2(y, x)) % 360.0
        dist = math.sqrt(x * x + y * y + z * z)
        buf += struct.pack("<ff", lon, dist)
    with open(os.path.join(OUT, "moon.bin"), "wb") as fh:
        fh.write(buf)
    meta = {"start_ut": t0.ut, "days": days}
    with open(os.path.join(OUT, "moon.json"), "w") as fh:
        json.dump(meta, fh)
    print("moon days:", days)


def export_check():
    import random
    rnd = random.Random(29)
    names = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
    bodies = [A.Body.Sun, A.Body.Moon, A.Body.Mercury, A.Body.Venus, A.Body.Mars,
              A.Body.Jupiter, A.Body.Saturn, A.Body.Uranus, A.Body.Neptune]
    pts = []
    years = [1985, 1999, 2000, 2010, 2026, 2026, 2026, 2030, 2050, 2077, 2100, 2119]
    for i in range(36):
        y = years[i % len(years)]
        t = A.Time.Make(y, rnd.randint(1, 12), rnd.randint(1, 28), rnd.randint(0, 23), rnd.randint(0, 59), 0)
        row = {"ut": t.ut, "lon": {}}
        for n, b in zip(names, bodies):
            v = A.GeoVector(b, t, False)
            x, yy, z = eqj_to_ecl(v)
            row["lon"][n] = math.degrees(math.atan2(yy, x)) % 360.0
        pts.append(row)
    with open(os.path.join(OUT, "ephem_check.json"), "w") as fh:
        json.dump(pts, fh, indent=0)
    print("check points:", len(pts))


if __name__ == "__main__":
    export_vsop()
    export_moon()
    export_check()
