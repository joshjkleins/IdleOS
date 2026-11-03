"""Tier length v2 (2026-11-02): hacking is the main supply (Josh: the auto-battler is the draw, assume lots of caches).
Base hacks as tier_time.py (rares + apt cache costs). Then the model adds FARM hacks (target, Footprint-parsed cache:
x2 basics, no rare) in batches while that lowers the tier's active time; the chain (mine/parse/crack/match/compile)
fills what's left. Env: APT, APT_T, MINE_MULT, DEC_TO (as tier_time.py), FARM=0 to switch farming off, FP=share of
non-rare caches Footprinted (default 0.7: imperfect)."""
import json, os, collections
P = os.path.expanduser("~/mnt/idle-os-prototype")
D = json.load(open(os.path.expanduser("~/econ/dump.json"))); U = json.load(open(P + "/data/upgrades.json"))
RARE_GOALS = [1, 3, 4, 5, 6, 7]
FIGHT_S, LOSS, EXTRA_HACKS, COMPROMISE = 115, 1.25, 1.15, 12
CRAFT_WASTE, VM_USE, SESSION_H = 1.35, 0.45, 2.0
SQL_PER_FIGHT = [10, 12, 30, 50, 30, 30]
env = lambda k, d: os.environ.get(k, d)
APT = float(env("APT", "1")); APT_T = [float(x) for x in env("APT_T", "1,1,1,1,1,1").split(",")]
MINE_MULT = [float(x) for x in env("MINE_MULT", "1,1,1,1,1,1").split(",")]
DEC_TO = env("DEC_TO", ""); FARM = env("FARM", "1") == "1"; FP = float(env("FP", "0.7"))
def avg(T, key):
    o = collections.Counter(); i = collections.Counter()
    for st in ("arrive", "done"):
        s = T["states"][st]["procs"][key]; ph = 3600.0 / s["seconds"] / 2
        for k, v in s["out"].items(): o[k] += v * ph
        for k, v in s["inp"].items(): i[k] += v * ph
    return o, i
def avg_job(T, getter):
    o = collections.Counter(); sec = 0.0
    for st in ("arrive", "done"):
        j = getter(T["states"][st])
        if not j: continue
        sec += j["seconds"] / 2
        for k, v in j["out"].items(): o[k] += v / 2
    return o, sec
def tier(T):
    t = T["tier"]; R = T["resources"]; M, Pc, Pe, Pm, C, Mt, Py = R; tg = T["targets"]
    apt = collections.Counter()
    for p in U["packages"]:
        for lv in p["levels"]:
            if lv["tier"] != t: continue
            for c in lv["costs"]:
                item, amt = c["item"], c["amount"] * APT * APT_T[t - 1]
                if DEC_TO and p["group"] == "Decoding" and item == M:
                    if DEC_TO == "free": continue
                    k, f = DEC_TO.split(":"); item, amt = ("SQL Injector" if k == "sql" else R[int(k)]), amt * float(f)
                apt[item] += amt
    goal = {g["item"]: g["amount"] for g in T["goals"]}
    plain = [avg_job(T, lambda S, n=x["cache"]: S["caches"].get(n)) for x in tg]
    fpd = [avg_job(T, lambda S, n=x["cache"]: S["fp"].get(n, {}).get("decode")) for x in tg]
    fpp = [avg_job(T, lambda S, n=x["cache"]: S["fp"].get(n, {}).get("parse"))[1] for x in tg]
    p_rare = [max(0.05, plain[i][0].get(tg[i]["rare"], 0.25)) + (0.1 if t >= 2 else 0) for i in range(5)]
    cont = [plain[4][0].get(tg[j]["cache"], 0.0) for j in range(5)]
    rare_need = [RARE_GOALS[t - 1] + (tg[i + 1]["access_rare_n"] if i < 4 else 0) for i in range(5)]
    cache_need = [apt.get(tg[i]["cache"], 0) for i in range(5)]
    h = [0.0] * 5
    h[4] = max(rare_need[4] / p_rare[4], cache_need[4])
    for j in range(4):
        h[j] = max(tg[j + 1]["access_rare_n"] / p_rare[j], max(rare_need[j] / p_rare[j], cache_need[j]) - h[4] * cont[j], 3)
    base = [x * EXTRA_HACKS for x in h]
    mo, _ = avg(T, "mine"); po, pi = avg(T, "parse"); co, ci = avg(T, "crack"); to, ti = avg(T, "match"); go, gi = avg(T, "compile")
    so, _ = avg(T, "phish_spear")
    vms = (T["states"]["arrive"]["vms"] + T["states"]["done"]["vms"]) / 2; v = vms * VM_USE
    def evaluate(farm):
        hacks = [base[j] + farm[j] for j in range(5)]
        fights = sum(hacks) * LOSS + COMPROMISE
        fight_h = fights * FIGHT_S / 3600
        sup = collections.Counter(); craft_extra = 0.0
        # base hacks: rare-needed caches decoded plain, the rest Footprinted at FP share; farm hacks all Footprinted
        for j in range(5):
            caches_j = base[j] + (hacks[4] * cont[j] if j < 4 else 0)
            rare_caches = min(caches_j, rare_need[j] / max(0.01, p_rare[j]) * 1.0)
            fp_c = max(0.0, caches_j - rare_caches) * FP + farm[j]
            pl_c = caches_j - max(0.0, caches_j - rare_caches) * FP
            for k, x in plain[j][0].items(): sup[k] += x * pl_c
            for k, x in fpd[j][0].items(): sup[k] += x * fp_c
            craft_extra += (pl_c * plain[j][1] + fp_c * (fpd[j][1] + fpp[j])) / 3600
        need = collections.Counter()
        for k in R: need[k] += goal.get(k, 0) + apt.get(k, 0)
        need[Py] += sum(hacks[j] * tg[j]["payload"] for j in range(5)) * LOSS + sum(x["access_payload_n"] for x in tg)
        if env("NO_CACHE_PAYLOAD", "") == "1": sup[Py] = 0.0   # what-if: caches stop dropping the tier's payload
        left = {k: max(0.0, need[k] - sup.get(k, 0)) for k in R}
        comp_h = left[Py] / go[Py]
        mt = left[Mt] + gi[Mt] * comp_h; match_h = mt / to[Mt]
        c = left[C] + ti[C] * match_h; crack_h = c / co[C]
        pe = left[Pe] + ci[Pe] * crack_h; pm = left[Pm] + ti[Pm] * match_h; pc = left[Pc] + gi[Pc] * comp_h
        parse_h = max(pe / po[Pe], pm / po[Pm], pc / po[Pc])
        mine_h = (left[M] + pi[M] * parse_h) / (mo[M] * MINE_MULT[t - 1])
        sql_h = (fights * SQL_PER_FIGHT[t - 1] + apt.get("SQL Injector", 0)) / so["SQL Injector"]
        chain = mine_h + parse_h + crack_h + match_h + comp_h
        work = (chain + craft_extra + sql_h) * CRAFT_WASTE
        active = max(fight_h, (work + fight_h) / (1 + v))
        sess = (work + fight_h) / (SESSION_H * (1 + v) + 0.5 * T["states"]["done"]["offline_cap_h"])
        return dict(t=t, loc=T["location"], hacks=sum(hacks), farm=sum(farm), fight_h=fight_h, chain=chain, mine=mine_h, work=work,
            active=active, sess=sess, upload=max(g["amount"] * g["upload_s"] for g in T["goals"]) / 3600, farm_by=list(farm))
    farm = [0.0] * 5; best = evaluate(farm)
    while FARM:
        cand = None
        for j in range(5):
            f2 = list(farm); f2[j] += 5
            r = evaluate(f2)
            if r["active"] < best["active"] - 0.01 and (cand is None or r["active"] < cand[1]["active"]): cand = (f2, r)
        if not cand: break
        farm, best = cand
    return best
print("tier              hacks (farm)  fight h | chain h (mine) | work h | ACTIVE h | upload floor | sessions | farmed per target")
tot = 0; ses = 0
for T in D["tiers"]:
    r = tier(T); tot += r["active"]; ses += r["sess"]
    print("T%d %-15s %5.0f (%4.0f) %6.1f | %5.1f (%5.1f) | %6.1f | %7.1f | %6.1f | %5.1f | %s" % (r["t"], r["loc"], r["hacks"], r["farm"], r["fight_h"], r["chain"], r["mine"], r["work"], r["active"], r["upload"], r["sess"], " ".join("%3.0f" % x for x in r["farm_by"])))
print("total active %.0f h, %.0f sessions" % (tot, ses))
