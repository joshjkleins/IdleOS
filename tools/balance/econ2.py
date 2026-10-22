"""Economy pass v2: Josh's active-play tier times, with cache loot as supply.
Per tier: hacks from the active time; caches = hacks (+2 lower caches per target-5 cache); variant mix:
EXTRACT share x5 rares, FOOTPRINT share x2 basic resources. Demand: upgrades (x UPG_MULT) + upload goal (GOAL each,
RARE_GOAL rares) + payloads (per hack + access) + SQL / spoofs (fights). Cache loot pays first, the chain makes the rest.
2026-10-21: caches no longer drop SQL / spoofs, so re-run tools/tests/econdump (loot.json) before trusting the SQL column.
Budget: main terminal outside fights + VM windows (VM_UPTIME) + one offline session at the tier's offline cap.
Usage: econ2.py [UPG_MULT] [GOAL] [RARE_GOAL]"""
import json, csv, re, sys, os
E = json.load(open("_to_delete/econ.json")); FC = json.load(open("/tmp/fightcost.json")); LOOT = json.load(open("/tmp/loot.json"))
ACTIVE = [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
HACK_SHARE, FIGHT_S, VM_UPTIME, EXTRACT, FOOTPRINT = 0.6, 70.0, 0.5, 0.25, 0.25
RARE_P = [0.25] * 6  # 2026-10-22: flat 25% rare chance (Decoding efficiency now adds basic resources instead)
BASIC_EFF = [1.05 + 0.005 * (l - 1) for l in (8, 22, 37, 52, 67, 82)]  # efficiency bonus basics at mid-tier decoding level
UPG_MULT = [float(x) for x in sys.argv[1].split(",")] if len(sys.argv) > 1 else [1.0] * 6
GOAL = [int(x) for x in sys.argv[2].split(",")] if len(sys.argv) > 2 else [200] * 6
RARE_GOAL = [int(x) for x in sys.argv[3].split(",")] if len(sys.argv) > 3 else [10] * 6
if len(UPG_MULT) == 1: UPG_MULT *= 6
if len(GOAL) == 1: GOAL *= 6
if len(RARE_GOAL) == 1: RARE_GOAL *= 6
def outs(s):
    d = {}
    for part in s.split(" · "):
        m = re.match(r"([\d.]+) (.+)", part)
        if m: d[m.group(2)] = float(m.group(1))
    return d
def rows(p, lvl): return [r for r in csv.DictReader(open(p, encoding="utf-8"), delimiter="\t") if r["level"] == lvl]
RT = {lv: (rows("tools/balance/rates_2026-10-20_arrive.tsv", lv), rows("tools/balance/rates_2026-10-20_done.tsv", lv)) for lv in ("1", "99")}
def per_hour(t, skill, label=""):
    acc_o, acc_i = {}, {}
    for lv in ("1", "99"):
        for rs in RT[lv]:
            r = [x for x in rs if x["tier"] == str(t) and x["skill"] == skill and x["process"].startswith(label)][0]
            for k, v in outs(r["out/h"]).items(): acc_o[k] = acc_o.get(k, 0) + v / 4
            for k, v in outs(r["in/h"]).items(): acc_i[k] = acc_i.get(k, 0) + v / 4
    return acc_o, acc_i
print("tier | hacks | caches | rares got/need | budget h | chain h needed (upgrades x%s, goal %s) | surplus from caches")
for t in range(1, 7):
    T = E[t - 1]; res = T["tier_resources"]; M, Pc, Pe, Pm, C, Mt, Py = res
    a = ACTIVE[t - 1]
    hacks = a * HACK_SHARE * 3600 / FIGHT_S
    per = hacks / 5.0
    caches = [per + per * 2 / 4.0] * 4 + [per]                 # target-5 caches hold 2 of the others
    rares_got = sum(caches) * RARE_P[t - 1] * ((1 - EXTRACT) + EXTRACT * 2)  # extraction: +1 rare (was +4)
    ACCESS_R = [2, 3, 4, 5, 5, 5]; CAP_R = [1, 1, 2, 2, 2, 2]          # proposed rare amounts per tier
    rares_need = 5 * RARE_GOAL[t - 1] + 4 * ACCESS_R[t - 1] + 9 * CAP_R[t - 1]
    supply = {}
    for i, c in enumerate(caches):
        for k, v in LOOT[str(t)][i].items():
            if k.endswith("Cache") or k.endswith("cache"): continue
            supply[k] = supply.get(k, 0) + c * v * (1 + FOOTPRINT) * BASIC_EFF[t - 1]
    fc = FC[str(t)]
    sql_need = sum(per * fc[i][1] for i in range(5)) + T["upgrades"].get("SQL Injector", 0) * UPG_MULT[t - 1]
    d = {k: T["upgrades"].get(k, 0) * UPG_MULT[t - 1] + (GOAL[t - 1] if k in T["upload"] else 0) for k in res}
    d[Py] += sum(per * T["targets"][i]["per_hack"] for i in range(5)) + sum(x["access_payloads"] for x in T["targets"])
    left = {k: max(0.0, d[k] - supply.get(k, 0)) for k in res}
    surplus = {k: int(supply.get(k, 0) - d[k]) for k in res if supply.get(k, 0) > d[k]}
    mine, _ = per_hour(t, "Mining"); parse, pin = per_hour(t, "Parsing"); crack, _ = per_hour(t, "Cracking")
    match, _ = per_hour(t, "Matching"); comp, _ = per_hour(t, "Compiling"); spear, _ = per_hour(t, "Phishing", "Spear")
    pi = list(pin.values())[0]
    py = left[Py]; mt = left[Mt] + py; c = left[C] + mt; pe = left[Pe] + c; pm = left[Pm] + mt; pc = left[Pc] + py
    parses = max(pe / (parse[Pe] / pi), pm / (parse[Pm] / pi), pc / (parse[Pc] / pi))
    m = left[M] + parses
    chain = m / mine[M] + parses / pi + c / crack[C] + mt / match[Mt] + py / comp[Py]
    sql_left = max(0, sql_need - supply.get("SQL Injector", 0)); sql_h = sql_left / (spear["SQL Injector"] / 2.4)
    vms = 1 + (t - 1) + 0.5
    budget = a * (1 - HACK_SHARE) + a * vms * VM_UPTIME + min(24, 1 + 4 * (t - 1) + 2)
    print(" T%d  | %4.0f | %5.0f | %4.0f / %3d | %6.1f | %6.1f  (+SQL %4.1f h) = %6.1f h | %s" % (t, hacks, sum(caches), rares_got, rares_need, budget, chain, sql_h, chain + sql_h,
        ", ".join("%s +%d" % (k, v) for k, v in surplus.items())))
