extends Node

signal log_cycle_completed

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
	"name": "Mining",
	"level": 1,
	"experience": 0,
	"color": Color("#1d9e75")
}

var LOGS = {
	"name": "Logs",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"unlocked": true,
	"base speed": 0.4,
	"overclock speed": 0.2,
	"overheat speed": 1.0,
	"heat": 1,
	"overclock heat": 3,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": Items.LOGS,
	"resource amount gained": 1,
	"description": "Finds logs that can be parsed for a random assortment of items.",
	"efficiency description": "Chance to receive multiple logs.",
	"signal": log_cycle_completed
}

#var LOGS = {
	#"name": "Logs",
	#"tier name": "TIER II | LOGS",
	#"level": 1,
	#"experience": 0,
	#"experience per level": 725,
	#"command": "log-mining",
	#"efficiency": 0.0,
	#"efficiency rate": 0.02,
	#"unlocked": true,
	#"base speed": 0.6,
	#"overclock speed": 0.2,
	#"overheat speed": 2.4,
	#"heat": 3,
	#"overclock heat": 7,
	#"overheat heat": 1,
	#"requirements": [],
	#"resource gained": Items.LOGS,
	#"resource amount gained": 1,
	#"description": "Finds logs that can be parsed for a random assortment of items.",
	#"efficiency description": "Chance to receive multiple logs.",
	#"signal": log_cycle_completed
#}

var minor_processes = [
	LOGS
]

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 1.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
