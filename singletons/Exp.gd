extends Node

signal gained_xp_signal
signal exp_updated_signal

const MAX_LEVEL: int = 99

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

func add_xp(major, minor, amount: int = 0): #singleton as param
	
	if amount > 0:
		major.SKILL["experience"] += amount
		gained_xp_signal.emit(amount)
		
	var major_new_level = get_level_from_xp(major.SKILL["experience"])
	
	#MAJOR LEVEL UPDATES
	while major.SKILL["level"] < major_new_level:
		major.SKILL["level"] += 1
		if major.SKILL.has("efficiency"):
			major.SKILL["efficiency"] += major.SKILL["efficiency rate"]

		if major.SKILL["level"] >= MAX_LEVEL:
			major.SKILL["level"] = MAX_LEVEL
			break
	
	if minor != null:
		minor["experience"] += amount
		var minor_new_level = get_level_from_xp(minor["experience"])
		#MINOR LEVEL UPDATES
		while minor["level"] < minor_new_level:
			minor["level"] += 1
			minor["efficiency"] += minor["efficiency rate"]
			if minor["level"] >= MAX_LEVEL:
				minor["level"] = MAX_LEVEL
				break

		exp_updated_signal.emit(amount, minor)
	major.signal_exp(amount)


func on_level_up(skill_data: Dictionary):
	#update efficiency
	skill_data["efficiency"] += skill_data["efficiency increase rate"]
	print("Leveled up!")
	print("Current process" + " is level " + str(int(skill_data.level)))
