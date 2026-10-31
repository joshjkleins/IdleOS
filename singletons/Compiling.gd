extends Node

## Heat plan: heat multiplier by the tier being worked on (see BaseTerminal.heat_tier_mult)
const HEAT_BY_TIER := [1.0, 1.387, 1.872, 2.55, 5.6, 7.5]

signal compile_cycle_complete
signal xp_gained
signal compile_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_COMPILING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0 # 2026-10-29: was 60
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/compiling_terminal.tscn")

## Modifier commands unlocked by Compiling capstones (see Mining.MODIFIERS for how they work).
## Debug (2026-10-23): payloads can come with intel (DEBUG_INTEL_CHANCE per payload, a random unlocked target
## of that payload's location gets 1 intel find, like decode -intel).
const MODIFIERS = [
	{"command": "debug", "name": "Debug", "package": "compiling.debug_build", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each payload has a 10% chance to also give 1 intel find on a target of its location."},
	{"command": "optimize", "name": "Optimize", "package": "compiling.optimize", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Burst chance x2 and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "compiling.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half output, +100% Compiling XP."},
]
const DEBUG_INTEL_CHANCE := 0.10

## Debug: 1 intel find on a random unlocked (normal) target of <payload_process>'s location. Returns the target or {}.
func debug_intel(payload_process: Dictionary) -> Dictionary:
	var tier = get_payload_processes().find(payload_process) + 1
	if tier <= 0:
		return {}
	var loc = Stats.hacking_targets.keys()[tier - 1]
	var pool = Stats.hacking_targets[loc].get("targets", []).filter(func(t): return t.get("unlocked", false) and !Decoding.is_intel_maxed(t))
	if pool.is_empty():
		return {}
	var t = pool.pick_random()
	Decoding.add_intel_point(t)
	return t

## Cold Build: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "compiling.cold_build"
const DEBUG_DURATION_MULT := 1.5
const BURST_SPEED := 100.0   # fill speed multiplier during a burst
const BURST_SECONDS := 1.0
const MOD_SQL_PER_TIER := 10 # SQL Injectors per full mod, x the item's tier (split across its hacks)

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
		out.message = "%s is already a hacking mod: manage it with the 'mod' command." % item.name
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
	"unlock tier": 1, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 1, # efficiency grows from this skill level (its old unlock level)
	"base speed": 10, # bar fill per second (100 = one payload)
	"overclock speed": 20,
	"overheat speed": 4,
	"heat": 1.35,
	"overclock heat": 1.71,
	"overheat heat": 0.27,
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
	"experience per level": 96, # xp per payload
	"command": "compile -lawfirm",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock tier": 2, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 15, # efficiency grows from this skill level (its old unlock level)
	"base speed": 6.4868, # bar fill per second (100 = one payload)
	"overclock speed": 12.9726,
	"overheat speed": 2.5949,
	"heat": 3.0929,
	"overclock heat": 3.9177,
	"overheat heat": 0.6186,
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
	"experience per level": 190, # xp per payload
	"command": "compile -hospital",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock tier": 3, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 30, # efficiency grows from this skill level (its old unlock level)
	"base speed": 4.2101, # bar fill per second (100 = one payload)
	"overclock speed": 8.4212,
	"overheat speed": 1.6844,
	"heat": 6.4404,
	"overclock heat": 8.1362,
	"overheat heat": 1.2766,
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
	"experience per level": 340, # xp per payload
	"command": "compile -bank",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock tier": 4, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 45, # efficiency grows from this skill level (its old unlock level)
	"base speed": 2.7351, # bar fill per second (100 = one payload)
	"overclock speed": 5.4702,
	"overheat speed": 1.0938,
	"heat": 14.5159,
	"overclock heat": 18.3887,
	"overheat heat": 2.8975,
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
	"experience per level": 586, # xp per payload
	"command": "compile -police",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock tier": 5, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 60, # efficiency grows from this skill level (its old unlock level)
	"base speed": 1.7775, # bar fill per second (100 = one payload)
	"overclock speed": 3.5559,
	"overheat speed": 0.711,
	"heat": 53.13,
	"overclock heat": 67.34,
	"overheat heat": 10.64,
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
	"experience per level": 959, # xp per payload
	"command": "compile -government",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock tier": 6, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 75, # efficiency grows from this skill level (its old unlock level)
	"base speed": 1.1538, # bar fill per second (100 = one payload)
	"overclock speed": 2.3077,
	"overheat speed": 0.4617,
	"heat": 119.6656,
	"overclock heat": 151.6045,
	"overheat heat": 23.9542,
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
		{'cmd': 'compile -mod=logs', 'description': 'Builds the Logs mod (a damage bonus), 1 hack per fill, until it is full'},
		{'cmd': 'compile -mod=ip address', 'description': 'Same for the IP address mod. Stop any time: hacks built so far stay'}
	],
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock tier": 99, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 3, # efficiency grows from this skill level (its old unlock level)
	"base speed": 10.0, # bar fill per second (100 = one hack of duration, ~10 s)
	"overclock speed": 15.0,
	"overheat speed": 5.0,
	"heat": 4.0,
	"overclock heat": 6.0,
	"overheat heat": 0.3,
	"vm token chance": 0.002,
	"requirements": "Some of the item + SQL Injectors for every hack built. 'ls <item>' shows its mod and cost.",
	"resource gained": "Temporary Hacking Modification",
	"description": "Turns an item into a hacking mod: a bonus that lasts a number of hacks. Every fill of the bar builds 1 hack of it; the first fill equips the mod, and it keeps building up to the item's max hacks. Stop whenever you like and keep what's built. Running it again on a mod you already have tops it back up.",
	"efficiency description": "Chance for a burst: 100x speed for 1 second, no heat.",
	"signal": compile_cycle_complete
}

## The six location payload recipes (School ... Government), without the MOD utility.
func get_payload_processes() -> Array:
	return minor_processes.filter(func(p): return p != MOD)

var minor_processes = [
	SCHOOL,
	LAWFIRM,
	HOSPITAL,
	BANK,
	POLICE,
	GOVERNMENT,
	# MOD retired 2026-10-23 ('compile -mod'): the dict stays for old saves / offline, but it isn't a process any more
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
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	SCHOOL["level"] = int(data.get("school_level", SCHOOL["level"]))
	SCHOOL["experience"] = int(data.get("school_experience", SCHOOL["experience"]))
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)
