extends Node

signal on_cooldown_signal #used to trigger HUD countdown in defragging view

#GENERAL MODULE DATA
var SKILL = {
	"name": "Defragging",
	"color": Color("#cf0000"),
	"cooldown": 0,
}

var MINING = {
	"name": "Mining",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Mining,
	"bonus time": 5,
	"bonus efficiency": 1.50,
	"description": "Efficiency increased by 50%."
}

var PARSING = {
	"name": "Parsing",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Parsing,
	"bonus time": 10,
	"bonus efficiency": 1.50,
	"description": "Efficiency increased by 50%."
}


var CRACKING = {
	"name": "Cracking",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Cracking,
	"bonus time": 10,
	"bonus efficiency": 1.50,
	"description": "Efficiency increased by 50%."
}


var MATCHING = {
	"name": "Matching",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Matching,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%."
}

var PHISHING = {
	"name": "Phishing",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Phishing,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%."
}

var HACKING = {
	"name": "Hacking",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Hacking,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%."
}

var DECODING = {
	"name": "Decoding",
	"unlocked": true,
	"unlock cost": 100,
	"skill": Decoding,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%."
}

func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

var minor_processes = [MINING, PARSING, CRACKING, MATCHING, PHISHING, HACKING, DECODING]

func activate_cooldown():
	SKILL["on cooldown"] = true
	var now = Time.get_unix_time_from_system()
	SKILL["cooldown"] = now + (15) #30 min = 30 * 60
	on_cooldown_signal.emit()

func on_cooldown() -> bool:
	return Time.get_unix_time_from_system() < SKILL["cooldown"]

func get_cd_time_remaining(time) -> int:
	return max(0, time - Time.get_unix_time_from_system())

func get_cd_time_text() -> String:
	var remaining = get_cd_time_remaining(SKILL["cooldown"])

	var minutes = remaining / 60
	var seconds = remaining % 60

	return "%02d:%02d" % [minutes, seconds]
