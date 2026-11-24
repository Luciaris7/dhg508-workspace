"""Synthesizes every sound in the game (no samples, no recordings).

  python gen_audio.py            -> assets/audio/{sfx,amb,music}/*.wav

Guide (plan 9.3): ambience carries 90%; music only in four places (menu,
prologue, dream church, ending); low end 20-60 Hz for pressure; flashes are
followed by thunder with a physical delay; nothing recognisably human.
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "audio")
SR = 22050
MSR = 32000
rng = np.random.default_rng(1234)


# ----------------------------------------------------------------- helpers
def t_(d, sr=SR):
    return np.arange(int(d * sr)) / sr


def white(d, sr=SR):
    return rng.standard_normal(int(d * sr))


def pink(d, sr=SR):
    n = int(d * sr)
    x = rng.standard_normal(n)
    b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
    return signal.lfilter(b, a, x) * 3.0


def brown(d, sr=SR):
    x = np.cumsum(rng.standard_normal(int(d * sr)))
    x = signal.lfilter([1, -1], [1, -0.995], x)
    return x / (np.max(np.abs(x)) + 1e-9)


def lp(x, f, sr=SR, o=2):
    b, a = signal.butter(o, min(f / (sr / 2), 0.99), "low")
    return signal.lfilter(b, a, x)


def hp(x, f, sr=SR, o=2):
    b, a = signal.butter(o, max(f / (sr / 2), 0.0001), "high")
    return signal.lfilter(b, a, x)


def bp(x, f0, f1, sr=SR, o=2):
    b, a = signal.butter(o, [max(f0 / (sr / 2), 0.0001), min(f1 / (sr / 2), 0.99)], "band")
    return signal.lfilter(b, a, x)


def env(n, a, d, sr=SR, curve=4.0):
    """attack seconds, then exponential-ish decay over d seconds."""
    na = max(1, int(a * sr))
    out = np.zeros(n)
    out[:na] = np.linspace(0, 1, na)
    rest = n - na
    if rest > 0:
        k = np.linspace(0, 1, rest)
        out[na:] = np.exp(-curve * k * (n / sr) / max(d, 1e-3))
    return out


def adsr(n, a, d, s, r, sr=SR):
    na, nd, nr = int(a * sr), int(d * sr), int(r * sr)
    ns = max(0, n - na - nd - nr)
    e = np.concatenate([np.linspace(0, 1, na), np.linspace(1, s, nd), np.full(ns, s), np.linspace(s, 0, nr)])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


def sine(f, d, sr=SR, ph=0.0):
    tt = t_(d, sr)
    if callable(f):
        f = f(tt)
    if np.ndim(f):
        return np.sin(2 * np.pi * np.cumsum(f) / sr + ph)
    return np.sin(2 * np.pi * f * tt + ph)


def saw(f, d, sr=SR):
    tt = t_(d, sr)
    if np.ndim(f):
        p = np.cumsum(f) / sr
    else:
        p = f * tt
    return 2 * (p % 1.0) - 1


def square(f, d, sr=SR, duty=0.5):
    tt = t_(d, sr)
    p = (np.cumsum(f) / sr) if np.ndim(f) else f * tt
    return np.where((p % 1.0) < duty, 1.0, -1.0)


def reverb(x, sec, sr=SR, mix=0.35, damp=3000):
    n = int(sec * sr)
    ir = rng.standard_normal(n) * np.exp(-6.9 * np.arange(n) / n)
    ir = lp(ir, damp, sr)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = signal.fftconvolve(x, ir)[: len(x) + n]
    dry = np.pad(x, (0, n))[: len(wet)]
    wet = wet[: len(dry)]
    return dry * (1 - mix) + wet * mix


def pad(x, d, sr=SR):
    return np.pad(x, (0, int(d * sr)))


def mixat(base, x, at, sr=SR, gain=1.0):
    i = int(at * sr)
    if i >= len(base):
        return base
    j = min(len(base), i + len(x))
    base[i:j] += x[: j - i] * gain
    return base


def norm(x, peak=0.89):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def rms_norm(x, db=-20.0, peak=0.95):
    r = np.sqrt(np.mean(x ** 2)) + 1e-9
    x = x * (10 ** (db / 20) / r)
    m = np.max(np.abs(x))
    if m > peak:
        x = x / m * peak
    return x


def loopify(x, fade, sr=SR):
    """Make a seamless loop: crossfade the last `fade` seconds into the head."""
    f = int(fade * sr)
    head = x[:f]
    tail = x[-f:]
    w = np.linspace(0, 1, f)
    out = x[: len(x) - f].copy()
    out[:f] = head * w + tail * (1 - w)
    return out


def save(kind, name, x, sr=SR):
    path = os.path.join(OUT, kind, name + ".wav")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.clip(x, -1, 1)
    wavfile.write(path, sr, (x * 32767).astype(np.int16))


def ks(freq, d, sr=SR, decay=0.996, bright=0.5):
    """Karplus-Strong plucked string via a comb filter."""
    n = int(d * sr)
    N = int(sr / freq)
    exc = np.zeros(n)
    burst = rng.uniform(-1, 1, N)
    burst = lp(burst, 1500 + bright * 4000, sr)
    exc[:N] = burst
    a = np.zeros(N + 2)
    a[0] = 1
    a[N] = -decay * 0.5
    a[N + 1] = -decay * 0.5
    return signal.lfilter([1], a, exc)


# ==================================================================== SFX
def sfx():
    S = lambda name, x, peak=0.85: save("sfx", name, norm(x, peak))
    # footsteps
    for i in range(1, 5):
        d = 0.16
        n = int(d * SR)
        crunch = bp(white(d), 900, 5000) * env(n, 0.004, 0.06)
        grains = np.zeros(n)
        for k in range(14):
            p = int(rng.uniform(0, 0.08) * SR)
            grains[p:p + 30] += rng.uniform(-1, 1, min(30, n - p)) * rng.uniform(0.3, 1)
        S("step_snow_%d" % i, crunch * 0.6 + hp(grains, 1500) * 0.5 + lp(white(d), 300) * env(n, 0.002, 0.03) * 0.8, 0.6)
        d = 0.14
        n = int(d * SR)
        thump = lp(white(d), 400) * env(n, 0.001, 0.03) + sine(110 + i * 7, d) * env(n, 0.001, 0.05) * 0.6
        creak = bp(white(d), 600, 1400) * env(n, 0.02, 0.05) * 0.15
        S("step_wood_%d" % i, thump + creak, 0.6)
    for i in range(1, 4):
        d = 0.3
        n = int(d * SR)
        ring = sum(sine(f * (1 + i * 0.03), d) * env(n, 0.001, 0.12 + 0.05 * k) * (0.5 / (k + 1)) for k, f in enumerate([420, 980, 1730, 2600]))
        S("step_metal_%d" % i, ring + lp(white(d), 900) * env(n, 0.001, 0.02), 0.55)
        S("step_stone_%d" % i, bp(white(0.12), 1200, 4000) * env(int(0.12 * SR), 0.001, 0.03), 0.5)
    for i in range(1, 5):
        d = 0.06
        n = int(d * SR)
        S("key_%d" % i, bp(white(d), 2000 + i * 300, 7000) * env(n, 0.0005, 0.012) + sine(1800 + i * 90, d) * env(n, 0.0005, 0.008) * 0.3, 0.5)

    # doors and furniture
    d = 1.0
    n = int(d * SR)
    f = 180 + 80 * np.sin(np.linspace(0, 9, n)) + rng.standard_normal(n) * 8
    creak = bp(saw(f, d), 300, 2200) * adsr(n, 0.05, 0.2, 0.6, 0.3) * 0.5
    S("door_open", mixat(creak, lp(white(0.15), 300) * env(int(0.15 * SR), 0.001, 0.05) * 2, 0.75), 0.7)
    ring = sum(sine(f, 0.8) * env(int(0.8 * SR), 0.001, 0.3) * 0.3 for f in [210, 530, 870])
    S("door_metal", mixat(ring + lp(white(0.8), 600) * env(int(0.8 * SR), 0.001, 0.05), lp(white(0.2), 400) * 0.8, 0.5), 0.7)
    S("chair", bp(saw(140 + 40 * np.sin(np.linspace(0, 6, int(0.5 * SR))), 0.5), 300, 1600) * adsr(int(0.5 * SR), 0.05, 0.1, 0.5, 0.2), 0.4)
    S("bed", bp(pink(1.2), 300, 3000) * adsr(int(1.2 * SR), 0.2, 0.3, 0.5, 0.5) + bp(saw(90 + 20 * np.sin(np.linspace(0, 4, int(1.2 * SR))), 1.2), 200, 900) * adsr(int(1.2 * SR), 0.4, 0.2, 0.3, 0.4) * 0.3, 0.5)
    S("car_door", lp(white(0.5), 500) * env(int(0.5 * SR), 0.001, 0.08) + sine(70, 0.5) * env(int(0.5 * SR), 0.001, 0.1) + bp(white(0.5), 2000, 6000) * env(int(0.5 * SR), 0.001, 0.02) * 0.3, 0.8)

    # computer
    d = 1.2
    n = int(d * SR)
    whine = sine(lambda tt: 9000 + 4000 * np.minimum(tt / 0.4, 1), d) * env(n, 0.05, 0.8) * 0.05
    S("crt_on", mixat(whine + bp(white(d), 3000, 9000) * env(n, 0.001, 0.15) * 0.4, lp(white(0.15), 200) * 1.2, 0.0), 0.7)
    S("crt_off", sine(lambda tt: 3000 * np.exp(-tt * 12) + 60, 0.4) * env(int(0.4 * SR), 0.001, 0.2) * 0.5 + bp(white(0.4), 2000, 8000) * env(int(0.4 * SR), 0.001, 0.05) * 0.3, 0.6)
    hdd = np.zeros(int(1.2 * SR))
    for k in range(18):
        mixat(hdd, bp(white(0.012), 1500, 6000) * env(int(0.012 * SR), 0.0005, 0.004), rng.uniform(0, 1.1))
    S("hdd", hdd + lp(white(1.2), 200) * 0.05, 0.5)
    fl = np.zeros(int(1.5 * SR))
    for k in range(12):
        mixat(fl, bp(saw(rng.uniform(300, 600), 0.1), 200, 2000) * env(int(0.1 * SR), 0.01, 0.06), k * 0.11)
    S("floppy", fl, 0.5)
    # startup chime: an original warm swell (four notes, not any OS sound)
    d = 3.2
    n = int(d * SR)
    ch = np.zeros(n)
    for k, (f, at) in enumerate([(392, 0.0), (523.25, 0.25), (659.25, 0.5), (783.99, 0.8)]):
        tone = (sine(f, d - at) + 0.3 * sine(f * 2, d - at) + 0.1 * sine(f * 3, d - at)) * adsr(int((d - at) * SR), 0.15, 0.6, 0.5, 1.2)
        mixat(ch, tone * 0.3, at)
    S("startup", reverb(ch, 1.5, mix=0.4)[:n], 0.6)
    S("ui_ding", (sine(1046.5, 0.6) + sine(1568, 0.6) * 0.5) * env(int(0.6 * SR), 0.002, 0.25), 0.5)
    S("error_ding", np.concatenate([sine(660, 0.15) * env(int(0.15 * SR), 0.002, 0.1), sine(440, 0.35) * env(int(0.35 * SR), 0.002, 0.2)]), 0.5)
    S("click", bp(white(0.03), 1500, 6000) * env(int(0.03 * SR), 0.0005, 0.006), 0.4)
    S("ui_tick", bp(white(0.02), 2500, 8000) * env(int(0.02 * SR), 0.0005, 0.004), 0.3)
    S("ui_ok", (sine(880, 0.18) + sine(1320, 0.18) * 0.4) * env(int(0.18 * SR), 0.002, 0.08), 0.45)
    S("ui_back", sine(lambda tt: 700 - 300 * tt / 0.15, 0.15) * env(int(0.15 * SR), 0.002, 0.06), 0.4)
    S("ui_open", bp(white(0.25), 400, 3000) * adsr(int(0.25 * SR), 0.05, 0.05, 0.4, 0.1), 0.3)
    S("win_open", bp(white(0.18), 800, 5000) * adsr(int(0.18 * SR), 0.04, 0.05, 0.3, 0.06), 0.25)
    S("win_close", bp(white(0.14), 500, 3000) * adsr(int(0.14 * SR), 0.01, 0.05, 0.2, 0.06), 0.22)
    S("mark", sine(1400, 0.08) * env(int(0.08 * SR), 0.001, 0.03), 0.35)
    S("error_buzz", lp(square(110, 0.35), 1500) * adsr(int(0.35 * SR), 0.005, 0.05, 0.8, 0.05), 0.4)
    S("lock_beep", np.concatenate([sine(1200, 0.09), np.zeros(int(0.06 * SR)), sine(1600, 0.16)]) * 0.6, 0.5)

    # generator and fuel
    S("can_pick", sum(sine(f, 0.5) * env(int(0.5 * SR), 0.001, 0.15) * 0.3 for f in [330, 710, 1240]) + lp(white(0.5), 600) * env(int(0.5 * SR), 0.001, 0.03), 0.6)
    d = 3.0
    n = int(d * SR)
    glug = np.zeros(n)
    tt = 0.0
    while tt < d - 0.2:
        f0 = rng.uniform(180, 380)
        bub = sine(lambda x: f0 + 900 * x, 0.06) * env(int(0.06 * SR), 0.005, 0.03)
        mixat(glug, bub, tt, gain=rng.uniform(0.3, 0.8))
        tt += rng.uniform(0.05, 0.14)
    save("sfx", "pour_loop", rms_norm(loopify(glug + bp(pink(d), 300, 2500) * 0.3, 0.3), -20))
    S("tank_full", sine(140, 0.6) * env(int(0.6 * SR), 0.001, 0.2) + lp(white(0.6), 500) * env(int(0.6 * SR), 0.001, 0.03), 0.6)
    for i in (1, 2):
        d = 0.35
        n = int(d * SR)
        S("cord_pull_%d" % i, bp(white(d), 1500, 6000) * np.interp(np.arange(n), [0, n * 0.1, n * 0.6, n], [0, 1, 0.6, 0]) + sine(lambda tt: 120 + 300 * tt, d) * env(n, 0.01, 0.2) * 0.2, 0.6)
    eng = lambda d, rate: _engine(d, rate)
    S("engine_cough", eng(0.6, 9) * env(int(0.6 * SR), 0.01, 0.3), 0.7)
    d = 3.0
    rate = np.concatenate([np.linspace(6, 26, int(1.2 * SR)), np.full(int(1.8 * SR), 26)])
    S("engine_start", _engine(d, rate) * adsr(int(d * SR), 0.02, 0.5, 0.8, 0.6), 0.8)
    for i in (1, 2):
        d = 0.25
        c = np.zeros(int(d * SR))
        for k in range(4):
            mixat(c, bp(white(0.01), 2000, 8000) * env(int(0.01 * SR), 0.0005, 0.004), k * 0.05 + i * 0.01)
        S("crank_%d" % i, c + lp(white(d), 300) * env(int(d * SR), 0.002, 0.05) * 0.5, 0.55)
    S("power_down", sine(lambda tt: 400 * np.exp(-tt * 3) + 30, 1.2) * env(int(1.2 * SR), 0.001, 0.8) * 0.7 + lp(white(1.2), 200) * env(int(1.2 * SR), 0.001, 0.1), 0.8)

    # water and ice
    S("ice_knock", sine(180, 0.4) * env(int(0.4 * SR), 0.001, 0.06) + lp(white(0.4), 800) * env(int(0.4 * SR), 0.001, 0.02), 0.7)
    for i in range(1, 4):
        d = 0.45
        n = int(d * SR)
        crack = bp(white(d), 1500, 8000) * env(n, 0.0005, 0.04) + lp(white(d), 500) * env(n, 0.001, 0.08) + sine(90 + i * 15, d) * env(n, 0.001, 0.1) * 0.6
        S("ice_chop_%d" % i, crack, 0.85)
    d = 1.6
    n = int(d * SR)
    splash = bp(white(d), 400, 6000) * adsr(n, 0.01, 0.3, 0.3, 1.0)
    S("ice_break", mixat(splash * 0.6, bp(white(0.3), 1000, 8000) * env(int(0.3 * SR), 0.0005, 0.06) * 1.5, 0.0), 0.85)
    S("axe_take", bp(white(0.5), 2000, 7000) * adsr(int(0.5 * SR), 0.05, 0.1, 0.5, 0.2) * 0.5 + sum(sine(f, 0.5) * env(int(0.5 * SR), 0.01, 0.2) * 0.2 for f in [800, 1900]), 0.5)
    d = 2.6
    n = int(d * SR)
    fill = bp(pink(d), 300, 3000) * adsr(n, 0.1, 0.2, 0.8, 0.4)
    gl = np.zeros(n)
    tt = 0.0
    while tt < d - 0.3:
        f0 = rng.uniform(300, 600) + tt * 120
        mixat(gl, sine(lambda x: f0 + 600 * x, 0.05) * env(int(0.05 * SR), 0.004, 0.02), tt, gain=0.4)
        tt += rng.uniform(0.04, 0.12)
    S("water_fill", fill + gl, 0.6)
    S("bucket_set", sine(160, 0.4) * env(int(0.4 * SR), 0.001, 0.1) + sum(sine(f, 0.4) * env(int(0.4 * SR), 0.001, 0.12) * 0.2 for f in [430, 1100]), 0.6)

    # antenna
    S("static_burst", bp(white(0.8), 800, 7000) * adsr(int(0.8 * SR), 0.01, 0.2, 0.6, 0.3), 0.6)
    d = 4.0
    st = bp(white(d), 600, 6000)
    crk = np.zeros(int(d * SR))
    for k in range(80):
        mixat(crk, white(0.004), rng.uniform(0, d - 0.01), gain=rng.uniform(1, 3))
    save("sfx", "static_loop", rms_norm(loopify(st * 0.5 + crk * 0.4 + sine(lambda tt: 600 + 200 * np.sin(tt * 3), d) * 0.05, 0.3), -22))
    d = 2.0
    whr = (sine(310, d) * 0.5 + sine(620, d) * 0.25 + sine(930, d) * 0.12) * (0.8 + 0.2 * np.sin(2 * np.pi * 24 * t_(d)))
    save("sfx", "servo_loop", rms_norm(loopify(whr + bp(white(d), 1000, 4000) * 0.08, 0.2), -20))
    S("box_open", lp(white(0.3), 1500) * env(int(0.3 * SR), 0.001, 0.04) + sum(sine(f, 0.3) * env(int(0.3 * SR), 0.001, 0.08) * 0.3 for f in [1200, 2700]), 0.6)
    S("plug_in", bp(white(0.06), 1500, 6000) * env(int(0.06 * SR), 0.0005, 0.01) + sine(400, 0.06) * env(int(0.06 * SR), 0.001, 0.02), 0.6)
    S("plug_out", bp(white(0.05), 1000, 4000) * env(int(0.05 * SR), 0.0005, 0.01), 0.5)
    sp = np.zeros(int(0.4 * SR))
    for k in range(25):
        mixat(sp, white(0.003), rng.uniform(0, 0.3), gain=rng.uniform(0.5, 1.5))
    S("spark", hp(sp, 2000) + sine(lambda tt: 3000 - 2000 * tt, 0.4) * env(int(0.4 * SR), 0.001, 0.05) * 0.3, 0.6)
    ac = np.zeros(int(2.2 * SR))
    for at in (0.2, 0.7, 1.3, 1.8):
        mixat(ac, sum(sine(f, 0.5) * env(int(0.5 * SR), 0.001, 0.15) * 0.3 for f in [520, 1340, 2210]), at)
    S("antenna_check", ac, 0.6)

    # storm
    for i in range(1, 4):
        d = 5.0 + i
        n = int(d * SR)
        rumble = lp(brown(d), 160) * adsr(n, 0.3 + i * 0.2, 1.0, 0.6, d - 2.0)
        sw = 1 + 0.6 * np.sin(np.linspace(0, 3 + i, n)) ** 2
        save("sfx", "thunder_%d" % i, norm(rumble * sw + lp(white(d), 900) * adsr(n, 0.05, 0.5, 0.2, d - 1.5) * 0.15, 0.9))
    d = 6.0
    n = int(d * SR)
    crack = hp(white(d), 1200) * env(n, 0.0005, 0.25) * 0.8
    S("thunder_close", crack + lp(brown(d), 200) * adsr(n, 0.02, 0.8, 0.7, 4.5) * 1.2, 0.95)

    # horror
    d = 1.4
    n = int(d * SR)
    beat = np.zeros(n)
    for at, g in ((0.0, 1.0), (0.28, 0.7)):
        mixat(beat, lp(sine(lambda tt: 55 - 15 * tt, 0.25), 200) * env(int(0.25 * SR), 0.005, 0.06), at, gain=g)
    S("heartbeat", beat, 0.9)
    loop = np.zeros(int(1.0 * SR))
    for at, g in ((0.0, 1.0), (0.26, 0.7)):
        mixat(loop, lp(sine(lambda tt: 52 - 12 * tt, 0.25), 200) * env(int(0.25 * SR), 0.005, 0.06), at, gain=g)
    save("sfx", "heartbeat_loop", norm(loop, 0.9))
    d = 3.0
    n = int(d * SR)
    sting = sum(saw(f * (1 + 0.004 * np.sin(np.linspace(0, 30, n))), d) for f in [233, 247, 262, 277]) * adsr(n, 0.005, 0.4, 0.4, 2.0)
    sting = bp(sting, 200, 4000) + lp(brown(d), 120) * adsr(n, 0.01, 0.5, 0.6, 2.0) * 2
    S("flesh_sting", reverb(sting, 2.0, mix=0.4)[:n], 0.9)
    S("red_sting", reverb(bp(sum(saw(f, 2.0) for f in [110, 116.5, 155.6, 164.8]), 100, 3000) * adsr(int(2.0 * SR), 0.003, 0.3, 0.3, 1.4), 2.0, mix=0.35)[:int(2.0 * SR)], 0.85)
    d = 4.0
    n = int(d * SR)
    S("low_boom", lp(sine(lambda tt: 70 * np.exp(-tt * 0.6) + 28, d), 300) * env(n, 0.005, 2.0) + lp(white(d), 120) * env(n, 0.002, 0.4), 0.95)
    S("title_hit", lp(sine(lambda tt: 60 * np.exp(-tt * 0.5) + 30, 6.0), 300) * env(int(6 * SR), 0.003, 3.0) + bp(white(6.0), 2000, 9000) * adsr(int(6 * SR), 0.01, 0.5, 0.15, 4.0) * 0.25, 0.95)
    d = 2.5
    n = int(d * SR)
    S("day_card", lp(sine(lambda tt: 50 + 4 * np.sin(tt * 3), d), 200) * env(n, 0.01, 1.4) + bp(white(d), 200, 900) * env(n, 0.01, 0.3) * 0.2, 0.8)
    d = 2.2
    n = int(d * SR)
    warble = sine(lambda tt: 140 + 40 * np.sin(tt * 23) + 30 * np.sin(tt * 5.3), d) * adsr(n, 0.1, 0.3, 0.8, 0.6)
    S("tear_drone", warble * 0.6 + bp(white(d), 1500, 7000) * adsr(n, 0.05, 0.2, 0.3, 0.5) * 0.25 + lp(brown(d), 80) * adsr(n, 0.1, 0.3, 0.8, 0.6), 0.75)
    S("flesh_hit", bp(white(0.4), 200, 1800) * env(int(0.4 * SR), 0.002, 0.12) * (1 + 0.8 * np.sin(np.linspace(0, 60, int(0.4 * SR)))) + lp(sine(80, 0.4), 300) * env(int(0.4 * SR), 0.002, 0.1), 0.8)
    d = 2.6
    n = int(d * SR)
    sq = bp(white(d), 2500, 6000) * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * t_(d))) ** 3
    save("sfx", "wipe_squeak", rms_norm(loopify(sq, 0.2), -18))

    # small things
    rat = np.zeros(int(0.9 * SR))
    for k in range(22):
        mixat(rat, bp(white(0.01), 2500, 9000) * env(int(0.01 * SR), 0.0005, 0.004), rng.uniform(0, 0.8))
    S("pills", rat, 0.5)
    S("gulp", bp(sine(lambda tt: 300 - 150 * tt, 0.35), 100, 1200) * env(int(0.35 * SR), 0.02, 0.15), 0.5)
    S("phone_beep", sine(1000, 0.45) * adsr(int(0.45 * SR), 0.005, 0.05, 0.9, 0.02), 0.45)
    S("phone_end", np.concatenate([bp(white(0.05), 1000, 4000) * env(int(0.05 * SR), 0.001, 0.01), np.zeros(int(0.2 * SR)), sine(480, 0.25) * 0.6]), 0.45)
    save("sfx", "tape_hiss", rms_norm(loopify(hp(pink(4.0), 2500) + lp(white(4.0), 150) * 0.2, 0.3), -30))

    # the gift of x: chip sounds
    S("mg_start", np.concatenate([square(f, 0.07) * env(int(0.07 * SR), 0.002, 0.05) for f in [523, 659, 784, 1046]]), 0.35)
    S("mg_swish", bp(white(0.12), 800, 4000) * adsr(int(0.12 * SR), 0.02, 0.03, 0.4, 0.05), 0.3)
    S("mg_dodge", square(1318, 0.06) * env(int(0.06 * SR), 0.001, 0.03), 0.25)
    S("mg_crash", bp(white(0.6), 200, 4000) * env(int(0.6 * SR), 0.001, 0.15) + square(lambda_f(400, 80, 0.6), 0.6) * env(int(0.6 * SR), 0.001, 0.25) * 0.4, 0.7)
    S("mg_over", np.concatenate([square(f, 0.16) * env(int(0.16 * SR), 0.003, 0.12) for f in [392, 330, 262, 196]]), 0.35)
    d = 4.0
    n = int(d * SR)
    choir = sum(_vowel(f, d) for f in [146.8, 220, 293.7]) * adsr(n, 1.5, 0.5, 0.7, 1.5)
    S("mg_arrive", reverb(choir, 3.0, mix=0.5)[:n], 0.7)
    d = 2.2
    n = int(d * SR)
    door = bp(saw(70 + 25 * np.sin(np.linspace(0, 7, n)) + rng.standard_normal(n) * 3, d), 120, 1600) * adsr(n, 0.2, 0.3, 0.7, 0.6)
    S("door_push", reverb(door + lp(brown(d), 100) * adsr(n, 0.3, 0.3, 0.6, 0.5), 2.5, mix=0.4)[:n], 0.85)


def lambda_f(f0, f1, d):
    return np.linspace(f0, f1, int(d * SR))


def _engine(d, rate):
    n = int(d * SR)
    r = np.full(n, float(rate)) if np.ndim(rate) == 0 else np.pad(rate, (0, max(0, n - len(rate))), mode="edge")[:n]
    ph = np.cumsum(r) / SR
    pulses = (np.sin(2 * np.pi * ph) > 0.85).astype(float)
    pulses = lp(pulses + rng.standard_normal(n) * 0.05, 300)
    body = lp(white(d), 180) * 0.3
    return pulses * 2 + body + lp(saw(r * 2, d), 400) * 0.15


def _vowel(f, d, sr=SR):
    """'Aah' -- a saw through two formant band-passes. Not a voice, a shape."""
    src = saw(f * (1 + 0.003 * np.sin(2 * np.pi * 5 * t_(d, sr))), d, sr)
    return bp(src, 650, 1100, sr, 2) * 0.6 + bp(src, 1000, 1400, sr, 2) * 0.3 + lp(src, 500, sr) * 0.3


# ============================================================== ambience
def amb():
    A = lambda name, x, db: save("amb", name, rms_norm(loopify(x, 2.0), db))
    d = 32.0
    n = int(d * SR)
    tt = t_(d)
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * tt / 11.0) * np.sin(2 * np.pi * tt / 4.3 + 1)
    w = bp(pink(d), 150, 1200) * gust + bp(white(d), 800, 3000) * gust ** 3 * 0.15
    A("amb_wind", w + lp(brown(d), 80) * 0.3, -22)
    A("amb_wind_night", w * 0.7 + lp(brown(d), 60) * 0.4 + _crickets_cold(d), -24)
    sw = 0.5 + 0.5 * np.sin(2 * np.pi * tt / 5.3) ** 2
    lap = np.zeros(n)
    at = 0.0
    while at < d - 1:
        mixat(lap, bp(white(0.6), 300, 2500) * adsr(int(0.6 * SR), 0.15, 0.1, 0.4, 0.3), at, gain=rng.uniform(0.3, 0.8))
        at += rng.uniform(1.5, 4.0)
    A("amb_lake", lp(pink(d), 600) * sw + lap, -22)
    A("amb_generator", _engine(d, 25.5 + 0.6 * np.sin(2 * np.pi * tt / 7)) + bp(white(d), 2000, 5000) * 0.05, -16)
    drops = np.zeros(n)
    for k in range(int(d * 40)):
        mixat(drops, bp(white(0.01), 2000, 8000) * env(int(0.01 * SR), 0.0005, 0.004), rng.uniform(0, d - 0.02), gain=rng.uniform(0.2, 1.0))
    A("amb_rain", hp(pink(d), 600) * 0.8 + drops * 0.5 + lp(brown(d), 100) * 0.3, -18)
    A("amb_rain_roof", lp(pink(d), 1500) * 0.8 + lp(drops, 2500) * 0.6 + lp(brown(d), 80) * 0.3, -20)
    hum = sine(60, d) * 0.15 + sine(120, d) * 0.08 + sine(180, d) * 0.03
    crack = np.zeros(n)
    for k in range(int(d * 3)):
        mixat(crack, bp(white(0.02), 1000, 6000) * env(int(0.02 * SR), 0.0005, 0.006), rng.uniform(0, d - 0.03), gain=rng.uniform(0.2, 1.0))
    A("amb_room", hum + crack * 0.6 + lp(pink(d), 300) * 0.25 + lp(w, 300) * 0.2, -26)
    creaks = np.zeros(n)
    for k in range(5):
        at = rng.uniform(0, d - 2)
        cd = rng.uniform(0.6, 1.4)
        mixat(creaks, bp(saw(rng.uniform(80, 160) + 30 * np.sin(np.linspace(0, 5, int(cd * SR))), cd), 200, 1400) * adsr(int(cd * SR), 0.2, 0.2, 0.5, 0.3), at, gain=0.3)
    A("amb_shed", lp(w, 500) * 0.5 + creaks + sine(50, d) * 0.04, -26)
    A("amb_pc", bp(pink(d), 150, 900) * 0.7 + sine(15700 / 2, d) * 0.002 + sine(120, d) * 0.05, -28)
    A("amb_sea", lp(pink(d), 900) * (0.4 + 0.6 * np.sin(2 * np.pi * tt / 6.0) ** 2) + bp(white(d), 2000, 6000) * 0.05 * np.sin(2 * np.pi * tt / 6.0 + 1) ** 4, -22)
    wet = bp(pink(d), 120, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * tt * 0.7) ** 6)
    sq = np.zeros(n)
    for k in range(int(d * 1.5)):
        cd = rng.uniform(0.15, 0.5)
        mixat(sq, bp(white(cd), 300, 1800) * adsr(int(cd * SR), 0.03, 0.05, 0.5, 0.1) * (1 + np.sin(np.linspace(0, 40, int(cd * SR)))), rng.uniform(0, d - 0.6), gain=0.4)
    beat = np.zeros(n)
    at = 0.0
    while at < d - 0.5:
        mixat(beat, lp(sine(48, 0.2), 150) * env(int(0.2 * SR), 0.005, 0.05), at)
        mixat(beat, lp(sine(44, 0.2), 150) * env(int(0.2 * SR), 0.005, 0.05), at + 0.27, gain=0.6)
        at += 1.1
    A("amb_flesh", wet * 0.6 + sq + beat * 0.8, -22)
    A("amb_drone", sum(sine(f * (1 + 0.002 * np.sin(tt * (k + 1))), d) * 0.3 for k, f in enumerate([36.7, 55, 58.3, 82.4])) + lp(brown(d), 60) * 0.3, -18)
    eng = _engine(d, 30 + 2 * np.sin(2 * np.pi * tt / 9.0))
    road = bp(pink(d), 100, 900) * 0.6
    save("amb", "car_engine", rms_norm(loopify(lp(eng, 600) + road, 2.0), -18))


def _crickets_cold(d):
    # no insects in a northern winter: just a far, tonal wind whistle
    tt = t_(d)
    return sine(780 + 40 * np.sin(tt * 0.3), d) * (0.5 + 0.5 * np.sin(tt * 0.21)) ** 6 * 0.04


# ================================================================== music
def music():
    M = lambda name, x, loop=True, db=-17.0: save("music", name, rms_norm(loopify(x, 3.0, MSR) if loop else x, db), MSR)
    sr = MSR
    # --- menu: one low drone and sparse single notes
    d = 64.0
    n = int(d * sr)
    tt = t_(d, sr)
    drone = (sine(41.2, d, sr) * 0.6 + sine(82.4 * 1.0015, d, sr) * 0.25 + sine(123.5, d, sr) * 0.08) * (0.8 + 0.2 * np.sin(2 * np.pi * tt / 13))
    notes = np.zeros(n)
    for k, (f, at) in enumerate([(329.6, 6), (246.9, 15), (196.0, 23), (329.6, 34), (293.7, 41), (246.9, 52), (164.8, 58)]):
        nd = 7.0
        bell = (sine(f, nd, sr) + 0.25 * sine(f * 2.01, nd, sr) + 0.1 * sine(f * 3.0, nd, sr)) * env(int(nd * sr), 0.01, 3.0, sr)
        mixat(notes, bell * 0.18, at, sr)
    M("music_menu", reverb(drone * 0.5 + notes, 4.0, sr, 0.45)[:n])
    # --- prologue: plucked folk progression, slow, a little out of true
    bpm = 72.0
    beat = 60.0 / bpm
    prog = [[164.8, 246.9, 329.6, 392.0], [130.8, 196.0, 329.6, 392.0], [196.0, 246.9, 293.7, 392.0], [146.8, 220.0, 293.7, 370.0]]
    bars = 24
    d = bars * 4 * beat
    n = int(d * sr)
    gtr = np.zeros(n)
    padm = np.zeros(n)
    for b in range(bars):
        ch = prog[b % 4]
        for s in range(8):
            f = ch[[0, 2, 1, 3, 2, 1, 3, 2][s]]
            if b % 8 == 7 and s == 6:
                f *= 1.059 ** -1     # one wrong note, every so often
            at = (b * 4 + s * 0.5) * beat
            pl = ks(f, 2.5, sr, decay=0.995, bright=0.3 if s % 2 else 0.5)
            mixat(gtr, pl * (0.5 if s % 2 else 0.7), at + rng.uniform(0, 0.01), sr)
        cd = 4 * beat
        for f in ch[:3]:
            mixat(padm, (sine(f / 2, cd, sr) * 0.5 + saw(f / 2, cd, sr) * 0.05) * adsr(int(cd * sr), 1.0, 0.5, 0.7, 1.0, sr) * 0.12, b * 4 * beat, sr)
    road = lp(pink(d, sr), 500, sr) * 0.03
    mus = lp(gtr, 3500, sr) + lp(padm, 1200, sr) + road
    M("music_prologue", reverb(mus, 1.8, sr, 0.25)[:n], db=-19)
    # --- dream church: organ and reversed, wordless choir
    d = 60.0
    n = int(d * sr)
    org = np.zeros(n)
    chords = [[73.4, 146.8, 220.0, 293.7, 349.2], [58.3, 116.5, 233.1, 293.7, 349.2], [65.4, 130.8, 196.0, 261.6, 311.1], [55.0, 110.0, 220.0, 277.2, 329.6]]
    for i in range(8):
        ch = chords[i % 4]
        cd = 7.5
        for f in ch:
            tone = sum(sine(f * h, cd, sr) * a for h, a in [(1, 1.0), (2, 0.5), (3, 0.3), (4, 0.2), (6, 0.1), (8, 0.06)])
            mixat(org, tone * adsr(int(cd * sr), 1.2, 0.5, 0.8, 1.8, sr) * 0.06, i * 7.5, sr)
    ch2 = np.zeros(n)
    for i in range(10):
        f = [293.7, 349.2, 440.0, 261.6, 220.0][i % 5]
        cd = 5.0
        v = _vowel(f, cd, sr) * np.linspace(0, 1, int(cd * sr)) ** 2   # swells then cuts: reversed
        mixat(ch2, v * 0.12, i * 6.0 + 1.0, sr)
    M("music_dream", reverb(org + ch2 + lp(brown(d, sr), 50, sr) * 0.15, 6.0, sr, 0.55)[:n])
    # --- ending: 40 s of pressure, 3 s of nothing, a burst, one tone
    d = 50.0
    n = int(d * sr)
    tt = t_(d, sr)
    grow = np.clip(tt / 40.0, 0, 1) ** 1.5 * (tt < 40.0)
    sub = sine(lambda x: 32 + 18 * np.clip(x / 40, 0, 1), d, sr)
    cluster = sum(saw(f * (1 + 0.003 * np.sin(x)), d, sr) for f, x in [(55, tt * 0.7), (58.3, tt * 0.9), (61.7, tt * 1.1), (82.4, tt * 0.5)])
    press = (sub * 0.7 + lp(cluster, 300, sr) * 0.25 * grow + lp(brown(d, sr), 70, sr) * 0.4) * grow
    burst = np.zeros(n)
    bd = 7.0
    hit = (lp(white(bd, sr), 3000, sr) * env(int(bd * sr), 0.002, 0.6, sr) + sum(saw(f, bd, sr) for f in [110, 164.8, 220, 233.1]) * env(int(bd * sr), 0.002, 2.5, sr) * 0.3 + lp(sine(lambda x: 60 * np.exp(-x) + 30, bd, sr), 200, sr) * env(int(bd * sr), 0.002, 3.0, sr))
    mixat(burst, hit, 43.0, sr)
    tone = sine(440, 6.5, sr) * adsr(int(6.5 * sr), 0.5, 1.0, 0.6, 4.0, sr) * 0.25
    mixat(burst, tone, 43.5, sr)
    endm = press + burst
    save("music", "music_ending", norm(reverb(endm, 3.0, sr, 0.3)[:n], 0.9), sr)


# ================================================================== STORY
def story():
    """Sounds for the investigation layer (MYSTERY_BIBLE). Separate part so the
    original sfx/amb/music files are not regenerated: python gen_audio.py story"""
    r = np.random.default_rng(4625)
    S = lambda name, x, peak=0.85: save("sfx", name, norm(x, peak))

    def radio_tone(d):
        n = int(d * SR)
        e = np.ones(n)
        k = int(0.006 * SR)
        e[:k] = np.linspace(0, 1, k)
        e[-k:] = np.linspace(1, 0, k)
        tone = sine(640, d) * e
        hiss = bp(r.standard_normal(n), 400, 2600) * 0.06
        return bp(tone, 300, 2400) + hiss

    # Morse: one unit = 0.12 s (flow.gd MORSE_UNIT)
    S("morse_dit", pad(radio_tone(0.12), 0.02), 0.7)
    S("morse_dah", pad(radio_tone(0.36), 0.02), 0.7)
    # echo sounder: a ping, and the return -- which "sings" like lake ice
    d = 0.3
    n = int(d * SR)
    S("sonar_ping", sine(1900, d) * env(n, 0.002, 0.08) + sine(3800, d) * env(n, 0.001, 0.03) * 0.3, 0.7)
    d = 1.6
    n = int(d * SR)
    tt = t_(d)
    chirp = sine(lambda x: 2600 * np.exp(-x * 2.8) + 240, d) * env(n, 0.01, 0.5)
    ret = sine(1350, d) * env(n, 0.004, 0.12) * 0.6
    S("sonar_echo", reverb(chirp * 0.7 + ret, 1.2, mix=0.45, damp=4000)[:n], 0.75)
    # paper
    d = 0.5
    n = int(d * SR)
    crk = np.zeros(n)
    for k in range(40):
        p = int(r.uniform(0, 0.42) * SR)
        ln = int(r.uniform(0.004, 0.02) * SR)
        crk[p:p + ln] += r.standard_normal(min(ln, n - p)) * r.uniform(0.2, 1.0)
    S("paper", bp(crk, 1500, 8000) + lp(r.standard_normal(n), 500) * env(n, 0.05, 0.3) * 0.1, 0.6)
    # a note is saved: two soft tones
    d = 0.7
    n = int(d * SR)
    ch = sine(659, d) * env(n, 0.005, 0.25) * 0.6
    ch = mixat(ch, sine(988, d) * env(n, 0.005, 0.3) * 0.5, 0.12)
    S("note_saved", lp(ch, 3000), 0.45)
    # the ice groans (the church rising / sinking)
    d = 3.5
    n = int(d * SR)
    f = 55 + 35 * np.sin(t_(d) * 1.7) + 15 * np.sin(t_(d) * 4.1)
    groan = lp(saw(f, d), 400) * adsr(n, 0.4, 0.6, 0.7, 1.2) + lp(brown(d), 120) * 0.6
    S("ice_groan", reverb(groan, 2.0, mix=0.4)[:n], 0.8)
    # a low bell under the water
    d = 6.0
    n = int(d * SR)
    bell = sum(sine(98 * m, d) * env(n, 0.003, 1.6 / (i + 1)) * (0.6 / (i + 1)) for i, m in enumerate([1.0, 2.0, 2.4, 3.0, 4.2, 5.4]))
    S("deep_bell", reverb(lp(bell, 1800), 3.0, mix=0.5)[:n], 0.8)
    # pulling a line out of the junction box under load
    d = 0.4
    n = int(d * SR)
    S("line_pull", bp(r.standard_normal(n), 2000, 7000) * env(n, 0.001, 0.05) + sine(120, d) * env(n, 0.001, 0.15) * 0.8, 0.7)


if __name__ == "__main__":
    import sys
    parts = sys.argv[1:] or ["sfx", "amb", "music", "story"]
    if "sfx" in parts:
        sfx()
        print("sfx ok")
    if "amb" in parts:
        amb()
        print("amb ok")
    if "music" in parts:
        music()
        print("music ok")
    # last, so the shared rng above produces the same files as before
    if "story" in parts:
        story()
        print("story ok")
