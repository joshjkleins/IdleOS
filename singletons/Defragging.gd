extends Node

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
	"name": "Defragging",
	"level": 1,
	"experience": 0,
	"efficiency": 0.05,
	"efficiency rate": 0.0015,
	"color": Color("#cf0000"),
}

var MINING = {
	"name": "Mining",
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
	"efficiency description": "Chance to receive multiple logs."
}

var PARSING = {
	"name": "Parsing",
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
	"efficiency description": "Chance to receive multiple logs."
}

func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

var minor_processes = [MINING, PARSING]
