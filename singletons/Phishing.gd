extends Node

signal spear_cycle_completed
signal whale_cycle_completed
signal xp_gained

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_PHISHING_TOKEN
@onready var MAX_VMS = process_upgrades["vm windows"]["amount"]
@onready var VM_UPTIME = process_upgrades["vm duration"]["amount"]
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/phishing_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

var max_lines: int = 3
var current_lines = []

#GENERAL MODULE DATA
var SKILL = {
	"name": "Phishing",
	"level": 1,
	"experience": 0,
	"color": Color("#1d9e75")
}

var SPEAR = {
	"name": "Spear",
	"tier name": "TIER I | SPEAR",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "spear-phishing",
	"efficiency": 0.3,
	"efficiency rate": 0.005,
	"unlocked": true,
	"wait time min": 5.0,
	"wait time max": 10.0,
	"download time": 7.5,
	"overclocked download time": 3.75,
	"overheated download time": 22.5,
	"heat": 2,
	"overclock heat": 5,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": [Items.USERNAMES, Items.IP_ADDRESS],
	"resource amount gained": 1,
	"description": "Send out emails in an attempt to get usernames and passwords",
	"efficiency description": "Chance for successful bite",
	"signal": spear_cycle_completed
}

var WHALING = {
	"name": "Whaling",
	"tier name": "TIER I | WHALING",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "whale-phishing",
	"efficiency": 0.2,
	"efficiency rate": 0.003,
	"unlocked": true,
	"wait time min": 6.0,
	"wait time max": 12.0,
	"download time": 9.5,
	"overclocked download time": 5.0,
	"overheated download time": 25.5,
	"heat": 4,
	"overclock heat": 7,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": [Items.ACCOUNT_NUMBERS, Items.ENCRYPTED_PINS],
	"resource amount gained": 1,
	"description": "Targets high level individuals for a chance to extract PINs and account numbers",
	"efficiency description": "Chance for successful bite",
	"signal": whale_cycle_completed
}

var minor_processes = [
	SPEAR,
	WHALING
]

func add_line(line):
	current_lines.append(line)

func remove_line(line):
	if current_lines.has(line):
		current_lines.erase(line)

func signal_exp(amount: int):
	xp_gained.emit()

var process_upgrades = {
	"max lines": { "id": 1, "name": "Max lines", "level": 0, "amount": 0, "increase per level": 1 },
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
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Matching, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.vm_cast_all_lines(minor_process, true)
	)
	CURRENT_VMS += 1
	return new_window
