extends Node

signal cred_cycle_completed
signal account_cycle_completed
signal xp_gained

# When the player earns the bonus
var bonus_expires_at: int

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
	"efficiency description": "Chance to not consume a username or password.",
	"signal": cred_cycle_completed
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
	"efficiency description": "Chance to not consume a PIN or Account number.",
	"signal": account_cycle_completed
}

var minor_processes = [
	CREDENTIAL,
	ACCOUNT
]

func signal_exp(amount: int):
	xp_gained.emit()

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 1.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
