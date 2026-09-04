extends Node

signal xp_gained
signal hacking_level_up_signal

var current_anon = 100
var max_anon = 100
var current_bandwidth = 10
var max_bandwidth = 10
var bandwidth_recovery_rate = 1
var bandwidth_recovery_speed = 1.0

# When the player earns the bonus
var bonus_expires_at: int

func grant_bonus():
	var now = Time.get_unix_time_from_system()
	bonus_expires_at = now + (30 * 60) # 30 minutes from now

func has_bonus() -> bool:
	return Time.get_unix_time_from_system() < bonus_expires_at

func get_bonus_time_remaining() -> int:
	return max(0, bonus_expires_at - Time.get_unix_time_from_system())

func get_bonus_time_text() -> String:
	var remaining = get_bonus_time_remaining()

	var minutes = remaining / 60
	var seconds = remaining % 60

	return "%02d:%02d" % [minutes, seconds]

#GENERAL MODULE DATA
var SKILL = {
	"name": "Hacking",
	"level": 1,
	"experience": 0,
	"efficiency": 0.05,
	"efficiency rate": 0.0015,
	"efficiency description": "Chance for hacking attack to deal double damage",
	"color": Color("#22C55E"),
	"level up signal": hacking_level_up_signal,
	"command": "cd hacking",
	"sfx": "cracking_item_received"
}

var SCHOOL = {
	"name": "School",
	"tier name": "TIER I | PASSWORD",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "crack -pw",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 3,
	"overclock heat": 8,
	"overheat heat": 1,
	"description": "Cracks encrypted passwords, transforming them into passwords",
	"targets": [
		{
			"name": "Student",
			"difficulty": "Easy",
			"command": "hack student",
			"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 1},
			"heat": 0.2,
			"exp": 600,
			"integrity": 100,
			"firewall": 10,
			"counter": 5,
			"counter speed": 16.0,
			"loot": Items.STUDENT_CACHE
		},
		{
			"name": "Administrator",
			"difficulty": "Easy",
			"command": "hack administrator",
			"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 2},
			"heat": 5,
			"exp": 600,
			"integrity": 100,
			"firewall": 10,
			"counter": 10,
			"counter speed": 5.0,
			"loot": Items.ADMIN_CACHE
		},
		{
			"name": "Vice Principal",
			"difficulty": "Medium",
			"command": "hack vice-principal",
			"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 3},
			"heat": 5,
			"exp": 600,
			"integrity": 100,
			"firewall": 10,
			"counter": 10,
			"counter speed": 5.0,
			"loot": Items.VICE_PRINCIPAL_CACHE
		},
		{
			"name": "Principal",
			"difficulty": "Medium",
			"command": "hack principal",
			"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 4},
			"heat": 5,
			"exp": 600,
			"integrity": 100,
			"firewall": 10,
			"counter": 10,
			"counter speed": 5.0,
			"loot": Items.PRINCIPAL_CACHE
		},
		{
			"name": "Superintendent",
			"difficulty": "Hard",
			"command": "hack superintendent",
			"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 5},
			"heat": 5,
			"exp": 600,
			"integrity": 100,
			"firewall": 10,
			"counter": 10,
			"counter speed": 5.0,
			"loot": Items.SUPERINTENDENT_CACHE
		}
	]
}

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

var minor_processes = [SCHOOL]
#
#var process_upgrades = {
	#"anonymity": { "id": 1, "name": "Anonymity", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"max bandwidth": { "id": 1, "name": "Max bandwidth", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"bandwidth regen": { "id": 1, "name": "Bandwidth regen rate", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
#}
#
#func get_upgrade_cost(upgrade_stat: String) -> int:
	#return process_upgrades[upgrade_stat]["level"] * 800 + 100
#
#func upgraded(upgrade_stat: Dictionary):
	#upgrade_stat["level"] += 1
	#upgrade_stat["amount"] += upgrade_stat["increase per level"]


func save_data() -> Dictionary:
	return {
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"skill_efficiency": SKILL["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	SKILL["efficiency"] = float(data.get("skill_efficiency", SKILL["efficiency"]))
