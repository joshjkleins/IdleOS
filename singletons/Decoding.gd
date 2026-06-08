extends Node

signal decode_cycle_completed
signal xp_gained

# When the player earns the bonus
var bonus_expires_at: int

#GENERAL MODULE DATA
var SKILL = {
	"name": "Decoding",
	"level": 1,
	"experience": 0,
	"color": Color("#378ADD"),
}

var CACHE = {
	"name": "Cache",
	"tier name": "TIER I | CACHE",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.03,
	"efficiency rate": 0.001,
	"unlocked": true,
	"base speed": 0.2,
	"overclock speed": 0.05,
	"overheat speed": 1.0,
	"heat": 5,
	"overclock heat": 7,
	"overheat heat": 2,
	"requirements": "cache",
	"description": "Decrypt caches gained from hacking to reveal additional items.",
	"efficiency description": "Chance to find rare item.",
	"signal": decode_cycle_completed
}


var minor_processes = [
	CACHE
]

func signal_exp(amount: int):
	xp_gained.emit()

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 1.0, "increase per level": 0.005 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
