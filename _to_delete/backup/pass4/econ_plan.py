"""Economy plan: fit a tier's costs to Josh's active-play time (T1 1-2 h, T2 2-3 h, ... T6 6-7 h; idle/offline on top).
Model (assumptions, all editable below):
  hacking   : HACK_SHARE of active time in fights (main terminal), FIGHT_S seconds per hack incl. connecting
  crafting  : main terminal the rest of the time + VM windows (1 + one per tier, half way through the tier)
              running VM_UPTIME of the time (token-limited); process rates halfway between level 1 and 99
  rares     : ~20-26% chance, about half the caches parsed to Extraction (x5 rare), target-5 caches +2 caches
Prints the hacks, rares and crafting hours available, and what today's costs need, so costs can be scaled to fit."""
import json, os, subprocess
ACTIVE = [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
HACK_SHARE, FIGHT_S, VM_UPTIME, VARIANT = 0.6, 70.0, 0.5, 0.5
RARE_P = [0.355, 0.364, 0.374, 0.385, 0.395, 0.406]  # 2026-10-21: base rare chance 35% (was 20%), +15% each   # xp_plan.py, mid-tier decoding level + tracks
def run(lvl):
    out = subprocess.run(["python3", "tools/balance/econ.py"], capture_output=True, text=True, env=dict(os.environ, LVL=lvl)).stdout
    rows = {}
    for line in out.splitlines()[1:]:
        f = [x.strip() for x in line.split("|")]
        t = int(f[0][1:]); hacks = int(f[1].split()[0]); sql_h = float(f[3].split("/")[1])
        hu, hl, hp, _ = [float(x) for x in f[5].split()]
        rows[t] = dict(hacks=hacks, sql_h=sql_h, upgrades=hu, uploads=hl, payloads=hp)
    return rows
L1, L99 = run("1"), run("99")
print("tier | active | hacks | rares | crafting h | today's needs at mid level (h): upgrades  upload goal  payloads(300 hacks)  SQL")
for t in range(1, 7):
    a = ACTIVE[t - 1]
    hacks = a * HACK_SHARE * 3600 / FIGHT_S
    caches = hacks * (1 + 0.2 * 2)                         # 1 in 5 hacks is target 5: +2 lower caches
    rares = caches * RARE_P[t - 1] * ((1 - VARIANT) + VARIANT * 5)
    vms = 1 + (t - 1) + 0.5
    craft = a * (1 - HACK_SHARE) + a * vms * VM_UPTIME
    m = {k: (L1[t][k] + L99[t][k]) / 2 for k in ("upgrades", "uploads", "payloads", "sql_h")}
    print(" T%d  | %4.1f h | %4.0f | %4.0f | %6.1f h | %24.1f %10.1f %14.1f %12.1f" % (t, a, hacks, rares, craft, m["upgrades"], m["uploads"], m["payloads"], m["sql_h"]))
