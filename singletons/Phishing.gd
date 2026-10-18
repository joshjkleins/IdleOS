extends Node

signal spear_cycle_completed
signal whale_cycle_completed
signal xp_gained
signal phishing_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_PHISHING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/phishing_terminal.tscn")

var max_lines: int = 3
var current_lines = []

#GENERAL MODULE DATA
var SKILL = {
	"name": "Phishing",
	"level": 1,
	"experience": 0,
	"color": Color("#3B82F6"),
	"level up signal": phishing_level_up_signal,
	"efficiency description": "Chance for successful bite",
	"command": "cd phishing",
	"sfx": "phishing_item_received"
}

var SPEAR = {
	"name": "Spear",
	"tier name": "TIER I | SPEAR",
	"level": 1,
	"experience": 0,
	"experience per level": 60,
	"command": "phish -spear",
	"display command": "phish -spear [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -spear', 'description': 'Cast every line' },
		{ 'cmd': 'phish -spear bait=logs', 'description': 'Each cast uses 1 Mining item: bite chance x1.10 (Logs) up to x1.35 (Databases)' },
	],
	"efficiency": 0.3,
	"efficiency rate": 0.005,
	"unlocked": true,
	"unlock level": 1,
	"cast time": 2.0,
	"overclock cast time": 1.0,
	"overheat cast time": 7.0,
	"wait time min": 5.0,
	"wait time max": 10.0,
	"download time": 7.5,
	"overclocked download time": 3.75,
	"overheated download time": 22.5,
	"heat": 0.3,
	"overclock heat": 0.6,
	"overheat heat": 0.1,
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 90 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 1, "weight": 10 },
	],
	"resource amount gained": 1,
	"description": "Harvest SQL Injectors and Packet Spoofs through targeted phishing emails",
	"efficiency description": "Chance for successful bite",
	"signal": spear_cycle_completed
}


var MOD = {
	"name": "Mod",
	"tier name": "TIER II | MOD",
	"level": 1,
	"experience": 0,
	"experience per level": 1000,
	"command": "phish -mod",
	"display command": "phish -mod [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -mod', 'description': 'Cast every line' },
		{ 'cmd': 'phish -mod bait=logs', 'description': 'Each cast uses 1 Mining item: bite chance x1.10 (Logs) up to x1.35 (Databases)' },
	],
	"efficiency": 0.001,
	"efficiency rate": 0.0001,
	"unlocked": false,
	"unlock level": 5,
	"cast time": 4.0,
	"overclock cast time": 1.5,
	"overheat cast time": 9.0,
	"wait time min": 7.0,
	"wait time max": 13.0,
	"download time": 35.0,
	"overclocked download time": 27.5,
	"overheated download time": 75.5,
	"heat": 0.3,
	"overclock heat": 0.6,
	"overheat heat": 0.1,
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_BOOSTER, "min": 1, "max": 1, "weight": 100 },
	],
	"resource amount gained": 1,
	"description": "A risky phishing attempt with a slim chance of uncovering a powerful Hacking Modification.",
	"efficiency description": "Chance for successful bite",
	"signal": spear_cycle_completed
}

var WHALING = {
	"name": "Whaling",
	"tier name": "TIER III | WHALING",
	"level": 1,
	"experience": 0,
	"experience per level": 230,
	"command": "phish -whale",
	"display command": "phish -whale [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -whale', 'description': 'Cast every line' },
		{ 'cmd': 'phish -whale bait=logs', 'description': 'Each cast uses 1 Mining item: bite chance x1.10 (Logs) up to x1.35 (Databases)' },
	],
	"efficiency": 0.25,
	"efficiency rate": 0.005,
	"unlocked": false,
	"unlock level": 15,
	# PLACEHOLDER: same catches as Spear until this tier's role is designed; paced like the other skills
	"cast time": 3.0,
	"overclock cast time": 1.5,
	"overheat cast time": 7.5,
	"wait time min": 7.5,
	"wait time max": 15.0,
	"download time": 11.25,
	"overclocked download time": 5.62,
	"overheated download time": 28.12,
	"heat": 0.45,
	"overclock heat": 0.9,
	"overheat heat": 0.15,
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 95 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 1, "weight": 5 },
	],
	"resource amount gained": 1,
	"description": "Targets high level individuals for a chance to extract PINs and account numbers",
	"efficiency description": "Chance for successful bite",
	"signal": whale_cycle_completed
}

var SMISH = {
	"name": "Smish",
	"tier name": "TIER IV | SMISH",
	"level": 1,
	"experience": 0,
	"experience per level": 800,
	"command": "phish -smish",
	"display command": "phish -smish [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -smish', 'description': 'Cast every line' },
		{ 'cmd': 'phish -smish bait=logs', 'description': 'Each cast uses 1 Mining item: bite chance x1.10 (Logs) up to x1.35 (Databases)' },
	],
	"efficiency": 0.2,
	"efficiency rate": 0.005,
	"unlocked": false,
	"unlock level": 35,
	# PLACEHOLDER: same catches as Spear until this tier's role is designed; paced like the other skills
	"cast time": 4.5,
	"overclock cast time": 2.25,
	"overheat cast time": 11.25,
	"wait time min": 11.25,
	"wait time max": 22.5,
	"download time": 16.88,
	"overclocked download time": 8.44,
	"overheated download time": 42.19,
	"heat": 0.67,
	"overclock heat": 1.35,
	"overheat heat": 0.23,
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 95 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 1, "weight": 5 },
	],
	"resource amount gained": 1,
	"description": "Targets high level individuals for a chance to extract PINs and account numbers",
	"efficiency description": "Chance for successful bite",
	"signal": whale_cycle_completed
}

var TRAP = {
	"name": "Trap",
	"tier name": "TIER V | TRAP",
	"level": 1,
	"experience": 0,
	"experience per level": 2300,
	"command": "phish -trap",
	"display command": "phish -trap [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -trap', 'description': 'Cast every line' },
		{ 'cmd': 'phish -trap bait=logs', 'description': 'Each cast uses 1 Mining item: bite chance x1.10 (Logs) up to x1.35 (Databases)' },
	],
	"efficiency": 0.15,
	"efficiency rate": 0.005,
	"unlocked": false,
	"unlock level": 55,
	# PLACEHOLDER: same catches as Spear until this tier's role is designed; paced like the other skills
	"cast time": 6.75,
	"overclock cast time": 3.38,
	"overheat cast time": 16.88,
	"wait time min": 16.88,
	"wait time max": 33.75,
	"download time": 25.31,
	"overclocked download time": 12.66,
	"overheated download time": 63.28,
	"heat": 1.01,
	"overclock heat": 2.02,
	"overheat heat": 0.34,
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 95 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 1, "weight": 5 },
	],
	"resource amount gained": 1,
	"description": "Targets high level individuals for a chance to extract PINs and account numbers",
	"efficiency description": "Chance for successful bite",
	"signal": whale_cycle_completed
}

## BAIT: any Mining item can be attached to a cast (phish -spear bait=logs). Each cast uses one and
## multiplies the bite chance: x1.10 for a tier 1 item (Logs), x1.15 for tier 2, ... x1.35 for tier 6.
## Multiplicative so rare catches (Mod) stay rare. Bite chance is capped at 100%.
const BAIT_BASE_BONUS = 0.05
const BAIT_BONUS_PER_TIER = 0.05

func is_bait(item: ItemData) -> bool:
	for mp in Mining.minor_processes:
		if mp["resource gained"] == item:
			return true
	return false

func get_bait_multiplier(bait: ItemData) -> float:
	return 1.0 + BAIT_BASE_BONUS + BAIT_BONUS_PER_TIER * bait.tier if bait else 1.0

## Splits "phish -spear bait=logs" into the command and the bait item. {"command", "bait", "error"}
func parse_bait(text: String) -> Dictionary:
	var out = {"command": text.strip_edges(), "bait": null, "error": ""}
	var at = text.find(" bait=")
	if at == -1:
		return out
	out.command = text.substr(0, at).strip_edges()
	var bait_name = text.substr(at + " bait=".length()).strip_edges()
	var bait = Inventory.get_item_by_name(bait_name)
	if bait == null:
		out.error = "Bait item not found: " + bait_name
	elif !is_bait(bait):
		out.error = bait.name + " can't be used as bait. Any Mining item works (logs, archives, metadata...)."
	else:
		out.bait = bait
	return out

var minor_processes = [
	SPEAR,
	MOD,
	WHALING,
	SMISH,
	TRAP,
]

func add_line(line):
	current_lines.append(line)

func remove_line(line):
	if current_lines.has(line):
		current_lines.erase(line)

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

#var process_upgrades = {
	#"max lines": { "id": 1, "name": "Max lines", "level": 0, "amount": 0, "increase per level": 1 },
	#"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
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

func has_requirements(_minor_process) -> bool:
	return true

func missing_requirements_text(_minor_process) -> String:
	return ""

func create_vm_window(minor_process, repeat, bait: ItemData = null) -> VMWindow:
	var setup = func(t):
		t.vm_cast_all_lines(minor_process, true, bait)
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, repeat)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"spear_level": SPEAR["level"],
		"spear_experience": SPEAR["experience"],
		"spear_efficiency": SPEAR["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	SPEAR["level"] = int(data.get("spear_level", SPEAR["level"]))
	SPEAR["experience"] = int(data.get("spear_experience", SPEAR["experience"]))
	SPEAR["efficiency"] = float(data.get("spear_efficiency", SPEAR["efficiency"]))
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)
