"""Seconds of each chain process per payload, per tier, from a ratetier TSV (rates.tsv / rates_arrive.tsv).
Usage: python3 payload_seconds.py <tsv> [level]   -> prints mine | parse | crack | match | compile = total."""
import csv, re, sys
def outs(s):
    d = {}
    for part in s.split(" · "):
        m = re.match(r"([\d.]+) (.+)", part)
        if m: d[m.group(2)] = float(m.group(1))
    return d
def seconds(path, lvl="1"):
    rows = list(csv.DictReader(open(path, encoding="utf-8"), delimiter="\t"))
    res = {}
    for t in "123456":
        R = {r["skill"]: r for r in rows if r["tier"] == t and r["level"] == lvl and r["skill"] in ("Mining", "Parsing", "Cracking", "Matching", "Compiling")}
        mine = outs(R["Mining"]["out/h"]); parse = outs(R["Parsing"]["out/h"]); pin = float(R["Parsing"]["in/h"].split()[0])
        crack_in = list(outs(R["Cracking"]["in/h"]).keys())[0]; crack_out = float(list(outs(R["Cracking"]["out/h"]).values())[0])
        crack_inrate = list(outs(R["Cracking"]["in/h"]).values())[0]
        comp_in = outs(R["Compiling"]["in/h"]); comp_out = list(outs(R["Compiling"]["out/h"]).values())[0]
        match_in = outs(R["Matching"]["in/h"]); match_out = list(outs(R["Matching"]["out/h"]).values())[0]
        per_pay_match = list(comp_in.values())[0] / comp_out
        per_match_each = list(match_in.values())[0] / match_out
        enc_per_crack = crack_inrate / crack_out
        mi = [k for k in match_in if k in parse][0]; ci = [k for k in comp_in if k in parse][0]
        need = {crack_in: per_pay_match * per_match_each * enc_per_crack, mi: per_pay_match * per_match_each, ci: per_pay_match}
        items = max(need[k] / (parse[k] / pin) for k in need)
        mined = list(mine.values())[0]
        s = [items / mined * 3600, items / pin * 3600, per_pay_match * per_match_each / crack_out * 3600, per_pay_match / match_out * 3600, 1 / comp_out * 3600]
        res[int(t)] = s
    return res
if __name__ == "__main__":
    lvl = sys.argv[2] if len(sys.argv) > 2 else "1"
    for t, s in seconds(sys.argv[1], lvl).items():
        print(f"  T{t}: " + " | ".join(f"{x:5.2f}" for x in s) + f" = {sum(s):5.1f}s")
