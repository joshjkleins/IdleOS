extends Node

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
