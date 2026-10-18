extends Node

signal log_cycle_completed
signal quality_log_cycle_completed
signal xp_gained
signal mining_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_MINING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0

## Modifier commands unlocked by Mining capstones ('<command>' on, '<command> -kill' off while a
## process runs in the main terminal). One modifier at a time per process, overclock included.
## speed: multiplies speed (0.5 = half speed). heat: multiplies heat (removed by COOL_PACKAGE).
const MODIFIERS = [
	{"command": "sift", "name": "Sift", "package": "mining.sift", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each cycle has a 15% chance to also find one of the tier's Parsing items."},
	{"command": "prospect", "name": "Prospect", "package": "mining.prospect", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Efficiency x2 and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "mining.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half resources, +100% Mining XP."},
]
const SIFT_CHANCE := 0.15
## Cool Bits: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "mining.cool_bits"
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/data_mining_terminal.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Mining",
	"level": 1,
	"experience": 0,
	"color": Color("#7A4A2E"),
	"level up signal": mining_level_up_signal,
	"efficiency description": "Chance to receive multiple resources. Greater than 100% efficiency yields guaranteed multiple resources.",
	"command": "cd mining",
	"sfx": "mining_item_received"
}

## Tiers follow the hacking locations: School > Lawfirm > Hospital > Bank > Police > Government.
## Pacing (see "experience per level" = xp per cycle): each tier's cycle is 1.5x longer than the last,
## tuned assuming +50% mining speed per tier from upgrades (T2 +50% ... T6 +250%). With those upgrades
## a level takes ~20-30 min from L15 to 99 on the main terminal; without them it's roughly half the XP rate.
var LOGS = {
	"name": "Logs",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 32,
	"command": "mine -logs",
	"efficiency": 0.0,
	"efficiency rate": 0.035, # 343% at L99, +100% from upgrades = ~443% at max
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.4,
	"overclock speed": 0.2,
	"overheat speed": 1.0,
	"heat": 0.8,
	"overclock heat": 1.5,
	"overheat heat": 0.3,
	"requirements": {},
	"resource gained": Items.LOGS,
	"resource amount gained": 1,
	"vm token chance": 0.01, # per cycle; scales with cycle length so tokens/hour stay level
	"description": "Finds logs that can be parsed for a random assortment of items.",
	"efficiency description": "Chance to receive multiple logs.",
	"signal": log_cycle_completed
}

var ARCHIVES = {
	"name": "Archives",
	"tier name": "TIER II | ARCHIVES",
	"level": 1,
	"experience": 0,
	"experience per level": 75,
	"command": "mine -archives",
	"efficiency": 0.0,
	"efficiency rate": 0.035, # 343% at L99, +100% from upgrades = ~443% at max
	"unlocked": false,
	"unlock level": 15,
	"base speed": 0.6,
	"overclock speed": 0.3,
	"overheat speed": 1.5,
	"heat": 1.2,
	"overclock heat": 2.25,
	"overheat heat": 0.45,
	"requirements": {},
	"resource gained": Items.ARCHIVES,
	"resource amount gained": 1,
	"vm token chance": 0.015, # per cycle; scales with cycle length so tokens/hour stay level
	"description": "Finds archives that can be Parsed through for resources or used as bait for Phishing.",
	"efficiency description": "Chance to receive multiple archives.",
	"signal": log_cycle_completed
}

var METADATA = {
	"name": "Metadata",
	"tier name": "TIER III | METADATA",
	"level": 1,
	"experience": 0,
	"experience per level": 145,
	"command": "mine -metadata",
	"efficiency": 0.0,
	"efficiency rate": 0.035, # 343% at L99, +100% from upgrades = ~443% at max
	"unlocked": false,
	"unlock level": 30,
	"base speed": 0.9,
	"overclock speed": 0.45,
	"overheat speed": 2.25,
	"heat": 1.8,
	"overclock heat": 3.38,
	"overheat heat": 0.67,
	"requirements": {},
	"resource gained": Items.METADATA,
	"resource amount gained": 1,
	"vm token chance": 0.0225, # per cycle; scales with cycle length so tokens/hour stay level
	"description": "Finds metadata that can be Parsed through for resources or used as bait for Phishing.",
	"efficiency description": "Chance to receive multiple metadata.",
	"signal": log_cycle_completed
}

var COOKIES = {
	"name": "Cookies",
	"tier name": "TIER IV | COOKIES",
	"level": 1,
	"experience": 0,
	"experience per level": 250,
	"command": "mine -cookies",
	"efficiency": 0.0,
	"efficiency rate": 0.035, # 343% at L99, +100% from upgrades = ~443% at max
	"unlocked": false,
	"unlock level": 45,
	"base speed": 1.35,
	"overclock speed": 0.675,
	"overheat speed": 3.375,
	"heat": 2.7,
	"overclock heat": 5.06,
	"overheat heat": 1.01,
	"requirements": {},
	"resource gained": Items.COOKIES,
	"resource amount gained": 1,
	"vm token chance": 0.0338, # per cycle; scales with cycle length so tokens/hour stay level
	"description": "Finds cookies that can be Parsed through for resources or used as bait for Phishing.",
	"efficiency description": "Chance to receive multiple cookies.",
	"signal": log_cycle_completed
}

var REPOSITORIES = {
	"name": "Repositories",
	"tier name": "TIER V | REPOSITORIES",
	"level": 1,
	"experience": 0,
	"experience per level": 415,
	"command": "mine -repos",
	"efficiency": 0.0,
	"efficiency rate": 0.035, # 343% at L99, +100% from upgrades = ~443% at max
	"unlocked": false,
	"unlock level": 60,
	"base speed": 2.0,
	"overclock speed": 1.0,
	"overheat speed": 5.0,
	"heat": 4.0,
	"overclock heat": 7.5,
	"overheat heat": 1.5,
	"requirements": {},
	"resource gained": Items.REPOSITORIES,
	"resource amount gained": 1,
	"vm token chance": 0.05, # per cycle; scales with cycle length so tokens/hour stay level
	"description": "Finds repositories of data that can be Parsed through for resources or used as bait for Phishing.",
	"efficiency description": "Chance to receive multiple repos.",
	"signal": log_cycle_completed
}

var DATABASES = {
	"name": "Databases",
	"tier name": "TIER VI | DATABASES",
	"level": 1,
	"experience": 0,
	"experience per level": 665,
	"command": "mine -databases",
	"efficiency": 0.0,
	"efficiency rate": 0.035, # 343% at L99, +100% from upgrades = ~443% at max
	"unlocked": false,
	"unlock level": 75,
	"base speed": 3.0,
	"overclock speed": 1.5,
	"overheat speed": 7.5,
	"heat": 6.0,
	"overclock heat": 11.25,
	"overheat heat": 2.25,
	"requirements": {},
	"resource gained": Items.DATABASES,
	"resource amount gained": 1,
	"vm token chance": 0.075, # per cycle; scales with cycle length so tokens/hour stay level
	"description": "Finds databases that can be Parsed through for resources or used as bait for Phishing.",
	"efficiency description": "Chance to receive multiple databases.",
	"signal": log_cycle_completed
}


var minor_processes = [
	LOGS,
	ARCHIVES,
	METADATA,
	COOKIES,
	REPOSITORIES,
	DATABASES
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

func has_requirements(_minor_process) -> bool:
	return true

func missing_requirements_text(_minor_process) -> String:
	return ""

func create_vm_window(minor_process, repeat) -> VMWindow:
	var setup = func(t):
		t.set_mine_type(minor_process, true)
		t.start_data_mining()
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, repeat)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"logs_level": LOGS["level"],
		"logs_experience": LOGS["experience"],
		"logs_efficiency": LOGS["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	LOGS["level"] = int(data.get("logs_level", LOGS["level"]))
	LOGS["experience"] = int(data.get("logs_experience", LOGS["experience"]))
	LOGS["efficiency"] = float(data.get("logs_efficiency", LOGS["efficiency"]))
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)
