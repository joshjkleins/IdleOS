"""Economy pass: hours of main-terminal work one tier costs (process level 1, rates between arriving and tier done)
vs ~4-5 h of hacking. Demand = upgrades (all groups) + upload goal + hacking payloads + target access + SQL / Packet
Spoofs for the fights (combat_sim) + upgrade caches (extra target-1 hacks). Supply = the tier's chain (ratetier),
Phishing Spear (unbaited ~ baited / 2.4) for SQL, Decoding for caches.
Reads _to_delete/econ.json, raredemand.json, tools/balance/rates_2026-10-20_{arrive,done}.tsv, /tmp/fightcost.json."""
import json, csv, re
E = json.load(open("_to_delete/econ.json")); R = json.load(open("_to_delete/raredemand.json"))
FC = json.load(open("/tmp/fightcost.json"))
HACKS = [[61, 61, 61, 61, 56], [56, 56, 56, 56, 52], [53, 53, 53, 53, 49], [50, 50, 50, 50, 46], [47, 47, 47, 47, 44], [45, 45, 45, 45, 42]]
def load(p):
    rows = list(csv.DictReader(open(p, encoding="utf-8"), delimiter="\t"))
    return [r for r in rows if r["level"] == __import__("os").environ.get("LVL", "1")]
def outs(s):
    d = {}
    for part in s.split(" · "):
        m = re.match(r"([\d.]+) (.+)", part)
        if m: d[m.group(2)] = float(m.group(1))
    return d
A = load("tools/balance/rates_2026-10-20_arrive.tsv"); D = load("tools/balance/rates_2026-10-20_done.tsv")
def rate(rows, t, skill, label_start=""):
    for r in rows:
        if r["tier"] == str(t) and r["skill"] == skill and r["process"].startswith(label_start):
            return r
def per_hour(t, skill, label=""):
    a, d = rate(A, t, skill, label), rate(D, t, skill, label)
    oa, od = outs(a["out/h"]), outs(d["out/h"])
    out = {k: (oa.get(k, 0) + od.get(k, 0)) / 2 for k in set(oa) | set(od)}
    ia, id_ = outs(a["in/h"]), outs(d["in/h"])
    inp = {k: (ia.get(k, 0) + id_.get(k, 0)) / 2 for k in set(ia) | set(id_)}
    return out, inp
print("tier | hacks (rares + upgrade caches) | fight h | SQL need / Spear h | payloads | chain h: upgrades  uploads  payloads  total | decode h | main terminal total")
for t in range(1, 7):
    T = E[t - 1]; res = T["tier_resources"]  # [mining, parsed->compile, encrypted, parsed->match, cracked, matched, payload]
    M, Pc, Pe, Pm, C, Mt, Py = res
    hacks = list(HACKS[t - 1])
    cache_cost = sum(v for k, v in T["upgrades"].items() if k.lower().endswith("cache"))
    hacks[0] += cache_cost  # upgrades pay in target 1's caches: each is a hack
    fc = FC[str(t)]
    fight_h = sum(h * (fc[i][0] + 4) for i, h in enumerate(hacks)) / 3600
    sql = sum(h * fc[i][1] for i, h in enumerate(hacks)) + T["upgrades"].get("SQL Injector", 0)
    spoofs = sum(h * fc[i][2] for i, h in enumerate(hacks))
    pay_hacks = sum(h * T["targets"][i]["per_hack"] for i, h in enumerate(hacks))
    pay_access = sum(x["access_payloads"] for x in T["targets"])
    # demand per chain item, three buckets
    def need(bucket):
        d = {k: 0.0 for k in res}
        if bucket == "upgrades":
            for k in res: d[k] += T["upgrades"].get(k, 0)
        if bucket == "uploads":
            for k in res: d[k] += T["upload"].get(k, 0)
        if bucket == "payloads":
            d[Py] += pay_hacks + pay_access
        return d
    mine, _ = per_hour(t, "Mining"); parse, pin = per_hour(t, "Parsing"); crack, _ = per_hour(t, "Cracking")
    match, _ = per_hour(t, "Matching"); comp, _ = per_hour(t, "Compiling")
    parse_items = list(pin.values())[0]
    def hours(d):
        py = d[Py]; mt = d[Mt] + py; c = d[C] + mt; pe = d[Pe] + c; pm = d[Pm] + mt; pc = d[Pc] + py
        yields = {Pe: parse[Pe] / parse_items, Pm: parse[Pm] / parse_items, Pc: parse[Pc] / parse_items}
        parses = max(pe / yields[Pe], pm / yields[Pm], pc / yields[Pc])
        m = d[M] + parses
        return m / mine[M] + parses / parse_items + c / crack[C] + mt / match[Mt] + py / comp[Py]
    hu, hl, hp = hours(need("upgrades")), hours(need("uploads")), hours(need("payloads"))
    spear, _ = per_hour(t, "Phishing", "Spear")
    sql_h = (sql - 0) / (spear.get("SQL Injector", 1) / 2.4)
    dec = rate(A, t, "Decoding"); dec_h = sum(hacks) / float(dec["cycles/h"])
    total = fight_h + hu + hl + hp + sql_h + dec_h
    print(" T%d  | %4d (+%3d caches) | %5.1f | %6d / %4.1f | %5d | %6.1f %7.1f %8.1f %6.1f | %4.1f | %6.1f h" % (t, sum(hacks), cache_cost,
        fight_h, sql, sql_h, pay_hacks + pay_access, hu, hl, hp, hu + hl + hp, dec_h, total))
