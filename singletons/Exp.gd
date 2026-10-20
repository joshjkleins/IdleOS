extends Node

signal gained_xp_signal
signal exp_updated_signal


const MAX_LEVEL: int = 99 # highest process unlock level is 80 (Compiling: Government)

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
		print('leveled up')
		major.SKILL["level"] += 1
		refresh_process_unlocks(major)
		major.SKILL["level up signal"].emit()
		Audiomanager.play_sfx("level_up")
		if major != Hacking:
			Inventory.add_resource(major.vm_token, 1)
		if level_bonus_applies(major) and int(major.SKILL["level"]) % LEVEL_BONUS_STEP == 0:
			Signals.system_message_signal.emit("[color=#4ec9b0]%s level %d bonus: +%s VM token chance per cycle (total +%s)[/color]" % [
				major.SKILL.name, int(major.SKILL["level"]), _pct(LEVEL_TOKEN_BONUS), _pct(vm_token_level_bonus(major))])
		if major.SKILL.has("efficiency"):
			major.SKILL["efficiency"] += major.SKILL["efficiency rate"]

		if major.SKILL["level"] >= MAX_LEVEL:
			major.SKILL["level"] = MAX_LEVEL
			break
	major.signal_exp(amount)
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
	


func on_level_up(skill_data: Dictionary):
	#update efficiency
	skill_data["efficiency"] += skill_data["efficiency increase rate"]
	print("Leveled up!")
	print("Current process" + " is level " + str(int(skill_data.level)))


#region process unlocks + saving
## Level bonus: every LEVEL_BONUS_STEP levels of a skill that makes VM tokens, +LEVEL_TOKEN_BONUS VM token chance
## per cycle (added to each process's base-speed chance, so tokens per hour still don't depend on speed).
## Hacking and Defragging don't make VM tokens and get none.
const LEVEL_BONUS_STEP := 5
const LEVEL_TOKEN_BONUS := 0.001

func level_bonus_applies(major) -> bool:
	return major in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling]

func vm_token_level_bonus(major) -> float:
	if !level_bonus_applies(major):
		return 0.0
	return LEVEL_TOKEN_BONUS * int(int(major.SKILL["level"]) / LEVEL_BONUS_STEP)

func _pct(v: float) -> String:
	return ("%.1f%%" % (v * 100.0))

## 'info <skill>': the bonus so far and the next one only
func level_bonus_text(major) -> String:
	if !level_bonus_applies(major):
		return ""
	var lvl = int(major.SKILL["level"])
	var t = "\n[color=#4ec9b0]LEVEL BONUS[/color] [color=#666666]· every %d levels: +%s VM token chance per cycle[/color]\n" % [LEVEL_BONUS_STEP, _pct(LEVEL_TOKEN_BONUS)]
	t += "├─ Now      +%s  (level %d)\n" % [_pct(vm_token_level_bonus(major)), lvl]
	if lvl >= MAX_LEVEL:
		t += "└─ Next     maxed\n"
	else:
		var nxt = (int(lvl / LEVEL_BONUS_STEP) + 1) * LEVEL_BONUS_STEP
		if nxt > MAX_LEVEL:
			t += "└─ Next     none (last bonus at level %d)\n" % (int(MAX_LEVEL / LEVEL_BONUS_STEP) * LEVEL_BONUS_STEP)
		else:
			t += "└─ Next     level %d: +%s total\n" % [nxt, _pct(LEVEL_TOKEN_BONUS * int(nxt / LEVEL_BONUS_STEP))]
	return t

## Processes unlock once their skill reaches "unlock level" (and never re-lock).
## (The old header did this as a side effect of displaying a skill; now it happens on level up + load.)
func refresh_process_unlocks(major) -> void:
	for p in major.minor_processes:
		if major.SKILL.level >= p.get("unlock level", 1):
			p["unlocked"] = true

## Tier of a tier-specific process (Mining, Cracking, Matching, Compiling payloads), else 0.
func process_tier(major, p: Dictionary) -> int:
	match major:
		Mining:
			return Mining.minor_processes.find(p) + 1
		Cracking:
			return Cracking.minor_processes.filter(func(x): return x != Cracking.VM).find(p) + 1
		Matching:
			return Matching.minor_processes.find(p) + 1
		Compiling:
			return Compiling.get_payload_processes().find(p) + 1
	return 0

## Tier-specific processes also need their tier (location) unlocked, not just the skill level. "" = ok.
func tier_block_reason(major, p: Dictionary) -> String:
	var t = process_tier(major, p)
	if t > 1 and !Upgrades.tier_unlocked(t):
		return "%s requires %s access (Tier %d)." % [p.name, Upgrades.tier_name(t), t]
	return ""

func refresh_all_process_unlocks() -> void:
	if DEV_MAX_ALL:
		_dev_max_all()
	for major in [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling]:
		refresh_process_unlocks(major)

## TESTING: every skill and process at max level and unlocked (applied at startup and after every
## load, so new processes are covered automatically). Turn off before release; saves made with it on
## keep the levels.
const DEV_MAX_ALL := false

func _dev_max_all() -> void:
	for major in [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling]:
		major.SKILL["level"] = MAX_LEVEL
		major.SKILL["experience"] = max(major.SKILL["experience"], xp_for_level(MAX_LEVEL))
		for p in major.minor_processes:
			if !p.has("level"):
				continue
			var key = str(major.SKILL.name) + "/" + str(p.name)
			if p.has("efficiency") and !_base_efficiency.has(key):
				_base_efficiency[key] = float(p["efficiency"])
			p["level"] = MAX_LEVEL
			p["experience"] = max(int(p.get("experience", 0)), xp_for_level(MAX_LEVEL))
			if p.has("efficiency"):
				p["efficiency"] = _base_efficiency[key] + float(p.get("efficiency rate", 0.0)) * (MAX_LEVEL - 1)
			p["unlocked"] = true

## Every process's progress, keyed by process name (skills used to save only their first process).
func processes_save_data(major) -> Dictionary:
	var out := {}
	for p in major.minor_processes:
		out[str(p.name)] = {
			"level": p.get("level", 1),
			"experience": p.get("experience", 0),
			"efficiency": p.get("efficiency", 0.0),
			"unlocked": p.get("unlocked", false),
		}
	return out

var _base_efficiency := {} # "Skill/Process" -> efficiency as defined in code, captured before any load

func processes_load_data(major, data: Dictionary) -> void:
	for p in major.minor_processes:
		var key = str(major.SKILL.name) + "/" + str(p.name)
		if p.has("efficiency") and !_base_efficiency.has(key):
			_base_efficiency[key] = float(p["efficiency"])
		var saved: Dictionary = data.get(str(p.name), {})
		if !saved.is_empty():
			p["level"] = int(saved.get("level", p.get("level", 1)))
			p["experience"] = int(saved.get("experience", p.get("experience", 0)))
			p["unlocked"] = p.get("unlocked", false) or bool(saved.get("unlocked", false))
		# Efficiency always comes from level (base + rate per level), never from the save: retuned bases
		# apply to old saves, and saves inflated by the old legacy-key bug heal on load.
		# (The base is captured above, so nothing may write "efficiency" before this runs.)
		if p.has("efficiency"):
			p["efficiency"] = _base_efficiency[key] + float(p.get("efficiency rate", 0.0)) * (p.get("level", 1) - 1)
	refresh_process_unlocks(major)

func _ready() -> void:
	SaveManager.save_loaded.connect(refresh_all_process_unlocks)
	refresh_all_process_unlocks.call_deferred()
#endregion
