"""XP pass: rares needed per tier (upgrades + upload goal + target access) vs rare drop chance -> hacks per target
-> hacking XP per tier at today's target exp, vs the XP to reach the levels the combat pass assumes.
Reads _to_delete/raredemand.json (tools/tests/raredemand). Usage: xp_plan.py [mods_per_rare]"""
import json, sys, random
d = json.load(open("_to_delete/raredemand.json"))
XP = [0] + d["xp_for_level"]                  # XP[l] = total xp at level l
ARRIVE = [1, 15, 30, 45, 60, 75, 90]          # combat pass: hacking level arriving at tier 1..6 (+ end of tier 6)
MODS = float(sys.argv[1]) if len(sys.argv) > 1 else 0   # extra rares per target for mods (20 = one full mod)
eff0, rate = d["decoding"]["efficiency"], d["decoding"]["rate"]
def track(id, tier):  # total of a track with every level up to <tier> installed
    return sum(v for t, v in d["tracks"][id] if t <= tier)
def caches_per_rare(p, tr, n=20000):
    """expected caches decoded per rare with chance p and Rare Tracker +tr per dry cache"""
    rnd = random.Random(1); tot = 0
    for _ in range(n):
        k = 0
        while True:
            k += 1
            if rnd.random() < p + tr * (k - 1): break
        tot += k
    return tot / n
print("Rares needed per tier: targets 1-4 = upgrades 4 + upload 10 + access 5 = 19, target 5 = 12 (+%g for mods)\n" % MODS)
print("tier  decode lvl  rare%%  caches/rare | hacks per target (own caches only)        | hacks w/ top-cache | XP at today's exp -> level | XP to reach next arrival level")
lvl = 1; xp_tot = 0
PROPOSAL = []; SUM = []
for T, tier in enumerate(d["tiers"], 1):
    dl = ARRIVE[T - 1] + 7                              # decoding level mid-tier ~ hacking level
    p = 0.25  # 2026-10-22: flat rare chance (efficiency no longer raises it; it adds basic resources)
    tr = track("decoding.rare_tracker", T)
    cpr = caches_per_rare(p, tr)
    tg = tier["targets"]
    need = [g["upgrades"] + g["upload"] + g["access"] + MODS for g in tg]
    hacks = [n * cpr for n in need]
    # top cache: each one decoded also yields ~lower_caches of the tier's other caches (spread over targets 1-4)
    lower = tg[4]["lower_caches"] / 4.0   # each target-5 cache holds this many of each lower target's cache
    top = hacks[4]                                        # hacks of target 5 you do anyway
    hacks2 = [max(0, h - top * lower) for h in hacks[:4]] + [top]
    xp = sum(h * g["exp"] for h, g in zip(hacks, tg)); xp2 = sum(h * g["exp"] for h, g in zip(hacks2, tg))
    want = XP[ARRIVE[T]] - XP[ARRIVE[T - 1]]
    xp_tot += xp
    reached = max(l for l in range(1, 100) if XP[l] <= xp_tot)
    print(" T%d     %3d      %4.1f%%   %5.1f    | %s | %s | %9d -> L%-3d | %9d  (L%d -> L%d)" % (T, dl, p * 100, cpr,
        " ".join("%5.0f" % h for h in hacks), " ".join("%4.0f" % h for h in hacks2), xp, reached, want, ARRIVE[T - 1], ARRIVE[T]))
    # exp per target that lands the next arrival level, keeping today's shape between the targets
    scale = want / max(1, xp2)
    PROPOSAL.append([int(round(g["exp"] * scale)) for g in tg])
    SUM.append((T, sum(hacks2), want))

print("\nProposed target exp (hacks with the target-5 cache bonus, today's shape):")
for (T, h, want), e in zip(SUM, PROPOSAL):
    print("  T%d  %4.0f hacks  %7d xp  exp %s" % (T, h, want, e))
json.dump(PROPOSAL, open("_to_delete/exp_proposal.json", "w"))
