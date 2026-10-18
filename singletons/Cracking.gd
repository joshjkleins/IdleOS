extends Node

signal pw_cycle_completed
signal pin_cycle_completed
signal xp_gained
signal cracking_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_CRACKING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0

## Modifier commands unlocked by Cracking capstones (see Mining.MODIFIERS for how they work).
const MODIFIERS = [
	{"command": "crossref", "name": "Cross-Reference", "package": "cracking.cross_reference", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each crack has a 10% chance to also produce the tier's matched item."},
	{"command": "analyze", "name": "Analyze", "package": "cracking.analyze", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Instant-crack chance x2 and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "cracking.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half output, +100% Cracking XP."},
]
const CROSSREF_CHANCE := 0.10
## Cryo Rig: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "cracking.cryo_rig"
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/pw_cracking_terminal.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Cracking",
	"level": 1,
	"experience": 0,
	"color": Color("#F2600C"),
	"level up signal": cracking_level_up_signal,
	"efficiency description": "Chance to instantly crack encryption",
	"command": "cd cracking",
	"sfx": "cracking_item_received"
}

## Tiers follow the hacking locations: School > Lawfirm > Hospital > Bank > Police > Government.
## Pacing follows Mining: each tier cracks 1.5x slower, tuned for +50% cracking speed per tier from upgrades.
## VM (token exchange) is a utility outside the tiers.
var PASSWORD = {
	"name": "Password",
	"tier name": "TIER I | PASSWORD",
	"level": 1,
	"experience": 0,
	"experience per level": 48, # xp per item cracked
	"command": "crack -password",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 3.0, # seconds per character (4 per crack)
	"overclock speed": 1.5,
	"overheat speed": 7.5,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"vm token chance": 0.01, # per crack; scales with crack length so tokens/hour stay level
	"requirements": {Items.ENCRYPTED_PASSWORDS: 1},
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"crack boxes": "word",
	"description": "Cracks encrypted passwords, transforming them into passwords.",
	"efficiency description": "Chance to instantly crack (BYPASSED)",
	"signal": pw_cycle_completed
}

var SIGNATURE = {
	"name": "Signature",
	"tier name": "TIER II | SIGNATURE",
	"level": 1,
	"experience": 0,
	"experience per level": 110, # xp per item cracked
	"command": "crack -signature",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 4.5, # seconds per character (4 per crack)
	"overclock speed": 2.25,
	"overheat speed": 11.25,
	"heat": 2.4,
	"overclock heat": 2.85,
	"overheat heat": 0.45,
	"vm token chance": 0.015, # per crack; scales with crack length so tokens/hour stay level
	"requirements": {Items.ENCRYPTED_SIGNATURE: 1},
	"resource gained": Items.DIGITAL_SIGNATURE,
	"resource amount gained": 1,
	"crack boxes": "hex",
	"description": "Cracks encrypted signatures, recovering a forgeable digital signature.",
	"efficiency description": "Chance to instantly crack (BYPASSED)",
	"signal": pw_cycle_completed
}

var BADGE = {
	"name": "Badge",
	"tier name": "TIER III | BADGE",
	"level": 1,
	"experience": 0,
	"experience per level": 215, # xp per item cracked
	"command": "crack -badge",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 30,
	"base speed": 6.75, # seconds per character (4 per crack)
	"overclock speed": 3.375,
	"overheat speed": 16.875,
	"heat": 3.6,
	"overclock heat": 4.27,
	"overheat heat": 0.67,
	"vm token chance": 0.0225, # per crack; scales with crack length so tokens/hour stay level
	"requirements": {Items.ENCRYPTED_BADGE_HASH: 1},
	"resource gained": Items.BADGE_HASH,
	"resource amount gained": 1,
	"crack boxes": "badge",
	"description": "Cracks encrypted badge hashes, recovering staff badge hashes.",
	"efficiency description": "Chance to instantly crack (BYPASSED)",
	"signal": pw_cycle_completed
}

var PIN = {
	"name": "PIN",
	"tier name": "TIER IV | PIN",
	"level": 1,
	"experience": 0,
	"experience per level": 375, # xp per item cracked
	"command": "crack -pin",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 45,
	"base speed": 10.0, # seconds per character (4 per crack)
	"overclock speed": 5.0,
	"overheat speed": 25.0,
	"heat": 5.33,
	"overclock heat": 6.33,
	"overheat heat": 1.0,
	"vm token chance": 0.0333, # per crack; scales with crack length so tokens/hour stay level
	"requirements": {Items.ENCRYPTED_PINS: 1},
	"resource gained": Items.PINS,
	"resource amount gained": 1,
	"crack boxes": "digits",
	"description": "Cracks encrypted PINs, transforming them into PINs.",
	"efficiency description": "Chance to instantly crack (BYPASSED)",
	"signal": pw_cycle_completed
}

var KEYS = {
	"name": "Keys",
	"tier name": "TIER V | KEYS",
	"level": 1,
	"experience": 0,
	"experience per level": 625, # xp per item cracked
	"command": "crack -keys",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 60,
	"base speed": 15.0, # seconds per character (4 per crack)
	"overclock speed": 7.5,
	"overheat speed": 37.5,
	"heat": 8.0,
	"overclock heat": 9.5,
	"overheat heat": 1.5,
	"vm token chance": 0.05, # per crack; scales with crack length so tokens/hour stay level
	"requirements": {Items.ENCRYPTED_SSH_KEY: 1},
	"resource gained": Items.PRIVATE_KEYS,
	"resource amount gained": 1,
	"crack boxes": "base64",
	"description": "Cracks encrypted SSH keys, recovering private keys.",
	"efficiency description": "Chance to instantly crack (BYPASSED)",
	"signal": pw_cycle_completed
}

var BIOMETRIC = {
	"name": "Biometric",
	"tier name": "TIER VI | BIOMETRIC",
	"level": 1,
	"experience": 0,
	"experience per level": 1000, # xp per item cracked
	"command": "crack -biometric",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 75,
	"base speed": 22.5, # seconds per character (4 per crack)
	"overclock speed": 11.25,
	"overheat speed": 56.25,
	"heat": 12.0,
	"overclock heat": 14.25,
	"overheat heat": 2.25,
	"vm token chance": 0.075, # per crack; scales with crack length so tokens/hour stay level
	"requirements": {Items.ENCRYPTED_BIO_HASH: 1},
	"resource gained": Items.BIO_TEMPLATE,
	"resource amount gained": 1,
	"crack boxes": "genome",
	"description": "Cracks encrypted biometric hashes, rebuilding biometric templates.",
	"efficiency description": "Chance to instantly crack (BYPASSED)",
	"signal": pw_cycle_completed
}

var VM = {
	"name": "VM",
	"tier name": "UTILITY | VM",
	"level": 1,
	"experience": 0,
	"experience per level": 48,
	"command": "crack -vm",
	"ssh command": "ssh cracking vm",
	"display command": "crack -vm use=<skill> create=<skill>",
	"example commands": [
		{'cmd': 'crack -vm use=mining create=phishing', 'description': 'Uses 3 VM Mining Tokens to create 1 VM Phishing Token'}
	],
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 5,
	"base speed": 3.0,
	"overclock speed": 1.5,
	"overheat speed": 7.5,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"vm token chance": 0.0, # it's already trading tokens
	"requirements": "VM Token x 3",
	"resource gained": "VM Token x 1",
	"resource amount gained": 1,
	"crack boxes": "vm",
	"description": "Cracks 3 VM Tokens of one skill into 1 VM Token of another, so a stockpile of one can go where you need it.",
	"efficiency description": "Chance to instantly crack VM Token",
	"signal": pw_cycle_completed
}

var minor_processes = [
	PASSWORD,
	SIGNATURE,
	BADGE,
	PIN,
	KEYS,
	BIOMETRIC,
	VM
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

#var process_upgrades = {
	#"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
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

#Cracking.get_vm_cracking_word(create_token)
func get_vm_cracking_word(vm_token: ItemData) -> String:
	match vm_token:
		Mining.vm_token:
			return "MINE"
		Parsing.vm_token:
			return "PRSE"
		Cracking.vm_token:
			return "CRCK"
		Matching.vm_token:
			return "MTCH"
		Phishing.vm_token:
			return "PHSH"
		Decoding.vm_token:
			return "DCOD"
		Compiling.vm_token:
			return "COMP"
		_:
			return "0000"

func has_requirements(minor_process) -> bool:
	if Inventory.get_amount(minor_process["requirements"].keys()[0]) > 0:
		return true
	return false

func missing_requirements_text(minor_process) -> String:
	return "Missing " + minor_process["requirements"].keys()[0].name

func create_vm_window(minor_process, use_token: ItemData = null, create_token: ItemData = null) -> VMWindow:
	var setup = func(t):
		t.set_cracking_type(minor_process, true, use_token, create_token)
		t.start()
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, true)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"password_level": PASSWORD["level"],
		"password_experience": PASSWORD["experience"],
		"password_efficiency": PASSWORD["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	PASSWORD["level"] = int(data.get("password_level", PASSWORD["level"]))
	PASSWORD["experience"] = int(data.get("password_experience", PASSWORD["experience"]))
	PASSWORD["efficiency"] = float(data.get("password_efficiency", PASSWORD["efficiency"]))
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)


var random_four_digit_words: Array = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]
