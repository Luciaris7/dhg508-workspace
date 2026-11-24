"""Search a difficulty scale for sim_minigame so an ordinary player reaches GOAL ~70 %."""
import random
import sys

import sim_minigame as s

BASE_X = [7.0, 9.0, 11.0, 13.0, 15.0]
BASE_W = [0.95, 0.8, 0.7, 0.6, 0.5]


def rates(n, k):
    s.XRATE = [x * k for x in BASE_X]
    s.SAFE = [w / k for w in BASE_W]
    out = []
    for react, lapse in [(0.55, 0.08), (0.40, 0.04), (0.30, 0.02), (0.22, 0.01)]:
        rng = random.Random(11)
        out.append(sum(1 for _ in range(n) if s.run(react, lapse, rng) >= s.GOAL) / n)
    return out


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 300
    for k in [float(a) for a in sys.argv[2:]] or [1.0, 1.2, 1.4, 1.6, 1.8, 2.0]:
        r = rates(n, k)
        print("k=%.2f  careless %5.1f%%  ordinary %5.1f%%  attentive %5.1f%%  expert %5.1f%%" % (k, *(x * 100 for x in r)))
