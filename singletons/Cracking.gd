extends Node

#GENERAL MODULE DATA
var SKILL = {
	"name": "Cracking",
	"level": 1,
	"experience": 0,
	"color": Color("#EF9F27"),
}

var PASSWORD = {
	"name": "Password",
	"tier name": "TIER I | PASSWORD",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 3,
	"overclock heat": 8,
	"overheat heat": 1,
	"requirements": Items.ENCRYPTED_PASSWORDS,
	"resource gained": Items.PASSWORDS,
	"resource amount gained": 1,
	"description": "Cracks encrypted passwords, transforming them into passwords",
	"efficiency description": "Chance to instantly crack password"
}

var PINS = {
	"name": "PIN",
	"tier name": "TIER I | PINS",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"base speed": 3.0,
	"overclock speed": 1.0,
	"overheat speed": 9.0,
	"heat": 3,
	"overclock heat": 8,
	"overheat heat": 1,
	"requirements": Items.ENCRYPTED_PINS,
	"resource gained": Items.PINS,
	"resource amount gained": 1,
	"description": "Cracks encrypted PINS, transforming them into PINS",
	"efficiency description": "Chance to instantly crack PINS"
}

var minor_processes = [
	PASSWORD,
	PINS
]

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount


var random_four_digit_words: Array = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]
