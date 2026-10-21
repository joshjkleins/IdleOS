import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# ---- tier reference data (from the live game) ----
TIER_NAMES = ["School","Lawfirm","Hospital","Bank","Police","Government"]
# primary basic cost item per tier (mined resource) and a secondary (cache)
TIER_BASIC = ["Logs","Archives","Metadata","Cookies","Repositories","Databases"]
TIER_CACHE = ["Student cache","Legal assistant cache","Receptionist cache","Teller Cache","Secretary cache","Clerk Cache"]
# every target's cache per tier (targets 1..5): Hacking upgrades rotate through them, 2 installs per target
TARGET_CACHES = [
    ["Student cache","Admin cache","Vice principal cache","Principal cache","Superintendent cache"],
    ["Legal assistant cache","Paralegal cache","Associate attorney cache","Lawyer cache","Partner cache"],
    ["Receptionist cache","Orderly cache","Nurse cache","Doctor cache","Chief of medicine cache"],
    ["Teller Cache","Loan Officer Cache","Branch Manager Cache","Security Cache","Chief Financial Officer Cache"],
    ["Secretary cache","Cop cache","Detective cache","Sergeant cache","Captain cache"],
    ["Clerk Cache","Analyst Cache","Ambassador Cache","Vice President Cache","President Cache"],
]
# rare item per tier (capstone cost)
TIER_RARE  = ["Falsified transcript database","Sealed case files","Prescription pad credentials","Vault Override","Corruption payout ledger","Black Budget Ledger"]

TIER_ITEMS = {
 "mined":      ["Logs","Archives","Metadata","Cookies","Repositories","Databases"],
 "address":    ["IP address","Email Header","Mac Address","Routing Number","Subnet Map","Gateway Address"],
 "encrypted":  ["Encrypted passwords","Encrypted Signature","Encrypted Badge Hash","Encrypted PINS","Encrypted SSH Key","Encrypted Bio Hash"],
 "identifier": ["Usernames","Case Number","Staff IDs","Account Numbers","Badge Number","Clearance ID"],
 "cracked":    ["Passwords","Digital Signature","Badge Hash","PINS","Private Keys","Bio Template"],
 "matched":    ["Credentials","Signed Certificate","Access Badge","Account access tokens","Officer Auth Key","Security Clearance"],
 "payload":    ["School payload","Lawfirm Payload","Hospital Payload","Bank Payload","Police Payload","Government Payload"],
 "cache":      TIER_CACHE,
}
TIER_RARES = [
 ["Parents credit card","Falsified transcript database","Student disciplinary records","School budget embezzlement logs","District wide master password"],
 ["Leaked deposition transcripts","Forged court document templates","Sealed case files","Offshore account records","Witness protection address"],
 ["Patient appointment history","Staff keycard clone data","Prescription pad credentials","Patient insurance data","Falsified drug trial results"],
 ["Cash Drawer Override Codes","Credit Records","Safe Deposit Box Registry","Vault Override","Swift Master Key"],
 ["Internal affairs complaint archive","Body cam footage deletion logs","Confidential informant registry","Evidence locker access codes","Corruption payout ledger"],
 ["Registered Voters Database","CIA Brief","Black Budget Ledger","Deep Cover IDs","Nuclear Codes"],
]
# currency per group: rate key (row in Cost Inputs), item description per tier
CURRENCY = {
 "System":    ("mining",     lambda t: TIER_ITEMS["mined"][t-1]),
 "Mining":    ("mining",     lambda t: TIER_ITEMS["mined"][t-1]),
 "Parsing":   ("parsing",    lambda t: f'{TIER_ITEMS["address"][t-1]} + {TIER_ITEMS["encrypted"][t-1]} + {TIER_ITEMS["identifier"][t-1]} (each)'),
 "Cracking":  ("cracking",   lambda t: TIER_ITEMS["cracked"][t-1]),
 "Matching":  ("matching",   lambda t: TIER_ITEMS["matched"][t-1]),
 "Phishing":  ("phishing",   lambda t: "SQL Injector"),
 "Decoding":  ("decoding",   lambda t: TIER_ITEMS["mined"][t-1] + " (decoded from caches)"),
 "Compiling": ("compiling",  lambda t: TIER_ITEMS["payload"][t-1]),
 "Hacking":   ("hacking",    lambda t: TIER_ITEMS["cache"][t-1]),
}
TOKEN_SLOTS = {("System","VM Windows"), ("System","Scheduler")}
GROUP_ORDER = ["System","Mining","Parsing","Cracking","Matching","Phishing","Decoding","Compiling","Hacking"]
import re
ID_OVERRIDES = {
 ("System","Cooling"):"system.cooling_amount", ("Hacking","SQL Damage"):"hacking.damage",
 ("Hacking","Firewall Damage"):"hacking.firewall", ("Hacking","Bandwidth Recovery"):"hacking.bandwidth_recovery",
 ("Hacking","Max Bandwidth"):"hacking.max_bandwidth", ("Hacking","Packet Spoof Healing"):"hacking.healing",
 ("Hacking","Mod Slot"):"hacking.mod_slots",
}
def slug(n):
    return re.sub(r"[^a-z0-9]+","_", n.lower().replace("'","")).strip("_")
def package_id(group, name):
    return ID_OVERRIDES.get((group,name), f"{group.lower()}.{slug(name)}")
def game_value(running, tier):
    """per-install value in game units: % units become fractions, signs are handled in game code"""
    if not running:
        return True
    start, step, unit = running
    v = step[tier-1] if isinstance(step, list) else step
    v = abs(v)
    if unit.startswith("= double"):
        return 1
    if "%" in unit:
        v = v / 100.0
    return round(v, 6)


# cost scaling: amount grows with tier and with install index within the tier
def cost(tier, install_idx, kind="basic"):
    # install_idx 1..10
    base = {"basic":40, "cache":4}[kind]
    tier_mult = [1,2.2,4.5,9,18,36][tier-1]
    amt = int(round(base * tier_mult * (0.6 + 0.08*install_idx)))
    item = TIER_BASIC[tier-1] if kind=="basic" else TIER_CACHE[tier-1]
    return f"{item} x{amt}"

def rare_cost(tier, amt=2):
    return f"{TIER_RARE[tier-1]} x{amt}"

# ---- group slot designs ----
# each group has exactly 10 slots per tier. slot = dict(type, name, effect, value_by_tier_fn)
# value_by_tier returns the per-install amount string for a given tier.

def pct_track(base):  # e.g. +15% speed each install
    return lambda t: f"+{base}%"
def flat_track(vals): # explicit per-tier flat amount
    return lambda t: vals[t-1]

TRACK="Track"; PTD="Pointed"; CAP="Capstone"
# additive speed bonus per install, by tier: 3 installs per tier bring the total to 1.5^tier - 1
SPEED_STEP = [round((1.5**t - 1.5**(t-1)) / 3, 4) for t in range(1, 7)]
# Cooling added by each tier's install: totals 0.4 / 0.75 / 1.3 / 2.0 / 3.05 / 4.6 C/s (base 0.1)
COOLING_STEP = [0.3, 0.35, 0.55, 0.7, 1.05, 1.55]
# SQL damage / firewall damage added per tier: totals +5/30/68/118/180/280 and +2/5/10/16/23/35
DAMAGE_STEP = [5, 25, 38, 50, 62, 100]
# Economy pass (2026-10-20, tools/balance/econ2.py): cost scale per tier so each tier fits Josh's active-play time
# (T1 1-2 h ... T6 6-7 h, cache loot counted), and rare items per capstone by tier
COST_SCALE = [0.1, 0.7, 0.85, 0.75, 0.75, 1.0]
BASIC_TIER_MULT = [3, 1, 1, 1, 1, 1]  # basic-resource costs only (2026-10-20 playthrough: T1 x3)
CAP_RARES = [1, 1, 2, 2, 2, 2]
HACK_CACHE_TOTAL = [10, 15, 22, 28, 34, 40]  # Hacking upgrades' cache cost per tier (all 10 installs)
FIREWALL_STEP = [2, 3, 5, 6, 7, 12]

GROUPS = {}

GROUPS["System"] = [
    # (type, name, effect, per-install value, running: (start, step, unit) or None)
    # Heat plan (2026-10-20): cooling grows with each tier's process heat, so a new tier runs ~1.3x hot on arrival,
    # cool after this tier's Cooling + Heat Reduction installs, and main + all VM windows run cool at the tier's end.
    (TRACK,"Cooling","Passive cooling per second",[f"+{v} C/s" for v in COOLING_STEP],(0.1,COOLING_STEP,"C/s cooling")),
    (TRACK,"Heat Reduction","Less heat from every process (percent of each heat tick)","-5%",(0.0,5,"% less heat")),
    (TRACK,"VM Windows","Max simultaneous VM windows","+1",(1,1,"VM windows")),
    (TRACK,"Background Services","Offline progression cap: +2 h per install on top of the 1 h base (24 h max)","+2 h",(0,2,"h added to the 1 h offline cap")),
    (TRACK,"Background Services","Offline progression cap","+2 h",(0,2,"h added to the 1 h offline cap")),
    (TRACK,"Defrag Duration","Defrag boosts last longer","+2.5 min",(10,2.5,"min boost")),
    (TRACK,"Defrag Cooldown","Shared defrag cooldown shorter (meets duration at max)","-2.5 min",(40,-2.5,"min cooldown")),
    (PTD,"Thermal Paste","Overheat clears sooner: the clear temp rises toward the 95 C trigger (today: clears at 80 C)","+2 C clear temp",(80,2,"C overheat clears")),
    (PTD,"Scheduler","VM tokens last longer per use","+10% VM uptime",(0,10,"% VM uptime")),
    (CAP,["Overheat Fan","Idle Cooling","Liquid Cooling","Load Balancer","Watchdog","Server Rack"],
        ["+0.3 C/s cooling while overheated (existing upgrade, kept)",
         "Cooling x2 while no process is running",
         "Overheat recovery twice as fast",
         "VM processes produce half heat",
         "Overclock switches off by itself at 90 C so it can't push you into overheat",
         "VMs produce no heat"],"one-off",None),
]
GROUPS["Mining"] = [
    (TRACK,"Speed","Mining cycle speed (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Mining cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Mining cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Extra resources per cycle (on top of level efficiency); +100% at max","+8.33%",(0,100/12,"% bonus efficiency")),
    (TRACK,"Efficiency","Extra resources per cycle","+8.33%",(0,100/12,"% bonus efficiency")),
    (TRACK,"Heat Sink","Less heat from Mining (replaces Yield, which outweighed efficiency)","-2%",(0,2,"% less Mining heat")),
    (TRACK,"Heat Sink","Less heat from Mining","-2%",(0,2,"% less Mining heat")),
    (PTD,"Vein Detection","Every Nth cycle yields double; N shrinks each tier","every 10th -> 5th",(11,-1,"= double every Nth cycle")),
    (PTD,"Pipelining","A finished cycle starts the next one partly filled","+10% head start",(0,10,"% head start")),
    (CAP,["Overclock","Deep Core","Sift","Prospect","Survey","Cool Bits"],
        ["MODIFIER 'overclock': faster, more heat (existing; tutorial step depends on it, so keep it cheap)",
         "Passive: VM Mining token chance x2",
         "MODIFIER 'sift': -50% speed, heat x1.5; each cycle 15% chance to also find one of the tier's Parsing items",
         "MODIFIER 'prospect': -40% speed; efficiency x2, VM token chance x2, heat x2",
         "MODIFIER 'survey': half resources, +100% Mining XP (for grinding levels)",
         "Passive: Overclock, Sift and Prospect produce no extra heat"],"one-off",None),
]
GROUPS["Parsing"] = [
    (TRACK,"Speed","Parsing cycle speed (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Parsing cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Parsing cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Chance to find a resource per row (on top of level efficiency); 20% at max","+1.67%",(0,20/12,"% bonus find chance")),
    (TRACK,"Efficiency","Chance to find a resource per row","+1.67%",(0,20/12,"% bonus find chance")),
    (TRACK,"Rows","Rows scanned per pass","+1",(0,1,"extra rows per pass")),
    (TRACK,"Rows","Rows scanned per pass","+1",(0,1,"extra rows per pass")),
    (PTD,"Pattern Cache","Each empty row raises the next row's find chance until a hit (bad-luck protection)","+1% per miss",(0,1,"% added per empty row")),
    (PTD,"Fast Skip","Empty rows are processed faster (works on every Parsing process from Tier 1)","+10%",(0,10,"% faster empty rows")),
    (CAP,["Overclock","Token Sniffer","Plaintext","Deep Read","Survey","Cold Cache"],
        ["MODIFIER 'overclock': faster, more heat (existing)",
         "Passive: VM Parsing token chance x2",
         "MODIFIER 'plaintext': -50% speed, heat x1.5; each find 10% chance to come out already cracked (skips Cracking)",
         "MODIFIER 'deep-read': -40% speed; row find chance x2 (not Network finds), VM token chance x2, heat x2",
         "MODIFIER 'survey': half resources, +100% Parsing XP (same command name in every skill)",
         "Passive: Overclock, Plaintext and Deep Read produce no extra heat"],"one-off",None),
]
GROUPS["Cracking"] = [
    (TRACK,"Speed","Cracking cycle speed (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Cracking cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Cracking cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Instant-crack chance (on top of level efficiency); 20% at max","+1.67%",(0,20/12,"% bonus instant-crack")),
    (TRACK,"Efficiency","Instant-crack chance","+1.67%",(0,20/12,"% bonus instant-crack")),
    (TRACK,"Recovery","Chance the encrypted input is not consumed (capped stand-in for Yield on converting skills); 20% at max","+1.67%",(0,20/12,"% input kept")),
    (TRACK,"Recovery","Chance the encrypted input is not consumed","+1.67%",(0,20/12,"% input kept")),
    (PTD,"Dictionary","Each box has a chance to start already solved","+8%",(0,8,"% box pre-solved")),
    (PTD,"Rainbow Tables","An instant crack gives the next cycle a head start","+10%",(0,10,"% head start after instant crack")),
    (CAP,["Overclock","Keyring","Cross-Reference","Analyze","Survey","Cryo Rig"],
        ["MODIFIER 'overclock': faster, more heat (existing)",
         "Passive: VM Cracking token chance x2",
         "MODIFIER 'crossref': -50% speed, heat x1.5; each crack 10% chance to also produce the tier's matched item (skips Matching)",
         "MODIFIER 'analyze': -40% speed; instant-crack chance x2, VM token chance x2, heat x2",
         "MODIFIER 'survey': half output, +100% Cracking XP",
         "Passive: Overclock, Cross-Reference and Analyze produce no extra heat"],"one-off",None),
]
GROUPS["Matching"] = [
    (TRACK,"Speed","Matching cycle speed (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Matching cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Matching cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Chance to assemble multiples (on top of level efficiency); 20% at max","+1.67%",(0,20/12,"% bonus efficiency")),
    (TRACK,"Efficiency","Chance to assemble multiples","+1.67%",(0,20/12,"% bonus efficiency")),
    (TRACK,"Recovery","Chance the inputs are not consumed; 20% at max","+1.67%",(0,20/12,"% inputs kept")),
    (TRACK,"Recovery","Chance the inputs are not consumed","+1.67%",(0,20/12,"% inputs kept")),
    (PTD,"Auto-Correlate","Each match starts with a head start","+10%",(0,10,"% head start")),
    (PTD,"Hot Cache","+1% speed per consecutive match up to the cap (cap +5% per tier); resets when stopped","+5% cap",(0,5,"% max momentum speed")),
    (CAP,["Overclock","Rolodex","Prebuild","Correlate","Survey","Cold Storage"],
        ["MODIFIER 'overclock': faster, more heat (existing)",
         "Passive: VM Matching token chance x2",
         "MODIFIER 'prebuild': -50% speed, heat x1.5; each match 5% chance to also produce the tier's payload (skips Compiling)",
         "MODIFIER 'correlate': -40% speed; efficiency x2, VM token chance x2, heat x2",
         "MODIFIER 'survey': half output, +100% Matching XP",
         "Passive: Overclock, Prebuild and Correlate produce no extra heat"],"one-off",None),
]
GROUPS["Phishing"] = [
    (TRACK,"Speed","Phishing speed: casts, waits, reels, Smish sends/replies, Trap setup; not Trap's 45 min fill (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Phishing speed (not Trap fill)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Phishing speed (not Trap fill)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Each process's efficiency x(1 + bonus): bite, reply or Trap rare chance; +20% of its own efficiency at max (59% -> 71%)","+1.67% of eff",(0,20/12,"% of own efficiency")),
    (TRACK,"Efficiency","Process efficiency, relative (+20% of its own at max)","+1.67% of eff",(0,20/12,"% of own efficiency")),
    (TRACK,"Lines","Max lines (Spear/Mod: one more parallel cast; Whaling: faster reel; Smish: +8 texts per blast)","+1",(0,1,"extra lines")),
    (TRACK,"Bait Power","Bait bite-chance bonus (Logs x1.10 -> x1.15 ...)","+5%",(0,5,"% bait bonus")),
    (PTD,"Bait Recycling","Chance a cast's 10 bait are not used up","+5%",(0,5,"% bait kept")),
    (PTD,"Quick Hook","Faster reel-in after a bite (Spear/Mod download, Whaling reel, Smish reply window)","-5% reel time",(0,5,"% faster reel")),
    (CAP,["Overclock","Tackle Box","Lure","Chum","Survey","Deep Water"],
        ["MODIFIER 'overclock': faster, more heat (existing)",
         "Passive: VM Phishing token chance x2",
         "MODIFIER 'lure': -50% speed, heat x1.5; each catch 3% chance to also hook a hacking mod item (not Trap)",
         "MODIFIER 'chum': -40% speed; every catch doubled, VM token chance x2, heat x2 (not Trap)",
         "MODIFIER 'survey': half catches, +100% Phishing XP",
         "Passive: Overclock, Lure and Chum produce no extra heat"],"one-off",None),
]
GROUPS["Decoding"] = [
    (TRACK,"Speed","Decode cycle speed (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Decode cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Decode cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Each process's efficiency x(1 + bonus): Cache / Deep Scan rare chance, Skim +50% basics, Package double, Intel finds, Salvage doubles; +20% of its own at max (Cache rare 7.9% -> 9.5% at L99)","+1.67% of eff",(0,20/12,"% of own efficiency")),
    (TRACK,"Efficiency","Process efficiency, relative (+20% of its own at max)","+1.67% of eff",(0,20/12,"% of own efficiency")),
    (TRACK,"Yield","Basic resources per decoded cache","+10%",(0,10,"% more basics")),
    (PTD,"Rare Tracker","Each cache without a rare adds rare chance to the next (resets on a rare drop); bad-luck protection","+0.25% per miss",(0,0.25,"% added per dry cache")),
    (PTD,"Compression","More basic resources per decoded cache (stacks with Yield)","+10%",(0,10,"% more basics")),
    (PTD,"Field Notes","Intel lasts more hacks: +1 max intel hack, and a first find starts with +1 hack","+1 hack",(0,1,"extra intel hacks")),
    (CAP,["Overclock","Token Vault","Index","Forensics","Survey","Clean Room"],
        ["MODIFIER 'overclock': faster, more heat (existing)",
         "Passive: VM Decoding token chance x2",
         "MODIFIER 'index': -50% speed, heat x1.5; each decoded cache adds 1 intel point on the target it came from",
         "MODIFIER 'forensics': -40% speed; one-time item find chance x2, VM token chance x2, heat x2",
         "MODIFIER 'survey': half loot, +100% Decoding XP",
         "Passive: Overclock, Index and Forensics produce no extra heat"],"one-off",None),
]
GROUPS["Compiling"] = [
    (TRACK,"Speed","Compile cycle speed (each install ~14.5% faster than before it)",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Compile cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Speed","Compile cycle speed",[f"+{v*100:.1f}%" for v in SPEED_STEP],(1.0,SPEED_STEP,"x speed")),
    (TRACK,"Efficiency","Burst chance x(1 + bonus) (burst: 100x speed for 1 second, no heat); +20% of its own at max (10.8% -> 13% at L99)","+1.67% of eff",(0,20/12,"% of own efficiency")),
    (TRACK,"Efficiency","Burst chance, relative (+20% of its own at max)","+1.67% of eff",(0,20/12,"% of own efficiency")),
    (TRACK,"Recovery","Chance a fill's inputs are not consumed (payloads and mod hacks); 20% at max","+1.67%",(0,20/12,"% inputs kept")),
    (TRACK,"Recovery","Chance the inputs are not consumed","+1.67%",(0,20/12,"% inputs kept")),
    (PTD,"Linker","Chance to build two payloads at once","+2.5%",(0,2.5,"% double payload")),
    (PTD,"Mod Tuning","Hacking mods built with Mod are stronger","+5%",(0,5,"% stronger compiled mods")),
    (CAP,["Overclock","Build Cache","Debug Build","Optimize","Survey","Cold Build"],
        ["MODIFIER 'overclock': faster, more heat (not on Access)",
         "Passive: VM Compiling token chance x2",
         "MODIFIER 'debug': -50% speed, heat x1.5; Mod can build the mod up to +50% more hacks (Mod only)",
         "MODIFIER 'optimize': -40% speed; burst chance x2, VM token chance x2, heat x2",
         "MODIFIER 'survey': half output, +100% Compiling XP",
         "Passive: Overclock, Debug Build and Optimize produce no extra heat"],"one-off",None),
]
GROUPS["Hacking"] = [
    # Combat pass (2026-10-20): grow with the tier like enemies and mods do, so mods stay ~+40% at every tier
    (TRACK,"SQL Damage","Integrity damage per SQL attack; each level also adds attack heat (balances System cooling)",[f"+{v} dmg, +0.1 heat" for v in DAMAGE_STEP],(20,DAMAGE_STEP,"dmg")),
    (TRACK,"Firewall Damage","Firewall damage per SQL attack",[f"+{v}" for v in FIREWALL_STEP],(1,FIREWALL_STEP,"firewall dmg")),
    (TRACK,"Bandwidth Recovery","Bandwidth regenerated per second","+0.5/s",(1,0.5,"/s bandwidth regen")),
    (TRACK,"Bandwidth Recovery","Bandwidth regenerated per second","+0.5/s",(1,0.5,"/s bandwidth regen")),
    (TRACK,"Max Bandwidth","Max bandwidth (room for mod bandwidth costs)","+5",(10,5,"max bandwidth")),
    (TRACK,"Packet Spoof Healing","Packet Spoof restores a % of max anonymity (base 5% = today's 5 of 100); Restore mods add % points (+5 = +5%)","+1% of max anon",(5,1,"% of max anonymity per spoof")),
    (PTD,"Mod Slot","+1 hacking mod slot","+1 slot",(1,1,"mod slots")),
    (PTD,"Spoof Threshold","Packet Spoof starts auto-healing at a higher anonymity %","+10%",(30,10,"% auto-spoof threshold")),
    (PTD,"Persistent Session","More EXPLOIT charge from every combat event","+10% charge gain",(0,10,"% charge gain")),
    (CAP,["Second Wind","Evasion","Recycler","Siphon","Dead Man's Switch","Exploit Kit"],
        ["Each win in a multi-hack run restores 25% of max anonymity (anonymity carries over between fights)",
         "10% chance to dodge a countermeasure completely",
         "50% chance an SQL Injector is not consumed",
         "Each SQL hit restores 0.5% of max anonymity",
         "Once per session, a hit that would trace you leaves you at 1 and restores 25% anonymity",
         "50% chance a one-time item is not consumed"],"one-off",None),
]

# capstone flavor per tier (used in notes), can be renamed freely
CAPSTONE_NOTES = {
 "Hacking": ["Second Wind: each win in a multi-hack run restores 25% of max anonymity",
             "Spoof Threshold: auto-spoof triggers at 40% then higher",
             "Overkill Carry: damage past 0 carries to the next target's firewall",
             "Multi-Thread: a 2nd SQL Injector fires at reduced rate",
             "Ghost Protocol: start each hack with 1 free Ghost effect",
             "Rootkit: one free firewall break per fight"],
}

# ---- build workbook ----
wb = openpyxl.Workbook()
F = "Arial"
hdr_fill = PatternFill("solid", fgColor="1F3A2E")
hdr_font = Font(name=F, bold=True, color="FFFFFF", size=10)
cap_fill = PatternFill("solid", fgColor="FFF2CC")   # capstone rows
ptd_fill = PatternFill("solid", fgColor="E6F0FF")   # pointed rows
grp_fills = {}
thin = Side(style="thin", color="D0D0D0")
border = Border(left=thin,right=thin,top=thin,bottom=thin)

ci = wb.active
ci.title = "Inputs"
ws = wb.create_sheet("All Upgrades", 0)
cols = ["Group","Tier","Location","Install #","Version at","Slot type","Upgrade","Effect","Per-install value","Total after install","Cost item","Amount","Capstone rare","Rares","Rate key","Notes","Package id","Game value","Before install"]
ws.append(cols)
for c in range(1,len(cols)+1):
    cell = ws.cell(1,c); cell.fill=hdr_fill; cell.font=hdr_font; cell.border=border
    cell.alignment=Alignment(vertical="center")

version = 0.0
# version advances per group independently; compute per group
counts = {}
for group, slots in GROUPS.items():
    gver = 0.0
    for tier in range(1,7):
        for i,slot in enumerate(slots, start=1):
            stype,name,effect,val = slot[:4]
            running = slot[4] if len(slot) > 4 else None
            if isinstance(val, list):
                val = val[tier-1]
            if isinstance(name, list):
                name, effect = name[tier-1], effect[tier-1]
                name = ("MAJOR: " + name) if stype == CAP else name
            gver = round(gver + 0.1, 1)
            total = ""
            if running:
                key = (group, slot[1] if not isinstance(slot[1], list) else i)
                counts[key] = counts.get(key, 0) + 1
                start, step, unit = running
                if isinstance(step, list):
                    # steps differ by tier: sum the steps of every install so far
                    done = counts[key]; per = sum(1 for sl in slots if sl[1] == slot[1])
                    v = start + sum(step[(n // per)] for n in range(done))
                else:
                    v = start + step * counts[key]
                v = int(v) if float(v).is_integer() else round(v, 2)
                if unit.startswith("= double"):
                    total = f"double every {v}th cycle"; v = None
                if v is not None: total = f"{v} {unit}"
            rkey, item_fn = CURRENCY[group]
            base_name = slot[1] if not isinstance(slot[1], list) else ""
            if (group, base_name) in TOKEN_SLOTS:
                rkey, cost_item = "tokens", "VM tokens (any skill)"
            else:
                cost_item = item_fn(tier)
            rare = ""
            if stype == CAP:
                gi = GROUP_ORDER.index(group) % 5
                rare = TIER_RARES[tier-1][gi]
            note=""
            if stype==CAP and isinstance(slot[1], list):
                note = ""
            elif stype==CAP and group in CAPSTONE_NOTES:
                note = CAPSTONE_NOTES[group][tier-1]
            elif stype==CAP:
                note = "capstone x.0 release — define the tier's standout effect"
            r_next = ws.max_row + 1
            cs = COST_SCALE[tier-1]
            if rkey == "tokens":
                amt = f"=MAX(1,ROUND({cs}*Inputs!$B$9*Inputs!$B$10^(B{r_next}-1),0))"
            elif rkey == "hacking":  # paid in the tier's target caches (slots 1-2 target 1 ... 9-10 target 5); ~20% of the tier's hacks
                cost_item = TARGET_CACHES[tier-1][min(4, (i-1)//2)]
                amt = f"=MAX(1,ROUND({HACK_CACHE_TOTAL[tier-1]}*Inputs!$B$6^(D{r_next}-1)/Inputs!$B$12,0))"
            else:
                rate = f"INDEX(Inputs!$C$15:$C$23,MATCH(\"{rkey}\",Inputs!$A$15:$A$23,0))"
                share = "/3" if rkey == "parsing" else ""
                amt = (f"=MAX(1,ROUND({cs*BASIC_TIER_MULT[tier-1]}*Inputs!$B$4*Inputs!$B$5^(B{r_next}-1)*{rate}{share}*Inputs!$B$7"
                       f"*Inputs!$B$6^(D{r_next}-1)/Inputs!$B$12,0))")
            rare_amt = CAP_RARES[tier-1] if rare else ""
            base_n = slot[1] if not isinstance(slot[1], list) else slot[1][tier-1]
            pid = package_id(group, base_n)
            gval = game_value(running, tier)
            if running:
                prev_key = (group, slot[1] if not isinstance(slot[1], list) else i)
                done = counts[prev_key] - 1
                st, sp, un = running
                if isinstance(sp, list):
                    per = sum(1 for sl in slots if sl[1] == slot[1])
                    pv = st + sum(sp[(n // per)] for n in range(done))
                else:
                    pv = st + sp * done
                pv = int(pv) if float(pv).is_integer() else round(pv, 2)
                before = f"double every {pv}th cycle" if un.startswith("= double") else f"{pv} {un}"
                if un.startswith("= double") and done == 0: before = "off"
            else:
                before = "not installed"
            row=[group,tier,TIER_NAMES[tier-1],i,f"v{gver:.1f}",stype,name,effect,val,total,cost_item,amt,rare,rare_amt,rkey,note,pid,gval,before]
            ws.append(row)
            r=ws.max_row
            for c in range(1,len(cols)+1):
                ws.cell(r,c).font=Font(name=F,size=10)
                ws.cell(r,c).border=border
                ws.cell(r,c).alignment=Alignment(vertical="center", wrap_text=(c in (8,11,16)))
            if stype==CAP:
                for c in range(1,len(cols)+1): ws.cell(r,c).fill=cap_fill
            elif stype==PTD:
                for c in range(1,len(cols)+1): ws.cell(r,c).fill=ptd_fill

widths=[11,5,10,8,9,9,22,40,16,24,30,10,26,7,10,36,26,10,24]
# ---- Cost Inputs (sheet 'CI') ----
ci["A1"]="Cost inputs — every Amount in 'All Upgrades' is calculated from this sheet (blue = edit me)"; ci["A1"].font=Font(name=F,bold=True,size=12)
inp=[(3,"",""),
 (4,"Hours of solo running per skill, per tier (Tier 1)",2),
 (5,"Tier time growth (each tier takes this much longer)",1.1),
 (6,"Cost growth per install within a tier",1.15),
 (7,"In-tier speed factor (avg speed while buying that tier's 3 speed installs)",1.25),
 (8,"Rare items per capstone",2),
 (9,"VM tokens for a token install (Tier 1)",10),
 (10,"VM token cost growth per tier",1.5),
 (12,"Weight sum of 10 installs (formula)","=(B6^10-1)/(B6-1)")]
for r,l,v in inp:
    if l: ci.cell(r,1,l).font=Font(name=F,size=10)
    if v!="":
        c=ci.cell(r,2,v); c.font=Font(name=F,size=10,color=("0000FF" if not str(v).startswith("=") else "000000"))
ci["B12"].number_format="0.00"
ci["A14"]="Rate key"; ci["B14"]="Currency"; ci["C14"]="Items per hour (Tier 1, level 10, no upgrades)"; ci["D14"]="Source"
for c in range(1,5):
    ci.cell(14,c).fill=hdr_fill; ci.cell(14,c).font=hdr_font
rates=[("mining","Tier mined item",570,"Measured: mine -logs, 8s cycles"),
 ("parsing","Tier address + encrypted + identifier (total)",930,"Measured: parse -footprint=logs"),
 ("cracking","Tier cracked item",375,"Measured: crack -password"),
 ("matching","Tier matched item",210,"Measured: match -cred"),
 ("phishing","SQL Injectors + Packet Spoofs",330,"Measured L10 spear: 217/h unbaited, 445/h baited (~6.5k Logs/h); ~330/h with bait limited to ~3k Logs/h"),
 ("decoding","Tier mined item from caches",4500,"Measured 120 caches/h x ~37.5 Logs per Student cache"),
 ("compiling","Tier payload",420,"Measured: compile -school"),
 ("hacking","Tier's first-target cache",82,"Student fights ~44s each incl. access (earlier fight logs)"),
 ("tokens","VM tokens",0,"Not time-priced: B9 x B10^(tier-1)")]
for i,(k,d,v,src) in enumerate(rates):
    r=15+i
    ci.cell(r,1,k); ci.cell(r,2,d); ci.cell(r,3,v).font=Font(name=F,size=10,color="0000FF"); ci.cell(r,4,src)
    for c in (1,2,4): ci.cell(r,c).font=Font(name=F,size=10)
ci["A25"]="How an Amount is priced: hours x tier growth^(tier-1) x items/hour x in-tier speed x install growth^(install-1) / weight sum."
ci["A26"]="So one skill's 10 installs in a tier cost exactly 'hours x tier growth^(tier-1)' of solo running at that tier's expected speed."
ci["A27"]="Rates assume each tier's process runs about as fast as Tier 1 did (1.5x slower base, 1.5x faster from the previous tier's speed installs)."
for r in (25,26,27): ci.cell(r,1).font=Font(name=F,size=10,italic=True)
ci.column_dimensions["A"].width=62; ci.column_dimensions["B"].width=40; ci.column_dimensions["C"].width=20; ci.column_dimensions["D"].width=58
for i,w in enumerate(widths,start=1):
    ws.column_dimensions[get_column_letter(i)].width=w
ws.freeze_panes="A2"
ws.auto_filter.ref=f"A1:{get_column_letter(len(cols))}{ws.max_row}"

# ---- Summary sheet ----
s = wb.create_sheet("Summary")
s.append(["IdleOS — Upgrade system plan (DRAFT for balancing)"])
s["A1"].font=Font(name=F,bold=True,size=13)
notes = [
 "",
 "MODEL",
 "  • 9 upgrade groups, 6 tiers each, exactly 10 installs per tier.",
 "  • Each install = +0.1 version. Finishing a tier lands on a clean x.0 (v1.0 ... v6.0). Start at v0.0.",
 "  • A tier's 10 installs unlock when that location unlocks (via the upload goal you already built).",
 "",
 "SLOT MIX PER TIER (10)",
 "  • ~6-7 Track rows: speed / efficiency / a group stat. Repeat each tier, values scale.",
 "  • ~2-3 Pointed rows (blue): change HOW the skill plays, not just a stat. Same concept each tier, scaling.",
 "  • 1 Capstone / MAJOR release (gold): the x.0 standout for that tier.",
 "",
 "COSTS (draft)",
 "  • Track rows cost that tier's basic resource; Pointed rows cost that tier's cache; Capstone adds a tier rare item.",
 "  • Amounts scale by tier (x1, x2.2, x4.5, x9, x18, x36) and by install index. Tune freely.",
 "",
 "HOW INSTALLS FEEL (planned, not in this sheet)",
 "  • apt-style install sequence + progress bar, before/after numbers (2.4s -> 2.1s), version banner.",
 "  • Each x.0 gets a MAJOR RELEASE banner + changelog of that tier's 10 installs.",
 "  • apt overview: a version bar per skill; locked tiers shown dim ('requires Lawfirm access').",
 "",
 "NOTE ON MATCHING",
 "  • Today Matching's hidden quantity bonus reads Upgrades.MATCHING.version (3+version*10). That's the only",
 "    place 'version' does anything mechanical. Under this plan that becomes the Efficiency/Yield tracks instead,",
 "    so version goes back to being pure flavor. No puzzle exists — that was my mistake in the earlier message.",
 "",
 "SYSTEM (decided)",
 "  • Cooling, Heat Reduction, VM Windows: 1 per tier. Background Services: 2 per tier, 2h each on top of a 1h base -> 24h offline cap at max (code caps at 24).",
 "  • Defrag: duration 10 -> 25 min, cooldown 40 -> 25 min (2.5 min steps) — they meet at max, so boosts never overlap.",
 "  • Capstones: Overheat Fan, Idle Cooling, Liquid Cooling, Load Balancer, Watchdog, Server Rack.",
 "",
 "HACKING (decided / proposed)",
 "  • Per tier: SQL Damage (+5 dmg, +0.1 heat), Firewall Dmg +2, BW Recovery x2 (+0.5/s), Max BW +5, Spoof Healing +1% of max anon (5% -> 11%),",
 "    Mod Slot +1 (1 -> 7), Spoof Threshold +10% (30% -> 90%), Persistent Session +10% charge gain, Capstone.",
 "  • At max: SQL attack heat 0.9 - 0.6 System heat reduction = 0.3 net, the same as an attack makes today.",
 "  • Capstones: Second Wind, Evasion, Recycler, Siphon, Dead Man's Switch, Exploit Kit (decided).",
 "  • Unused alternates: Multi-Thread, Chain Breach, Overkill Carry.",
 "  • Max anonymity is NOT an apt upgrade: hybrid (wired): 100 + 5 x (Hacking level - 1) + 100 x (locations unlocked - 1) — see 'Max Anonymity' tab.",
 "",
 "MINING (decided)",
 "  • Per tier: Speed x3, Efficiency x2 (+8.33%, +100% max), Heat Sink x2 (-2% Mining heat, -24% max), Vein Detection, Pipelining, Capstone.",
 "  • Mining level efficiency: lower from +8%/level (784% at 99) to +3.5%/level (343% at 99) -> 443% total at max",
 "    (~5.4 resources per cycle). Game value: 'efficiency rate' 0.08 -> 0.035 on every Mining process.",
 "  • Speed: the game adds speed bonuses (1 + total), so the % per install grows each tier to keep the pacing model:",
 "    3 installs = +50% per tier compounding -> x11.4 at max. Each install is ~14.5% faster than the one before.",
 "  • Capstones: Overclock (mod), Deep Core, Sift (mod, heat x1.5), Prospect (mod, heat x2), Survey (mod), Cool Bits",
 "    (Cool Bits removes the extra heat from Overclock, Sift and Prospect). Survey: half resources, +100% XP.",
 "",
 "VM TOKENS (rule for every skill)",
 "  • Roll VM tokens on time spent processing, not per cycle: chance per cycle = token rate x the cycle's real duration.",
 "    Otherwise speed upgrades (x11.4) multiply token income: Mining Logs at max would be x27 tokens/hour vs today.",
 "  • With time-based rolls, only the token capstones raise income: Deep Core / Token Sniffer x2, Prospect / Deep Read x2",
 "    = x4 at most, which matches demand at max (7 VM windows / 1.6x Scheduler uptime = ~x4.4 tokens needed).",
 "  • Fallback if x4 feels high in play: +50% per boost instead of x2 (x2.25 with both).",
 "",
 "MODIFIERS (proposed pattern for every skill)",
 "  • Capstone pattern (approved): T1 Overclock + 3 modifier-command capstones + 2 passive capstones, themed per skill.",
 "  • A modifier is a command like overclock: '<name>' while the process runs, '<name> -kill' to stop.",
 "  • One modifier at a time per process (overclock counts). Each has a real trade-off, so it's a choice, not a buff.",
 "  • They fill the MODIFIERS box in 'info <skill>'; locked rows show 'unlocks at <Skill> vN.0'.",
 "  • Installs within a tier can be bought in any order; the 10th install of a tier is the x.0 MAJOR RELEASE banner.",
 "",
 "PARSING (decided / proposed)",
 "  • Per tier: Speed x3, Efficiency x2 (+1.67%, 20% max), Rows x2 (+1), Pattern Cache (+1% per miss), Fast Skip (+10%), Capstone.",
 "  • Fast Skip replaces Target Lock (Extraction unlocks too late for a Tier 1 upgrade).",
 "  • Capstones: Overclock, Token Sniffer (VM token x2), Plaintext (mod), Deep Read (mod), Survey (mod), Cold Cache.",
 "  • 'survey' = the same XP-for-resources command name in every skill.",
 "",
 "CRACKING (decided)",
 "  • Per tier: Speed x3, Efficiency x2 (+1.67%, 20% max), Recovery x2 (+1.67% input kept, 20% max), Dictionary (+8% box pre-solved),",
 "    Rainbow Tables (+10% head start after an instant crack), Capstone.",
 "  • Recovery replaces Yield on converting skills (Cracking, Matching, Compiling): +1 yield/install = 13 out per 1 in",
 "    at max, which would make the upstream skills irrelevant. 20% keep chance = 1.25 out per 1 in at max.",
 "  • Capstones: Overclock, Keyring (token x2), Cross-Reference (mod), Analyze (mod), Survey (mod), Cryo Rig.",
 "",
 "MATCHING (decided)",
 "  • Per tier: Speed x3, Efficiency x2 (20% max), Recovery x2 (20% max), Auto-Correlate (+10% head start), Hot Cache (+1% per match, cap 30%), Capstone.",
 "  • Removes the hidden version-based quantity bonus (3 + version x 10); these tracks replace it.",
 "  • Capstones: Overclock, Rolodex (token x2), Prebuild (mod), Correlate (mod), Survey (mod), Cold Storage.",
 "",
 "PHISHING (decided)",
 "  • Phishing level efficiency (bite chance): +0.5%/level -> +0.3%/level (L99 base ~59%), so bait and Bait Power",
 "    still matter late. Game value: 'efficiency rate' 0.005 -> 0.003 on Phishing processes.",
 "  • Per tier: Speed x3, Efficiency x2 (bite chance, 20% max), Lines x1 (+6 max), Bait Power (+5%), Bait Recycling (+5%),",
 "    Quick Hook (-5% reel), Capstone. Lines are one per tier because each line is a whole parallel cast.",
 "  • Efficiency is relative (+20% of each process's own efficiency at max) so Smish (3-8% reply) and Trap",
 "    (15-25% rare) scale with it too. Speed covers every Phishing step except Trap's fixed 45 min fill.",
 "  • Processes: Spear (T1), Whaling (T2), Smish (T3), Trap (T4), Mod (utility). Upgrade tiers are location tiers.",
 "  • Capstones: Overclock, Tackle Box (token x2), Lure (mod), Chum (mod), Survey (mod), Deep Water.",
 "",
 "DECODING (decided)",
 "  • Per tier: Speed x3, Efficiency x2 (rare chance, +4% max), Yield (+10% basics), Rare Tracker (+0.25% per dry cache),",
 "    Compression (+10% basics per cache), Field Notes (+1 intel hack), Capstone.",
 "  • Capstones: Overclock, Token Vault (token x2), Index (mod), Forensics (mod), Survey (mod), Clean Room.",
 "",
 "COMPILING (decided)",
 "  • Per tier: Speed x3, Efficiency x2 (burst chance, 20% max), Recovery x2 (20% max), Linker (+2.5% double payload),",
 "    Mod Tuning (+5% stronger compiled mods), Capstone.",
 "  • Capstones: Overclock, Build Cache (token x2), Debug Build (mod), Optimize (mod), Survey (mod), Cold Build.",
 "",
 "COSTS (formula-driven — edit the blue inputs on the Inputs sheet)",
 "  • Each skill pays in its own output for the tier; Hacking pays in the tier's caches; System pays in mined items,",
 "    except VM Windows and Scheduler, which cost VM tokens. Capstones also cost 2 of one of the tier's rare items,",
 "    spread so each rare type is used by 1-2 groups (see 'Rare Demand').",
 "  • One skill's 10 installs in a tier = 2h of solo running at Tier 1, x1.1 per tier (~3.2h solo at Tier 6);",
 "    roughly 1-2h for a player keeping a VM on that skill. 'Tier Totals' checks every group/tier against the target.",
 "  • Rare chance: Decoding base 10% -> 4% at L1 and +0.04%/level (~8% at L99); Efficiency is relative (+20% of its own at max, ~9.5%); Rare Tracker adds up to +1.5% per dry cache of that type.",
 "    Game values: CACHE 'efficiency' 0.1 -> 0.04, 'efficiency rate' 0.001 -> 0.0004.",
 "",
 "BAIT LOOP (decided) — fixes the cache basics flood and the SQL Injector gap together",
 "  • Loop: Hack -> caches -> Decode -> basics -> bait -> Phish -> SQL Injectors -> Hack.",
 "  • Bait: each cast uses 10 of the item (was 1) and doubles the catch, on top of the bite-chance boost.",
 "  • Check (Tier 1, measured rates): ~3,300 Logs/h used as bait vs ~3,000/h from hacking + decoding;",
 "    ~600 SQL Injectors/h with bait vs ~570/h used by nonstop Student hacking.",
 "  • Logs from caches now have a competing use, so they're no longer free currency for Mining/Parsing upgrades.",
 "  • Re-measured with bait (L10 Spear): 217/h unbaited, 445/h baited, but bait burns ~6.5k Logs/h vs ~3k/h coming in,",
 "    so bait is on ~46% of the time: ~320/h blended. The Inputs rate stays 330/h.",
 "",
 "OPEN FOR YOU TO CUT/ADD",
 "  • Rename any Pointed/Capstone. Change the 10-slot mix per group. Retune every value and cost in 'All Upgrades'.",
 "  • Capstones for groups other than Hacking are placeholders ('MAJOR: ...') — name them when you like the mix.",
]
for n in notes:
    s.append([n]); 
    cell=s.cell(s.max_row,1); cell.font=Font(name=F,size=10,bold=n.isupper() and n.strip()!="" and not n.startswith(" "))
s.column_dimensions["A"].width=110

# max anonymity options (formulas so you can tune the inputs)
ma = wb.create_sheet("Max Anonymity")
ma["A1"] = "Max anonymity options (edit the blue inputs)"; ma["A1"].font=Font(name=F,bold=True,size=12)
ma["A3"]="Base anonymity"; ma["B3"]=100
ma["A4"]="Per Hacking level"; ma["B4"]=5
ma["A5"]="Per tier unlocked (hybrid only)"; ma["B5"]=100
for r in (3,4,5): ma.cell(r,2).font=Font(name=F,color="0000FF")
hdr=["Tier","Typical Hacking level at tier entry","First target counter dmg","Toughest target counter dmg",
     "Level only: max anon","Hits to trace (first target)","Hybrid: max anon","Hits to trace (first target)"]
for c,h in enumerate(hdr, start=1):
    cell=ma.cell(7,c,h); cell.fill=hdr_fill; cell.font=hdr_font; cell.alignment=Alignment(wrap_text=True,vertical="center")
data=[(1,1,5,12),(2,15,10,24),(3,30,18,42),(4,45,28,66),(5,60,40,96),(6,75,60,144),("max",99,60,144)]
for i,(t,lvl,c1,c2) in enumerate(data):
    r=8+i
    ma.cell(r,1,t); ma.cell(r,2,lvl); ma.cell(r,3,c1); ma.cell(r,4,c2)
    ma.cell(r,5,f"=$B$3+$B$4*(B{r}-1)")
    ma.cell(r,6,f"=E{r}/C{r}")
    tiers = 6 if t=="max" else t
    ma.cell(r,7,f"=$B$3+$B$4*(B{r}-1)+$B$5*({tiers}-1)")
    ma.cell(r,8,f"=G{r}/C{r}")
    for c in (6,8): ma.cell(r,c).number_format="0.0"
    for c in range(1,9): ma.cell(r,c).font=Font(name=F,size=10)
ma["A20"]="Packet Spoof healing (% of max anonymity)"; ma["A20"].font=Font(name=F,bold=True,size=11)
ma["A21"]="Base heal %"; ma["B21"]=0.05
ma["A22"]="Heal % per tier upgrade"; ma["B22"]=0.01
ma["A23"]="Spoof every (s)"; ma["B23"]=12.5
ma["A24"]="Counter every (s), first target"; ma["B24"]=6.25
for r in (21,22,23,24): ma.cell(r,2).font=Font(name=F,color="0000FF")
ma["B21"].number_format="0%"; ma["B22"].number_format="0%"
hdr2=["Tier","Heal % (with that tier's upgrade)","Heal per spoof (hybrid anon)","First target counter dmg","Heal/s","Incoming dmg/s","Sustain ratio (heal / incoming)"]
for c,h in enumerate(hdr2, start=1):
    cell=ma.cell(26,c,h); cell.fill=hdr_fill; cell.font=hdr_font; cell.alignment=Alignment(wrap_text=True,vertical="center")
ma.row_dimensions[26].height=45
for i in range(6):
    r=27+i; src=8+i
    ma.cell(r,1,i+1)
    ma.cell(r,2,f"=$B$21+$B$22*{i+1}"); ma.cell(r,2).number_format="0%"
    ma.cell(r,3,f"=ROUND(G{src}*B{r},0)")
    ma.cell(r,4,f"=C{src}")
    ma.cell(r,5,f"=C{r}/$B$23"); ma.cell(r,5).number_format="0.0"
    ma.cell(r,6,f"=D{r}/$B$24"); ma.cell(r,6).number_format="0.0"
    ma.cell(r,7,f"=E{r}/F{r}"); ma.cell(r,7).number_format="0.00"
    for c in range(1,8): ma.cell(r,c).font=Font(name=F,size=10)
ma["A34"]="Sustain ratio 1.0 = spoofs out-heal the tier's weakest target exactly. Today (Tier 1, flat 5): 0.5. Toughest targets hit ~2.4x harder."
ma["A35"]="Hacking mods (Restore) and Booster Shot stay as they are: mods add flat restore, Booster Shot doubles the whole heal."
for r in (34,35): ma.cell(r,1).font=Font(name=F,size=10,italic=True)
ma["A16"]="Hits to trace = max anonymity / the tier's first easy target's counter damage (no damage reduction, no spoofs)."
ma["A17"]="Tier 1 today: 100 / 5 = 20 hits. Hybrid keeps later tiers close to that feel; level-only lets them get steadily deadlier."
ma["A18"]="Packet Spoof healing is now % of max anonymity (table below), so it follows this curve."
for r in (16,17,18): ma.cell(r,1).font=Font(name=F,size=10,italic=True)
ma.column_dimensions["A"].width=30
for col in "BCDEFGH": ma.column_dimensions[col].width=16
ma.row_dimensions[7].height=45

# ---- Tier Totals: verifies the time target ----
tt = wb.create_sheet("Tier Totals")
tt.append(["Group","Tier","Currency (sum of 10 installs)","Hours of solo running it represents","Rares"])
for c in range(1,6):
    tt.cell(1,c).fill=hdr_fill; tt.cell(1,c).font=hdr_font
last = ws.max_row
for group in GROUPS:
    for tier in range(1,7):
        r = tt.max_row + 1
        rkey = CURRENCY[group][0]
        tt.append([group, tier,
            f'=SUMIFS(\'All Upgrades\'!$L$2:$L${last},\'All Upgrades\'!$A$2:$A${last},A{r},\'All Upgrades\'!$B$2:$B${last},B{r},\'All Upgrades\'!$O$2:$O${last},"<>tokens")',
            f'=C{r}{"*3" if rkey=="parsing" else ""}/INDEX(Inputs!$C$15:$C$23,MATCH("{rkey}",Inputs!$A$15:$A$23,0))/Inputs!$B$7',
            f'=SUMIFS(\'All Upgrades\'!$N$2:$N${last},\'All Upgrades\'!$A$2:$A${last},A{r},\'All Upgrades\'!$B$2:$B${last},B{r})'])
        tt.cell(r,4).number_format="0.00"
        for c in range(1,6): tt.cell(r,c).font=Font(name=F,size=10)
tt["G1"]="Hours = currency / (items per hour x in-tier speed). Should equal Inputs!B4 x Inputs!B5^(tier-1)."; tt["G1"].font=Font(name=F,italic=True,size=10)
for col,w in zip("ABCDE",[12,6,26,30,8]): tt.column_dimensions[col].width=w

# ---- Rare demand per tier ----
rd = wb.create_sheet("Rare Demand")
rd.append(["Tier","Rare item","Used by capstone of","Capstone need","Upload goal","Total needed","Caches per rare at 4% (L1)","At 8% (L99)","At 12% (max)"])
for c in range(1,10):
    rd.cell(1,c).fill=hdr_fill; rd.cell(1,c).font=hdr_font
for t in range(1,7):
    for ri,rname in enumerate(TIER_RARES[t-1]):
        users=[g for g in GROUP_ORDER if GROUP_ORDER.index(g)%5==ri]
        r=rd.max_row+1
        rd.append([t,rname,", ".join(users),f"={len(users)}*Inputs!$B$8",10,f"=D{r}+E{r}",f"=F{r}/0.04",f"=F{r}/0.08",f"=F{r}/0.12"])
        for c in (7,8,9): rd.cell(r,c).number_format="0"
        for c in range(1,10): rd.cell(r,c).font=Font(name=F,size=10)
rd["K1"]="Caches columns = caches you'd decode to collect that rare's total need at each rare chance."; rd["K1"].font=Font(name=F,italic=True,size=10)
for col,w in zip("ABCDEFGHI",[6,34,22,13,11,12,22,12,13]): rd.column_dimensions[col].width=w

# counts sheet
c2 = wb.create_sheet("Counts")
c2.append(["Group","Installs/tier","Tiers","Total installs","Final version"])
for cc in range(1,6):
    c2.cell(1,cc).fill=hdr_fill; c2.cell(1,cc).font=hdr_font
for group in GROUPS:
    c2.append([group,10,6,60,"v6.0"])
c2.append(["TOTAL",90,"",540,""])
for col,w in zip("ABCDE",[12,13,7,14,13]): c2.column_dimensions[col].width=w
for cc in range(1,6):
    c2.cell(c2.max_row,cc).font=Font(name=F,bold=True)

import os, sys
wb.save(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "idleos_upgrades.xlsx"))
print("rows:", ws.max_row-1)
