"""Balance simulation for HOMEWARD (scripts/minigame/minigame.gd).

Re-implements the in-game generator -- levels by score, x reefs per 10 s, the
safe-window fairness rule, 0.15 s lane switch -- and plays it with simple
human-like players: each sees a reef only `reaction` seconds after it appears,
and on any decision may lapse (do nothing) with probability `lapse`.

Target (user, 2026-11-16): about 70 % of runs reach GOAL = 2000 for an
ordinary player (reaction 0.40 s, lapse 4 %).

  python sim_minigame.py [runs]
"""
import random
import sys

THRESH = [0, 400, 800, 1200, 1600]
XRATE = [9.8, 12.6, 15.4, 18.2, 21.0]
SAFE = [0.68, 0.57, 0.50, 0.43, 0.36]
GOAL = 2000
POINTS = 50
PASS_T = 2.67
SWITCH = 0.15
HALF_T = [9.0 / 65.2, 10.0 / 65.2, 12.0 / 65.2]   # (half width + 4 px) / speed
DT = 1.0 / 60.0


def level_for(s):
    lv = 0
    for i, t in enumerate(THRESH):
        if s >= t:
            lv = i
    return lv


def lane_ok(rocks, ln, arr, w):
    blocked = set()
    for (a, l, _s) in rocks:
        if l == ln and abs(a - arr) < 0.42:
            return False
        if abs(a - arr) < w + 0.38:
            blocked.add(l)
    blocked.add(ln)
    return len(blocked) < 3


def run(reaction, lapse, rng):
    t = 0.0
    nxt = 1.2
    rocks = []          # (arrival, lane, spawned_at)
    lane = 1.0
    target = 1
    score = 0
    think = 0.0
    while score < GOAL:
        lv = level_for(score)
        nxt -= DT
        if nxt <= 0:
            arr = t + PASS_T
            lanes = [0, 1, 2]
            rng.shuffle(lanes)
            ch = next((ln for ln in lanes if lane_ok(rocks, ln, arr, SAFE[lv])), -1)
            if ch < 0:
                nxt = 0.05
            else:
                rocks.append((arr, ch, t))
                nxt = 10.0 / XRATE[lv] * rng.uniform(0.9, 1.1)
        think -= DT
        if think <= 0:
            think = 0.12
            if rng.random() < lapse:
                think = 0.6          # attention lapse: nothing for a moment
            else:
                seen = [r for r in rocks if t - r[2] >= reaction]
                best, best_v = target, -1e9
                for ln in range(3):
                    travel = abs(ln - lane) * SWITCH
                    threats = [r[0] - t for r in seen if r[1] == ln and r[0] - t > -HALF_T[ln]]
                    nearest = min(threats) if threats else 9.0
                    v = min(nearest, 3.0) - travel * 2.0 - (0.05 if ln != target else 0)
                    if abs(ln - lane) >= 1.5:
                        if any(r[1] == 1 and abs(r[0] - t - SWITCH) < HALF_T[1] + 0.05 for r in seen):
                            v -= 5
                    if v > best_v:
                        best_v, best = v, ln
                target = best
        step = DT / SWITCH
        lane = float(target) if abs(target - lane) <= step else lane + (step if target > lane else -step)
        cur = int(round(lane))
        for r in rocks:
            if r[1] == cur and abs(r[0] - t) < HALF_T[cur] and abs(lane - cur) < 0.35:
                return score
        passed = [r for r in rocks if r[0] < t - HALF_T[r[1]]]
        score += POINTS * len(passed)
        rocks = [r for r in rocks if r[0] >= t - HALF_T[r[1]]]
        t += DT
    return GOAL


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    rng = random.Random(7)
    print("player        reaction  lapse   runs   reach %d   median" % GOAL)
    for name, react, lapse in [("careless", 0.55, 0.08), ("ordinary", 0.40, 0.04),
                               ("attentive", 0.30, 0.02), ("expert", 0.22, 0.01)]:
        scores = sorted(run(react, lapse, rng) for _ in range(n))
        reach = sum(1 for s in scores if s >= GOAL) / n
        print("%-12s %8.2f %6.2f %6d   %8.1f%%   %6d" % (name, react, lapse, n, reach * 100, scores[n // 2]))
