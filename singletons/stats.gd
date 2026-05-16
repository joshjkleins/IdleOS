extends Node

signal gained_xp_signal

const MAX_LEVEL = 99

var player_stats = {
	"Data Mining": {
		"name": "Data mining",
		"experience": 0,
		"exp per level": 200,
		"command": "data-mining",
		"level": 1,
		"efficiency": 0.0,
		"efficiency increase rate": 0.08,
		"unlocked": true,
		"base speed": 0.25,
		"overclock speed": 0.0625,
		"overheat speed": 1.0,
		"heat": 1,
		"overclock heat": 3,
		"overheat heat": 1,
		"requirements": [],
		"description": "Generates data used for purchasing items from the marketplace.",
		"efficiency description": "Chance to receive multiple data."
	},
	"Log Parsing": {
		"name": "Log parsing",
		"experience": 0,
		"exp per level": 200,
		"command": "log-parsing",
		"level": 1,
		"base speed": 0.4,
		"overclock speed": 0.1,
		"overheat speed": 3.0,
		"efficiency": 0.0,
		"efficiency increase rate": 0.01,
		"unlocked": true,
		"heat": 3,
		"overclock heat": 4,
		"requirements": [Items.LOGS],
		"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
		"efficiency description": "Increases chance of finding a resource per row."
	},
	"Password Cracking": {
		"name": "Password cracking",
		"experience": 0,
		"exp per level": 900,
		"command": "pw-cracking",
		"level": 1,
		"efficiency": 0.0,
		"efficiency increase rate": 0.002,
		"unlocked": true,
		"heat": 3,
		"overclock heat": 8,
		"overheat heat": 1,
		"base speed": 3.0,
		"overclock speed": 1.0,
		"overheat speed": 9.0,
		"requirements": [Items.ENCRYPTED_PASSWORDS],
		"description": "Cracks encrypted passwords, turning them into Passwords that can be used in credential matching.",
		"efficiency description": "Chance to instantly crack password."
	},
	"Credential Matching": {
		"name": "Credential matching",
		"experience": 0,
		"exp per level": 1100,
		"command": "cred-matching",
		"level": 1,
		"efficiency": 0.0,
		"efficiency increase rate": 0.002,
		"unlocked": true,
		"heat": 1,
		"overclock heat": 1,
		"overheat heat": 1,
		"base speed": 1.0,
		"overclock speed": 0.33,
		"overheat speed": 3.0,
		"requirements": [Items.USERNAMES, Items.PASSWORDS],
		"description": "Creates credentials using passwords & usernames.",
		"efficiency description": "Chance to not consume a username or password."
	},
	"Hacking": {
		"name": "Hacking",
		"experience": 0,
		"command": "hacking",
		"level": 1,
		"base speed": 0.2,
		"overclock speed": 0.05,
		"overheat speed": 1.0,
		"efficiency": 0.05,
		"efficiency increase rate": 0.0025,
		"unlocked": true,
		"heat": 7,
		"overclock heat": 25,
		"overheat heat": 2,
		"requirements": [Items.IP_ADDRESS, Items.CREDENTIALS],
		"description": "Hack targets and extract caches for valuable items.",
		"efficiency description": "Increases chance of successful hacking"
	},
	"Cache Decrypting": {
		"name": "Cache decrypting",
		"experience": 0,
		"exp per level": 2000,
		"command": "cache-decrypting",
		"level": 1,
		"base speed": 0.2,
		"overclock speed": 0.05,
		"overheat speed": 1.0,
		"efficiency": 0.03,
		"efficiency increase rate": 0.001,
		"unlocked": true,
		"heat": 5,
		"overclock heat": 10,
		"overheat heat": 2,
		"requirements": ["Any type of cache"],
		"description": "Decrypt caches gained from hacking to reveal additional items.",
		"efficiency description": "Chance to find rare item."
	}
}

var combat_stats = {
	"SQL Injection": {
		"name": "SQL injection",
		"experience": 0,
		"exp per level": 200,
		"level": 1,
		"damage": 0.0,
		"efficiency increase rate": 0.01,
		"unlocked": true,
		"base speed": 0.25,
		"overclock speed": 0.0625,
		"overheat speed": 1.0,
		"heat": 1,
		"overclock heat": 3,
		"overheat heat": 1,
		"requirements": [],
		"description": "Generates data used for purchasing items from the marketplace.",
		"efficiency description": "Chance to receive multiple data."
	}
}

var MAX_TEMP = 100
var MIN_TEMP = 30
var system_tempature = 30
var cooling_amount = -1 #reduces temp by 1
var cooling_frequency = 1.0 #every 1 second
var overheated = false
var overclocked = false

#hacking
var current_anon = 100
var max_anon = 100

var hacking_targets = {
	"School": {
		"command": "view school",
		"name": "School",
		"difficulty": "Easy",
		"targets": [
			{
				"name": "Student",
				"difficulty": "Easy",
				"command": "hack student",
				"heat": 5,
				"exp": 600,
				"integrity": 100,
				"counter": 5,
				"loot": Items.STUDENT_CACHE
			},
			{
				"name": "Administrator",
				"difficulty": "Easy",
				"command": "hack administrator",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"integrity": 100,
				"counter": 5,
				"loot": Items.ADMIN_CACHE
			},
			{
				"name": "Vice Principal",
				"difficulty": "Medium",
				"command": "hack vice-principal",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"integrity": 100,
				"counter": 5,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.VICE_PRINCIPAL_CACHE
			},
			{
				"name": "Principal",
				"difficulty": "Medium",
				"command": "hack principal",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.PRINCIPAL_CACHE
			},
			{
				"name": "Superintendent",
				"difficulty": "Hard",
				"command": "hack superintendent",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.SUPERINTENDENT_CACHE
			}
		],
		"art": preload("res://art/school-ascii.png")
	}, "Library": {
		"command": "view library",
		"name": "Library",
		"difficulty": "Easy",
		"targets": [
			{
				"name": "Patreon",
				"difficulty": "Easy",
				"command": "hack patreon",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.PATRON_CACHE
			},
			{
				"name": "Volunteer",
				"difficulty": "Easy",
				"command": "hack volunteer",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.VOLUNTEER_CACHE
			},
			{
				"name": "Assistant Librarian",
				"difficulty": "Medium",
				"command": "hack assistant-librarian",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.ASSISTANT_LIBRARIAN_CACHE
			},
			{
				"name": "Head Librarian",
				"difficulty": "Medium",
				"command": "hack head-librarian",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.HEAD_LIBRARIAN_CACHE
			},
			{
				"name": "Director",
				"difficulty": "Hard",
				"command": "hack director",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.DIRECTOR_CACHE
			}
		],
		"art": preload("res://art/library-ascii.png")
	}, "Small Business": {
		"command": "view small-business",
		"name": "Small Business",
		"difficulty": "Easy",
		"targets": [
			{
				"name": "Worker",
				"difficulty": "Easy",
				"command": "hack worker",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.WORKER_CACHE
			},
			{
				"name": "Supervisor",
				"difficulty": "Easy",
				"command": "hack supervisor",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.SUPERVISOR_CACHE
			},
			{
				"name": "Manager",
				"difficulty": "Medium",
				"command": "hack manager",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.MANAGER_CACHE
			},
			{
				"name": "Human Resources",
				"difficulty": "Medium",
				"command": "hack human-resources",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.HUMAN_RESOURCES_CACHE
			},
			{
				"name": "Owner",
				"difficulty": "Hard",
				"command": "hack owner",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.OWNER_CACHE
			}
		],
		"art": preload("res://art/small-business-ascii.png")
	}, "University": {
		"command": "view university",
		"name": "University",
		"difficulty": "Moderate",
		"targets": [
			{
				"name": "Teachers Assistant",
				"difficulty": "Easy",
				"command": "hack teachers-assistant",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.TEACHERS_ASSISTANT_CACHE
			},
			{
				"name": "Professor",
				"difficulty": "Easy",
				"command": "hack professor",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.PROFESSOR_CACHE
			},
			{
				"name": "Department Chair",
				"difficulty": "Medium",
				"command": "hack department-chair",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.DEPARTMENT_CHAIR_CACHE
			},
			{
				"name": "Dean",
				"difficulty": "Medium",
				"command": "hack dean",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.DEAN_CACHE
			},
			{
				"name": "University President",
				"difficulty": "Hard",
				"command": "hack university-president",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.UNIVERSITY_PRESIDENT_CACHE
			}
		],
		"art": preload("res://art/university-ascii.png")
	}, "Hospital": {
		"command": "view hospital",
		"name": "Hospital",
		"difficulty": "Easy",
		"targets": [
			{
				"name": "Receptionist",
				"difficulty": "Easy",
				"command": "hack receptionist",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.RECEPTIONIST_CACHE
			},
			{
				"name": "Orderly",
				"difficulty": "Easy",
				"command": "hack orderly",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.ORDERLY_CACHE
			},
			{
				"name": "Nurse",
				"difficulty": "Medium",
				"command": "hack nurse",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.NURSE_CACHE
			},
			{
				"name": "Doctor",
				"difficulty": "Medium",
				"command": "hack doctor",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.DOCTOR_CACHE
			},
			{
				"name": "Chief of Medicine",
				"difficulty": "Hard",
				"command": "hack chief-medicine",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.CHIEF_OF_MEDICINE_CACHE
			}
		],
		"art": preload("res://art/hospital-ascii.png")
	}, "Police Station": {
		"command": "view police-station",
		"name": "Police Station",
		"difficulty": "Easy",
		"targets": [
			{
				"name": "Secretary",
				"difficulty": "Easy",
				"command": "hack secretary",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.SECRETARY_CACHE
			},
			{
				"name": "Cop",
				"difficulty": "Easy",
				"command": "hack cop",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.COP_CACHE
			},
			{
				"name": "Detective",
				"difficulty": "Medium",
				"command": "hack detective",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.DETECTIVE_CACHE
			},
			{
				"name": "Sergeant",
				"difficulty": "Medium",
				"command": "hack sergeant",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.SERGEANT_CACHE
			},
			{
				"name": "Captain",
				"difficulty": "Hard",
				"command": "hack captain",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.CAPTAIN_CACHE
			}
		],
		"art": preload("res://art/police-station-ascii.png")
	}, "Lawfirm": {
		"command": "view lawfirm",
		"name": "Lawfirm",
		"difficulty": "Easy",
		"targets": [
			{
				"name": "Legal Assistant",
				"difficulty": "Easy",
				"command": "hack legal-assistant",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.LEGAL_ASSISTANT_CACHE
			},
			{
				"name": "Paralegal",
				"difficulty": "Easy",
				"command": "hack paralegal",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.PARALEGAL_CACHE
			},
			{
				"name": "Associate Attorney",
				"difficulty": "Medium",
				"command": "hack associate-attorney",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.ASSOCIATE_ATTORNEY_CACHE
			},
			{
				"name": "Lawyer",
				"difficulty": "Medium",
				"command": "hack lawyer",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.LAWYER_CACHE
			},
			{
				"name": "Partner",
				"difficulty": "Hard",
				"command": "hack partner",
				"heat": 10,
				"exp": 600,
				"time to hack": 2.0,
				"overheat time to hack": 10.0,
				"overclock time to hack": 0.5,
				"loot": Items.PARTNER_CACHE
			}
		],
		"art": preload("res://art/lawfirm-ascii.png")
	}
}

func update_tempature(amount: int):
	system_tempature += amount
	if system_tempature >= MAX_TEMP:
		system_tempature = MAX_TEMP
	elif system_tempature <= MIN_TEMP:
		system_tempature = MIN_TEMP
	
	
	#OVERHEAT PARAMETERS
	if system_tempature <= 40: #if overheated, stops overheat mode when reaching below 40
		overheated = false
	elif system_tempature >= 95: #if temp reaches 95 then overheat
		overclocked = false
		overheated = true
	elif system_tempature >= 85: #attempt to auto stop overclock when above 85
		overclocked = false
	Signals.system_temp_updated(system_tempature)
	
	if amount > 0:
		Signals.heat_added(amount)

func get_hacking_target_by_command(command):
	for target in hacking_targets:
		for person in hacking_targets[target]["targets"]:
			if person["command"] == command:
				return person
	return {}

func get_hacking_location_by_command(command):
	for target in hacking_targets:
		if hacking_targets[target]["command"] == command:
			return hacking_targets[target]
	return {}


#unlock module
func unlock_module(mod_name: String):
	if not player_stats.has(mod_name):
		return "Item ID not found."
	
	if player_stats[mod_name]["unlocked"]:
		return "Module already unlocked, you shouldn't be seeing this message..."
	
	player_stats[mod_name]["unlocked"] = true
	return mod_name + " has been unlocked and can now be installed."

#lists unlocked processes
func list_unlocked_processes():
	var output = "\n"
	var first_col = 25
	var second_col = 20
	
	#Heading
	output += "Module" + " ".repeat(first_col - 6) + "Command" + " ".repeat(second_col - 7) + "Description\n"
	#output += "Module              Command               Description\n"
	output += "-".repeat(first_col + second_col + 40) + "\n"
	
	for process in player_stats.keys():
		var proc = player_stats[process]
		var desc = proc["description"]
		if desc.length() > 80:
			var slice = desc.substr(0, 80)
			var break_index = slice.rfind(" ")
			if break_index == -1:
				break_index = 80

			desc = (
				desc.substr(0, break_index)
				+ "\n"
				+ " ".repeat(45)
				+ desc.substr(break_index + 1)
			)


		if proc.unlocked:
			output += process + " ".repeat(first_col - process.length()) + proc["command"] + " ".repeat(second_col - proc.command.length()) + desc + "\n"
	
	return output


func get_xp_display(skill_data: Dictionary) -> Dictionary:
	var level = skill_data["level"]
	
	# Cap at max level
	if level >= MAX_LEVEL:
		return {
			"progress": 1.0,
			"current": 0,
			"needed": 0,
			"display": "MAX"
		}
	
	var current_level_xp = xp_for_level(level)        # XP threshold for current level
	var next_level_xp    = xp_for_level(level + 1)    # XP threshold for next level
	var xp_into_level    = skill_data["experience"] - current_level_xp
	var xp_needed        = next_level_xp - current_level_xp  # = xp_to_new_level(level)
	
	return {
		"progress": float(xp_into_level) / float(xp_needed),  # 0.0–1.0
		"current":  xp_into_level,   # shown left of slash
		"needed":   xp_needed,       # shown right of slash
		"display":  "%d/%d" % [xp_into_level, xp_needed]
	}

#returns experience needed provided level
func xp_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 0
	return floor(50.0 * pow(lvl, 2.4))

#returns experience needed for next level
func xp_to_new_level(lvl: int):
	return xp_for_level(lvl + 1) - xp_for_level(lvl)

#returns current level given current total experience
func get_level_from_xp(total_xp: int):
	var lvl = 1
	while lvl < MAX_LEVEL and total_xp >= xp_for_level(lvl + 1):
		lvl += 1
	return lvl

#return between 0.0-1.0
func get_xp_progress(skill_data: Dictionary) -> float:
	var current_level_xp = xp_for_level(skill_data["level"])
	var next_level_xp = xp_for_level(skill_data["level"] + 1)
	return float(skill_data["experience"] - current_level_xp) / float(next_level_xp - current_level_xp)

func add_xp(skill_data: Dictionary, amount: int = 0):
	if skill_data["level"] >= MAX_LEVEL:
		return

	if amount > 0:
		print("Gained xp from specified amount")
		skill_data["experience"] += amount
		gained_xp_signal.emit(amount)
	else:
		skill_data["experience"] += skill_data["exp per level"]
		gained_xp_signal.emit(skill_data["exp per level"])

	var new_level = get_level_from_xp(skill_data["experience"])

	while skill_data["level"] < new_level:
		skill_data["level"] += 1
		on_level_up(skill_data)

		if skill_data["level"] >= MAX_LEVEL:
			skill_data["level"] = MAX_LEVEL
			break

func on_level_up(skill_data: Dictionary):
	#update efficiency
	skill_data["efficiency"] += skill_data["efficiency increase rate"]
	print("Leveled up!")
	print("Current process" + " is level " + str(int(skill_data.level)))
