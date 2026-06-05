extends Node

# When the player earns the bonus
var bonus_expires_at: int

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
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Mining,
	"bonus time": 30,
	"description": "Efficiency doubled for 30 minutes."
}

var PARSING = {
	"name": "Parsing",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"efficiency": 0.0,
	"efficiency rate": 0.08,
	"skill": Parsing,
	"bonus time": 30,
	"description": "Efficiency doubled for 30 minutes."
}

func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

var minor_processes = [MINING, PARSING]
