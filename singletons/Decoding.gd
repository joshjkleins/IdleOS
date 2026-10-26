extends Node

## Heat plan: heat multiplier by the tier being worked on (see BaseTerminal.heat_tier_mult)
const HEAT_BY_TIER := [0.719, 1.063, 1.538, 2.095, 4.954, 7.188]

signal cache_decode_cycle_completed
signal intel_decode_cycle_completed
signal xp_gained
signal decoding_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_DECODING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 60.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/cache_decrypt_terminal.tscn")

var first_cache_decoded: bool = false

## Modifier commands unlocked by Decoding capstones (see Mining.MODIFIERS for how they work).
## They work on the cache processes (Cache, Skim, Deep Scan) and Salvage; Intel refuses them.
const MODIFIERS = [
	{"command": "index", "name": "Index", "package": "decoding.index", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each decoded cache adds 1 intel point on the target it came from."},
	{"command": "forensics", "name": "Forensics", "package": "decoding.forensics", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Exploit chance x2 and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "decoding.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half loot, +100% Decoding XP."},
]
## Clean Room: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "decoding.clean_room"
const FORENSICS_EXPLOIT_MULT := 2.0

## A process's efficiency with the Efficiency track: +X% of the process's own efficiency (x1.20 at max).
## Cache / Deep Scan: +X% basic resources per cache (2026-10-22; it used to be the rare chance); every other
## process its own effect.
func get_efficiency(process: Dictionary = {}) -> float:
	if process.is_empty():
		process = CACHE
	return min(1.0, float(process["efficiency"]) * (1.0 + Upgrades.cur("decoding.efficiency")))

## Chance for a cache's rare item when decoded by <process>: RARE_CHANCE (+ Deep Scan's "rare bonus", + the Rare
## Tracker for <cache>); Skim never finds it. Not tied to efficiency or level (2026-10-22).
const RARE_CHANCE := 0.25
func get_rare_chance(process: Dictionary = {}, cache: CacheData = null) -> float:
	if process.is_empty():
		process = CACHE
	if process.get("rare multiplier", 1.0) <= 0.0:
		return 0.0
	return min(1.0, RARE_CHANCE * process.get("rare multiplier", 1.0) + process.get("rare bonus", 0.0) + tracker_bonus(cache))

## Cache / Deep Scan efficiency: basic resources x (1 + efficiency)
func efficiency_basic_mult(process: Dictionary) -> float:
	return 1.0 + get_efficiency(process) if process == CACHE or process == DEEP else 1.0

#region rare tracker
## Rare Tracker: every cache of a type that decodes without its rare adds the installed bonus to that type's
## next one (variants share a counter: "Student cache Extraction" counts as "Student cache"). Saved.
var rare_tracker := {} # cache family name -> dry caches in a row
## Cache families that already gave their first-time rare: the first decode of every cache family that can
## drop a rare always does (CacheDecrypting.get_potential_items; live decoding only). Hidden on purpose: drop
## tables keep showing the normal chance, so the first one just feels lucky.
var first_rare_given := {}

func cache_family(cache: CacheData) -> String:
	var n = cache.name
	var at = n.to_lower().find("cache")
	return n.substr(0, at + 5) if at != -1 else n

func tracker_bonus(cache: CacheData) -> float:
	if cache == null:
		return 0.0
	return int(rare_tracker.get(cache_family(cache), 0)) * Upgrades.cur("decoding.rare_tracker")

## After a rare roll on <cache>: reset on a rare, otherwise one more dry cache (only while the track is installed)
func note_rare_roll(cache: CacheData, got_rare: bool) -> void:
	var key = cache_family(cache)
	if got_rare:
		rare_tracker.erase(key)
	elif Upgrades.cur("decoding.rare_tracker") > 0.0:
		rare_tracker[key] = int(rare_tracker.get(key, 0)) + 1
	SaveManager.mark_dirty()
#endregion

## Yield: basic resources per decoded cache
func yield_multiplier() -> float:
	return 1.0 + Upgrades.cur("decoding.yield")

## Compression: more basic resources per decoded cache (stacks with Yield)
func compression_multiplier() -> float:
	return 1.0 + Upgrades.cur("decoding.compression")

## Survey: half an amount (coin flip on odd amounts)
static func survey_half(amount: int) -> int:
	return amount / 2 + (1 if amount % 2 == 1 and randf() < 0.5 else 0)

## Index: the target a cache came from (easy mode first; the hard one once the easy one's intel is maxed)
func target_for_cache(cache: CacheData) -> Dictionary:
	var family = cache_family(cache)
	var found: Array = []
	for loc in Stats.hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in Stats.hacking_targets[loc].get(list, []):
				if t.get("loot") is CacheData and t.loot.name == family and t.get("unlocked", false):
					found.append(t)
	for t in found:
		if !is_intel_maxed(t):
			return t
	return {}

#GENERAL MODULE DATA
var SKILL = {
	"name": "Decoding",
	"level": 1,
	"experience": 0,
	"color": Color("#14B8A6"),
	"level up signal": decoding_level_up_signal,
	"efficiency description": "Cache / Deep Scan: bonus basic resources from every cache.",
	"command": "cd decoding",
	"sfx": "cracking_item_received"
}

var CACHE = {
	"name": "Cache",
	"tier name": "TIER I | CACHE",
	"decode kind": "cache",
	"level": 1,
	"experience": 0,
	"experience per level": 150,
	"command": "decode -cache",
	"display command": "decode -cache[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -cache', 'description': 'Decodes every cache you have, starting with least rare.'},
		{'cmd': 'decode -cache=student cache', 'description': 'Decodes "Student Caches" and stops when done instead of moving on to other caches.'}
	],
	"efficiency": 0.05, # +5% basic resources at L1, +0.5% per level (2026-10-22: efficiency = more basics; rare is RARE_CHANCE)
	"efficiency rate": 0.005,
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
	"efficiency description": "Bonus basic resources from every cache.",
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
	"unlock level": 5,
	"base speed": 0.2,
	"overclock speed": 0.1,
	"overheat speed": 0.5,
	"heat": 3.2,
	"overclock heat": 3.5,
	"overheat heat": 0.3,
	"vm token chance": 0.01,
	"requirements": "Nothing (an unlocked hacking target)",
	"description": "Gathers intel on a hacking target. Each successful line lowers a stat with a maximum of -10% for 15 hacks.",
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
	"experience per level": 75,
	"command": "decode -skim",
	"display command": "decode -skim[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -skim', 'description': 'Skims every cache you have'},
		{'cmd': 'decode -skim=student cache', 'description': 'Skims only Student caches'}
	],
	"efficiency": 0.1,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 15,
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
	"unlock level": 10,
	"base speed": 0.2, # seconds per byte revealed
	"overclock speed": 0.1,
	"overheat speed": 0.5,
	"heat": 6.4,
	"overclock heat": 7.0,
	"overheat heat": 0.6,
	"vm token chance": 0.02,
	"requirements": "Basic resource x100",
	"description": "Breaks down 100 of a basic resource at a time. Each of its 10 lines has a chance at 5-10 random VM tokens: 3% per line for tier 1 items, 6% for tier 2, up to 18% for tier 6.",
	"efficiency description": "Chance a token find is doubled.",
	"signal": cache_decode_cycle_completed
}

var DEEP = {
	"name": "Deep",
	"tier name": "TIER III | DEEP SCAN",
	"decode kind": "deep",
	"level": 1,
	"experience": 0,
	"experience per level": 300,
	"command": "decode -deep",
	"display command": "decode -deep[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -deep', 'description': 'Deep scans every cache you have (1 VM Decoding token each)'},
		{'cmd': 'decode -deep=student cache', 'description': 'Deep scans only Student caches'}
	],
	"efficiency": 0.05, # +5% basics at L1 like Cache (rare: RARE_CHANCE + rare bonus = 40%)
	"efficiency rate": 0.005,
	"rare bonus": 0.15, # Deep Scan: +15% rare chance on top of Cache's (2026-10-21; was x2)
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
	"description": "Deep scans a cache at half speed for +15% chance at its rare item. Costs 1 VM Decoding token per cache.",
	"efficiency description": "Bonus basic resources from every cache.",
	"signal": cache_decode_cycle_completed
}

var minor_processes = [
	CACHE,
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
		"rare_tracker": rare_tracker,
		"first_rare_given": first_rare_given,
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	CACHE["level"] = int(data.get("cache_level", CACHE["level"]))
	CACHE["experience"] = int(data.get("cache_experience", CACHE["experience"]))
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	first_cache_decoded = data.get("first_cache_decoded", false)
	first_rare_given = data.get("first_rare_given", {}).duplicate()
	rare_tracker = {}
	var saved_tracker: Dictionary = data.get("rare_tracker", {})
	for k in saved_tracker:
		rare_tracker[k] = int(saved_tracker[k])
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

## SALVAGE: 100 of a basic resource per run, 10 lines, each with a chance at 5-10 random VM tokens.
const SALVAGE_COST = 100
const SALVAGE_LINES = 10
const SALVAGE_TOKENS_MIN = 5   # 2026-10-22: was 10-20
const SALVAGE_TOKENS_MAX = 10
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
func roll_salvage(item: ItemData, mod: String = "") -> Array:
	var rows = []
	var chance = get_salvage_line_chance(item)
	for i in SALVAGE_LINES:
		if randf() < chance:
			var amount = randi_range(SALVAGE_TOKENS_MIN, SALVAGE_TOKENS_MAX)
			if randf() < get_efficiency(SALVAGE):
				amount *= 2
			if mod == "survey":
				amount = max(1, survey_half(amount))
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
	out.ok = true
	return out


#region intel
## Intel per target, saved: key -> {"lv": [integrity, firewall, counter, counter speed] in steps, "dur": hacks earned,
## "hacks": hacks left}. Each step is INTEL_STEP (2%) off that stat for a hack that uses the intel. Gathering builds
## it up one point per successful line, in this order (2026-10-21):
##   one stat +2% at a time until all four are at 2%, then +1 hack; all four to 4%, +1 hack; ... all at 10%,
##   then +1 hack per point up to INTEL_MAX_HACKS (15, + Field Notes).
## Each hack attempt uses 1 hack of intel; when the last one is used the intel is spent (back to nothing).
const INTEL_LINES = 5
const INTEL_STATS = ["integrity", "firewall", "counter", "counter speed"]
const INTEL_STEP = 0.02
const INTEL_MAX_STEPS = 5 # 10%
const INTEL_MAX_HACKS = 15 # base; Field Notes adds +1 per tier installed (intel_max_hacks())
var intel := {}

## "School/Student" or "School/Student (Hard)/hard" style key (easy and hard mode are separate).
func intel_key(target: Dictionary) -> String:
	return Stats.target_key(target)

func get_intel(target: Dictionary) -> Dictionary:
	var i: Dictionary = intel.get(intel_key(target), {})
	var lv = i.get("lv", [0, 0, 0, 0])
	var hacks = int(i.get("hacks", 0))
	return {"lv": [int(lv[0]), int(lv[1]), int(lv[2]), int(lv[3])], "dur": int(i.get("dur", hacks)), "hacks": hacks}

## stat -> share removed (0.0 .. 0.10)
func intel_pcts(target: Dictionary) -> Dictionary:
	var i = get_intel(target)
	var out = {}
	for k in INTEL_STATS.size():
		out[INTEL_STATS[k]] = i.lv[k] * INTEL_STEP
	return out

func is_intel_maxed(target: Dictionary) -> bool:
	var i = get_intel(target)
	return i.lv.min() >= INTEL_MAX_STEPS and i.hacks >= intel_max_hacks()

## Field Notes: +1 max intel hack per install, and a first find starts with that many extra hacks
func field_notes() -> int:
	return int(round(Upgrades.cur("decoding.field_notes")))

func intel_max_hacks() -> int:
	return INTEL_MAX_HACKS + field_notes()

func add_intel_point(target: Dictionary) -> void:
	var i = get_intel(target)
	var lo = i.lv.min()
	if i.hacks <= 0:
		i = {"lv": [1, 0, 0, 0], "dur": 1 + field_notes(), "hacks": 1 + field_notes()}
	elif lo < i.lv.max():
		i.lv[i.lv.find(lo)] += 1 # finish the round: next stat up to the same %
	elif lo >= INTEL_MAX_STEPS:
		if i.dur < intel_max_hacks():
			i.dur += 1
		i.hacks = min(i.hacks + 1, i.dur) # all at 10%: more hacks (or a refill of used ones)
	elif i.dur < lo + 1 + field_notes():
		i.dur += 1 # round done: +1 hack
		i.hacks += 1
	else:
		i.lv[0] += 1 # next round
	intel[intel_key(target)] = i
	SaveManager.mark_dirty()

## Called once per hack attempt: returns {"pcts": stat -> share, "hacks_left"} (empty if no intel) and uses a hack.
func use_intel(target: Dictionary) -> Dictionary:
	var key = intel_key(target)
	var i = get_intel(target)
	if i.hacks <= 0:
		return {}
	var out = {"pcts": intel_pcts(target), "hacks_left": i.hacks - 1}
	if i.hacks <= 1:
		intel.erase(key) # spent
	else:
		i.hacks -= 1
		intel[key] = i
	SaveManager.mark_dirty()
	return out

## "-4% integrity · -4% firewall · -2% counter · -2% counter speed"
func intel_effect_text(target: Dictionary) -> String:
	var p = intel_pcts(target)
	return " · ".join(INTEL_STATS.map(func(s): return "-%d%% %s" % [roundi(p[s] * 100), s]))

func intel_text(target: Dictionary) -> String:
	var i = get_intel(target)
	if i.hacks <= 0:
		return "no intel  (builds up to -%d%% on every stat for %d hacks)" % [roundi(INTEL_STEP * INTEL_MAX_STEPS * 100), intel_max_hacks()]
	return "%s  for %d hack%s" % [intel_effect_text(target), i.hacks, "" if i.hacks == 1 else "s"]

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
	if arg in ["-h", "help"]:
		return ContextCommands.intel_help_commands()
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
	var i = get_intel(target)
	var key = intel_key(target)
	var hard = key.ends_with("/hard")
	var p = intel_pcts(target)
	var out = "INTEL  ·  %s%s  [color=#666666](%s)[/color]\n" % [target.name, " (hard)" if hard and !target.name.to_lower().contains("hard") else "", key.get_slice("/", 0)]
	if i.hacks <= 0:
		out += "  current        none\n"
	else:
		out += "  current        %s\n" % intel_effect_text(target)
		out += "  hacks left     %d  [color=#666666](max %d)[/color]\n" % [i.hacks, intel_max_hacks()]
	out += "  target stats   integrity %s  ·  firewall %s  ·  counter %s  ·  counter speed %s\n" % [str(target.get("integrity", "-")), str(target.get("firewall", "-")), str(target.get("counter", "-")), str(target.get("counter speed", "-"))]
	if i.hacks > 0:
		out += "  next hack      integrity %d  ·  firewall %d  ·  counter %d  ·  counter speed %s\n" % [int(round(float(target.get("integrity", 0)) * (1.0 - p.integrity))), int(round(float(target.get("firewall", 0)) * (1.0 - p.firewall))), int(round(float(target.get("counter", 0)) * (1.0 - p.counter))), str(snappedf(float(target.get("counter speed", 0)) * (1.0 - p["counter speed"]), 0.1))]
	out += "  [color=#666666]builds 2%% at a time, one stat per find, +1 hack each time all four match; at 10%% every find adds a hack (max %d)[/color]\n" % intel_max_hacks()
	out += "[color=#666666]gather more with: decode -intel=%s%s[/color]" % [target.name.to_lower().replace(" (hard)", "").replace(" ", "-"), " hard" if hard else ""]
	return out

func intel_list_text(location_filter: String = "") -> String:
	var out = "INTEL  [color=#666666]·  intel <location>  ·  intel <target>  ·  gather with decode -intel=<target>  ·  intel -h for help[/color]\n"
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
func get_drop_table(cache: CacheData, process: Dictionary = {}, exploit_mult: float = 1.0) -> Array:
	var rows = []
	for e in cache.entries:
		var r = _entry_range(cache, e)
		var y = yield_multiplier() * compression_multiplier() * efficiency_basic_mult(process if !process.is_empty() else CACHE) if is_basic_item(e.item) else 1.0
		rows.append({"name": e.item.name, "min": int(ceil(r.x * y)), "max": int(ceil(r.y * y)), "chance": _entry_chance(cache, e), "rare": false})
	if cache == Items.VM_CACHE:
		return [{"name": "Random VM token (per line, %d lines)" % VM_CACHE_LINES, "min": VM_CACHE_MIN, "max": VM_CACHE_MAX, "chance": VM_CACHE_LINE_CHANCE, "rare": false}]
	rows.append({"name": Items.VM_CACHE.name, "min": 1, "max": 1, "chance": VM_CACHE_CHANCE, "rare": false})
	if cache.get_variant() == CacheData.CacheVariant.NETWORK:
		rows.append({"name": "Random VM token", "min": CacheData.NETWORK_VM_MIN, "max": CacheData.NETWORK_VM_MAX, "chance": CacheData.NETWORK_VM_CHANCE, "rare": false})
	var rare_chance = get_cache_rare_chance(cache, get_rare_chance(process, cache))
	if rare_chance > 0.0:
		for e in cache.rare_pool:
			rows.append({"name": e.item.name, "min": _rare_amount(cache), "max": _rare_amount(cache), "chance": rare_chance, "rare": true})
	rows.append_array(Exploits.drop_rows(cache, process, exploit_mult))
	return rows

## Rolls one decode: [{item, amount, rare}] with the rare item (if any) last.
## <process> decides the rare chance (Skim: none, Deep Scan: +15%); Skim's efficiency can add +50% basics.
## Yield multiplies basics, the Rare Tracker adds to the rare chance, <mod> is the terminal's modifier
## command (forensics: one-time item chance x2, survey: half loot).
## VM cache: every other cache has VM_CACHE_CHANCE to drop one (the tutorial's first Student cache always
## does). Decoding a VM cache: each of its VM_CACHE_LINES lines has VM_CACHE_LINE_CHANCE at
## VM_CACHE_MIN..MAX tokens of a random skill (equal odds). Not parsable.
const VM_CACHE_CHANCE := 0.4 # 2026-10-22: was 20%
const VM_CACHE_LINES := 5
const VM_CACHE_LINE_CHANCE := 0.5
const VM_CACHE_MIN := 1
const VM_CACHE_MAX := 3
func roll_vm_cache() -> Array:
	var loot = []
	for i in VM_CACHE_LINES:
		if randf() < VM_CACHE_LINE_CHANCE:
			loot.append({"item": vm_tokens().pick_random(), "amount": randi_range(VM_CACHE_MIN, VM_CACHE_MAX), "rare": false})
	return loot

func roll_loot(cache: CacheData, process: Dictionary = {}, mod: String = "") -> Array:
	if process.is_empty():
		process = CACHE
	if cache == Items.VM_CACHE:
		return roll_vm_cache()
	var basic_mult = (1.5 if (process == SKIM and randf() < get_efficiency(SKIM)) else 1.0) * yield_multiplier() * compression_multiplier() * efficiency_basic_mult(process)
	var loot = []
	for e in cache.entries:
		if randf() <= _entry_chance(cache, e):
			var r = _entry_range(cache, e)
			var amount = randi_range(r.x, r.y)
			if is_basic_item(e.item):
				amount = int(ceil(amount * basic_mult))
			loot.append({"item": e.item, "amount": amount, "rare": false})
	if randf() < VM_CACHE_CHANCE:
		loot.append({"item": Items.VM_CACHE, "amount": 1, "rare": false})
	if cache.get_variant() == CacheData.CacheVariant.NETWORK and randf() <= CacheData.NETWORK_VM_CHANCE:
		loot.append({"item": vm_tokens().pick_random(), "amount": randi_range(CacheData.NETWORK_VM_MIN, CacheData.NETWORK_VM_MAX), "rare": false})
	var rare_chance = get_cache_rare_chance(cache, get_rare_chance(process, cache)) if !cache.rare_pool.is_empty() else 0.0
	if rare_chance > 0.0:
		var got = randf() < rare_chance
		note_rare_roll(cache, got)
		if got:
			loot.append({"item": cache.rare_pool.pick_random().item, "amount": _rare_amount(cache), "rare": true})
	for ex in Exploits.roll_drops(cache, process, FORENSICS_EXPLOIT_MULT if mod == "forensics" else 1.0):
		loot.append({"item": ex, "amount": 1, "rare": true})
	if mod == "survey":
		var kept = []
		for d in loot:
			d.amount = survey_half(d.amount)
			if d.amount > 0:
				kept.append(d)
		loot = kept
	return loot
#endregion
