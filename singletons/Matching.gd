extends Node

#GENERAL MODULE DATA
var SKILL = {
	"name": "Matching",
	"level": 1,
	"experience": 0,
	"color": Color("#D4537E"),
}

var CREDENTIAL = {
	"name": "Credential",
	"tier name": "TIER I | CREDENTIAL",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"base speed": 1.0,
	"overclock speed": 0.33,
	"overheat speed": 3.0,
	"heat": 1,
	"overclock heat": 1,
	"overheat heat": 1,
	"requirements": [Items.USERNAMES, Items.PASSWORDS],
	"resource gained": Items.CREDENTIALS,
	"resource amount gained": 1,
	"description": "Creates credentials using passwords & usernames.",
	"efficiency description": "Chance to not consume a username or password."
}

var ACCOUNT = {
	"name": "Account",
	"tier name": "TIER I | ACCOUNT",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"base speed": 1.0,
	"overclock speed": 0.33,
	"overheat speed": 3.0,
	"heat": 1,
	"overclock heat": 1,
	"overheat heat": 1,
	"requirements": [Items.PINS, Items.ACCOUNT_NUMBERS],
	"resource gained": Items.ACCOUNT_ACCESS_TOKENS,
	"resource amount gained": 1,
	"description": "Creates account access token using PINs & Account numbers.",
	"efficiency description": "Chance to not consume a PIN or Account number."
}

var minor_processes = [
	CREDENTIAL,
	ACCOUNT
]

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount
