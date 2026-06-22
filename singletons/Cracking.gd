extends Node

signal pw_cycle_completed
signal pin_cycle_completed
signal xp_gained
signal cracking_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_CRACKING_TOKEN
@onready var MAX_VMS = process_upgrades["vm windows"]["amount"]
@onready var VM_UPTIME = process_upgrades["vm duration"]["amount"]
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/pw_cracking_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Cracking",
	"level": 1,
	"experience": 0,
	"color": Color("#EF9F27"),
	"level up signal": cracking_level_up_signal,
	"efficiency description": "Chance to instantly crack encryption",
}

var PASSWORD = {
	"name": "Password",
	"tier name": "TIER I | PASSWORD",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -pw",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 3,
	"overclock heat": 8,
	"overheat heat": 1,
	"requirements": Items.ENCRYPTED_PASSWORDS,
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"description": "Cracks encrypted passwords, transforming them into passwords",
	"efficiency description": "Chance to instantly crack password",
	"signal": pw_cycle_completed
}

var PINS = {
	"name": "PIN",
	"tier name": "TIER I | PINS",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -pin",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 3,
	"overclock heat": 8,
	"overheat heat": 1,
	"requirements": Items.ENCRYPTED_PINS,
	"resource gained": Items.PINS,
	"resource amount gained": 1,
	"description": "Cracks encrypted PINS, transforming them into PINS",
	"efficiency description": "Chance to instantly crack PINS",
	"signal": pin_cycle_completed
}

var minor_processes = [
	PASSWORD,
	PINS
]

func signal_exp(amount: int):
	xp_gained.emit()

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
	
	if upgrade_stat["name"].to_lower() == "vm windows":
		MAX_VMS += upgrade_stat["increase per level"]
	if upgrade_stat["name"].to_lower() == "vm duration":
		VM_UPTIME += upgrade_stat["increase per level"]

func has_requirements(minor_process) -> bool:
	if Inventory.get_amount(minor_process["requirements"]) > 0:
		return true
	return false

func missing_requirements_text(minor_process) -> String:
	return "Missing " + minor_process["requirements"].name

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Cracking, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_cracking_type(minor_process, true)
		content_instance.start()
	)
	CURRENT_VMS += 1
	return new_window


var random_four_digit_words: Array = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]
