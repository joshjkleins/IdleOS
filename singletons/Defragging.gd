extends Node

signal on_cooldown_signal #used to trigger HUD countdown in defragging view

#GENERAL MODULE DATA
var SKILL = {
	"name": "Defragging",
	"color": Color("#EF4444"),
	"cooldown": 0,
	"command": "cd defragging"
}

var MINING = {
	"name": "Mining",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.LOGS, "amount": 15 },
	"skill": Mining,
	"bonus time": 10,
	"bonus efficiency": 1.50,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -mining"
}

var PARSING = {
	"name": "Parsing",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.ENCRYPTED_PASSWORDS, "amount": 15 },
	"skill": Parsing,
	"bonus time": 10,
	"bonus efficiency": 1.50,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -parsing"
}


var CRACKING = {
	"name": "Cracking",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.USERNAMES, "amount": 15 },
	"skill": Cracking,
	"bonus time": 10,
	"bonus efficiency": 1.50,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -cracking"
}


var MATCHING = {
	"name": "Matching",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.CREDENTIALS, "amount": 15 },
	"skill": Matching,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -matching"
}

var PHISHING = {
	"name": "Phishing",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.IP_ADDRESS, "amount": 15 },
	"skill": Phishing,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -phishing"
}

var HACKING = {
	"name": "Hacking",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.SQL_INJECTOR, "amount": 15 },
	"skill": Hacking,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -hacking"
}

var DECODING = {
	"name": "Decoding",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.PASSWORDS, "amount": 15 },
	"skill": Decoding,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -decoding"
}

var COMPILING = {
	"name": "Compiling",
	"unlocked": true,
	"unlock cost": 100,
	"requirements": { "item": Items.SCHOOL_PAYLOAD, "amount": 15 },
	"skill": Compiling,
	"bonus time": 10,
	"bonus efficiency": 1.5,
	"description": "Efficiency increased by 50%.",
	"command": "defrag -compiling"
}

func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

var minor_processes = [MINING, PARSING, CRACKING, MATCHING, PHISHING, HACKING, DECODING, COMPILING]

func has_requirements(skill: Dictionary):
	var item = skill["requirements"]["item"]
	var amount = skill["requirements"]["amount"]
	if Inventory.get_amount(item) < amount:
		return false
	return true

func activate_cooldown():
	SKILL["on cooldown"] = true
	var now = Time.get_unix_time_from_system()
	var minute = 60
	SKILL["cooldown"] = now + (20 * minute) #30 min = 30 * 60
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


func save_data() -> Dictionary:
	return {
		"skill": {
			"experience": SKILL.get("experience", 0),
			"level": SKILL.get("level", 1),
			"cooldown": SKILL.get("cooldown", 0),
			"on cooldown": SKILL.get("on cooldown", false)
		},
		"upgrades": {
			"mining": MINING.get("unlocked", false),
			"parsing": PARSING.get("unlocked", false),
			"cracking": CRACKING.get("unlocked", false),
			"matching": MATCHING.get("unlocked", false),
			"phishing": PHISHING.get("unlocked", false),
			"hacking": HACKING.get("unlocked", false),
			"decoding": DECODING.get("unlocked", false),
			"compiling": COMPILING.get("unlocked", false)
		}
	}


func load_data(data: Dictionary):
	if data.has("skill"):
		var skill_data = data["skill"]

		SKILL["experience"] = skill_data.get("experience", 0)
		SKILL["level"] = skill_data.get("level", 1)
		SKILL["cooldown"] = skill_data.get("cooldown", 0)
		SKILL["on cooldown"] = skill_data.get("on cooldown", false)

	if data.has("upgrades"):
		var upgrades = data["upgrades"]

		MINING["unlocked"] = upgrades.get("mining", MINING["unlocked"])
		PARSING["unlocked"] = upgrades.get("parsing", PARSING["unlocked"])
		CRACKING["unlocked"] = upgrades.get("cracking", CRACKING["unlocked"])
		MATCHING["unlocked"] = upgrades.get("matching", MATCHING["unlocked"])
		PHISHING["unlocked"] = upgrades.get("phishing", PHISHING["unlocked"])
		HACKING["unlocked"] = upgrades.get("hacking", HACKING["unlocked"])
		DECODING["unlocked"] = upgrades.get("decoding", DECODING["unlocked"])
		COMPILING["unlocked"] = upgrades.get("compiling", COMPILING["unlocked"])
