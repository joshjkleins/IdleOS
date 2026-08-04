extends Node

signal compile_cycle_complete
signal xp_gained
signal compile_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_COMPILING_TOKEN
@onready var MAX_VMS = process_upgrades["vm windows"]["amount"]
@onready var VM_UPTIME = process_upgrades["vm duration"]["amount"]
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/compile_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Compiling",
	"level": 1,
	"experience": 0,
	"color": Color("#8B5CF6"),
	"level up signal": compile_level_up_signal,
	"efficiency description": "??????",
	"command": "cd compiling"
}

var SCHOOL = {
	"name": "School",
	"tier name": "TIER I | CACHE",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "compile -school",
	"efficiency": 0.1,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 15.0,
	"overclock speed": 3.0,
	"overheat speed": 0.2,
	"heat": 5,
	"overclock heat": 7,
	"overheat heat": 2,
	"requirements": [ { "item": Items.IP_ADDRESS, "amount": 1 }, { "item": Items.CREDENTIALS, "amount": 1 } ],
	"resource gained": Items.SCHOOL_PAYLOAD,
	"description": "Compile resources to create a payload used to hack targets.",
	"efficiency description": "?????",
	"signal": compile_cycle_complete
}

var SMALL_BUSINESS = {
	"name": "Small Business",
	"tier name": "TIER I | CACHE",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "compile -small-business",
	"efficiency": 0.1,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 10.0,
	"overclock speed": 3.0,
	"overheat speed": 0.2,
	"heat": 5,
	"overclock heat": 7,
	"overheat heat": 2,
	"requirements": [ { "item": Items.IP_ADDRESS, "amount": 5 }, { "item": Items.ACCOUNT_ACCESS_TOKENS, "amount": 2 } ],
	"resource gained": Items.SMALL_BUSINESS_PAYLOAD,
	"description": "Compile resources to create a payload used to hack targets.",
	"efficiency description": "?????",
	"signal": compile_cycle_complete
}

var minor_processes = [
	SCHOOL,
	SMALL_BUSINESS
]

func signal_exp(_amount: int):
	xp_gained.emit()

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.005 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
}


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

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
	
	if upgrade_stat["name"].to_lower() == "vm windows":
		MAX_VMS += upgrade_stat["increase per level"]
	if upgrade_stat["name"].to_lower() == "vm duration":
		VM_UPTIME += upgrade_stat["increase per level"]

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Parsing, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		#content_instance.set_parse_type(minor_process, true)
		content_instance.start(minor_process, true)
	)
	CURRENT_VMS += 1
	return new_window
