extends Node
## DRIVERS (skill revamp phase 2, 2026-10-27): permanent per-skill items that change hacking. They live inside
## their skill (not in 'ls'): 'cd mining' -> 'driver'. Slots come from the skill level (SLOT_LEVELS); equipping
## is free, so respec is just equip / unequip. Equipped drivers rank up (1-3) from their skill's XP, and keep
## the rank when unequipped. They drop from Hacking compromises (singletons/Compromise.gd, 2026-10-28): each
## skill's 1st-5th driver belongs to tier 1-5 (School ... Police Station). 'driver give <id>' (DEV_GIVE) for testing.

signal changed
signal ranked_up(id: String, rank: int)

const SLOT_LEVELS = [10, 60]            # a slot at each of these skill levels (2 max)
const RANK_XP = [0, 25000, 150000]      # skill XP earned while equipped for rank 1 / 2 / 3
const MAX_RANK = 3
const DEV_GIVE := true                  # TESTING: 'driver give <id|all>' grants drivers. Turn off before release.

## id -> {skill, name, values per rank, text with %s for the value, format}
## format: "pct" (+10%; "%s chance ..." texts drop the +), "temp" (80°C), "nth" (10th), "x" (×1.5), "s" (2s), "num" (40)
const DEFS = {
	# Mining: bandwidth and endurance
	"deep_reserves": {"skill": "Mining", "name": "Deep Reserves", "short": "%s no-BW attacks", "values": [0.10, 0.15, 0.25],
		"text": "%s chance an SQL Injector attack uses no bandwidth"},
	"steady_flow": {"skill": "Mining", "name": "Steady Flow", "short": "%s dmg at max BW", "values": [0.10, 0.15, 0.25],
		"text": "%s damage on attacks made at max bandwidth"},
	"stockpile": {"skill": "Mining", "name": "Stockpile", "short": "%s double shots", "values": [0.10, 0.15, 0.25],
		"text": "%s chance an attack fires 2 SQL Injectors at once"},
	"cool_head": {"skill": "Mining", "name": "Cool Head", "short": "1st overheat: %s", "values": [80.0, 70.0, 50.0],
		"text": "the first overheat of a hack resets your temperature to %s", "format": "temp"},
	"long_haul": {"skill": "Mining", "name": "Long Haul", "short": "%s dmg per breach", "values": [0.02, 0.03, 0.05],
		"text": "%s damage for every target breached consecutively (stacks 5 times)", "max_stacks": 5},
	# Cracking: crits
	"brute_force": {"skill": "Cracking", "name": "Brute Force", "short": "%s crit chance", "values": [0.03, 0.05, 0.08],
		"text": "%s crit chance"},
	"hash_collision": {"skill": "Cracking", "name": "Hash Collision", "short": "every %s hit crits", "values": [10, 8, 6],
		"text": "every %s attack is a guaranteed crit", "format": "nth"},
	"rainbow_table": {"skill": "Cracking", "name": "Rainbow Table", "short": "%s crit dmg, FW down", "values": [0.20, 0.30, 0.50],
		"text": "%s crit damage while the firewall is down"},
	"salted_hash": {"skill": "Cracking", "name": "Salted Hash", "short": "crits refund %s BW", "values": [0.10, 0.15, 0.25],
		"text": "crits refund %s of your max bandwidth", "format": "pct_plain"},
	"cracked_wide": {"skill": "Cracking", "name": "Cracked Wide", "short": "crits %s FW dmg", "values": [1.5, 1.75, 2.0],
		"text": "crits that hit the firewall deal %s firewall damage", "format": "x"},
	# Matching: firewall
	"credential_reuse": {"skill": "Matching", "name": "Credential Reuse", "short": "%s FW damage", "values": [0.10, 0.15, 0.25],
		"text": "%s firewall damage per hit"},
	"session_hijack": {"skill": "Matching", "name": "Session Hijack", "short": "FW down %s longer", "values": [2.0, 3.0, 5.0],
		"text": "the firewall stays down %s longer after a break", "format": "s"},
	"token_replay": {"skill": "Matching", "name": "Token Replay", "short": "FW reboots at %s", "values": [0.90, 0.80, 0.70],
		"text": "the firewall reboots at %s strength", "format": "pct_plain"},
	"master_key": {"skill": "Matching", "name": "Master Key", "short": "%s 1st hit past FW", "values": [0.20, 0.30, 0.50],
		"text": "the first hit after each reboot ignores the firewall and deals %s damage"},
	"brute_match": {"skill": "Matching", "name": "Brute Match", "short": "%s dmg while FW up", "values": [0.10, 0.15, 0.25],
		"text": "%s damage while the firewall is up"},
	# Phishing: anonymity and spoofs
	"social_proof": {"skill": "Phishing", "name": "Social Proof", "short": "%s spoof healing", "values": [0.10, 0.15, 0.25],
		"text": "Packet Spoofs restore %s more"},
	"burner_account": {"skill": "Phishing", "name": "Burner Account", "short": "%s free spoofs", "values": [0.10, 0.15, 0.25],
		"text": "%s chance a Packet Spoof isn't used up"},
	"cover_story": {"skill": "Phishing", "name": "Cover Story", "short": "%s counters miss", "values": [0.05, 0.08, 0.12],
		"text": "%s chance a countermeasure misses"},
	"lure": {"skill": "Phishing", "name": "Lure", "short": "%s spoof chains", "values": [0.10, 0.12, 0.15],
		"text": "%s chance a Packet Spoof instantly uses another one"},
	"cheap_spoof": {"skill": "Phishing", "name": "Cheap Spoof", "short": "%s no-BW spoofs", "values": [0.15, 0.25, 0.40],
		"text": "%s chance a Packet Spoof costs no bandwidth"},
	# Parsing: intel and countermeasures
	"intel_reserve": {"skill": "Parsing", "name": "Intel Reserve", "short": "%s intel kept", "values": [0.20, 0.30, 0.50],
		"text": "%s chance a hack doesn't use up intel"},
	"weak_point": {"skill": "Parsing", "name": "Weak Point", "short": "%s dmg, full intel", "values": [0.05, 0.08, 0.12],
		"text": "%s damage when you have full intel on the target (-10%% on every stat)"},
	"read_ahead": {"skill": "Parsing", "name": "Read Ahead", "short": "1st counter %s slower", "values": [0.50, 0.75, 1.00],
		"text": "each hack's first countermeasure charges %s slower", "format": "pct_plain"},
	"countermeasure_log": {"skill": "Parsing", "name": "Countermeasure Log", "short": "%s less ctr dmg/hit", "values": [0.01, 0.02, 0.03],
		"text": "each countermeasure taken lowers the next ones' damage by %s (stacks 5 times)", "format": "pct_plain", "max_stacks": 5},
	"signal_boost": {"skill": "Parsing", "name": "Signal Boost", "short": "%s BW when hit", "values": [0.05, 0.08, 0.12],
		"text": "restores %s of max bandwidth each time a countermeasure hits you", "format": "pct_plain"},
	# Decoding: loot and Exploit charge
	"bonus_cache": {"skill": "Decoding", "name": "Bonus Cache", "short": "%s extra cache", "values": [0.05, 0.15, 0.25],
		"text": "%s chance a breach drops an extra cache"},
	"charged_up": {"skill": "Decoding", "name": "Charged Up", "short": "%s Exploit charge", "values": [0.10, 0.15, 0.25],
		"text": "%s Exploit charge gain"},
	"head_start": {"skill": "Decoding", "name": "Head Start", "short": "starts at %s charge", "values": [40.0, 60.0, 80.0],
		"text": "each hack starts with %s Exploit charge", "format": "num"},
	"refund": {"skill": "Decoding", "name": "Refund", "short": "%s Exploit refund", "values": [0.10, 0.15, 0.25],
		"text": "%s chance an Exploit isn't used up"},
	"salvage_rights": {"skill": "Decoding", "name": "Salvage Rights", "short": "%s VM cache drop", "values": [0.10, 0.12, 0.15],
		"text": "%s chance a breach also drops a VM cache"}, # 2026-10-27: was a payload refund (same as Payload Recycler)
	# Compiling: SQL damage and speed
	"optimized_build": {"skill": "Compiling", "name": "Optimized Build", "short": "%s SQL damage", "values": [0.05, 0.08, 0.12],
		"text": "%s SQL damage"},
	"quick_compile": {"skill": "Compiling", "name": "Quick Compile", "short": "%s attack speed", "values": [0.05, 0.08, 0.12],
		"text": "SQL Injectors attack %s faster", "format": "pct_plain"},
	"payload_recycler": {"skill": "Compiling", "name": "Payload Recycler", "short": "%s payload refund", "values": [0.10, 0.15, 0.25],
		"text": "%s chance a hack doesn't spend its payload"},
	"warm_start": {"skill": "Compiling", "name": "Warm Start", "short": "instant 1st attack", "values": [1.0, 1.0, 1.0],
		"text": "each hack's first attack fires instantly", "format": "none"},
	"overclocked_build": {"skill": "Compiling", "name": "Overclocked Build", "short": "%s dmg overclocked", "values": [0.10, 0.15, 0.25],
		"text": "%s damage while overclocked"},
}

var owned := {}    # id -> skill XP earned while equipped
var equipped := {} # skill name -> [ids]

#region queries
func skill_node(name: String) -> Node:
	return get_node_or_null("/root/" + name)

func slots(skill_name: String) -> int:
	var s = skill_node(skill_name)
	if s == null:
		return 0
	var lvl = int(s.SKILL.get("level", 1))
	return SLOT_LEVELS.filter(func(l): return lvl >= l).size()

func next_slot_level(skill_name: String) -> int:
	var s = skill_node(skill_name)
	var lvl = int(s.SKILL.get("level", 1)) if s else 1
	for l in SLOT_LEVELS:
		if lvl < l:
			return l
	return 0

func skill_defs(skill_name: String) -> Array:
	return DEFS.keys().filter(func(id): return DEFS[id].skill == skill_name)

func has_drivers(skill_name: String) -> bool:
	return !skill_defs(skill_name).is_empty()

func is_owned(id: String) -> bool:
	return owned.has(id)

func is_equipped(id: String) -> bool:
	return DEFS.has(id) and equipped.get(DEFS[id].skill, []).has(id)

func rank(id: String) -> int:
	var xp = int(owned.get(id, 0))
	var r = 1
	for i in RANK_XP.size():
		if xp >= RANK_XP[i]:
			r = i + 1
	return min(r, MAX_RANK)

## value at the current rank (0 when not equipped: callers can just use it)
func value(id: String) -> float:
	if !is_equipped(id):
		return 0.0
	return float(DEFS[id].values[rank(id) - 1])

## 0..1 toward the next rank, 1.0 at max rank
func rank_progress(id: String) -> float:
	var r = rank(id)
	if r >= MAX_RANK:
		return 1.0
	var xp = float(owned.get(id, 0))
	return clamp((xp - RANK_XP[r - 1]) / float(RANK_XP[r] - RANK_XP[r - 1]), 0.0, 0.999)

## the header's compact version ("short" in DEFS, same value), e.g. "10% no-BW attacks"
func short_text(id: String, r: int = -1) -> String:
	return value_text(id, r, true)

func value_text(id: String, r: int = -1, short: bool = false) -> String:
	var d = DEFS[id]
	var tpl = str(d.get("short", d.text)) if short else str(d.text)
	var v = float(d.values[(rank(id) if r < 0 else r) - 1])
	var vt = ""
	match d.get("format", "pct"):
		"temp": vt = "%d°C" % int(v)
		"nth": vt = "%dth" % int(v)
		"x": vt = "x%s" % str(v).trim_suffix(".0")
		"s": vt = "%ds" % int(v)
		"num": vt = str(int(v))
		"none": return tpl
		"pct_plain": vt = "%d%%" % roundi(v * 100.0)
		_: vt = ("%d%%" % roundi(v * 100.0)) if d.text.begins_with("%s chance") else ("+%d%%" % roundi(v * 100.0))
	return tpl % vt

func all_equipped() -> Array:
	var out = []
	for s in equipped:
		out.append_array(equipped[s])
	return out
#endregion

#region changes
func grant(id: String) -> bool:
	if !DEFS.has(id) or owned.has(id):
		return false
	owned[id] = 0
	SaveManager.mark_dirty()
	changed.emit()
	return true

## "" on success, otherwise why not
func equip(id: String) -> String:
	if !DEFS.has(id) or !owned.has(id):
		return "You don't have that driver."
	var sk = DEFS[id].skill
	var list: Array = equipped.get(sk, [])
	if list.has(id):
		return "%s is already equipped." % DEFS[id].name
	if list.size() >= slots(sk):
		if slots(sk) == 0:
			return "No %s driver slot yet: the first opens at %s level %d." % [sk, sk, SLOT_LEVELS[0]]
		return "Every %s driver slot is in use. Remove one first ('driver -remove <id>')." % sk
	list.append(id)
	equipped[sk] = list
	SaveManager.mark_dirty()
	changed.emit()
	return ""

func unequip(id: String) -> String:
	if !is_equipped(id):
		return "That driver isn't equipped."
	equipped[DEFS[id].skill].erase(id)
	SaveManager.mark_dirty()
	changed.emit()
	return ""

## Exp.add_xp: equipped drivers of <skill> earn its XP toward their next rank
func add_skill_xp(skill_name: String, amount: int) -> void:
	for id in equipped.get(skill_name, []):
		var before = rank(id)
		owned[id] = int(owned.get(id, 0)) + amount
		if rank(id) > before:
			ranked_up.emit(id, rank(id))
			if !Offline.computing:
				Signals.system_message_signal.emit("[color=#ffc24a]%s driver %s reached rank %d:[/color] %s" % [skill_name, DEFS[id].name, rank(id), value_text(id)])

## Exp.add_xp: a level that opens a slot
func on_level_up(skill_name: String, level: int) -> void:
	if level in SLOT_LEVELS and has_drivers(skill_name) and !Offline.computing:
		Signals.system_message_signal.emit("[color=#ffc24a]%s Driver slot unlocked.[/color] cd into %s to view more details." % [skill_name, skill_name.to_lower()])
#endregion

#region text
## title + the slots (shared by 'driver' and 'info <skill>')
func slots_text(skill_name: String) -> String:
	var G = "#4ec994"
	var D = "#888888"
	var s = slots(skill_name)
	var t = "\n[color=#4ec9b0]%s DRIVERS[/color]   [color=%s]slots %d/%d[/color]\n" % [skill_name.to_upper(), D, all_equipped().filter(func(i): return DEFS[i].skill == skill_name).size(), s]
	for i in SLOT_LEVELS.size():
		var list: Array = equipped.get(skill_name, [])
		if i >= s:
			t += "[color=%s]SLOT %d  locked · opens at %s level %d[/color]\n" % [D, i + 1, skill_name, SLOT_LEVELS[i]]
		elif i < list.size():
			var id = list[i]
			t += "SLOT %d  [color=%s]%s[/color]  %s  %s  %s\n" % [i + 1, G, DEFS[id].name, _rank_bar(id), value_text(id), _rank_progress(id)]
		else:
			t += "SLOT %d  [color=%s]empty[/color]\n" % [i + 1, D]
	return t

## 'info <skill>': the slots + a pointer to 'driver'
func info_text(skill_name: String) -> String:
	if !has_drivers(skill_name):
		return ""
	return slots_text(skill_name) + "[color=#888888]use '[/color][color=#4ec994]driver[/color][color=#888888]' to manage[/color]\n"

## 'driver' inside a skill
func skill_text(skill_name: String) -> String:
	var G = "#4ec994"
	var D = "#888888"
	var t = slots_text(skill_name)
	var mine = skill_defs(skill_name).filter(func(id): return owned.has(id))
	t += "\nAVAILABLE\n"
	if mine.is_empty():
		t += "  [color=%s]-[/color]\n" % D
	for id in mine:
		t += "  %s  %s  %s  rank %d  %s\n" % [id.rpad(14), DEFS[id].name.rpad(14), ("[color=%s]EQUIPPED[/color]" % G) if is_equipped(id) else "        ", rank(id), value_text(id)]
	t += "\n[color=%s]driver -add <id>[/color]      [color=%s]equip a driver (ex. driver -add %s)[/color]\n" % [G, D, mine[0] if !mine.is_empty() else "long_haul"]
	t += "[color=%s]driver -remove <id>[/color]   [color=%s]unequip it (it keeps its rank)[/color]\n" % [G, D]
	t += "[color=%s]Drivers increase in rank with %s XP[/color]\n" % [D, skill_name]
	t += "[color=%s]New drivers drop from compromises in Hacking (ex. 'recon school')[/color]" % D
	return t

## 'driver' at root: one line per skill
func summary_text() -> String:
	var t = "\n[color=#4ec9b0]DRIVERS[/color]\n"
	for sk in ["Mining", "Parsing", "Cracking", "Matching", "Phishing", "Decoding", "Compiling"]:
		if !has_drivers(sk):
			continue
		var list: Array = equipped.get(sk, [])
		t += "  %s  slots %d/%d  %s  [color=#666666](cd %s -> driver)[/color]\n" % [sk.rpad(10), list.size(), slots(sk),
			", ".join(list.map(func(id): return "%s (rank %d)" % [DEFS[id].name, rank(id)])) if !list.is_empty() else "-", sk.to_lower()]
	return t

func _rank_bar(id: String) -> String:
	var r = rank(id)
	return "rank %d %s" % [r, "▮".repeat(r) + "▯".repeat(MAX_RANK - r)]

func _rank_progress(id: String) -> String:
	var r = rank(id)
	if r >= MAX_RANK:
		return "[color=#ffc24a]max rank[/color]"
	return "[color=#888888]%s / %s xp to rank %d[/color]" % [_commas(int(owned.get(id, 0))), _commas(RANK_XP[r]), r + 1]

static func _commas(n: int) -> String:
	var s = str(n)
	var out = ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out
#endregion

#region commands ('driver ...' from idle_os_2; <skill_name> = the skill the terminal is in, "" at root)
func handle(text: String, skill_name: String) -> String:
	var t = text.strip_edges().to_lower()
	var arg = ""
	for p in ["driver -add", "driver -remove", "driver give", "drivers", "driver"]:
		if t.begins_with(p):
			arg = t.trim_prefix(p).strip_edges()
			t = p
			break
	match t:
		"driver", "drivers":
			if skill_name == "" or !has_drivers(skill_name):
				return summary_text() if skill_name == "" else "%s has no drivers yet." % skill_name
			return skill_text(skill_name)
		"driver -add":
			var id = _find(arg)
			if id == "":
				return "No driver called '%s'. Type 'driver' to see yours." % arg
			var r = equip(id)
			return r if r != "" else "[color=#4ec994]%s equipped.[/color] %s" % [DEFS[id].name, value_text(id)]
		"driver -remove":
			var id = _find(arg)
			if id == "":
				return "No driver called '%s'." % arg
			var r = unequip(id)
			return r if r != "" else "%s removed (rank %d kept)." % [DEFS[id].name, rank(id)]
		"driver give":
			if !DEV_GIVE:
				return "Command not found"
			# 'driver give all', 'driver give tier1' (a compromise tier's 7: School = tier1 ... Police Station = tier5), or one id
			var ids = DEFS.keys() if arg == "all" else (Compromise.tier_drivers(int(arg.trim_prefix("tier"))) if arg.begins_with("tier") and arg.trim_prefix("tier").is_valid_int() else [_find(arg)])
			var got = []
			for id in ids:
				if id != "" and grant(id):
					got.append(DEFS[id].name)
			return ("[color=#888888](dev) granted: %s[/color]" % ", ".join(got)) if !got.is_empty() else "Nothing granted (unknown id or already owned)."
	return ""

## id or name ("long_haul", "long haul", "Long Haul")
func _find(arg: String) -> String:
	var a = arg.to_lower().replace(" ", "_")
	for id in DEFS:
		if id == a or DEFS[id].name.to_lower().replace(" ", "_") == a:
			return id
	return ""
#endregion

#region save
func save_data() -> Dictionary:
	return {"owned": owned, "equipped": equipped}

func load_data(data: Dictionary) -> void:
	owned = {}
	for id in data.get("owned", {}):
		if DEFS.has(id):
			owned[id] = int(data.owned[id])
	equipped = {}
	var eq: Dictionary = data.get("equipped", {})
	for sk in eq:
		equipped[sk] = Array(eq[sk]).filter(func(id): return owned.has(id))
	changed.emit()
#endregion
