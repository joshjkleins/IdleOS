extends Node

signal compile_cycle_complete
signal xp_gained
signal compile_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_COMPILING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/compiling_terminal.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Compiling",
	"level": 1,
	"experience": 0,
	"color": Color("#8B5CF6"),
	"level up signal": compile_level_up_signal,
	"efficiency description": "Chance to increase speed by 1000% for 1 second and apply no heat.",
	"command": "cd compiling",
	"sfx": "compiling_item_received"
}

## Tiers follow the hacking locations: School > Lawfirm > Hospital > Bank > Police > Government.
## Each payload = that tier's address (Parsing) + its matched item (Matching).
## Pacing follows Mining: each tier compiles 1.5x slower, tuned for +50% compiling speed per tier from upgrades.
## Mod (hacking mods) is a utility outside the tiers.
var SCHOOL = {
	"name": "School",
	"tier name": "TIER I | SCHOOL",
	"level": 1,
	"experience": 0,
	"experience per level": 40, # xp per payload
	"command": "compile -school",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 10.0, # bar fill per second (100 = one payload)
	"overclock speed": 20.0,
	"overheat speed": 4.0,
	"heat": 1.5,
	"overclock heat": 1.9,
	"overheat heat": 0.3,
	"vm token chance": 0.01, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.IP_ADDRESS: 1,
		Items.CREDENTIALS: 1
	},
	"resource gained": Items.SCHOOL_PAYLOAD,
	"description": "Compiles a School payload from its address and matched access, used to hack School targets.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

var LAWFIRM = {
	"name": "Lawfirm",
	"tier name": "TIER II | LAWFIRM",
	"level": 1,
	"experience": 0,
	"experience per level": 93, # xp per payload
	"command": "compile -lawfirm",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 6.667, # bar fill per second (100 = one payload)
	"overclock speed": 13.333,
	"overheat speed": 2.667,
	"heat": 2.25,
	"overclock heat": 2.85,
	"overheat heat": 0.45,
	"vm token chance": 0.015, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.EMAIL_HEADER: 1,
		Items.SIGNED_CERTIFICATE: 1
	},
	"resource gained": Items.LAWFIRM_PAYLOAD,
	"description": "Compiles a Lawfirm payload from its address and matched access, used to hack Lawfirm targets.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

var HOSPITAL = {
	"name": "Hospital",
	"tier name": "TIER III | HOSPITAL",
	"level": 1,
	"experience": 0,
	"experience per level": 180, # xp per payload
	"command": "compile -hospital",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 30,
	"base speed": 4.444, # bar fill per second (100 = one payload)
	"overclock speed": 8.889,
	"overheat speed": 1.778,
	"heat": 3.38,
	"overclock heat": 4.27,
	"overheat heat": 0.67,
	"vm token chance": 0.0225, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.MAC_ADDRESS: 1,
		Items.ACCESS_BADGE: 1
	},
	"resource gained": Items.HOSPITAL_PAYLOAD,
	"description": "Compiles a Hospital payload from its address and matched access, used to hack Hospital targets.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

var BANK = {
	"name": "Bank",
	"tier name": "TIER IV | BANK",
	"level": 1,
	"experience": 0,
	"experience per level": 314, # xp per payload
	"command": "compile -bank",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 45,
	"base speed": 2.963, # bar fill per second (100 = one payload)
	"overclock speed": 5.926,
	"overheat speed": 1.185,
	"heat": 5.06,
	"overclock heat": 6.41,
	"overheat heat": 1.01,
	"vm token chance": 0.0338, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.ROUTING_NUMBER: 1,
		Items.ACCOUNT_ACCESS_TOKENS: 1
	},
	"resource gained": Items.BANK_PAYLOAD,
	"description": "Compiles a Bank payload from its address and matched access, used to hack Bank targets.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

var POLICE = {
	"name": "Police",
	"tier name": "TIER V | POLICE",
	"level": 1,
	"experience": 0,
	"experience per level": 527, # xp per payload
	"command": "compile -police",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 60,
	"base speed": 1.975, # bar fill per second (100 = one payload)
	"overclock speed": 3.951,
	"overheat speed": 0.79,
	"heat": 7.59,
	"overclock heat": 9.62,
	"overheat heat": 1.52,
	"vm token chance": 0.0506, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.SUBNET_MAP: 1,
		Items.OFFICER_AUTH_KEYS: 1
	},
	"resource gained": Items.POLICE_PAYLOAD,
	"description": "Compiles a Police payload from its address and matched access, used to hack Police targets.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

var GOVERNMENT = {
	"name": "Government",
	"tier name": "TIER VI | GOVERNMENT",
	"level": 1,
	"experience": 0,
	"experience per level": 840, # xp per payload
	"command": "compile -government",
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 75,
	"base speed": 1.317, # bar fill per second (100 = one payload)
	"overclock speed": 2.634,
	"overheat speed": 0.527,
	"heat": 11.39,
	"overclock heat": 14.43,
	"overheat heat": 2.28,
	"vm token chance": 0.0759, # per payload; scales with compile length so tokens/hour stay level
	"requirements": {
		Items.GATEWAY_ADDRESS: 1,
		Items.SECURITY_CLEARANCE: 1
	},
	"resource gained": Items.GOVERNMENT_PAYLOAD,
	"description": "Compiles a Government payload from its address and matched access, used to hack Government targets.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

## ACCESS: unlocks the next hacking target of a location (one-time per target). The cost comes from
## Stats.get_access_recipe(): 5 of the previous target's rare item + that location's payloads.
var ACCESS = {
	"name": "Access",
	"tier name": "UTILITY | ACCESS",
	"level": 1,
	"experience": 0,
	"experience per level": 150,
	"command": "compile -access",
	"ssh command": "ssh compiling access",
	"display command": "compile -access=<target>",
	"example commands": [
		{'cmd': 'compile -access=administrator', 'description': 'Unlocks the Administrator: 5 Parents credit cards + 10 School payloads (+25 payloads per target after)'},
	],
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 4.0, # bar fill per second (100 = done)
	"overclock speed": 8.0,
	"overheat speed": 1.6,
	"heat": 3.0,
	"overclock heat": 3.8,
	"overheat heat": 0.6,
	"vm token chance": 0.0,
	"requirements": "Previous target's rare item x5 + payloads",
	"resource gained": "Access to the next target",
	"description": "Compiles access to the next hacking target at a location from the previous target's rare item and the location's payloads. Each target only needs it once.",
	"efficiency description": "Chance to compile the next payload instantly.",
	"signal": compile_cycle_complete
}

## Validates compile -access=<name>: {"ok", "message", "target", "requirements": {item: amount}}
func check_access(target_name: String) -> Dictionary:
	var out = {"ok": false, "message": "", "target": {}, "requirements": {}}
	var t = Stats.find_target_by_name(target_name)
	if target_name.strip_edges() == "" or t.is_empty():
		out.message = "Name a target. [color=#666666]ex. compile -access=administrator[/color]"
		return out
	if t.get("unlocked", false):
		out.message = t.name + " is already unlocked."
		return out
	var p = Stats.target_place(t)
	if !Stats.hacking_targets[p.location].get("unlocked", false):
		out.message = "%s is in a locked location: %s." % [t.name, Stats.get_location_unlock_hint(p.location)]
		return out
	var r = Stats.get_access_recipe(t)
	if r.is_empty() or r.rare == null:
		out.message = t.name + " " + Stats.get_unlock_hint(t) + "."
		return out
	out.requirements = {r.rare: r.rare_amount, r.payload: r.payload_amount}
	var missing = []
	for item in out.requirements:
		if Inventory.get_amount(item) < out.requirements[item]:
			missing.append("%s %d/%d" % [item.name, Inventory.get_amount(item), out.requirements[item]])
	if !missing.is_empty():
		out.message = "Access to %s needs: %s" % [t.name, ", ".join(missing)]
		return out
	out.target = t
	out.ok = true
	return out

var MOD = {
	"name": "Mod",
	"tier name": "UTILITY | MOD",
	"level": 1,
	"experience": 0,
	"experience per level": 100,
	"command": "compile -mod",
	"ssh command": "ssh compiling mod",
	"display command": "compile -mod=<item>",
	"example commands": [
		{'cmd': 'compile -mod=logs', 'description': 'Uses 10 Logs to grant a hacking modification for 1 hack.'},
		{'cmd': 'compile -mod=ip address', 'description': 'Uses 10 IP Addresses to grant a hacking modification for 1 hack.'}
	],
	"efficiency": 0.01,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 3,
	"base speed": 2.0,
	"overclock speed": 3.0,
	"overheat speed": 1.0,
	"heat": 20.0,
	"overclock heat": 30.0,
	"overheat heat": 0.3,
	"requirements": "Any item. Use 'ls <item>' to view details of each item.",
	"resource gained": "Temporary Hacking Modification",
	"description": "Compile resources into temporary hacking modifications.",
	"efficiency description": "?",
	"signal": compile_cycle_complete
}

## The six location payload recipes (School ... Government), without the ACCESS / MOD utilities.
func get_payload_processes() -> Array:
	return minor_processes.filter(func(p): return p != MOD and p != ACCESS)

var minor_processes = [
	SCHOOL,
	LAWFIRM,
	HOSPITAL,
	BANK,
	POLICE,
	GOVERNMENT,
	ACCESS,
	MOD
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

#func get_upgrade_cost(upgrade_stat: String) -> int:
	#return process_upgrades[upgrade_stat]["level"] * 800 + 100

#func upgraded(upgrade_stat: Dictionary):
	#upgrade_stat["level"] += 1
	#upgrade_stat["amount"] += upgrade_stat["increase per level"]
	#
	#if upgrade_stat["name"].to_lower() == "vm windows":
		#MAX_VMS += upgrade_stat["increase per level"]
	#if upgrade_stat["name"].to_lower() == "vm duration":
		#VM_UPTIME += upgrade_stat["increase per level"]

func create_vm_window(minor_process, item = null) -> VMWindow:
	var setup = func(t):
		t.start(minor_process, true, item)
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, true)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"school_level": SCHOOL["level"],
		"school_experience": SCHOOL["experience"],
		"school_efficiency": SCHOOL["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	SCHOOL["level"] = int(data.get("school_level", SCHOOL["level"]))
	SCHOOL["experience"] = int(data.get("school_experience", SCHOOL["experience"]))
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)
