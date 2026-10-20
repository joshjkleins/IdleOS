"""Heat plan step 2: scale each tier's process heat to the target arrival heat/s.
Reads _to_delete/heat.tsv (HEAT=1 ratetier run with HEAT_BY_TIER all 1.0 and the current heat values).
target(skill, T) = TIER_HEAT[T] * SKILL_MULT[skill] * (1 - 5% * (T-1))   [arriving: previous tier's reduction]
Per-tier processes (Mining, Cracking, Matching, Compiling payloads): their "heat", "overclock heat" and
"overheat heat" are multiplied. Shared processes get a HEAT_BY_TIER table (Parsing, Phishing, Decoding,
Compiling Mod/Access). Run once (it multiplies what's there)."""
import csv, re, sys
TIER_HEAT = [0.1, 0.146, 0.208, 0.3, 0.70, 1.0]
SKILL_MULT = {"Mining": 0.9, "Parsing": 1.0, "Phishing": 1.0, "Cracking": 1.15, "Decoding": 1.15, "Matching": 1.25, "Compiling": 1.35}
PER_TIER = {"Mining": ["Logs", "Archives", "Metadata", "Cookies", "Repositories", "Databases"],
            "Cracking": ["Password", "Signature", "Badge", "PIN", "Keys", "Biometric"],
            "Matching": ["Credential", "Certificate", "Badge", "Account", "Officer", "Clearance"],
            "Compiling": ["School", "Lawfirm", "Hospital", "Bank", "Police", "Government"]}
def target(skill, t): return TIER_HEAT[t-1] * SKILL_MULT[skill] * (1 - 0.05 * (t-1))
rows = list(csv.reader(open("_to_delete/heat.tsv", encoding="utf-8"), delimiter="\t"))[1:]
meas = {}
for r in rows:
    t = int(r[0]); v = float(r[3].split("/")[0]) if r[3] != "-" else None
    meas.setdefault((r[1], r[2]), {})[t] = v
def m(skill, label_pred, t):
    vals = [d[t] for (sk, lab), d in meas.items() if sk == skill and label_pred(lab) and d.get(t)]
    return sum(vals) / len(vals)
out = {}
# per-tier processes: the label in heat.tsv is the process name (+ " payload" for Compiling)
for skill, names in PER_TIER.items():
    for t, name in enumerate(names, 1):
        lab = name + " payload" if skill == "Compiling" else name
        cur = [d[t] for (sk, l), d in meas.items() if sk == skill and l == lab and d.get(t)][0]
        out[(skill, name)] = target(skill, t) / cur
tables = {
    "Parsing": [target("Parsing", t) / m("Parsing", lambda l: l.startswith("Footprint"), t) for t in range(1, 7)],
    "Phishing": [target("Phishing", t) / m("Phishing", lambda l: l == "Spear (no bait)", t) for t in range(1, 7)],
    "Decoding": [target("Decoding", t) / m("Decoding", lambda l: l.startswith("Decode"), t) for t in range(1, 7)],
    "Compiling": [target("Compiling", t) / target("Compiling", 1) for t in range(1, 7)],
}
for k, v in out.items(): print(k, round(v, 3))
for k, v in tables.items(): print(k, [round(x, 3) for x in v])
if "--apply" not in sys.argv: sys.exit()
def scale_block(path, name, f):
    s = open(path, encoding="utf-8").read()
    i = s.index('"name": "%s",' % name)
    j = s.find('"name": "', i + 10)
    j = len(s) if j < 0 else j
    blk = s[i:j]
    def rep(mo):
        return '%s%s' % (mo.group(1), round(float(mo.group(2)) * f, 4))
    nb, n = re.subn(r'("(?:heat|overclock heat|overheat heat)": )([0-9.]+)', rep, blk)
    assert n >= 1, (path, name)
    open(path, "w", encoding="utf-8", newline="").write(s[:i] + nb + s[j:])
for (skill, name), f in out.items():
    scale_block("singletons/%s.gd" % skill, name, f)
for skill, tab in tables.items():
    p = "singletons/%s.gd" % skill
    s = open(p, encoding="utf-8").read()
    s = s.replace("const HEAT_BY_TIER := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]", "const HEAT_BY_TIER := [%s]" % ", ".join(str(round(x, 3)) for x in tab))
    open(p, "w", encoding="utf-8", newline="").write(s)
print("applied")
