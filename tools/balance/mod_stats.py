"""Compile -mod stats for every tier's resources, rares and caches (Josh, 2026-10-20).
Same mod type per role at every tier, higher each tier; a rare = the next tier's basic of its role.
Reads _to_delete/modroles.tsv (tools/tests/modroles). Run again after changing a table; it overwrites.
2026-10-21 (playthrough): T1 crit 5% encrypted / 7.5% cracked (T2+ unchanged); payloads -> Countermeasure Reset
(MOD_TYPE 28, 5/7/9/11/13/15%); the target-2 rares keep bandwidth regen ("band" role)."""
import csv, re, shutil, os, sys
T = {  # MOD_TYPE: DAMAGE 0, EFFICIENCY 1, FIREWALL_REDUCTION 2, FIREWALL_DAMAGE 3, RESTORE 4, BAND_RATE 5,
       #           ATTACK_SPEED 6, DAMAGE_REDUCTION 7, COUNTER_SLOW 8, COUNTER_RESET 28
    "mining":         (0, [10, 20, 35, 55, 80, 120, 170]),        # SQL damage +
    "parsed_match":   (2, [15, 30, 53, 83, 120, 180, 255]),       # firewall reduction (start + every reboot)
    "parsed_compile": (3, [10, 20, 35, 55, 80, 120, 170]),        # firewall damage per hit +
    "encrypted":      (1, [0.05, 0.04, 0.06, 0.08, 0.10, 0.12]),  # crit chance +
    "cracked":        (1, [0.075, 0.06, 0.09, 0.12, 0.15, 0.18, 0.20]),
    "matched":        (6, [0.15, 0.20, 0.25, 0.30, 0.35, 0.40]),  # attack speed +%
    "payload":        (28, [0.05, 0.07, 0.09, 0.11, 0.13, 0.15]),  # Countermeasure Reset: chance per SQL hit
    "band":           (5, [2, 3, 4, 5, 6, 7, 8]),                 # bandwidth regen +/s (target-2 rares)
    "restore":        (4, [12, 15, 18, 21, 24, 27, 30]),          # Packet Spoof heal +% points (rares only)
    "counter_slow":   (8, [0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45]),  # rares only
}
RARE_ROLE = {1: "mining", 2: "band", 3: "restore", 4: "cracked", 5: "counter_slow"}  # rare N comes from target N's cache
CACHE_DR_START = [5, 15, 30, 50, 75, 110]  # counter damage reduction: target 1's cache, +1 per target after
DUR = {"basic": (5, 100), "payload": (10, 50), "rare": (5, 20), "cache": (10, 25)}  # hacks, items consumed
def setf(s, key, val):
    line = "%s = %s" % (key, val)
    if re.search(r"^%s = .*$" % re.escape(key), s, re.M):
        return re.sub(r"^%s = .*$" % re.escape(key), line, s, count=1, flags=re.M)
    m = re.search(r"^metadata/", s, re.M)
    return s[:m.start()] + line + "\n" + s[m.start():] if m else s.rstrip("\n") + "\n" + line + "\n"
def fmt(v): return ("%.4f" % v).rstrip("0").rstrip(".") + ("" if "." in ("%.4f" % v).rstrip("0").rstrip(".") else ".0")
rows = list(csv.reader(open("_to_delete/modroles.tsv", encoding="utf-8"), delimiter="\t"))
os.makedirs("_to_delete/backup/modstats", exist_ok=True)
for t, role, path in rows:
    t = int(t); p = path.replace("res://", "")
    if role.startswith("cache"):
        k = int(role[5:]); mt, val, kind = 7, CACHE_DR_START[t - 1] + (k - 1), "cache"
    elif role.startswith("rare"):
        r = RARE_ROLE[int(role[4:])]; mt, vals = T[r]; val, kind = vals[min(t, len(vals) - 1)], "rare"   # next tier's value
    else:
        mt, vals = T[role]; val = vals[t - 1]; kind = "payload" if role == "payload" else "basic"
    b = "_to_delete/backup/modstats/" + p.replace("/", "__")
    if not os.path.exists(b): shutil.copy(p, b)
    s = open(p, encoding="utf-8").read()
    s = setf(s, "hacking_mod_type", mt); s = setf(s, "hacking_mod_value", fmt(float(val)))
    s = setf(s, "hacking_mod_duration", DUR[kind][0]); s = setf(s, "hacking_mod_consumed", DUR[kind][1])
    open(p, "w", encoding="utf-8", newline="").write(s)
    print(t, role, p.split("/")[-1], mt, val)
