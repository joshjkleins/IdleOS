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
		"description": "Generates data used for purchasing items from the marketplace."
	},
	"Log Parsing": {
		"experience": 0,
		"command": "log-parsing",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.003,
		"unlocked": false,
		"description": "Parses through logs for a chance to gain random resources. Requires Logs."
	},
	"Password Cracking": {
		"experience": 0,
		"command": "pw-cracking",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.02,
		"unlocked": false,
		"description": "Cracks passwords to be used in credentials. Requires scrambled passwords."
	},
	"Credential Matching": {
		"experience": 0,
		"command": "cred-matching",
		"level": 1,
		"effeciency": 0.0,
		"effeciency increase rate": 0.02,
		"unlocked": false,
		"description": "IDK yet"
	}
}

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
	output += "-".repeat(first_col + second_col + 11) + "\n"
	
	for process in player_stats.keys():
		var proc = player_stats[process]
		if proc.unlocked:
			output += process + " ".repeat(first_col - process.length()) + proc["command"] + " ".repeat(second_col - proc.command.length()) + proc["description"] + "\n"
	
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
