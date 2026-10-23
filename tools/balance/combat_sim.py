"""Combat simulator: a Python copy of scripts/hacking_game.gd's fight rules (easy mode), for tuning targets.
Mirrors: SQL bar 20/s (x attack speed mods), Packet Spoof bar 8/s with first claim on bandwidth, bandwidth regen
(+ overclock x2 / overheat x0.5), firewall absorbs each hit and loses fw damage per hit, break -> down for
reboot time (counters -50%), then reboots to its (reduced) start value; counters: bar speed/s, dmg - reduction
(min 1); crit chance (level + mods) x2; spoof heal % of max anon below the threshold; heat / overheat; intel
(2026-10-21 rework: one share off integrity, firewall, counter damage and counter speed, 10% when maxed);
the Countermeasure Reset payload mod ("ctr_reset": chance per SQL hit to empty the counter bar);
the equippable mods; Evasion / Siphon / Dead Man's Switch capstones.
fight(...) -> dict(won, time, anon_left_pct)."""
import random
DT = 0.1
SQL_COST = 5     # SQL Injector bandwidth per attack (items/combat/sql_injector.tres; 2026-10-23: was 6)
SQL_SPEED = 25.0 # SQL Injector bar fill per second (2026-10-23: was 20)
# ---- player progression ----
LEVEL_AT_TIER = [1, 15, 30, 45, 60, 75]          # hacking level on arrival (assumed)
TRACK = {"damage": 5, "firewall": 2, "bw_regen": 1, "max_bw": 5, "healing": 0.01, "mod_slots": 1, "spoof_thr": 0.1}
CAPSTONE_TIER = {"second_wind": 1, "evasion": 2, "recycler": 3, "siphon": 4, "dead_mans": 5, "exploit_kit": 6}
COOLING = [0.2, 0.5, 0.85, 1.4, 2.1, 3.15, 4.7]  # C/s after tier n of System (index 0 = none)
HEAT_RED = [0, .05, .10, .15, .20, .25, .30]
HEAT_TIER = [1.0, 1.46, 2.08, 3.0, 7.0, 10.0]     # hacking heat x location tier (heat plan; to be wired in game)
import os
# Damage / firewall tracks: GEO=1 grows them with the tier like enemies and mods do (proposal); else today's linear sheet
GEO = os.environ.get("GEO", "1") == "1"
DMG_TOT = [0, 5, 30, 67.5, 117.5, 180, 280] if GEO else [0, 5, 10, 15, 20, 25, 30]   # total after tier n
FW_TOT = [0, 2, 5, 9.5, 15.5, 23, 35] if GEO else [0, 2, 4, 6, 8, 10, 12]
def tot(tab, upg):
    i = int(upg); f = upg - i
    return tab[min(i, 6)] + (tab[min(i + 1, 6)] - tab[min(i, 6)]) * f
def player(tier, upg, level=None, mods=(), overclock=True, policy="auto", extra=()):
    """upg = whole tiers of hacking (+ System) upgrades installed (tier-1 = arriving, tier = all of this tier);
    extra = tracks of the next tier also installed: damage, firewall, bw_regen, max_bw, healing, mod_slots."""
    lvl = level or LEVEL_AT_TIER[tier - 1]
    P = _player(tier, upg, lvl, mods, overclock, policy)
    if extra:
        Q = _player(tier, upg + 1, lvl, mods, overclock, policy)
        keymap = {"damage": ["dmg"], "firewall": ["fw_dmg"], "bw_regen": ["bw_regen"], "max_bw": ["max_bw"], "healing": ["heal"], "mod_slots": ["slots"]}
        for e in extra:
            for k in keymap[e]: P[k] = Q[k]
        if "damage" in extra: P["dmg_installs"] += 1
    return P
def _player(tier, upg, lvl, mods, overclock, policy):
    return dict(
        tier=tier, upg=upg, level=lvl, max_anon=100 + 5 * (lvl - 1) + 100 * (tier - 1),
        dmg=20 + tot(DMG_TOT, upg), fw_dmg=1 + tot(FW_TOT, upg),
        bw_regen=1 + TRACK["bw_regen"] * upg, max_bw=10 + TRACK["max_bw"] * upg,
        heal=0.05 + TRACK["healing"] * upg, slots=1 + int(TRACK["mod_slots"] * upg),
        thr=0.30 + TRACK["spoof_thr"] * int(upg), crit=0.05 + 0.00255 * (lvl - 1),
        caps={k for k, t in CAPSTONE_TIER.items() if upg >= t},
        cool=COOLING[min(6, int(upg))], heat_red=HEAT_RED[min(6, int(upg))],
        dmg_installs=int(upg),  # damage track installs (1 per tier)
        mods=dict(mods), overclock=overclock, policy=policy)
INTEL_MAX = 0.10  # Decoding.INTEL_STEP x INTEL_MAX_STEPS: full intel is -10% on all four stats
def fight(P, E, intel=0.0, seed=None, max_t=600.0, start_anon=None, spoofs=None):
    """E: integrity, firewall, counter, counter speed, heat, [firewall reboot]. intel: 0..1 of full intel
    (every stat -10% at 1.0; the game builds it 2% per stat at a time)."""
    rnd = random.Random(seed)
    m = P["mods"]; g = lambda k: m.get(k, 0.0)
    integ, fw0, ctr, cspd = E["integrity"], E["firewall"], E["counter"], E["counter speed"]
    reboot = E.get("firewall reboot", 10.0)
    if intel:
        k = 1.0 - INTEL_MAX * intel  # same share off every stat (hacking_game._apply_intel)
        integ = max(1, int(round(integ * k))); fw0 = max(0, int(round(fw0 * k)))
        ctr = max(0, int(round(ctr * k))); cspd = max(0.1, cspd * k)
    fw_start = max(0, fw0 - g("fw_red"))
    n_mods = len(m)
    sql_cost = min(P["max_bw"], SQL_COST + 1 * len([k for k in m if k != "sql_boost"]))  # 2026-10-23: equipped mods +1 bandwidth each (SQL Booster 0)
    spoof_cost = 0 if "ghost_packet" in m else 2
    anon = P["max_anon"] if start_anon is None else start_anon; amax = P["max_anon"]; bw = P["max_bw"]
    spoofs_left = 10**9 if spoofs is None else spoofs  # Packet Spoofs in the inventory (None = unlimited)
    hp = integ; fw = fw_start; fw_down = 0.0; bricked = False; breach = False; fresh = True
    atk = spd_bar = cbar = 0.0; defending = False
    temp = 30.0; overheated = False; oc = P["overclock"]
    t = 0.0; decoys = int(g("decoys")); dead_used = False
    n_atk = 0; n_spoof = 0
    hm = HEAT_TIER[P["tier"] - 1] * (1 - P["heat_red"])
    atk_heat = (0.3 + 0.1 * P["dmg_installs"]) * hm
    def heat(h):
        nonlocal temp, overheated, oc
        if overheated: temp += 0.3 * hm; return
        temp += h + (2 * hm if oc and "cold_boot" not in m else 0)
        if temp >= 95: overheated = True; oc = False
    crit_p = (P["crit"] + g("crit")) * (2 if "vuln_scanner" in m else 1)
    while t < max_t:
        t += DT
        # temperature
        cool = P["cool"] + (0.3 if overheated and P["upg"] >= 1 else 0)   # Overheat Fan (System T1 capstone)
        if overheated and P["upg"] >= 3: cool *= 2                          # Liquid Cooling (T3)
        temp = max(30.0, temp - cool * DT)
        if overheated and temp <= 80: overheated = False
        if P["overclock"] and not overheated:
            if oc and temp > 90: oc = False
            elif not oc and temp < 60: oc = True
        ocv = 2.0 if oc else (0.5 if overheated else 1.0)
        enemy_x = 2.0 if (overheated and "cold_boot" not in m) else 1.0
        bw = min(P["max_bw"], bw + (P["bw_regen"] + g("band_rate") + g("burst") * P["max_bw"]) * ocv * DT)
        atk += SQL_SPEED * (1 + g("atk_spd") + g("sql_boost")) * DT
        if defending: spd_bar += 8 * (1 + g("spoof_speed")) * DT
        if anon > 0 and t >= g("stealth"):
            slow = max(0.05, 0.5 - g("shatter")) if fw_down > 0 else 1.0
            cbar += cspd * enemy_x * slow / (1 + g("counter_slow")) * (1 - g("latency")) * DT
        if fw_down > 0:
            fw_down -= DT
            if fw_down <= 0:
                if "firmware_brick" in m: bricked = True
                else: fw = fw_start; fresh = True
        if P["policy"] == "early" and not defending and anon < amax * 0.8: defending = True
        def_wait = False
        if defending and spoofs_left - n_spoof <= 0: defending = False  # out of Packet Spoofs
        if defending and spd_bar >= 100:
            if bw >= spoof_cost:
                amt = int(-(-amax * (P["heal"]) // 1)) + int(-(-amax * g("restore") / 100 // 1))
                amt *= 2 if "proxy_chain" in m else 1
                anon = min(amax, anon + amt); bw -= spoof_cost; heat(0.5 * hm); spd_bar = 0; n_spoof += 1
                defending = anon * 100 <= amax * int(P["thr"] * 100)
            else: def_wait = True
        if atk >= 100 and not def_wait and bw >= sql_cost:
            crit = 2.0 if (breach or rnd.random() <= crit_p) else 1.0  # breach: first hit after a firewall break crits
            breach = False
            if crit > 1 and "critical_overflow" in m: crit *= 2
            raw = int(round(P["dmg"] + g("dmg")) * (1 + g("dmg_pct")) * crit)
            fb = fw if (fw_down <= 0 and not bricked) else 0
            hp -= max(raw - fb, 0)
            if fb > 0:
                fw -= P["fw_dmg"] + g("fw_dmg") + g("shredder") * fw0 + (g("opener") if fresh else 0)  # opener: Handshake Exploit
                fresh = False
            bw -= sql_cost; heat(atk_heat); atk = 0; n_atk += 1
            if g("ctr_reset") and cbar > 0 and rnd.random() < g("ctr_reset"): cbar = 0.0  # Countermeasure Reset (payloads)
            if "siphon" in P["caps"]: anon = min(amax, anon + -(-amax * 0.005 // 1))
            if hp <= 0: return dict(won=True, time=t, anon=anon / amax, sql=n_atk, spoofs=n_spoof)
            if fb > 0 and fw <= 0:
                fw = 0; fw_down = reboot; breach = True
                hp -= int(round(integ * g("cascade")))
                if hp <= 0: return dict(won=True, time=t, anon=anon / amax, sql=n_atk, spoofs=n_spoof)
        if cbar >= 100:
            cbar = 0
            if decoys > 0: decoys -= 1
            elif "evasion" in P["caps"] and rnd.random() < 0.1: pass
            else:
                d = max(1, ctr - g("dr"))
                anon -= d; heat(E.get("heat", 1.0) * hm)
                if anon <= 0 and "dead_mans" in P["caps"] and not dead_used:
                    dead_used = True; anon = 1 + -(-amax * 0.25 // 1)
                if g("mirror"):
                    hp -= int(round(d * g("mirror")))
                    if hp <= 0: return dict(won=True, time=t, anon=anon / amax, sql=n_atk, spoofs=n_spoof)
                if anon <= 0: return dict(won=False, time=t, anon=0.0, sql=n_atk, spoofs=n_spoof)
                if anon * 100 <= amax * int(P["thr"] * 100) and spoofs_left - n_spoof > 0: defending = True
    return dict(won=False, time=t, anon=anon / amax, sql=n_atk, spoofs=n_spoof)
def summary(P, E, intel=0.0, n=60):
    rs = [fight(P, E, intel, seed=i) for i in range(n)]
    w = [r for r in rs if r["won"]]
    return dict(win=len(w) / n, time=sum(r["time"] for r in w) / max(1, len(w)), anon=sum(r["anon"] for r in w) / max(1, len(w)),
                sql=sum(r["sql"] for r in rs) / n, spoofs=sum(r["spoofs"] for r in rs) / n)
