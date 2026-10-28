extends Node

signal gained_xp_signal
signal exp_updated_signal
signal process_unlocked_signal # a level up just unlocked processes (they wait in unlock_queue for the terminal)

## [{"skill": major, "process": p}] unlocked by a level up, not yet announced (idle_os_2 prints and clears it:
## right away at the main terminal, or once you're back from hacking / the offline download).
var unlock_queue: Array = []


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

## 2026-10-26 (skill revamp): only the main skill levels. A process gives its skill XP (minor is the process
## that earned it, passed on to listeners) and its efficiency follows the skill level (refresh_efficiency).
## Defrag XP (Police) adds +50% while it runs.
func add_xp(major, minor, amount: int = 0): #singleton as param
	if amount > 0 and major != Defragging:
		amount = int(round(amount * Defragging.get_xp_multiplier()))
	if amount > 0:
		major.SKILL["experience"] += amount
		gained_xp_signal.emit(amount)
		Drivers.add_skill_xp(str(major.SKILL.name), amount) # equipped drivers rank up from their skill's XP
		
	var major_new_level = get_level_from_xp(major.SKILL["experience"])
	#MAJOR LEVEL UPDATES
	while major.SKILL["level"] < major_new_level:
		major.SKILL["level"] += 1
		refresh_efficiency(major) # before the signal: listeners show the new efficiency
		major.SKILL["level up signal"].emit()
		Drivers.on_level_up(str(major.SKILL.name), int(major.SKILL["level"]))
		Audiomanager.play_sfx("level_up")
		if major != Hacking:
			Inventory.add_resource(major.vm_token, 1)
		if level_bonus_applies(major) and int(major.SKILL["level"]) % LEVEL_BONUS_STEP == 0 and !Offline.computing:
			Signals.system_message_signal.emit("[color=#4ec9b0]%s level %d bonus: +%s VM token chance per cycle (total +%s)[/color]" % [
				major.SKILL.name, int(major.SKILL["level"]), _pct(LEVEL_TOKEN_BONUS), _pct(vm_token_level_bonus(major))])
		if major.SKILL.has("efficiency"):
			major.SKILL["efficiency"] += major.SKILL["efficiency rate"]

		if major.SKILL["level"] >= MAX_LEVEL:
			major.SKILL["level"] = MAX_LEVEL
			break
	major.signal_exp(amount)
	if minor != null:
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

## 2026-10-26 (skill revamp): processes unlock with their tier ("unlock tier": that tier's location is open;
## 1 = from the start), never from levels, and never re-lock. Newly opened ones queue for the tier-unlock screen.
func refresh_process_unlocks(major, announce: bool = false) -> void:
	var fresh = false
	for p in major.minor_processes:
		var open = Upgrades.tier_unlocked(int(p.get("unlock tier", 1)))
		if open and announce and !p.get("unlocked", false):
			unlock_queue.append({"skill": major, "process": p, "tier": int(p.get("unlock tier", 1))})
			fresh = true
		p["unlocked"] = open
	if fresh:
		process_unlocked_signal.emit()

## The tier a process opens with (1 = from the start)
func process_tier(_major, p: Dictionary) -> int:
	return int(p.get("unlock tier", 1))

## "" when the process's tier is open, otherwise why it can't run yet
func tier_block_reason(major, p: Dictionary) -> String:
	var t = process_tier(major, p)
	if t > 1 and !Upgrades.tier_unlocked(t):
		return "%s opens with %s access (Tier %d): finish the upload goal before it ('upload')." % [p.name, Upgrades.tier_name(t), t]
	return ""

## announce: a tier just opened (Stats.unlock_location), so what it brings goes to the tier-unlock screen
func refresh_all_process_unlocks(announce: bool = false) -> void:
	if DEV_MAX_ALL:
		_dev_max_all()
	for major in [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling]:
		refresh_process_unlocks(major, announce)
		refresh_efficiency(major)
	for p in Defragging.minor_processes:
		var open = Upgrades.tier_unlocked(int(p.get("unlock tier", 1)))
		if open and announce and !p.get("unlocked", false):
			unlock_queue.append({"skill": Defragging, "process": p, "tier": int(p.get("unlock tier", 1))})
		p["unlocked"] = open
	if announce and !unlock_queue.is_empty():
		process_unlocked_signal.emit()

## Process efficiency from the skill level: base + rate per level above "efficiency level" (the process's old unlock
## level, so a later process still starts near its base). One number per skill drives every process.
func process_efficiency(major, p: Dictionary) -> float:
	var key = str(major.SKILL.name) + "/" + str(p.name)
	if !_base_efficiency.has(key):
		_base_efficiency[key] = float(p.get("efficiency", 0.0))
	var lvl = int(major.SKILL.get("level", 1))
	var from = int(p.get("efficiency level", 1))
	return _base_efficiency[key] + float(p.get("efficiency rate", 0.0)) * max(0, lvl - max(1, from))

func refresh_efficiency(major) -> void:
	for p in major.minor_processes:
		if p.has("efficiency"):
			p["efficiency"] = process_efficiency(major, p)

## TESTING: every skill at max level and every tier's processes open (applied at startup and after every
## load). Turn off before release.
const DEV_MAX_ALL := false

func _dev_max_all() -> void:
	for major in [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling]:
		major.SKILL["level"] = MAX_LEVEL
		major.SKILL["experience"] = max(major.SKILL["experience"], xp_for_level(MAX_LEVEL))
		for p in major.minor_processes:
			p["unlocked"] = true

## Processes no longer save progress (no process levels since the skill revamp); kept for the save layout.
func processes_save_data(_major) -> Dictionary:
	return {}

var _base_efficiency := {} # "Skill/Process" -> efficiency as defined in code, captured before any load

## Old saves' process levels / XP are ignored (2026-10-26). Unlocks and efficiency are worked out again.
func processes_load_data(major, _data: Dictionary) -> void:
	for p in major.minor_processes:
		var key = str(major.SKILL.name) + "/" + str(p.name)
		if p.has("efficiency") and !_base_efficiency.has(key):
			_base_efficiency[key] = float(p["efficiency"])
		p["unlocked"] = false
	refresh_process_unlocks(major)
	refresh_efficiency(major)

func _ready() -> void:
	SaveManager.save_loaded.connect(refresh_all_process_unlocks)
	refresh_all_process_unlocks.call_deferred()
#endregion
