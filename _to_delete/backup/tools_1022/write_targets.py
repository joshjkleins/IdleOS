"""Write combat_tune_T<n>.json enemies into singletons/stats.gd (easy-mode targets, by name)."""
import json, re, csv
rows = [r for r in csv.reader(open("_to_delete/combatdump.tsv", encoding="utf-8"), delimiter="\t") if len(r) > 3 and r[0] not in ("loc", "UPG", "")]
p = "singletons/stats.gd"; s = open(p, encoding="utf-8").read()
CAP = [0.25, 0.25, 0.35, 0.45, 0.40]
LOCS = ["School", "Lawfirm", "Hospital", "Bank", "Police Station", "Government"]
for r in rows:
    loc, i, name = r[0], int(r[1]), r[2]
    t = LOCS.index(loc) + 1
    e = json.load(open("tools/balance/combat_tune_T%d.json" % t))[i - 1]["enemy"]
    a = s.index('"name": "%s",' % name); b = s.index('"loot":', a)
    blk = s[a:b]
    vals = {"heat": round(0.5 + 0.3 * (i - 1), 2), "integrity": e["integrity"], "firewall": e["firewall"], "counter": e["counter"],
            "counter speed": float(e["counter speed"]), "intel cap": CAP[i - 1], "firewall reboot": float(e["firewall reboot"])}
    for k, v in vals.items():
        blk, n = re.subn(r'"%s": [0-9.]+,' % re.escape(k), '"%s": %s,' % (k, v), blk, count=1); assert n == 1, (name, k)
    blk, n = re.subn(r'"intel stat": "[^"]*",', '"intel stat": "%s",' % e["intel stat"], blk, count=1); assert n == 1
    s = s[:a] + blk + s[b:]
    print(t, i, name, vals["integrity"], vals["firewall"], vals["counter"])
open(p, "w", encoding="utf-8", newline="").write(s)
