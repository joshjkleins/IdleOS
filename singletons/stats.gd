extends Node

const MAX_LEVEL = 99

var player_stats = {
	"Data Mining": {
		"experience": 0,
		"command": "data-mining",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.03,
		"unlocked": true,
		"description": "Generates data used for purchasing items from the marketplace.",
		"effeciency description": "Increases speed of mining."
	},
	"Log Parsing": {
		"experience": 0,
		"command": "log-parsing",
		"level": 1,
		"base speed": 0.4,
		"overclock speed": 0.1,
		"current speed": 0.4,
		"effeciency": 0.0,
		"effeciency increase rate": 0.003,
		"unlocked": true,
		"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
		"effeciency description": "Increases chance of finding a resource per row."
	},
	"Password Cracking": {
		"experience": 0,
		"command": "pw-cracking",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.02,
		"unlocked": true,
		"description": "Cracks passwords to be used in credentials. Requires scrambled passwords.",
		"effeciency description": "Increases chance of revealing more than one letter."
	},
	"Credential Matching": {
		"experience": 0,
		"command": "cred-matching",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.01,
		"unlocked": true,
		"description": "Combines passwords and usernames to create a credential. Requires cracked passwords and usernames.",
		"effeciency description": "Increases chance for a match per row."
	},
	"Hacking": {
		"experience": 0,
		"command": "hacking",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.01,
		"unlocked": true,
		"description": "Used to hack targets. Requires ip addresses and credentials.",
		"effeciency description": "IDK yet"
	}
}

var overclock_duration = 5.0

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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Administrator",
				"difficulty": "Easy",
				"command": "hack administrator",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Vice Principal",
				"difficulty": "Medium",
				"command": "hack vice-principal",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Principal",
				"difficulty": "Medium",
				"command": "hack principal",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Superintendent",
				"difficulty": "Hard",
				"command": "hack superintendent",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Volunteer",
				"difficulty": "Easy",
				"command": "hack volunteer",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Assistant Librarian",
				"difficulty": "Medium",
				"command": "hack assistant-librarian",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Head Librarian",
				"difficulty": "Medium",
				"command": "hack head-librarian",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Director",
				"difficulty": "Hard",
				"command": "hack director",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Supervisor",
				"difficulty": "Easy",
				"command": "hack supervisor",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Manager",
				"difficulty": "Medium",
				"command": "hack manager",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Human Resources",
				"difficulty": "Medium",
				"command": "hack human-resources",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Owner",
				"difficulty": "Hard",
				"command": "hack owner",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Professor",
				"difficulty": "Easy",
				"command": "hack professor",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Department Chair",
				"difficulty": "Medium",
				"command": "hack department-chair",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Dean",
				"difficulty": "Medium",
				"command": "hack dean",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "University President",
				"difficulty": "Hard",
				"command": "hack university-president",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Orderly",
				"difficulty": "Easy",
				"command": "hack orderly",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Nurse",
				"difficulty": "Medium",
				"command": "hack nurse",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Doctor",
				"difficulty": "Medium",
				"command": "hack doctor",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Chief of Medicine",
				"difficulty": "Hard",
				"command": "hack chief-medicine",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Cop",
				"difficulty": "Easy",
				"command": "hack cop",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Detective",
				"difficulty": "Medium",
				"command": "hack detective",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Sergeant",
				"difficulty": "Medium",
				"command": "hack sergeant",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Captain",
				"difficulty": "Hard",
				"command": "hack captain",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
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
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Paralegal",
				"difficulty": "Easy",
				"command": "hack paralegal",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Associate Attorney",
				"difficulty": "Medium",
				"command": "hack associate-attorney",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Lawyer",
				"difficulty": "Medium",
				"command": "hack lawyer",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			},
			{
				"name": "Partner",
				"difficulty": "Hard",
				"command": "hack partner",
				"loot": {
					0: {"item": Items.DATA, "min": 1, "max": 5, "weight": 50},
					1: {"item": Items.LOGS, "min": 10, "max": 20, "weight": 35},
					2: {"item": Items.ENCRYPTED_PASSWORDS, "min": 3, "max": 5, "weight": 10},
					3: {"item": Items.PARENTS_CREDIT_CARD, "min": 1, "max": 1, "weight": 5}
				}
			}
		],
		"art": preload("res://art/lawfirm-ascii.png")
	}
}

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

func add_xp(skill_data: Dictionary, amount: int):
	if skill_data["level"] >= MAX_LEVEL:
		return
	skill_data["experience"] += amount
	var new_level = get_level_from_xp(skill_data["experience"])
	
	if new_level > skill_data["level"]:
		skill_data["level"] = new_level
		on_level_up(skill_data)

func on_level_up(skill_data: Dictionary):
	#update effeciency
	skill_data["effeciency"] += skill_data["effeciency increase rate"]
	print("Leveled up!")
	print("Current process" + " is level " + str(int(skill_data.level)))
