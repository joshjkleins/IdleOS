import itertools, sys
from multiprocessing import Pool
import combat_sim as cs
MODS = {"dmg": 10, "fw_dmg": 10, "fw_red": 15, "atk_spd": .15, "crit": .03, "band_rate": 2, "dr": 7}
def P(mods):
    p = cs.player(1, 1, level=10)
    p["heal"] = 0.05; p["thr"] = 0.30; p["caps"] = set()
    p["mods"] = dict(mods)
    return p
def evalE(E, n=24):
    out = {}
    out["none"] = cs.summary(P({}), E, 0, n)
    out["single"] = max((cs.summary(P({k: v}), E, 0, n) for k, v in MODS.items()), key=lambda r: r["win"])
    pairs = [cs.summary(P({a: MODS[a], b: MODS[b]}), E, 0, n) for a, b in itertools.combinations(MODS, 2)]
    good = [r for r in pairs if r["win"] >= 0.7]
    out["pairs_good"] = len(good); out["pairs"] = len(pairs)
    out["pair_time"] = sum(r["time"] for r in good) / max(1, len(good))
    out["best_pair"] = max(r["win"] for r in pairs)
    return out
def job(args):
    I, F, C, S = args
    E = {"integrity": I, "firewall": F, "counter": C, "counter speed": S, "heat": 0.5, "firewall reboot": 10.0}
    r = evalE(E)
    return (args, r["none"]["win"], r["single"]["win"], r["pairs_good"], r["pairs"], int(r["pair_time"]), r["best_pair"])
if __name__ == "__main__":
    grid = [(I, F, C, S) for I in (300, 400, 500, 650) for F in (25, 40, 60) for C in (10, 14, 18) for S in (16.0, 20.0)]
    with Pool() as pool:
        res = pool.map(job, grid)
    ok = [r for r in res if r[2] <= 0.3 and r[3] >= 8 and 45 <= r[5] <= 150]
    for r in sorted(ok, key=lambda r: -r[3])[:15]: print("OK", r)
    print("---")
    for r in sorted(res, key=lambda r: r[0])[:72:6]: print(r)
