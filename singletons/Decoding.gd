extends Node

signal cache_decode_cycle_completed
signal intel_decode_cycle_completed
signal xp_gained
signal decoding_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_DECODING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/cache_decrypt_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Decoding",
	"level": 1,
	"experience": 0,
	"color": Color("#14B8A6"),
	"level up signal": decoding_level_up_signal,
	"efficiency description": "Chance to find rare item.",
	"command": "cd decoding",
	"sfx": "cracking_item_received"
}

var CACHE = {
	"name": "Cache",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "decode -cache",
	"efficiency": 0.1,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.2,
	"overclock speed": 0.05,
	"overheat speed": 1.0,
	"heat": 3.2,
	"overclock heat": 3.5,
	"overheat heat": 0.3,
	"requirements": "cache",
	"description": "Decrypt caches gained from hacking to reveal additional items.",
	"efficiency description": "Chance to find rare item.",
	"signal": cache_decode_cycle_completed
}

var minor_processes = [
	CACHE
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
	if Inventory.has_cache():
		return true
	return false

func missing_requirements_text(_minor_process) -> String:
	return "Missing: Cache(any)"

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Decoding, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		Stats.CURRENT_ALL_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_cache_type(minor_process, true)
		content_instance.start_decrypting()
	)
	CURRENT_VMS += 1
	Stats.CURRENT_ALL_VMS += 1
	return new_window


func save_data() -> Dictionary:
	return {
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"cache_level": CACHE["level"],
		"cache_experience": CACHE["experience"],
		"cache_efficiency": CACHE["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	CACHE["level"] = int(data.get("cache_level", CACHE["level"]))
	CACHE["experience"] = int(data.get("cache_experience", CACHE["experience"]))
	CACHE["efficiency"] = float(data.get("cache_efficiency", CACHE["efficiency"]))
