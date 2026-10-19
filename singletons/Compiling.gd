extends Node

signal compile_cycle_complete
signal xp_gained
signal compile_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_COMPILING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/compiling_terminal.tscn")

## Modifier commands unlocked by Compiling capstones (see Mining.MODIFIERS for how they work).
## Access refuses every modifier; Debug only works on Mod (see compiling_terminal.modifier_block_reason).
const MODIFIERS = [
	{"command": "debug", "name": "Debug", "package": "compiling.debug_build", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Mods compiled with it can be built up to +50% more hacks (Mod only)."},
	{"command": "optimize", "name": "Optimize", "package": "compiling.optimize", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Burst chance x2 and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "compiling.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half output, +100% Compiling XP."},
]
## Cold Build: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "compiling.cold_build"
const DEBUG_DURATION_MULT := 1.5
const BURST_SPEED := 100.0   # fill speed multiplier during a burst
const BURST_SECONDS := 1.0
const MOD_SQL_PER_TIER := 10 # SQL Injectors per full mod, x the item's tier (split across its hacks)
const ACCESS_STAGES_BASE := 10 # stages for a location's second target; +STEP per target after
const ACCESS_STAGES_STEP := 5

## Process efficiency with the Efficiency track: +X% of the process's own (burst) chance, x1.20 at max.
func get_efficiency(p: Dictionary) -> float:
	return float(p["efficiency"]) * (1.0 + Upgrades.cur("compiling.efficiency"))

#region mod (one fill = one hack of duration)
## Per-fill cost of building a mod from <item>: its full cost split over its hacks, plus SQL Injectors.
func mod_fill_cost(item: ItemData) -> Dictionary:
	var dur = max(1, item.hacking_mod_duration)
	var out = {item: int(ceil(float(item.hacking_mod_consumed) / dur))}
	var sql = int(ceil(float(MOD_SQL_PER_TIER * max(1, item.tier)) / dur))
	if item == Items.SQL_INJECTOR:
		out[item] += sql
	else:
		out[Items.SQL_INJECTOR] = sql
	return out

## Most hacks a mod built from <item> can reach (Debug: +50%)
func mod_cap(item: ItemData, debug: bool = false) -> int:
	return int(round(item.hacking_mod_duration * (DEBUG_DURATION_MULT if debug else 1.0)))

func can_afford(cost: Dictionary) -> bool:
	for item in cost:
		if Inventory.get_amount(item) < cost[item]:
			return false
	return true

## "School payload 11/1, Parents credit card 0/5" (missing amounts in red unless <plain>, for plain Labels)
func cost_text(cost: Dictionary, plain: bool = false) -> String:
	var parts = []
	for item in cost:
		var have = Inventory.get_amount(item)
		parts.append(("%s %d/%d" if (have >= cost[item] or plain) else "%s [color=red]%d/%d[/color]") % [item.name, have, cost[item]])
	return ", ".join(parts)

## Validates compile -mod=<item>: {"ok", "message", "item"}. Shared by the main terminal and 'ssh compiling mod=...'.
func check_mod(item_text: String, example: String = "compile -mod=logs") -> Dictionary:
	var out = {"ok": false, "message": "", "item": null}
	if item_text.strip_edges() == "":
		out.message = "Name an item to build a mod from. [color=#666666]ex. %s  ('ls <item>' shows its mod)[/color]" % example
		return out
	var item = Inventory.get_item_by_name(item_text.strip_edges())
	if item == null:
		out.message = "Item not recognized. [color=#666666]ex. %s[/color]" % example
		return out
	if item.hacking_mod_item:
		out.message = "%s is already a hacking mod: equip it with 'mod -add'." % item.name
		return out
	if !item.is_compilable_mod():
		out.message = item.name + " cannot be compiled into a Hacking Mod."
		return out
	var cost = mod_fill_cost(item)
	if !can_afford(cost):
		out.message = "Each hack of a %s mod costs %s." % [item.name, cost_text(cost)]
		return out
	var t = item.hacking_mod_type
	if HackingMods.has_mod(t):
		var top = mod_cap(item, Upgrades.has("compiling.debug_build"))
		if int(HackingMods.current_mods[t].duration) >= top:
			out.message = "Your %s mod is already at its max of %d hacks." % [HackingMods.get_mod_name(t), top]
			return out
	elif HackingMods.at_max_mods():
		out.message = "All mod slots are in use. Use the 'mod' command to manage active Hacking Mods."
		return out
	out.item = item
	out.ok = true
	return out
#endregion

#region access (staged, progress saved per target)
var access_progress := {} # Stats.target_key -> stages done

func access_stages(target: Dictionary) -> int:
	var p = Stats.target_place(target)
	var index = int(p.get("index", 1))
	return ACCESS_STAGES_BASE + ACCESS_STAGES_STEP * max(0, index - 1)

func access_done(target: Dictionary) -> int:
	return int(access_progress.get(Stats.target_key(target), 0))

## What stage <stage> (0-based) consumes: the payloads are spread over the stages, the rare items are
## only taken by the final stage.
func access_stage_cost(target: Dictionary, stage: int) -> Dictionary:
	var r = Stats.get_access_recipe(target)
	if r.is_empty() or r.rare == null:
		return {}
	var n = access_stages(target)
	var total = int(r.payload_amount)
	var pay = int(floor(float(stage + 1) * total / n)) - int(floor(float(stage) * total / n))
	var out = {}
	if pay > 0:
		out[r.payload] = pay
	if stage == n - 1:
		out[r.rare] = int(r.rare_amount)
	return out

## Called when a stage finishes; returns true when it was the final one (the target unlocks).
func complete_access_stage(target: Dictionary) -> bool:
	var key = Stats.target_key(target)
	access_progress[key] = access_done(target) + 1
	SaveManager.mark_dirty()
	if access_progress[key] >= access_stages(target):
		access_progress.erase(key)
		Stats.unlock_target(target)
		return true
	return false
#endregion

#GENERAL MODULE DATA
var SKILL = {
	"name": "Compiling",
	"level": 1,
	"experience": 0,
	"color": Color("#8B5CF6"),
	"level up signal": compile_level_up_signal,
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"command": "cd compiling",
	"sfx": "compiling_item_received"
}

## Tiers follow the hacking locations: School > Lawfirm > Hospital > Bank > Police > Government.
## Each payload = that tier's address (Parsing) + its matched item (Matching).
## Pacing follows Mining: each tier compiles 1.5x slower, tuned for +50% compiling speed per tier from upgrades.
## Mod (hacking mods) is a utility outside the tiers.
var SCHOOL = {
	"name": "School",
	"tier name": "TIER I | SCHOOL",
	"level": 1,
	"experience": 0,
	"experience per level": 40, # xp per payload
	"command": "compile -school",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 10.0, # bar fill per second (100 = one payload)
	"overclock speed": 20.0,
	"overheat speed": 4.0,
	"heat": 1.5,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"vm token chance": 0.01, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.IP_ADDRESS: 1,
		Items.CREDENTIALS: 1
	},
	"resource gained": Items.SCHOOL_PAYLOAD,
	"description": "Compiles a School payload from its address and matched access, used to hack School targets.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

var LAWFIRM = {
	"name": "Lawfirm",
	"tier name": "TIER II | LAWFIRM",
	"level": 1,
	"experience": 0,
	"experience per level": 93, # xp per payload
	"command": "compile -lawfirm",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 6.667, # bar fill per second (100 = one payload)
	"overclock speed": 13.333,
	"overheat speed": 2.667,
	"heat": 2.25,
	"overclock heat": 2.85,
	"overheat heat": 0.45,
	"vm token chance": 0.015, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.EMAIL_HEADER: 1,
		Items.SIGNED_CERTIFICATE: 1
	},
	"resource gained": Items.LAWFIRM_PAYLOAD,
	"description": "Compiles a Lawfirm payload from its address and matched access, used to hack Lawfirm targets.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

var HOSPITAL = {
	"name": "Hospital",
	"tier name": "TIER III | HOSPITAL",
	"level": 1,
	"experience": 0,
	"experience per level": 180, # xp per payload
	"command": "compile -hospital",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 30,
	"base speed": 4.444, # bar fill per second (100 = one payload)
	"overclock speed": 8.889,
	"overheat speed": 1.778,
	"heat": 3.38,
	"overclock heat": 4.27,
	"overheat heat": 0.67,
	"vm token chance": 0.0225, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.MAC_ADDRESS: 1,
		Items.ACCESS_BADGE: 1
	},
	"resource gained": Items.HOSPITAL_PAYLOAD,
	"description": "Compiles a Hospital payload from its address and matched access, used to hack Hospital targets.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

var BANK = {
	"name": "Bank",
	"tier name": "TIER IV | BANK",
	"level": 1,
	"experience": 0,
	"experience per level": 314, # xp per payload
	"command": "compile -bank",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 45,
	"base speed": 2.963, # bar fill per second (100 = one payload)
	"overclock speed": 5.926,
	"overheat speed": 1.185,
	"heat": 5.06,
	"overclock heat": 6.41,
	"overheat heat": 1.01,
	"vm token chance": 0.0338, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.ROUTING_NUMBER: 1,
		Items.ACCOUNT_ACCESS_TOKENS: 1
	},
	"resource gained": Items.BANK_PAYLOAD,
	"description": "Compiles a Bank payload from its address and matched access, used to hack Bank targets.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

var POLICE = {
	"name": "Police",
	"tier name": "TIER V | POLICE",
	"level": 1,
	"experience": 0,
	"experience per level": 527, # xp per payload
	"command": "compile -police",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 60,
	"base speed": 1.975, # bar fill per second (100 = one payload)
	"overclock speed": 3.951,
	"overheat speed": 0.79,
	"heat": 7.59,
	"overclock heat": 9.62,
	"overheat heat": 1.52,
	"vm token chance": 0.0506, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.SUBNET_MAP: 1,
		Items.OFFICER_AUTH_KEYS: 1
	},
	"resource gained": Items.POLICE_PAYLOAD,
	"description": "Compiles a Police payload from its address and matched access, used to hack Police targets.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

var GOVERNMENT = {
	"name": "Government",
	"tier name": "TIER VI | GOVERNMENT",
	"level": 1,
	"experience": 0,
	"experience per level": 840, # xp per payload
	"command": "compile -government",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 75,
	"base speed": 1.317, # bar fill per second (100 = one payload)
	"overclock speed": 2.634,
	"overheat speed": 0.527,
	"heat": 11.39,
	"overclock heat": 14.43,
	"overheat heat": 2.28,
	"vm token chance": 0.0759, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.GATEWAY_ADDRESS: 1,
		Items.SECURITY_CLEARANCE: 1
	},
	"resource gained": Items.GOVERNMENT_PAYLOAD,
	"description": "Compiles a Government payload from its address and matched access, used to hack Government targets.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

## ACCESS: unlocks the next hacking target of a location (one-time per target). The cost comes from
## Stats.get_access_recipe(): 5 of the previous target's rare item + that location's payloads.
var ACCESS = {
	"name": "Access",
	"tier name": "UTILITY | ACCESS",
	"level": 1,
	"experience": 0,
	"experience per level": 30, # per stage
	"command": "compile -access",
	"ssh command": "ssh compiling access",
	"display command": "compile -access=<target>",
	"example commands": [
		{'cmd': 'compile -access=administrator', 'description': 'Compiles access to the Administrator in 10 stages (progress is saved): 1 School payload per stage, 5 Parents credit cards at the final stage'},
	],
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 3.333, # bar fill per second (100 = one stage, ~30 s)
	"overclock speed": 6.667,
	"overheat speed": 1.333,
	"heat": 3.0,
	"overclock heat": 3.8,
	"overheat heat": 0.6,
	"vm token chance": 0.0,
	"requirements": "Payloads per stage + the previous target's rare item x5 at the final stage",
	"resource gained": "Access to the next target",
	"description": "Compiles access to the next hacking target at a location in stages (10 for the second target, +5 per target after; progress is saved). Each stage uses some of the location's payloads; the final stage also takes 5 of the previous target's rare item.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

## Validates compile -access=<name>: {"ok", "message", "target", "requirements": {item: amount}}
func check_access(target_name: String) -> Dictionary:
	var out = {"ok": false, "message": "", "target": {}, "requirements": {}}
	var t = Stats.find_target_by_name(target_name)
	if target_name.strip_edges() == "" or t.is_empty():
		out.message = "Name a target. [color=#666666]ex. compile -access=administrator[/color]"
		return out
	if t.get("unlocked", false):
		out.message = t.name + " is already unlocked."
		return out
	var p = Stats.target_place(t)
	if !Stats.hacking_targets[p.location].get("unlocked", false):
		out.message = "%s is in a locked location: %s." % [t.name, Stats.get_location_unlock_hint(p.location)]
		return out
	var r = Stats.get_access_recipe(t)
	if r.is_empty() or r.rare == null:
		out.message = t.name + " " + Stats.get_unlock_hint(t) + "."
		return out
	var stage = access_done(t)
	out.requirements = access_stage_cost(t, stage)
	if !can_afford(out.requirements):
		var final = stage == access_stages(t) - 1
		out.message = "Access to %s, stage %d/%d%s needs: %s" % [t.name, stage + 1, access_stages(t), " (final)" if final else "", cost_text(out.requirements)]
		return out
	out.target = t
	out.ok = true
	return out

var MOD = {
	"name": "Mod",
	"tier name": "UTILITY | MOD",
	"level": 1,
	"experience": 0,
	"experience per level": 20, # per hack compiled
	"command": "compile -mod",
	"ssh command": "ssh compiling mod",
	"display command": "compile -mod=<item>",
	"example commands": [
		{'cmd': 'compile -mod=logs', 'description': 'Builds a Logs mod one hack per fill (20 Logs + 2 SQL Injectors each), up to 5 hacks.'},
		{'cmd': 'compile -mod=ip address', 'description': 'Builds an IP address mod the same way. Stop any time: the hacks built so far stay.'}
	],
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 3,
	"base speed": 10.0, # bar fill per second (100 = one hack of duration, ~10 s)
	"overclock speed": 15.0,
	"overheat speed": 5.0,
	"heat": 4.0,
	"overclock heat": 6.0,
	"overheat heat": 0.3,
	"vm token chance": 0.002,
	"requirements": "Per hack: the item's cost / its hacks + SQL Injectors (10 x tier per full mod). 'ls <item>' shows its mod.",
	"resource gained": "Temporary Hacking Modification",
	"description": "Builds a hacking mod one hack at a time: the first fill equips it, each fill after adds a hack, up to the item's duration. Stop any time and keep what's built; an equipped mod of the same type gets topped up.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

## The six location payload recipes (School ... Government), without the ACCESS / MOD utilities.
func get_payload_processes() -> Array:
	return minor_processes.filter(func(p): return p != MOD and p != ACCESS)

var minor_processes = [
	SCHOOL,
	LAWFIRM,
	HOSPITAL,
	BANK,
	POLICE,
	GOVERNMENT,
	ACCESS,
	MOD
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


func has_requirements(minor_process) -> bool:
	for req in minor_process.requirements:
		if Inventory.get_amount(req.item) < req.amount:
			return false
	return true

func missing_requirements_text(minor_process) -> String:
	var text = ""
	for req in minor_process.requirements:
		if Inventory.get_amount(req.item) < req.amount:
			text += "Missing " + req.item.name + " x" + str(req.amount) + "\n"
	return text

#func get_upgrade_cost(upgrade_stat: String) -> int:
	#return process_upgrades[upgrade_stat]["level"] * 800 + 100

#func upgraded(upgrade_stat: Dictionary):
	#upgrade_stat["level"] += 1
	#upgrade_stat["amount"] += upgrade_stat["increase per level"]
	#
	#if upgrade_stat["name"].to_lower() == "vm windows":
		#MAX_VMS += upgrade_stat["increase per level"]
	#if upgrade_stat["name"].to_lower() == "vm duration":
		#VM_UPTIME += upgrade_stat["increase per level"]

func create_vm_window(minor_process, item = null) -> VMWindow:
	var setup = func(t):
		t.start(minor_process, true, item)
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, true)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"school_level": SCHOOL["level"],
		"school_experience": SCHOOL["experience"],
		"school_efficiency": SCHOOL["efficiency"],
		"access_progress": access_progress,
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	SCHOOL["level"] = int(data.get("school_level", SCHOOL["level"]))
	SCHOOL["experience"] = int(data.get("school_experience", SCHOOL["experience"]))
	access_progress = {}
	var saved_access: Dictionary = data.get("access_progress", {})
	for k in saved_access:
		access_progress[k] = int(saved_access[k])
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)
