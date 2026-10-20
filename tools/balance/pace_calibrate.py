"""Pace plan (step 3): every tier's chain arrives at the same seconds per payload as Tier 1 (process level 1,
the previous tier's upgrades installed). Reads _to_delete/rates_arrive.tsv (ARRIVE=1 ratetier run).
  find  : Parsing.FIND_BY_TIER so Footprint finds per Mining item match Tier 1's
  time  : Mining / Cracking / Matching / Compiling processes' speed values, Parsing.TIME_BY_TIER
Slower cycles carry proportionally more heat and XP each (heat/s and XP/h unchanged).
It multiplies what's there: re-measure between passes. Usage: pace_calibrate.py find|time [--apply]"""
import csv, re, sys
sys.path.insert(0, "tools/balance")
from payload_seconds import seconds, outs
PATH = "_to_delete/rates_arrive.tsv"
PER_TIER = {"Mining": ["Logs", "Archives", "Metadata", "Cookies", "Repositories", "Databases"],
            "Cracking": ["Password", "Signature", "Badge", "PIN", "Keys", "Biometric"],
            "Matching": ["Credential", "Certificate", "Badge", "Account", "Officer", "Clearance"],
            "Compiling": ["School", "Lawfirm", "Hospital", "Bank", "Police", "Government"]}
STEP = {"Mining": 0, "Parsing": 1, "Cracking": 2, "Matching": 3, "Compiling": 4}
MATCH_T1 = 12.0  # Tier 1 Matching evened out (was ~17 s per payload on arrival, the slowest step)
def scale_block(path, name, f, fill_rate=False):
    s = open(path, encoding="utf-8").read()
    i = s.index('"name": "%s",' % name)
    j = s.find('"name": "', i + 10); j = len(s) if j < 0 else j
    blk = s[i:j]
    def num(x): return ("%.4f" % x).rstrip("0").rstrip(".")
    blk, n = re.subn(r'("(?:base|overclock|overheat) speed(?: min| max)?": )([0-9.]+)',
                     lambda m: m.group(1) + num(float(m.group(2)) / f if fill_rate else float(m.group(2)) * f), blk)
    assert n >= 2, (path, name, n)
    blk = re.sub(r'("(?:heat|overclock heat|overheat heat)": )([0-9.]+)', lambda m: m.group(1) + num(float(m.group(2)) * f), blk)
    blk = re.sub(r'("experience per level": )([0-9]+)', lambda m: m.group(1) + str(max(1, int(round(int(m.group(2)) * f)))), blk, count=1)
    open(path, "w", encoding="utf-8", newline="").write(s[:i] + blk + s[j:])
def set_table(name, vals, mult=True):
    p = "singletons/Parsing.gd"; s = open(p, encoding="utf-8").read()
    m = re.search(r"const %s := \[([^\]]*)\]" % name, s)
    cur = [float(x) for x in m.group(1).split(",")]
    new = [round(c * v, 4) if mult else round(v, 4) for c, v in zip(cur, vals)]
    s = s[:m.start()] + "const %s := [%s]" % (name, ", ".join(str(x) for x in new)) + s[m.end():]
    open(p, "w", encoding="utf-8", newline="").write(s)
    return new
mode = sys.argv[1]; apply = "--apply" in sys.argv
rows = list(csv.DictReader(open(PATH, encoding="utf-8"), delimiter="\t"))
if mode == "find":
    y = {}
    for r in rows:
        if r["skill"] == "Parsing" and r["level"] == "1":
            o = outs(r["out/h"]); n = float(r["in/h"].split()[0])
            y[int(r["tier"])] = sum(o.values()) / len(o) / n
    f = [y[1] / y[t] for t in range(1, 7)]
    print("finds per item per output:", {t: round(v, 3) for t, v in y.items()}, "-> FIND x", [round(x, 3) for x in f])
    if apply: print("FIND_BY_TIER", set_table("FIND_BY_TIER", f))
elif mode == "time":
    s = seconds(PATH, "1")
    tgt = list(s[1]); tgt[3] = MATCH_T1
    for t in range(1, 7):
        fs = [tgt[k] / s[t][k] for k in range(5)]
        print("T%d factors mine %.2f parse %.2f crack %.2f match %.2f compile %.2f" % ((t,) + tuple(fs)))
        if apply:
            for skill, names in PER_TIER.items():
                scale_block("singletons/%s.gd" % skill, names[t - 1], fs[STEP[skill]], fill_rate=(skill == "Compiling"))
    if apply:
        print("TIME_BY_TIER", set_table("TIME_BY_TIER", [tgt[1] / s[t][1] for t in range(1, 7)]))
        # Parsing heat follows its slower lines (heat_tier_mult multiplies by TIME_BY_TIER itself)
