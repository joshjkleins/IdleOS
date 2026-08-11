extends Node

var MINING = {
	"skill": Mining,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "mining.speed",
			"description": "Reduces time required to complete mining cycle.",
			"levels": [ 
				{
					"level": 1,
					"id": "mining.speed", 
					"requirements": [{"item": Items.LOGS, "amount": 10 }],
					"amount": 0.05,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "mining.speed", 
					"requirements":[ {"item": Items.LOGS, "amount": 15 }],
					"amount": 0.05,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "mining.speed", 
					"requirements": [{"item": Items.LOGS, "amount": 25 }],
					"amount": 0.05,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Efficiency",
			"id": "mining.efficiency",
			"description": "Increases mining efficiency.",
			"levels": [ 
				{
					"level": 1,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 10 }],
					"amount": 0.25,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 15 }],
					"amount": 0.25,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 25 }],
					"amount": 0.25,
					"unlocked": false
				}
			]
		}
	],
}

var PARSING = {
	"skill": Parsing,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "parsing.speed",
			"description": "Reduces time required to complete parsing cycle.",
			"levels": [ 
				{
					"level": 1,
					"id": "mining.speed", 
					"requirements": [{"item": Items.LOGS, "amount": 10 }],
					"amount": 0.05,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "mining.speed", 
					"requirements":[ {"item": Items.LOGS, "amount": 15 }],
					"amount": 0.05,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "mining.speed", 
					"requirements": [{"item": Items.LOGS, "amount": 25 }],
					"amount": 0.05,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Efficiency",
			"id": "parsing.efficiency",
			"description": "Increases parsing efficiency.",
			"levels": [ 
				{
					"level": 1,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 10 }],
					"amount": 0.25,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 15 }],
					"amount": 0.25,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 25 }],
					"amount": 0.25,
					"unlocked": false
				}
			]
		}
	],
}

var all_upgrades = [ MINING, PARSING ]

func get_package_info(package_id):
	for up in all_upgrades:
		for i in up.upgrades:
			if i.id == package_id:
				return i

func get_skill_from_package_id(package_id):
	for up in all_upgrades:
		for i in up.upgrades:
			if i.id == package_id:
				var col = up.skill.SKILL.color
				var color = col.to_html()
				var colored_name = "[color=#%s]%s[/color]" % [color, up.skill.SKILL.name]
				return colored_name

func get_skill_level_from_package_id(package_id):
	var level = 0
	var max_level = 0
	for up in all_upgrades:
		for i in up.upgrades:
			if i.id == package_id:
				#i = compelete package
				max_level = i.levels.size()
				for lvl in i.levels:
					if lvl.unlocked:
						level += 1
				
				return str(level) + "/" + str(max_level)


func get_current_effect_total_from_package(package):
	var amount = 0.0
	for lvl in package.levels:
		if lvl.unlocked:
			amount += lvl.amount
	return amount

func get_next_effect_total_from_package(package):
	var amount = 0.0
	
	for lvl in package.levels:
		amount += lvl.amount
		
		if !lvl.unlocked:
			break
	return amount
	

func get_upgrade_requirement_from_package(package) -> Array:
	for lvl in package.levels:
		if lvl.unlocked == false:
			return lvl.requirements
	return []
