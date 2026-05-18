extends Node

#GENERAL MODULE DATA
var SKILL = {
	"name": "Mining",
	"level": 1,
	"experience": 0,
}

var DATA = {
	"name": "Data",
	"tier name": "TIER I | DATA",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"unlocked": true,
	"base speed": 0.25,
	"overclock speed": 0.0625,
	"overheat speed": 1.0,
	"heat": 1,
	"overclock heat": 3,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": Items.DATA,
	"resource amount gained": 1,
	"description": "Generates data. Used as the main currency.",
	"efficiency description": "Chance to receive multiple data."
}

var LOGS = {
	"name": "Logs",
	"tier name": "TIER II | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 725,
	"command": "log-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.02,
	"unlocked": true,
	"base speed": 0.6,
	"overclock speed": 0.2,
	"overheat speed": 2.4,
	"heat": 3,
	"overclock heat": 7,
	"overheat heat": 1,
	"requirements": [],
	"resource gained": Items.LOGS,
	"resource amount gained": 1,
	"description": "Finds logs that can be parsed for a random assortment of items.",
	"efficiency description": "Chance to receive multiple logs."
}

var minor_processes = [
	DATA,
	LOGS
]

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount
