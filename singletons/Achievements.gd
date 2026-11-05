extends Node
## 2026-11-03 (Josh): Steam achievements. Conditions are checked every couple of seconds while a profile is loaded (and
## right after it loads, so a save that already qualifies unlocks them), plus a few one-off events (event(id)).
## Unlocks are kept in user://achievements.cfg (account-wide like Steam's, not per save slot) and pushed to Steam
## (SteamManager); unlocks made while Steam was unavailable are pushed the next time it is. HACKERMAN unlocks once
## every other one is unlocked. 'achievements' lists them; DEV adds 'achievements reset' / 'achievement unlock <id>'.

const DEV := false # TESTING: 'achievements reset' and 'achievement unlock <id>'. Turn off before release.
const PATH := "user://achievements.cfg"
const STAT_HACKS := "HACKS_WON" # Steam stat (int) that HACKS_100 is linked to in Steamworks
const CHECK_SECONDS := 2.0

## [API name, display name, description, hidden]
const DEFS := [
	["FIRST_BREACH", "First Breach", "Win your first hack.", false],
	["TIER_1", "School's Out", "Complete the School upload goal.", false],
	["TIER_2", "Objection", "Complete the Lawfirm upload goal.", false],
	["TIER_3", "Code Blue", "Complete the Hospital upload goal.", false],
	["TIER_4", "Insider Trading", "Complete the Bank upload goal.", false],
	["TIER_5", "Off the Record", "Complete the Police Station upload goal.", false],
	["TIER_6", "Classified", "Complete the Government upload goal.", false],
	["COMPROMISE_1", "Expelled", "Fully compromise the School: own all of its drivers.", false],
	["COMPROMISE_2", "Disbarred", "Fully compromise the Lawfirm: own all of its drivers.", false],
	["COMPROMISE_3", "Malpractice", "Fully compromise the Hospital: own all of its drivers.", false],
	["COMPROMISE_4", "Bank Run", "Fully compromise the Bank: own all of its drivers.", false],
	["COMPROMISE_5", "Internal Affairs", "Fully compromise the Police Station: own all of its drivers.", false],
	["COMPROMISE_6", "Regime Change", "Fully compromise the Government: own every Firmware.", false],
	["WHITE_HAT", "White Hat", "Lock the launch codes away.", true],
	["BLACK_HAT", "Black Hat", "Steal the launch codes.", true],
	["SKILL_50", "Halfway There", "Get any skill to level 50.", false],
	["SKILL_99", "Maxed Out", "Get any skill to level 99.", false],
	["ALL_99", "Full Stack", "Get every skill to level 99.", false],
	["FIRMWARE_1", "Flashed", "Install your first Firmware.", false],
	["FIRMWARE_ALL", "Bare Metal", "Install every Firmware.", false],
	["HACKS_100", "Script Kiddie No More", "Win 100 hacks.", false],
	["FIRST_EXPLOIT", "Zero Day", "Use an Exploit during a hack.", false],
	["FULL_MODS", "Fully Modded", "Fill every hacking mod slot.", false],
	["DRIVER_R3", "Driver Update", "Get a driver to rank 3.", false],
	["FIRST_VM", "Virtualized", "Run a process in a virtual machine.", false],
	["QUEUE_6", "Job Scheduler", "Queue 6 steps.", false],
	["OFFLINE_24", "Away From Keyboard", "Come back from a full 24 hour offline session.", false],
	["ALERT_CLEARED", "Lay Low", "Clear a target's alert after it reached 100%.", false],
	["OVERHEAT", "Thermal Throttling", "Overheat your system.", false],
	["SUDO_RM", "sudo rm -rf", "Try to delete everything.", true],
	["STUDENT_100", "Detention", "Hack the Student 100 times.", false],
	["FULLY_AUTOMATED", "Fully Automated", "Run Mining, Parsing, Cracking, Matching and Compiling at the same time.", false],
	["HACKERMAN", "Hackerman", "Unlock every other achievement.", false],
]

var unlocked := {} # API name -> unix time
var _accum := 0.0
var _hacks_sent := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	Signals.system_overheated_signal.connect(func(): event("OVERHEAT"))
	SaveManager.save_loaded.connect(func(): check_all.call_deferred())
	_sync_to_steam.call_deferred()

func ids() -> Array:
	return DEFS.map(func(d): return d[0])

func def(id: String) -> Array:
	for d in DEFS:
		if d[0] == id:
			return d
	return []

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

#region unlocking
## one-off events from the game (an Exploit used, 'sudo rm -rf', a 24 h offline return, a 100% alert cleared ...)
func event(id: String) -> void:
	unlock(id)

func unlock(id: String) -> void:
	if unlocked.has(id) or def(id).is_empty():
		return
	unlocked[id] = int(Time.get_unix_time_from_system())
	_save()
	SteamManager.unlock(id)
	var d = def(id)
	if SaveManager.session_active:
		Signals.system_message_signal.emit("[color=#ffc24a]ACHIEVEMENT UNLOCKED[/color]  %s  [color=#888888]%s[/color]" % [d[1], d[2]])
	if id != "HACKERMAN" and ids().all(func(i): return i == "HACKERMAN" or unlocked.has(i)):
		unlock("HACKERMAN")

## Steam may have been unavailable when some unlocked: push them now (setAchievement on an unlocked one is harmless)
func _sync_to_steam() -> void:
	if !SteamManager.available:
		return
	for id in unlocked:
		if !SteamManager.is_unlocked(id):
			SteamManager.unlock(id)
#endregion

#region conditions
func _process(delta: float) -> void:
	_accum += delta
	if _accum < CHECK_SECONDS:
		return
	_accum = 0.0
	if SaveManager.session_active:
		check_all()

const SKILLS := ["Mining", "Parsing", "Cracking", "Matching", "Phishing", "Decoding", "Compiling", "Hacking"]
const AUTOMATED := ["Mining", "Parsing", "Cracking", "Matching", "Compiling"]

func check_all() -> void:
	var wins = 0
	for k in Stats.wins:
		if !str(k).ends_with("/hard"):
			wins += int(Stats.wins[k])
	if wins >= 1: unlock("FIRST_BREACH")
	if wins >= 100: unlock("HACKS_100")
	if wins != _hacks_sent:
		_hacks_sent = wins
		SteamManager.set_stat(STAT_HACKS, wins)
	var keys = Stats.hacking_targets.keys()
	for t in range(1, 7):
		if t in Uploads.completed_tiers: unlock("TIER_%d" % t)
		if t <= keys.size() and Compromise.is_repeat(keys[t - 1]): unlock("COMPROMISE_%d" % t)
	if Ending.choice == "white": unlock("WHITE_HAT")
	if Ending.choice == "black": unlock("BLACK_HAT")
	var levels = SKILLS.map(func(s): return int(get_node("/root/" + s).SKILL.level))
	if levels.any(func(l): return l >= 50): unlock("SKILL_50")
	if levels.any(func(l): return l >= 99): unlock("SKILL_99")
	if levels.all(func(l): return l >= 99): unlock("ALL_99")
	if Firmware.installed.size() >= 1: unlock("FIRMWARE_1")
	if Firmware.installed.size() >= Firmware.DEFS.size(): unlock("FIRMWARE_ALL")
	if HackingMods.current_mods.size() >= HackingMods.MAX_MOD_SLOTS: unlock("FULL_MODS")
	if Drivers.owned.keys().any(func(id): return Drivers.rank(id) >= 3): unlock("DRIVER_R3")
	if !VMManager.vms.is_empty(): unlock("FIRST_VM")
	if Queue.steps.size() >= 6: unlock("QUEUE_6")
	var student = Stats.hacking_targets.get("School", {}).get("targets", [{}])[0]
	if !student.is_empty() and Stats.get_wins(student) >= 100: unlock("STUDENT_100")
	var os = get_tree().get_first_node_in_group("main_os")
	if os:
		var running = HintEngine._running(os).map(func(s): return str(s.SKILL.name))
		if AUTOMATED.all(func(s): return s in running): unlock("FULLY_AUTOMATED")
#endregion

#region text
## 'achievements'
func list_text() -> String:
	var G = "#4ec994"; var D = "#888888"; var Y = "#ffc24a"
	var t = "\n[bgcolor=#2a2410][color=%s] ACHIEVEMENTS [/color][/bgcolor]  [color=%s]%d/%d unlocked%s[/color]\n" % [Y, D, unlocked.size(), DEFS.size(), "" if SteamManager.available else "  ·  Steam not connected (they sync once it is)"]
	for d in DEFS:
		var got = unlocked.has(d[0])
		if d[3] and !got:
			t += "  [color=%s]▯  ???[/color]  [color=#555f69]hidden[/color]\n" % D
			continue
		t += "  [color=%s]%s  %s[/color]  [color=%s]%s[/color]\n" % [G if got else D, "▮" if got else "▯", str(d[1]).rpad(22), "#cccccc" if got else D, d[2]]
	return t

## 'achievements ...' from the main terminal
func handle(text: String) -> String:
	var t = text.strip_edges().to_lower()
	if t in ["achievements", "achievement", "achievements -h", "achievements ls"]:
		return list_text()
	if DEV and t == "achievements reset":
		unlocked.clear(); _save(); SteamManager.reset_all(); _hacks_sent = -1
		return "(dev) achievements reset (local and Steam)"
	if DEV and t.begins_with("achievement unlock "):
		var id = t.trim_prefix("achievement unlock ").strip_edges().to_upper()
		if def(id).is_empty():
			return "(dev) no achievement '%s'" % id
		unlock(id)
		return "(dev) unlocked %s" % id
	return "usage: achievements"
#endregion

func _save() -> void:
	var cfg = ConfigFile.new()
	for id in unlocked:
		cfg.set_value("unlocked", id, unlocked[id])
	cfg.save(PATH)

func _load() -> void:
	var cfg = ConfigFile.new()
	unlocked = {}
	if cfg.load(PATH) != OK:
		return
	for id in cfg.get_section_keys("unlocked") if cfg.has_section("unlocked") else []:
		unlocked[id] = int(cfg.get_value("unlocked", id, 0))
