extends Node

signal log_cycle_completed
signal quality_log_cycle_completed
signal xp_gained
signal mining_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_MINING_TOKEN
@onready var MAX_VMS = process_upgrades["vm windows"]["amount"]
@onready var VM_UPTIME = process_upgrades["vm duration"]["amount"]
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/data_mining_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Mining",
	"level": 1,
	"experience": 0,
	"color": Color("#a97c54"),
	"level up signal": mining_level_up_signal,
	"efficiency description": "Chance to receive multiple resources. Greater than 100% efficiency yields guaranteed multiple resources.",
}

var LOGS = {
	"name": "Logs",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "mine -logs",
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.4,
	"overclock speed": 0.2,
	"overheat speed": 1.0,
	"heat": 1,
	"overclock heat": 3,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": Items.LOGS,
	"resource amount gained": 1,
	"description": "Finds logs that can be parsed for a random assortment of items.",
	"efficiency description": "Chance to receive multiple logs.",
	"signal": log_cycle_completed
}

var QUALITY = {
	"name": "Quality",
	"tier name": "TIER II | QUALITY LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 725,
	"command": "mine -quality",
	"efficiency": 0.0,
	"efficiency rate": 0.02,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 0.9,
	"overclock speed": 0.4,
	"overheat speed": 2.9,
	"heat": 5,
	"overclock heat": 11,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": Items.QUALITY_LOGS,
	"resource amount gained": 1,
	"description": "Finds logs that can be parsed for a random assortment of items.",
	"efficiency description": "Chance to receive multiple logs.",
	"signal": quality_log_cycle_completed
}

var minor_processes = [
	LOGS,
	QUALITY
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
	return true

func missing_requirements_text(minor_process) -> String:
	return ""

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = "MINING | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Mining, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_mine_type(minor_process, true)
		content_instance.start_data_mining()
	)
	CURRENT_VMS += 1
	return new_window
