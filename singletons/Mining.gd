extends Node

signal log_cycle_completed
signal quality_log_cycle_completed
signal xp_gained
signal mining_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_MINING_TOKEN
@onready var MAX_VMS = 1
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/data_mining_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Mining",
	"level": 1,
	"experience": 0,
	"color": Color("#7A4A2E"),
	"level up signal": mining_level_up_signal,
	"efficiency description": "Chance to receive multiple resources. Greater than 100% efficiency yields guaranteed multiple resources.",
	"command": "cd mining"
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
	"heat": 0.8,
	"overclock heat": 1.5,
	"overheat heat": 0.3,
	"requirements": [],
	"resource gained": Items.LOGS,
	"resource amount gained": 1,
	"description": "Finds logs that can be parsed for a random assortment of items.",
	"efficiency description": "Chance to receive multiple logs.",
	"signal": log_cycle_completed
}

var minor_processes = [
	LOGS
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

func has_requirements(_minor_process) -> bool:
	return true

func missing_requirements_text(_minor_process) -> String:
	return ""

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = "MINING | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	#new_window.set_cooling_reduction(VM_COOLING_REDUCTION)
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Mining, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func():
		CURRENT_VMS -= 1
		Stats.remove_vm_count(1)
		#new_window.remove_cooling_reduction()
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_mine_type(minor_process, true)
		content_instance.start_data_mining()
	)
	CURRENT_VMS += 1
	Stats.CURRENT_ALL_VMS += 1
	return new_window


func save_data() -> Dictionary:
	return {
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"logs_level": LOGS["level"],
		"logs_experience": LOGS["experience"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	LOGS["level"] = int(data.get("logs_level", LOGS["level"]))
	LOGS["experience"] = int(data.get("logs_experience", LOGS["experience"]))
