extends Node

signal spear_cycle_completed

var max_lines: int = 3
var current_lines = []

#GENERAL MODULE DATA
var SKILL = {
	"name": "Phishing",
	"level": 1,
	"experience": 0,
	"color": Color("#1d9e75")
}

var SPEAR = {
	"name": "Spear phishing",
	"tier name": "TIER I | SPEAR",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "spear-phishing",
	"efficiency": 0.0,
	"efficiency rate": 0.003,
	"unlocked": true,
	"base speed": 8.0,
	"overclock speed": 5.0,
	"overheat speed": 25.0,
	"heat": 1,
	"overclock heat": 3,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": [Items.USERNAMES, Items.PASSWORDS],
	"resource amount gained": 1,
	"description": "Send out email to targeted persons in an attempt to get usernames and passwords",
	"efficiency description": "Chance for successful attempt",
	"signal": spear_cycle_completed
}

var minor_processes = [
	SPEAR
]

func add_line(line: Dictionary) -> bool:
	if current_lines.size() >= max_lines:
		return false
	
	current_lines.append(line)
	return true


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
