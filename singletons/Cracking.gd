extends Node

signal pw_cycle_completed
signal pin_cycle_completed
signal xp_gained
signal cracking_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_CRACKING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 6.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/pw_cracking_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

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

var PASSWORD = {
	"name": "Password",
	"tier name": "TIER I | PASSWORD",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -password",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"requirements": {Items.ENCRYPTED_PASSWORDS: 1},
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"description": "Cracks encrypted passwords, transforming them into passwords",
	"efficiency description": "Chance to instantly crack password",
	"signal": pw_cycle_completed
}

var VM = {
	"name": "VM",
	"tier name": "TIER II | VM",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -vm",
	"ssh command": "ssh cracking vm",
	"display command": "crack -vm use=<skill> create=<skill>",
	"example commands": [
		{'cmd': 'crack -vm use=mining create=phishing', 'description': 'Uses 3 VM Mining Tokens to create 1 VM Phishing Token'}
	],
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 8,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"requirements": "VM Token x 3",
	"resource gained": "VM Token x 1",
	"resource amount gained": 1,
	"description": "Cracks 3 VM Tokens to be used on a different process.",
	"efficiency description": "Chance to instantly crack VM Token",
	"signal": pw_cycle_completed
}

var PIN = {
	"name": "PIN",
	"tier name": "TIER III | PIN",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -pin",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 20,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"requirements": {Items.ENCRYPTED_PINS: 1},
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"description": "Cracks encrypted PINs, transforming them into PINs",
	"efficiency description": "Chance to instantly crack PIN",
	"signal": pw_cycle_completed
}

var API = {
	"name": "API",
	"tier name": "TIER IV | API",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -api",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 40,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"requirements": "Hashed API key x1",
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"description": "Cracks hashed API key, transforming them into API Key",
	"efficiency description": "Chance to instantly crack API",
	"signal": pw_cycle_completed
}

var ROOT = {
	"name": "ROOT",
	"tier name": "TIER V | ROOT",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -api",
	"efficiency": 0.05,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 60,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 1.6,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"requirements": "Encrypted Root Key x1",
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"description": "Cracks encrypted Root key, transforming them into Root Key",
	"efficiency description": "Chance to instantly crack Root Key",
	"signal": pw_cycle_completed
}


var minor_processes = [
	PASSWORD,
	VM,
	PIN,
	API,
	ROOT
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
	return "Missing " + minor_process["requirements"].name

func create_vm_window(minor_process, use_token: ItemData = null, create_token: ItemData = null) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = true
	
	new_window.set_repeat(true)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Cracking, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		Stats.CURRENT_ALL_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_cracking_type(minor_process, true, use_token, create_token)
		content_instance.start()
	)
	CURRENT_VMS += 1
	Stats.CURRENT_ALL_VMS += 1
	return new_window


func save_data() -> Dictionary:
	return {
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


var random_four_digit_words: Array = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]
