"""Rough tier-length model (2026-11-02). Reads ~/econ/dump.json (tools/tests/econdump3.gd) + data/upgrades.json.
Rates = average of tier arrival and tier done. Assumptions (imperfect player) at the top."""
import json, os, collections, sys
P = os.path.expanduser("~/mnt/idle-os-prototype")
D = json.load(open(os.path.expanduser("~/econ/dump.json")))
U = json.load(open(P + "/data/upgrades.json"))
RARE_GOALS = [1, 3, 4, 5, 6, 7]
FIGHT_S = 95 + 20          # right-build fight ~60-125s + connect / menus
LOSS = 1.25                # attempts per win (wrong builds, learning)
EXTRA_HACKS = 1.15         # farming mods / exploits, repeat fights for fun
COMPROMISE = 12            # compromise fights incl. retries
CRAFT_WASTE = 1.35         # idle gaps, overheating, wrong process, not perfectly balancing the chain
VM_USE = 0.45              # share of VM window-hours actually producing (tokens, attention)
SQL_PER_FIGHT = [10, 12, 30, 50, 30, 30]  # from winning harness fights
APT = float(os.environ.get("APT", "1"))   # share of the tier's apt upgrades bought (1 = all)
SESSION_H = 2.0
MINE_MULT = [float(x) for x in os.environ.get("MINE_MULT", "1,1,1,1,1,1").split(",")]   # what-if: mining speed per tier
APT_T = [float(x) for x in os.environ.get("APT_T", "1,1,1,1,1,1").split(",")]           # what-if: apt cost scale per tier                           # active play per session; between sessions the player is away >= offline cap
HACK_ARR = [1, 15, 30, 45, 60, 75, 90]
def xp_for(l): return 0 if l <= 1 else 50.0 * l ** 2.4
def lvl_from(xp):
    l = 1
    while l < 99 and xp_for(l + 1) <= xp: l += 1
    return l
def avg_rate(T, key):
    a, d = T["states"]["arrive"]["procs"][key], T["states"]["done"]["procs"][key]
    o = collections.Counter(); i = collections.Counter()
    for s in (a, d):
        ph = 3600.0 / s["seconds"] / 2
        for k, v in s["out"].items(): o[k] += v * ph
        for k, v in s["inp"].items(): i[k] += v * ph
    return o, i
def cache_loot(T, name):
    o = collections.Counter(); sec = 0
    for st in ("arrive", "done"):
        c = T["states"][st]["caches"].get(name)
        if not c: continue
        sec += c["seconds"] / 2
        for k, v in c["out"].items(): o[k] += v / 2
    return o, sec
hack_xp_total = 0.0
rows = []
for T in D["tiers"]:
    t = T["tier"]; R = T["resources"]; M, Pc, Pe, Pm, C, Mt, Py = R
    tg = T["targets"]
    apt = collections.Counter()
    for p in U["packages"]:
        for lv in p["levels"]:
            if lv["tier"] == t:
                for c in lv["costs"]: apt[c["item"]] += c["amount"] * APT * APT_T[t - 1]
    goal = {g["item"]: g["amount"] for g in T["goals"]}
    # --- hacks ---------------------------------------------------------------
    loot = [cache_loot(T, x["cache"]) for x in tg]
    p_rare = [max(0.05, loot[i][0].get(tg[i]["rare"], 0.25)) + (0.1 if t >= 2 else 0) for i in range(5)]  # + win streak
    cont = [loot[4][0].get(tg[j]["cache"], 0.0) for j in range(5)]  # top target's cache holds the others
    rare_need = [RARE_GOALS[t - 1] + (tg[i + 1]["access_rare_n"] if i < 4 else 0) for i in range(5)]
    cache_need = [apt.get(tg[i]["cache"], 0) for i in range(5)]
    h = [0.0] * 5
    h[4] = max(rare_need[4] / p_rare[4], cache_need[4])
    for j in range(4):
        access_only = (tg[j + 1]["access_rare_n"]) / p_rare[j]       # must be hacked directly to open the next target
        rest = max(rare_need[j] / p_rare[j], cache_need[j]) - h[4] * cont[j]
        h[j] = max(access_only, rest, 3)
    hacks = [x * EXTRA_HACKS for x in h]
    fights = sum(hacks) * LOSS + COMPROMISE
    fight_h = fights * FIGHT_S / 3600
    caches = [hacks[j] + hacks[4] * cont[j] for j in range(4)] + [hacks[4]]
    hack_xp = sum(hacks[j] * tg[j]["exp"] for j in range(5))
    hack_xp_total += hack_xp
    # --- cache supply ----------------------------------------------------------
    supply = collections.Counter(); dec_h = 0
    for j in range(5):
        for k, v in loot[j][0].items(): supply[k] += v * caches[j]
        dec_h += loot[j][1] * caches[j] / 3600
    # --- demand ---------------------------------------------------------------
    need = collections.Counter()
    for k in R: need[k] += goal.get(k, 0) + apt.get(k, 0)
    pay_hacks = sum(hacks[j] * tg[j]["payload"] for j in range(5)) * LOSS   # payload is spent on losses too
    need[Py] += pay_hacks + sum(x["access_payload_n"] for x in tg)
    left = {k: max(0.0, need[k] - supply.get(k, 0)) for k in R}
    from_cache = {k: min(need[k], supply.get(k, 0)) for k in R}
    # --- chain hours --------------------------------------------------------------
    mo, _ = avg_rate(T, "mine"); po, pi = avg_rate(T, "parse"); co, ci = avg_rate(T, "crack")
    to, ti = avg_rate(T, "match"); go, gi = avg_rate(T, "compile")
    py = left[Py]; comp_h = py / go[Py]
    mt = left[Mt] + gi[Mt] * comp_h; match_h = mt / to[Mt]
    c = left[C] + ti[C] * match_h; crack_h = c / co[C]
    pe = left[Pe] + ci[Pe] * crack_h; pm = left[Pm] + ti[Pm] * match_h; pc = left[Pc] + gi[Pc] * comp_h
    parse_h = max(pe / po[Pe], pm / po[Pm], pc / po[Pc])
    m = left[M] + pi[M] * parse_h; mine_h = m / (mo[M] * MINE_MULT[t - 1])
    sql = fights * SQL_PER_FIGHT[t - 1] + apt.get("SQL Injector", 0)
    so, _ = avg_rate(T, "phish_spear"); sql_h = sql / so["SQL Injector"]
    work = (mine_h + parse_h + crack_h + match_h + comp_h + dec_h + sql_h) * CRAFT_WASTE
    vms = (T["states"]["arrive"]["vms"] + T["states"]["done"]["vms"]) / 2
    v = vms * VM_USE
    active = max(fight_h, (work + fight_h) / (1 + v))
    # idle view: each SESSION_H session is followed by an offline stretch at the cap (queue at half speed, main only)
    per_session = SESSION_H * (1 + v) + 0.5 * T["states"]["done"]["offline_cap_h"]
    sessions = (work + fight_h) / per_session
    upload_floor = max(g["amount"] * g["upload_s"] for g in T["goals"]) / 3600
    lvl_end = lvl_from(hack_xp_total)
    rows.append(dict(t=t, loc=T["location"], hacks=sum(hacks), fights=fights, fight_h=fight_h, caches=sum(caches), dec_h=dec_h,
        chain=dict(mine=mine_h, parse=parse_h, crack=crack_h, match=match_h, comp=comp_h), sql_h=sql_h, work=work, vms=vms,
        active=active, upload=upload_floor, lvl=lvl_end, need=need, from_cache=from_cache, R=R, h=hacks, pay=pay_hacks,
        offcap=T["states"]["done"]["offline_cap_h"], sessions=sessions, apt_m=apt.get(M, 0)))
f = lambda x: "%5.1f" % x
print("APT share %.0f%%" % (APT * 100))
print("tier            hacks  fights  fight h | caches dec h | chain h (mine parse crack match comp) | sql h | craft work h | VMs | ACTIVE h | upload floor h | Hacking lvl end (design)")
for r in rows:
    ch = r["chain"]
    print("T%d %-12s %5.0f %6.0f %7.1f | %5.0f %5.1f | %5.1f (%s %s %s %s %s) | %4.1f | %6.1f | %3.1f | %6.1f | %6.1f | %3d (%d) | sessions %4.1f" % (r["t"], r["loc"], r["hacks"], r["fights"], r["fight_h"], r["caches"], r["dec_h"],
        sum(ch.values()), f(ch["mine"]), f(ch["parse"]), f(ch["crack"]), f(ch["match"]), f(ch["comp"]), r["sql_h"], r["work"], r["vms"], r["active"], r["upload"], r["lvl"], HACK_ARR[r["t"]], r["sessions"]))
print()
print("share of each chain item's demand paid by cache loot:")
for r in rows:
    print("T%d " % r["t"] + "  ".join("%s %d/%d (%d%%)" % (k[:12], r["from_cache"][k], r["need"][k], 100 * r["from_cache"][k] / max(1, r["need"][k])) for k in r["R"]))
print()
print("hacks per target:")
for r in rows:
    print("T%d " % r["t"] + " ".join("%5.0f" % x for x in r["h"]), " payloads for hacks %d" % r["pay"])
if os.environ.get("SHORT"):
    print("\ncompact: tier | craft work h (1 terminal) | ACTIVE h | upload floor h | sessions")
    for r in rows:
        print("T%d %-15s %6.1f %7.1f %6.1f %6.1f" % (r["t"], r["loc"], r["work"], r["active"], r["upload"], r["sessions"]))
