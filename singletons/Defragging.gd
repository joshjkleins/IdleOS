extends Node

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
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Mining,
	"bonus time": 10,
	"description": "Efficiency doubled for 10 minutes."
}

var PARSING = {
	"name": "Parsing",
	"unlocked": false,
	"unlock cost": 100,
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Parsing,
	"bonus time": 10,
	"description": "Efficiency doubled for 10 minutes."
}


var CRACKING = {
	"name": "Cracking",
	"unlocked": false,
	"unlock cost": 100,
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Cracking,
	"bonus time": 10,
	"description": "Efficiency doubled for 10 minutes."
}


var MATCHING = {
	"name": "Matching",
	"unlocked": false,
	"unlock cost": 100,
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Matching,
	"bonus time": 10,
	"description": "Efficiency doubled for 10 minutes."
}

var PHISHING = {
	"name": "Phishing",
	"unlocked": false,
	"unlock cost": 100,
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Phishing,
	"bonus time": 10,
	"description": "Efficiency doubled for 10 minutes."
}

var HACKING = {
	"name": "Hacking",
	"unlocked": false,
	"unlock cost": 100,
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Hacking,
	"bonus time": 10,
	"description": "Increase bandwidth regeneration."
}

var DECODING = {
	"name": "Decoding",
	"unlocked": false,
	"unlock cost": 100,
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Decoding,
	"bonus time": 10,
	"description": "Efficiency doubled for 10 minutes."
}

func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

var minor_processes = [MINING, PARSING, CRACKING, MATCHING, PHISHING, HACKING, DECODING]

func activate_cooldown():
	SKILL["on cooldown"] = true
	var now = Time.get_unix_time_from_system()
	SKILL["cooldown"] = now + (30 * 60) #30 min

func on_cooldown() -> bool:
	return Time.get_unix_time_from_system() < SKILL["cooldown"]

func get_cd_time_remaining(time) -> int:
	return max(0, time - Time.get_unix_time_from_system())

func get_cd_time_text() -> String:
	var remaining = get_cd_time_remaining(SKILL["cooldown"])

	var minutes = remaining / 60
	var seconds = remaining % 60

	return "%02d:%02d" % [minutes, seconds]
