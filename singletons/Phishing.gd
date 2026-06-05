extends Node

signal spear_cycle_completed
signal whale_cycle_completed

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
	"name": "Spear",
	"tier name": "TIER I | SPEAR",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "spear-phishing",
	"efficiency": 0.3,
	"efficiency rate": 0.005,
	"unlocked": true,
	"wait time min": 5.0,
	"wait time max": 10.0,
	"download time": 7.5,
	"overclocked download time": 3.75,
	"overheated download time": 22.5,
	"heat": 2,
	"overclock heat": 5,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": [Items.USERNAMES, Items.ENCRYPTED_PASSWORDS],
	"resource amount gained": 1,
	"description": "Send out emails in an attempt to get usernames and passwords",
	"efficiency description": "Chance for successful bite",
	"signal": spear_cycle_completed
}

var WHALING = {
	"name": "Whaling",
	"tier name": "TIER I | WHALING",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "whale-phishing",
	"efficiency": 0.2,
	"efficiency rate": 0.003,
	"unlocked": true,
	"wait time min": 6.0,
	"wait time max": 12.0,
	"download time": 9.5,
	"overclocked download time": 5.0,
	"overheated download time": 25.5,
	"heat": 4,
	"overclock heat": 7,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": [Items.ACCOUNT_NUMBERS, Items.ENCRYPTED_PINS],
	"resource amount gained": 1,
	"description": "Targets high level individuals for a chance to extract PINs and account numbers",
	"efficiency description": "Chance for successful bite",
	"signal": whale_cycle_completed
}

var minor_processes = [
	SPEAR,
	WHALING
]

func add_line(line):
	current_lines.append(line)

func remove_line(line):
	if current_lines.has(line):
		current_lines.erase(line)

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount

var process_upgrades = {
	"max lines": { "id": 1, "name": "Max lines", "level": 0, "amount": 0, "increase per level": 1 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 1.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
