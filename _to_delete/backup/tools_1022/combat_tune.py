"""Tune easy-mode targets to Josh's ladder with combat_sim. Usage: combat_tune.py <tier> [n]
Scenarios (player at tier T; upg = hacking/System upgrade tiers installed):
  S1 arrive : upg T-1, no mods, no intel          S2 arrive + 1 mod (SQL damage)
  S2i       : arrive + full intel                  S3 arrive + this tier's Damage + Firewall levels, 2 mods (slots allowing)
  S4 mid    : S3 + Bandwidth, Max Bandwidth, Healing, Mod Slot levels, mods in every slot
  S5 done   : every upgrade of the tier, mods in every slot          (i = + full intel)
Gate (scale k searched so the gate's win rate hits the goal):
  target 1: S1 >= 90%   target 2: S2 >= 90%   target 3: S3 >= 85%   target 4: S4 >= 80%   target 5: S5 >= 70%
Profiles (x the tier base): what makes each target hard + its intel stat + firewall reboot seconds."""
import sys, json, copy
from multiprocessing import Pool
import combat_sim as cs
G = [1, 2, 3.5, 5.5, 8, 12]
MOD_VALUES = {  # this tier's compile mods (mod_stats.py), best of each type
    "dmg": [10, 20, 35, 55, 80, 120], "fw_dmg": [10, 20, 35, 55, 80, 120], "fw_red": [15, 30, 53, 83, 120, 180],
    "atk_spd": [.15, .2, .25, .3, .35, .4], "crit": [.03, .06, .09, .12, .15, .18], "band_rate": [2, 3, 4, 5, 6, 7],
    "dr": [7, 17, 32, 52, 77, 112]}
MOD_ORDER = ["dmg", "fw_dmg", "atk_spd", "band_rate", "crit", "dr", "fw_red"]
PROFILES = [  # integrity, firewall, counter, counter speed, reboot, intel stat
    dict(integrity=1.0, firewall=1.0, counter=1.0, speed=16, reboot=10, intel="firewall"),
    dict(integrity=1.35, firewall=1.0, counter=1.1, speed=16, reboot=8, intel="integrity"),
    dict(integrity=1.3, firewall=1.7, counter=1.2, speed=16, reboot=14, intel="firewall"),
    dict(integrity=1.5, firewall=1.2, counter=0.75, speed=30, reboot=6, intel="counter speed"),
    dict(integrity=2.0, firewall=1.6, counter=1.9, speed=20, reboot=10, intel="counter"),
]
BASE = dict(integrity=100, firewall=10, counter=5)  # School target-1 shape; tier T uses x G[T-1]
SCEN = ["S1", "S2", "S2i", "S3", "S3i", "S4", "S4i", "S5", "S5i"]
GATES = [("S1", .40), ("S2", .35), ("S3", .30), ("S4", .30), ("S5", .25)]  # mean anonymity left (losses = 0)
INTEL_CAP = [0.25, 0.25, 0.35, 0.45, 0.40]  # share of the intel stat full intel removes
TIME_GOAL = [60, 70, 80, 80, 90]  # seconds for the gate fight
def enemy(T, slot, k, r=1.0):
    """k: overall difficulty, r: integrity share (fight length) vs counter damage"""
    p = PROFILES[slot]
    return {"integrity": max(1, int(BASE["integrity"] * G[T-1] * p["integrity"] * k * r)),
            "firewall": int(BASE["firewall"] * G[T-1] * p["firewall"] * k),
            "counter": max(1, int(round(BASE["counter"] * G[T-1] * p["counter"] * k / r))),
            "counter speed": float(p["speed"]), "firewall reboot": p["reboot"], "intel stat": p["intel"],
            "heat": round(0.5 + 0.3 * slot, 2), "intel cap": INTEL_CAP[slot]}
def scen(T, name):
    base = name.rstrip("i") if name != "S2i" else "S2i"
    up = {"S1": T-1, "S2": T-1, "S2i": T-1, "S3": T-1, "S4": T-1, "S5": T}[base]
    extra = {"S3": ("damage", "firewall"), "S4": ("damage", "firewall", "bw_regen", "max_bw", "healing", "mod_slots")}.get(base, ())
    P = cs.player(T, up, extra=extra)
    nm = min(P["slots"], {"S1": 0, "S2": 1, "S2i": 0, "S3": 2}.get(base, P["slots"]))
    P["mods"] = {k: MOD_VALUES[k][T-1] for k in MOD_ORDER[:nm]}
    return P, (1.0 if name.endswith("i") else 0.0)
def win(T, slot, k, name, n, r=1.0):
    P, intel = scen(T, name)
    return cs.summary(P, enemy(T, slot, k, r), intel, n)
def fit_k(T, slot, gate, goal, n, r):
    lo, hi = 0.05, 12.0
    for _ in range(9):
        mid = (lo * hi) ** 0.5
        w = win(T, slot, mid, gate, n, r)
        if w["win"] * w["anon"] >= goal: lo = mid
        else: hi = mid
    return lo
def tune(args):
    T, slot, n = args
    gate, goal = GATES[slot]
    rlo, rhi = 0.5, 2.0
    for _ in range(6):  # fight length: more integrity share = longer fight
        r = (rlo * rhi) ** 0.5
        k = fit_k(T, slot, gate, goal, n, r)
        if win(T, slot, k, gate, n, r)["time"] < TIME_GOAL[slot]: rlo = r
        else: rhi = r
    k = fit_k(T, slot, gate, goal, n, r)
    row = {"slot": slot + 1, "k": round(k, 2), "r": round(r, 2), "enemy": enemy(T, slot, k, r)}
    for sc in SCEN:
        w = win(T, slot, k, sc, n, r); row[sc] = (round(w["win"], 2), int(w["time"]), round(w["anon"], 2))
    return row
if __name__ == "__main__":
    T = int(sys.argv[1]); n = int(sys.argv[2]) if len(sys.argv) > 2 else 40
    with Pool() as pool:
        rows = pool.map(tune, [(T, s, n) for s in range(5)])
    json.dump(rows, open("/tmp/tune_T%d.json" % T, "w"))
    for r in rows:
        e = r["enemy"]
        print("T%d.%d k=%.2f int %5d fw %4d ctr %4d spd %2d rb %2d intel %-13s | %s" % (T, r["slot"], r["k"], e["integrity"], e["firewall"], e["counter"],
            e["counter speed"], e["firewall reboot"], e["intel stat"], "  ".join("%s %3d%% %3ds %3d%%" % (s, r[s][0]*100, r[s][1], r[s][2]*100) for s in SCEN)))
