extends Node

var current_anon = 100
var max_anon = 100
var current_bandwidth = 10
var max_bandwidth = 10
var bandwidth_recovery_rate = 1
var bandwidth_recovery_speed = 1.0

#GENERAL MODULE DATA
var SKILL = {
	"name": "Hacking",
	"level": 1,
	"experience": 0,
	"efficiency": 0.05,
	"efficiency rate": 0.0015,
	"color": Color("#00CC55"),
}


func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

var minor_processes = []

var process_upgrades = {
	"anonymity": { "id": 1, "name": "Anonymity", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"max bandwidth": { "id": 1, "name": "Max bandwidth", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"bandwidth regen": { "id": 1, "name": "Bandwidth regen rate", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
