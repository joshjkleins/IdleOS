"""First-session timeline: a new player following the tutorial, then the post-tutorial loop.
Reading: words / WPM for each tutorial step + extra time to read big command outputs; typing: per command.
Process times: Offline job models at level 1, no upgrades (tools/tests/rates1.gd, 2026-10-23):
  mine logs 8.0s/log · parse footprint 4.0s/log (0.47 usernames, 0.45 enc pw, 0.42 IP per log) · crack 11.3s/pw
  match 12.1s/cred · spear 13.1s/cast (2.0 SQL, 0.23 spoofs) · compile 9.1s/payload · decode 20s/cache
  student fight ~50s (combat_sim, 9 SQL) + ~8s load/prepare · VM token = 30s of a second process.
Usage: first_hour.py [wpm]   (default: 3 readers, 160 / 230 / 350 wpm)"""
import re, sys

TXT = open("singletons/Tutorial.gd", encoding="utf-8").read()
TASKS = dict(re.findall(r"TutorialEvent\.(\w+): \"(.*?)\",\n", TXT[TXT.index("var tutorial_tasks"):]))
def words(ev): return len(re.sub(r"\[[^\]]*\]", "", TASKS.get(ev, "")).split())

MINE, PARSE, CRACK, MATCH, SPEAR, COMPILE, DECODE = 8.0, 4.0, 11.33, 12.12, 13.1, 9.1, 20.0
P_USER, P_ENC, P_IP = 0.473, 0.447, 0.42
VM = 30.0
TYPE = 6.0     # seconds to type a command (incl. a typo / Tab now and then)
# extra reading for big outputs (s): the help list, info tables, inventory, the upload goal, apt
OUT = {"RUN_HELP_COMMAND": 25, "INFO_COMMAND": 15, "INFO_MINING_COMMAND": 15, "LIST_ITEMS": 6, "LIST_LOG_DETAILS": 10,
       "UPLOAD_INFO": 12, "NAVIGATE_MINING": 8, "NAVIGATE_PARSING": 8, "UNLOCK_MINING_OVERCLOCK_WITH_APT": 25,
       "NAVIGATE_HACKING": 20, "HACK_STUDENT": 15, "DECODE_1_STUDENT_CACHE": 8}
INTRO = 45.0   # boot + install screen + welcome message (~10s of animation, the rest reading)

def run(wpm):
    t = INTRO; log = [("intro + welcome", t, 0)]
    def read(ev): return words(ev) / wpm * 60.0 + OUT.get(ev, 0)
    def step(ev, extra=0.0, label=None):
        nonlocal t
        d = read(ev) + TYPE + extra
        t += d; log.append((label or ev, t, d))
    # mining starts at step 3; the next steps are read while it runs
    step("RUN_HELP_COMMAND"); step("NAVIGATE_MINING"); step("RUN_MINING_LOG")
    mine_start = t
    for ev in ["INFO_COMMAND", "INFO_MINING_COMMAND", "USE_FOCUS", "USE_STICKY", "LIST_ITEMS", "LIST_LOG_DETAILS"]:
        step(ev)
    step("RUN_VM_WITH_SSH"); vm_start = t
    # 35 logs: main terminal + one VM token (30s) + level-up tokens (~2 by 35 logs, say they use 1 more)
    need = 35
    def logs_at(x): return max(0, x - mine_start) / MINE + min(max(0, x - vm_start), 2 * VM) / MINE
    wait_from = t
    while logs_at(t) < need: t += 1
    log.append(("  ...waiting: mine 35 logs", t, t - wait_from))
    step("MINE_20_LOGS", label="read mine-35 text (during the wait)", extra=-TYPE) if False else None
    for ev in ["USE_UNSTICKY", "STOP_MINING_PROCESS", "UPLOAD_INFO", "PACKAGE_5_LOGS", "NAVIGATE_PARSING"]:
        step(ev)
    step("PARSE_20_LOGS")  # starts parsing + reads; VM token for parsing
    p_start = t - TYPE
    # 30 logs on main + VM (30s = 7.5 logs): 6 enc / 5 user / 5 IP come with it
    w = t
    while (t - p_start) / PARSE + min(max(0, t - p_start - 20), VM) / PARSE < 30: t += 1
    log.append(("  ...waiting: parse 30 logs", t, t - w))
    for ev in ["OBTAIN_3_ENCRYPTED_PASSWORDS", "OBTAIN_3_USERNAMES", "OBTAIN_3_IP_ADDRESSES", "UPLOAD_IP_ADDRESS"]:
        step(ev, extra=-TYPE + 2 if ev.startswith("OBTAIN") else 0)  # already done: just read and click on
    def proc(ev, n, per, vm=True, label=None):
        nonlocal t
        step(ev); s = t - TYPE; w = t
        while (t - s) / per + (min(max(0, t - s - 15), VM) / per if vm else 0) < n: t += 1
        log.append(("  ...waiting: " + (label or ev), t, t - w))
    proc("CRACK_3_PASSWORDS", 6, CRACK, label="crack 6 passwords")
    step("UPLOAD_PASSWORD")
    proc("MATCH_3_CREDENTIALS", 5, MATCH, label="match 5 credentials")
    step("UPLOAD_CREDENTIAL"); step("TRACK_SQL")
    proc("PHISH_15_SQL_INJECTORS", 5, SPEAR, label="phish 10 SQL (5 casts)")
    step("PHISH_1_PACKET_SPOOFS", extra=SPEAR * 1.5)  # usually a spoof came already; sometimes a cast or two more
    step("UNTRACK_ITEMS")
    proc("COMPILE_3_SCHOOL_PAYLOADS", 4, COMPILE, label="compile 4 payloads")
    step("UPLOAD_SCHOOL_PAYLOAD"); step("NAVIGATE_HACKING")
    step("HACK_STUDENT", extra=58, label="HACK_STUDENT (first fight ~50s + load)")
    first_hack = t
    step("DECODE_1_STUDENT_CACHE", extra=DECODE + 8)
    step("UPLOAD_PARENTS_CC")  # assumes the cache had one (24%); otherwise a few more hacks
    step("UNLOCK_MINING_OVERCLOCK_WITH_APT", extra=0)
    return log, first_hack

readers = [int(sys.argv[1])] if len(sys.argv) > 1 else [160, 230, 350]
for wpm in readers:
    log, fh = run(wpm)
    print("\n=== reader %d wpm ===   tutorial done %s   first hack %s" % (wpm, f"{log[-1][1]/60:.1f} min", f"{fh/60:.1f} min"))
    waits = 0
    for name, at, d in log:
        mark = "  <-- 10 min" if at >= 600 and at - d < 600 else ""
        print("  %5.1f min  %+5.0fs  %s%s" % (at / 60, d, name, mark))
        if name.strip().startswith("...waiting"): waits += d
    print("  waiting with nothing to read: %.1f min of %.1f" % (waits / 60, log[-1][1] / 60))
