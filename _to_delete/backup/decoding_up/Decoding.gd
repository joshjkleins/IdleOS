extends Node

signal cache_decode_cycle_completed
signal intel_decode_cycle_completed
signal xp_gained
signal decoding_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_DECODING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/cache_decrypt_terminal.tscn")

var first_cache_decoded: bool = false

## A process's efficiency incl. upgrades + defrag bonus (for Cache / Deep Scan: the rare item chance).
func get_efficiency(process: Dictionary = {}) -> float:
	if process.is_empty():
		process = CACHE
	var efficiency_upgrade = Upgrades.get_package_info("decoding.efficiency").current
	var defrag_bonus = 1.0 # defrag no longer boosts skills
	return min(1.0, (process["efficiency"] + efficiency_upgrade) * defrag_bonus)

## Chance for a cache's rare item when decoded by <process> (Skim never finds it, Deep Scan doubles it).
func get_rare_chance(process: Dictionary = {}) -> float:
	if process.is_empty():
		process = CACHE
	return min(1.0, get_efficiency(process) * process.get("rare multiplier", 1.0))

#GENERAL MODULE DATA
var SKILL = {
	"name": "Decoding",
	"level": 1,
	"experience": 0,
	"color": Color("#14B8A6"),
	"level up signal": decoding_level_up_signal,
	"efficiency description": "Chance to find rare item.",
	"command": "cd decoding",
	"sfx": "cracking_item_received"
}

var CACHE = {
	"name": "Cache",
	"tier name": "TIER I | CACHE",
	"decode kind": "cache",
	"level": 1,
	"experience": 0,
	"experience per level": 50,
	"command": "decode -cache",
	"display command": "decode -cache[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -cache', 'description': 'Decodes every cache you have, starting with least rare.'},
		{'cmd': 'decode -cache=student cache', 'description': 'Decodes "Student Caches" and stops when done instead of moving on to other caches.'}
	],
	"efficiency": 0.1,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.2,
	"overclock speed": 0.05,
	"overheat speed": 1.0,
	"heat": 3.2,
	"overclock heat": 3.5,
	"overheat heat": 0.3,
	"vm token chance": 0.01,
	"requirements": "Cache x1", #handled within the decoding terminal script
	"description": "Decrypt caches gained from hacking to reveal additional items.",
	"efficiency description": "Chance to find rare item.",
	"signal": cache_decode_cycle_completed
}

var PACKAGE = {
	"name": "Package",
	"tier name": "UPLOAD | PACKAGE",
	"decode kind": "package",
	"level": 1,
	"experience": 0,
	"experience per level": 10,
	"command": "decode -package",
	"display command": "decode -package=<item> (<amount>)",
	"example commands": [
		{'cmd': 'decode -package=logs', 'description': 'Packages Logs one at a time for upload (stops once the goal is covered)'},
		{'cmd': 'decode -package=logs 5', 'description': 'Packages 5 Logs, then stops'},
		{'cmd': 'upload', 'description': 'Shows the current upload goal and what is packaged'}
	],
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.2, # seconds per byte revealed (one 20-byte line per item)
	"overclock speed": 0.1,
	"overheat speed": 0.5,
	"heat": 0.64,
	"overclock heat": 0.7,
	"overheat heat": 0.06,
	"vm token chance": 0.002,
	"requirements": "An item in the current upload goal",
	"description": "Packages items for upload, one per pass. Packaged items wait in the upload staging area until you run 'upload -<item>'.",
	"efficiency description": "Chance to package a second item in the same pass.",
	"signal": cache_decode_cycle_completed
}

var INTEL = {
	"name": "Intel",
	"tier name": "UTILITY | INTEL",
	"decode kind": "intel",
	"level": 1,
	"experience": 0,
	"experience per level": 50,
	"command": "decode -intel",
	"display command": "decode -intel=<target>",
	"example commands": [
		{'cmd': 'decode -intel', 'description': 'Lists targets and the intel you have on each'},
		{'cmd': 'decode -intel=student', 'description': 'Gathers intel on the Student until stopped or maxed'},
		{'cmd': 'decode -intel=student hard', 'description': 'Hard mode targets keep their own intel'}
	],
	"efficiency": 0.15,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 0.2,
	"overclock speed": 0.1,
	"overheat speed": 0.5,
	"heat": 3.2,
	"overclock heat": 3.5,
	"overheat heat": 0.3,
	"vm token chance": 0.01,
	"requirements": "Nothing (an unlocked hacking target)",
	"description": "Gathers intel on a hacking target, free to run. Each successful line weakens the target's intel stat by 1 more or lasts 1 more hack (alternating), up to 25% of that stat and 10 hacks. Used up one hack at a time.",
	"efficiency description": "Chance per line to gather intel.",
	"signal": intel_decode_cycle_completed
}

var SKIM = {
	"name": "Skim",
	"tier name": "TIER II | SKIM",
	"decode kind": "skim",
	"rare multiplier": 0.0,
	"level": 1,
	"experience": 0,
	"experience per level": 25,
	"command": "decode -skim",
	"display command": "decode -skim[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -skim', 'description': 'Skims every cache you have'},
		{'cmd': 'decode -skim=student cache', 'description': 'Skims only Student caches'}
	],
	"efficiency": 0.1,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 5,
	"base speed": 0.1, # seconds per byte revealed
	"overclock speed": 0.05,
	"overheat speed": 0.25,
	"heat": 1.6,
	"overclock heat": 1.75,
	"overheat heat": 0.15,
	"vm token chance": 0.005,
	"requirements": "Cache x1",
	"description": "Skims caches twice as fast as a full decode, but never finds the rare item.",
	"efficiency description": "Chance for +50% basic resources from a cache.",
	"signal": cache_decode_cycle_completed
}

var SALVAGE = {
	"name": "Salvage",
	"tier name": "UTILITY | SALVAGE",
	"decode kind": "salvage",
	"level": 1,
	"experience": 0,
	"experience per level": 100,
	"command": "decode -salvage",
	"display command": "decode -salvage=<item>",
	"example commands": [
		{'cmd': 'decode -salvage=logs', 'description': 'Breaks down 100 Logs at a time into VM tokens'}
	],
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 25,
	"base speed": 0.2, # seconds per byte revealed
	"overclock speed": 0.1,
	"overheat speed": 0.5,
	"heat": 6.4,
	"overclock heat": 7.0,
	"overheat heat": 0.6,
	"vm token chance": 0.02,
	"requirements": "Basic resource x100",
	"description": "Breaks down 100 of a basic resource at a time. Each of its 10 lines has a chance at 10-20 random VM tokens: 3% per line for tier 1 items, 6% for tier 2, up to 18% for tier 6.",
	"efficiency description": "Chance a token find is doubled.",
	"signal": cache_decode_cycle_completed
}

var DEEP = {
	"name": "Deep",
	"tier name": "TIER III | DEEP SCAN",
	"decode kind": "deep",
	"level": 1,
	"experience": 0,
	"experience per level": 100,
	"command": "decode -deep",
	"display command": "decode -deep[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -deep', 'description': 'Deep scans every cache you have (1 VM Decoding token each)'},
		{'cmd': 'decode -deep=student cache', 'description': 'Deep scans only Student caches'}
	],
	"efficiency": 0.1,
	"efficiency rate": 0.001,
	"rare multiplier": 2.0,
	"token cost": 1, # VM Decoding tokens per cache
	"unlocked": false,
	"unlock level": 40,
	"base speed": 0.4, # seconds per byte revealed
	"overclock speed": 0.2,
	"overheat speed": 1.0,
	"heat": 6.4,
	"overclock heat": 7.0,
	"overheat heat": 0.6,
	"vm token chance": 0.02,
	"requirements": "Cache x1 | VM Decoding token x1",
	"description": "Deep scans a cache at half speed for double the chance at its rare item. Costs 1 VM Decoding token per cache.",
	"efficiency description": "Chance to find the rare item (doubled).",
	"signal": cache_decode_cycle_completed
}

var minor_processes = [
	CACHE,
	PACKAGE,
	SKIM,
	INTEL,
	SALVAGE,
	DEEP,
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

#var process_upgrades = {
	#"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.005 },
	#"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	#"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	#"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
#}
#
#func get_upgrade_cost(upgrade_stat: String) -> int:
	#return process_upgrades[upgrade_stat]["level"] * 800 + 100
#
#func upgraded(upgrade_stat: Dictionary):
	#upgrade_stat["level"] += 1
	#upgrade_stat["amount"] += upgrade_stat["increase per level"]
	#
	#if upgrade_stat["name"].to_lower() == "vm windows":
		#MAX_VMS += upgrade_stat["increase per level"]
	#if upgrade_stat["name"].to_lower() == "vm duration":
		#VM_UPTIME += upgrade_stat["increase per level"]

func has_requirements(minor_process) -> bool:
	# cache kinds need a cache; the others are checked in validate_start()
	if minor_process.get("decode kind", "cache") in ["cache", "skim", "deep"]:
		return Inventory.has_cache()
	return true

func missing_requirements_text(_minor_process) -> String:
	return "Missing: Cache(any)"

func create_vm_window(minor_process, repeat, cache_target = null) -> VMWindow:
	var setup = func(t):
		t.set_cache_type(minor_process, true, cache_target)
		t.start_decrypting()
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, repeat)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"cache_level": CACHE["level"],
		"cache_experience": CACHE["experience"],
		"cache_efficiency": CACHE["efficiency"],
		"first_cache_decoded": first_cache_decoded,
		"intel": intel,
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	CACHE["level"] = int(data.get("cache_level", CACHE["level"]))
	CACHE["experience"] = int(data.get("cache_experience", CACHE["experience"]))
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	first_cache_decoded = data.get("first_cache_decoded", false)
	intel = {}
	var saved_intel: Dictionary = data.get("intel", {})
	for k in saved_intel:
		intel[k] = {"amount": int(saved_intel[k].get("amount", 0)), "hacks": int(saved_intel[k].get("hacks", 0))}
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)

#region cache variants
## Drop rules for caches and their variants (tuning values are constants on CacheData).
## `ls <cache>` uses get_drop_table(), decoding uses roll_loot(), so the two always agree.

## Basic resources = everything except hacking mods, SQL injectors, packet spoofs, VM tokens and rare items.

func is_basic_item(item: ItemData) -> bool:
	if item.hacking_mod_item or item.exploit_id != "":
		return false
	if item == Items.SQL_INJECTOR or item == Items.PACKET_SPOOF:
		return false
	return not item in vm_tokens()

## SALVAGE: 100 of a basic resource per run, 10 lines, each with a chance at 10-20 random VM tokens.
const SALVAGE_COST = 100
const SALVAGE_LINES = 10
const SALVAGE_TOKENS_MIN = 10
const SALVAGE_TOKENS_MAX = 20
const SALVAGE_CHANCE_PER_TIER = 0.03 # chance per line: 3% x the item's tier (tier 1 = 3% ... tier 6 = 18%)

## The tier (1-6) a basic resource belongs to, 0 if none.
func get_resource_tier(item: ItemData) -> int:
	for tier in range(1, 7):
		if get_tier_resources(tier).has(item):
			return tier
	return 0

func get_salvage_line_chance(item: ItemData) -> float:
	return SALVAGE_CHANCE_PER_TIER * get_resource_tier(item)

## The basic resources of each tier, in chain order: mined, address, encrypted, identifier, cracked, matched, payload.
func get_tier_resources(tier: int) -> Array:
	var k = tier - 1
	var mined: ItemData = Mining.minor_processes[k]["resource gained"]
	var crack = Cracking.minor_processes.filter(func(p): return p != Cracking.VM)[k]
	var match_p = Matching.minor_processes[k]
	var comp = Compiling.get_payload_processes()[k]
	var address = comp.requirements.keys().filter(func(i): return i != match_p["resource gained"])[0]
	var identifier = match_p.requirements.keys().filter(func(i): return i != crack["resource gained"])[0]
	return [mined, address, crack.requirements.keys()[0], identifier, crack["resource gained"], match_p["resource gained"], comp["resource gained"]]

func is_salvageable(item: ItemData) -> bool:
	return get_resource_tier(item) > 0

## One salvage run's lines for <item>: [{item, amount} or null] (null = nothing on that line).
## Line chance comes from the item's tier; efficiency is the chance a find is doubled.
func roll_salvage(item: ItemData) -> Array:
	var rows = []
	var chance = get_salvage_line_chance(item)
	for i in SALVAGE_LINES:
		if randf() < chance:
			var amount = randi_range(SALVAGE_TOKENS_MIN, SALVAGE_TOKENS_MAX)
			if randf() < get_efficiency(SALVAGE):
				amount *= 2
			rows.append({"item": vm_tokens().pick_random(), "amount": amount, "rare": false})
		else:
			rows.append(null)
	return rows

## Checks a start command's argument (the text after "=", or "" when none) for <process>.
## Returns {"ok": bool, "message": String, "arg": the cache / item / target to decode, or null}.
func validate_start(process: Dictionary, arg_text: String) -> Dictionary:
	var out = {"ok": false, "message": "", "arg": null}
	arg_text = arg_text.strip_edges()
	var kind = process.get("decode kind", "cache")
	match kind:
		"cache", "skim", "deep":
			if arg_text != "":
				var cache = Inventory.get_item_by_name(arg_text)
				if cache == null or not cache is CacheData:
					out.message = arg_text + " cache not found."
					return out
				if Inventory.get_amount(cache) <= 0:
					out.message = "No " + cache.name + " in inventory."
					return out
				out.arg = cache
			elif !Inventory.has_cache():
				out.message = "No caches found."
				return out
			var cost: int = process.get("token cost", 0)
			if cost > 0 and Inventory.get_amount(Items.VM_DECODING_TOKEN) < cost:
				out.message = "%s needs %d VM Decoding token per cache." % [process.name, cost]
				return out
		"salvage":
			var item = Inventory.get_item_by_name(arg_text) if arg_text != "" else null
			if item == null:
				out.message = "Name a basic resource to salvage. [color=#666666]ex. decode -salvage=logs[/color]"
				return out
			if !is_salvageable(item):
				out.message = item.name + " can't be salvaged. Only basic resources (Mining through Compiling items) can."
				return out
			if Inventory.get_amount(item) < SALVAGE_COST:
				out.message = "Salvage needs %d %s (you have %d)." % [SALVAGE_COST, item.name, Inventory.get_amount(item)]
				return out
			out.arg = item
		"intel":
			if arg_text == "":
				out.message = intel_list_text()
				return out
			var target = find_target(arg_text)
			if target.is_empty():
				out.message = "Target not found or not unlocked: %s  [color=#666666]ex. decode -intel=student  |  decode -intel=student hard[/color]" % arg_text
				return out
			if is_intel_maxed(target):
				out.message = "Intel on %s is maxed: %s" % [target.name, intel_text(target)]
				return out
			out.arg = target
		"package":
			# optional amount: 'decode -package=logs 5' packages 5 then stops
			next_package_limit = 0
			var words = arg_text.split(" ", false)
			if words.size() > 1 and words[-1].is_valid_int():
				next_package_limit = max(1, int(words[-1]))
				arg_text = " ".join(words.slice(0, words.size() - 1))
			var item = Inventory.get_item_by_name(arg_text) if arg_text != "" else null
			if item != null and next_package_limit == 0 and !Tutorial.is_tutorial_complete():
				out.message = "Add how many to package, e.g. 'decode -package=%s 5'. During the tutorial, always package an exact amount so you keep enough for the next steps." % item.name.to_lower()
				return out
			if item == null:
				out.message = "Name an item to package. [color=#666666]ex. decode -package=logs  (see 'upload' for the goal)[/color]"
				return out
			if !Uploads.is_goal_item(item):
				out.message = item.name + " isn't part of the current upload goal. Type 'upload' to see it."
				return out
			if Uploads.get_still_needed(item) <= 0:
				out.message = "Enough %s is already packaged or uploaded for this goal." % item.name
				return out
			if Inventory.get_amount(item) <= 0:
				out.message = "No %s in inventory." % item.name
				return out
			out.arg = item
	out.ok = true
	return out

## 'decode -package=<item> <amount>': read by the terminal that starts next (0 = until the goal is covered)
var next_package_limit := 0

#region intel
## Intel per target, saved: key -> {"amount": stat reduction, "hacks": hacks left}.
## Each successful line alternates +1 amount / +1 hack (first find = -1 for 1 hack), capped at
## INTEL_CAP_RATIO of the target's intel stat and INTEL_MAX_HACKS. One hack is used per hack attempt.
const INTEL_LINES = 5
const INTEL_CAP_RATIO = 0.25
const INTEL_MAX_HACKS = 10
const INTEL_STATS = ["firewall", "integrity", "counter", "counter speed"] # "intel stat" a target can name
var intel := {}

## "School/Student" or "School/Student (Hard)/hard" style key (easy and hard mode are separate).
func intel_key(target: Dictionary) -> String:
	return Stats.target_key(target)

func intel_stat(target: Dictionary) -> String:
	var s = target.get("intel stat", "firewall")
	return s if s in INTEL_STATS else "firewall"

func intel_cap(target: Dictionary) -> int:
	return max(1, int(float(target.get(intel_stat(target), 0)) * INTEL_CAP_RATIO))

func get_intel(target: Dictionary) -> Dictionary:
	return intel.get(intel_key(target), {"amount": 0, "hacks": 0})

func is_intel_maxed(target: Dictionary) -> bool:
	var i = get_intel(target)
	return i.amount >= intel_cap(target) and i.hacks >= INTEL_MAX_HACKS

func add_intel_point(target: Dictionary) -> void:
	var i = get_intel(target).duplicate()
	var cap = intel_cap(target)
	if i.hacks == 0:
		i.amount = max(i.amount, 1)
		i.hacks = 1
	elif i.amount <= i.hacks and i.amount < cap:
		i.amount += 1
	elif i.hacks < INTEL_MAX_HACKS:
		i.hacks += 1
	elif i.amount < cap:
		i.amount += 1
	intel[intel_key(target)] = i
	SaveManager.mark_dirty()

## Called once per hack attempt: returns {"stat", "amount", "hacks_left"} (empty if no intel) and uses a hack.
func use_intel(target: Dictionary) -> Dictionary:
	var key = intel_key(target)
	var i = intel.get(key, {})
	if i.is_empty() or i.hacks <= 0:
		return {}
	var out = {"stat": intel_stat(target), "amount": min(i.amount, intel_cap(target)), "hacks_left": i.hacks - 1}
	if i.hacks <= 1:
		intel.erase(key)
	else:
		intel[key] = {"amount": i.amount, "hacks": i.hacks - 1}
	SaveManager.mark_dirty()
	return out

func intel_text(target: Dictionary) -> String:
	var i = get_intel(target)
	if i.hacks <= 0:
		return "no intel  (max -%d %s / %d hacks)" % [intel_cap(target), intel_stat(target), INTEL_MAX_HACKS]
	return "-%d %s for %d hack%s  (max -%d / %d)" % [i.amount, intel_stat(target), i.hacks, "" if i.hacks == 1 else "s", intel_cap(target), INTEL_MAX_HACKS]

## "student", "student hard", "legal-assistant", "student (hard)" -> the unlocked target, or {}.
func find_target(text: String) -> Dictionary:
	var name = text.to_lower().replace("-", " ").strip_edges()
	var hard = name.ends_with(" hard") or name.contains("(hard)")
	name = name.replace("(hard)", "").trim_suffix(" hard").strip_edges()
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if !l.get("unlocked", true):
			continue
		var list = l.get("hard mode targets", []) if hard else l.get("targets", [])
		if hard and !l.get("hard mode unlocked", false):
			continue
		for t in list:
			if t.get("unlocked", false) and t.name.to_lower().replace("(hard)", "").strip_edges() == name:
				return t
	return {}

## 'intel' / 'intel <location>' / 'intel <target> [hard]'.
func intel_command_text(arg: String) -> String:
	arg = arg.to_lower().strip_edges()
	if arg == "":
		return intel_list_text()
	for loc in Stats.hacking_targets:
		if loc.to_lower() == arg.replace("-", " ") or loc.to_lower().replace(" ", "-") == arg:
			return intel_list_text(loc)
	var target = find_target(arg)
	if target.is_empty():
		return "No unlocked location or target named '%s'. [color=#666666]ex. intel  |  intel school  |  intel student  |  intel student hard[/color]" % arg
	return intel_detail_text(target)

func intel_detail_text(target: Dictionary) -> String:
	var stat = intel_stat(target)
	var base = target.get(stat, 0)
	var i = get_intel(target)
	var key = intel_key(target)
	var hard = key.ends_with("/hard")
	var out = "INTEL  ·  %s%s  [color=#666666](%s)[/color]\n" % [target.name, " (hard)" if hard and !target.name.to_lower().contains("hard") else "", key.get_slice("/", 0)]
	out += "  intel stat     %s (base %s)\n" % [stat, str(base)]
	if i.hacks > 0:
		out += "  current        -%d %s for %d hack%s  ->  next hack: %s %s\n" % [i.amount, stat, i.hacks, "" if i.hacks == 1 else "s", str(max(0, base - i.amount)), stat]
	else:
		out += "  current        none\n"
	out += "  max            -%d %s (25%%) for %d hacks\n" % [intel_cap(target), stat, INTEL_MAX_HACKS]
	out += "  target stats   integrity %s  ·  firewall %s  ·  counter %s  ·  counter speed %s\n" % [str(target.get("integrity", "-")), str(target.get("firewall", "-")), str(target.get("counter", "-")), str(target.get("counter speed", "-"))]
	out += "[color=#666666]gather more with: decode -intel=%s%s[/color]" % [target.name.to_lower().replace(" (hard)", "").replace(" ", "-"), " hard" if hard else ""]
	return out

func intel_list_text(location_filter: String = "") -> String:
	var out = "Intel  [color=#666666](intel <location> | intel <target> [hard]  ·  decode -intel=<target> to gather)[/color]\n"
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if !l.get("unlocked", true) or (location_filter != "" and loc != location_filter):
			continue
		out += "\n" + loc.to_upper() + "\n"
		for list in ["targets", "hard mode targets"]:
			if list == "hard mode targets" and !l.get("hard mode unlocked", false):
				continue
			for t in l.get(list, []):
				if t.get("unlocked", false):
					var label = t.name + (" (hard)" if list == "hard mode targets" and !t.name.to_lower().contains("hard") else "")
					out += "  %-28s %s\n" % [label, intel_text(t)]
	return out
#endregion

func vm_tokens() -> Array:
	return [Items.VM_MINING_TOKEN, Items.VM_PARSING_TOKEN, Items.VM_CRACKING_TOKEN, Items.VM_MATCHING_TOKEN,
		Items.VM_PHISHING_TOKEN, Items.VM_DECODING_TOKEN, Items.VM_COMPILING_TOKEN]

func _entry_range(cache: CacheData, entry: CacheEntry) -> Vector2i:
	var mult = 1
	if cache.get_variant() == CacheData.CacheVariant.FOOTPRINT and is_basic_item(entry.item):
		mult = CacheData.FOOTPRINT_MULTIPLIER
	return Vector2i(entry.min_quantity * mult, entry.max_quantity * mult)

func _entry_chance(cache: CacheData, entry: CacheEntry) -> float:
	var bonus = CacheData.CORRUPTION_DROP_BONUS if cache.get_variant() == CacheData.CacheVariant.CORRUPTION else 0.0
	return min(1.0, entry.drop_chance + bonus)

func get_cache_rare_chance(cache: CacheData, base_rare_chance: float) -> float:
	if base_rare_chance <= 0.0:
		return 0.0
	match cache.get_variant():
		CacheData.CacheVariant.FOOTPRINT:
			return 0.0
		CacheData.CacheVariant.CORRUPTION:
			return min(1.0, base_rare_chance + CacheData.CORRUPTION_DROP_BONUS)
	return base_rare_chance

func _rare_amount(cache: CacheData) -> int:
	if cache.get_variant() == CacheData.CacheVariant.EXTRACTION:
		return 1 + CacheData.EXTRACTION_EXTRA_RARE
	return 1

## For `ls` and the decoding terminal: [{name, min, max, chance, rare}]. <process> = Cache (default),
## Skim (no rare) or Deep Scan (rare x2).
func get_drop_table(cache: CacheData, process: Dictionary = {}) -> Array:
	var rows = []
	for e in cache.entries:
		var r = _entry_range(cache, e)
		rows.append({"name": e.item.name, "min": r.x, "max": r.y, "chance": _entry_chance(cache, e), "rare": false})
	if cache.get_variant() == CacheData.CacheVariant.NETWORK:
		rows.append({"name": "Random VM token", "min": CacheData.NETWORK_VM_MIN, "max": CacheData.NETWORK_VM_MAX, "chance": CacheData.NETWORK_VM_CHANCE, "rare": false})
	var rare_chance = get_cache_rare_chance(cache, get_rare_chance(process))
	if rare_chance > 0.0:
		for e in cache.rare_pool:
			rows.append({"name": e.item.name, "min": _rare_amount(cache), "max": _rare_amount(cache), "chance": rare_chance, "rare": true})
	var ex = Exploits.drop_row(cache, process)
	if !ex.is_empty():
		rows.append(ex)
	return rows

## Rolls one decode: [{item, amount, rare}] with the rare item (if any) last.
## <process> decides the rare chance (Skim: none, Deep Scan: x2); Skim's efficiency can add +50% basics.
func roll_loot(cache: CacheData, process: Dictionary = {}) -> Array:
	if process.is_empty():
		process = CACHE
	var basic_mult = 1.5 if (process == SKIM and randf() < get_efficiency(SKIM)) else 1.0
	var loot = []
	for e in cache.entries:
		if randf() <= _entry_chance(cache, e):
			var r = _entry_range(cache, e)
			var amount = randi_range(r.x, r.y)
			if is_basic_item(e.item):
				amount = int(ceil(amount * basic_mult))
			loot.append({"item": e.item, "amount": amount, "rare": false})
	if cache.get_variant() == CacheData.CacheVariant.NETWORK and randf() <= CacheData.NETWORK_VM_CHANCE:
		loot.append({"item": vm_tokens().pick_random(), "amount": randi_range(CacheData.NETWORK_VM_MIN, CacheData.NETWORK_VM_MAX), "rare": false})
	if !cache.rare_pool.is_empty() and randf() < get_cache_rare_chance(cache, get_rare_chance(process)):
		loot.append({"item": cache.rare_pool.pick_random().item, "amount": _rare_amount(cache), "rare": true})
	var ex = Exploits.roll_drop(cache, process)
	if ex:
		loot.append({"item": ex, "amount": 1, "rare": true})
	return loot
#endregion
