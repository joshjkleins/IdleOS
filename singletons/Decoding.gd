extends Node

#GENERAL MODULE DATA
var SKILL = {
	"name": "Decoding",
	"level": 1,
	"experience": 0,
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
	"efficiency description": "Chance to find rare item."
}


var minor_processes = [
	CACHE
]

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount
