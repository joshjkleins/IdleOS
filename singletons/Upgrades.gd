extends Node

var MINING = {
	"skill": Mining,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "mining.speed",
			"description": "Increases mining speed.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "mining.speed", 
					"requirements": [{"item": Items.LOGS, "amount": 35 }],
					"amount": 0.50,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Efficiency",
			"id": "mining.efficiency",
			"description": "Increases mining efficiency.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "mining.efficiency", 
					"requirements": [{ "item": Items.LOGS, "amount": 120 }],
					"amount": 1.5,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "mining.overclock",
			"description": "Allows overclocking of Mining, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "mining.overclock", 
					"requirements": [{"item": Items.LOGS, "amount": 250 }, {"item": Items.PARENTS_CREDIT_CARD, "amount": 1 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var PARSING = {
	"skill": Parsing,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "parsing.speed",
			"description": "Increases parsing speed.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "parsing.speed", 
					"requirements": [{"item": Items.IP_ADDRESS, "amount": 20 }, {"item": Items.USERNAMES, "amount": 20 }, {"item": Items.ENCRYPTED_PASSWORDS, "amount": 20 }],
					"amount": 0.35,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Efficiency",
			"id": "parsing.efficiency",
			"description": "Increases parsing efficiency.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "parsing.efficiency", 
					"requirements": [{"item": Items.IP_ADDRESS, "amount": 50 }, {"item": Items.USERNAMES, "amount": 50 }, {"item": Items.ENCRYPTED_PASSWORDS, "amount": 50 }],
					"amount": 0.05,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "parsing.overclock",
			"description": "Allows overclocking of Parsing, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "parsing.overclock", 
					"requirements": [{"item": Items.USERNAMES, "amount": 50 }, {"item": Items.ENCRYPTED_PASSWORDS, "amount": 50 }, {"item": Items.IP_ADDRESS, "amount": 50 }, {"item": Items.FALSIFIED_TRANSCRIPT_DATABASE, "amount": 1 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var CRACKING = {
	"skill": Cracking,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "cracking.speed",
			"description": "Increases cracking speed.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "cracking.speed", 
					"requirements": [{"item": Items.PASSWORDS, "amount": 25 }],
					"amount": 0.3,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Efficiency",
			"id": "cracking.efficiency",
			"description": "Increases cracking efficiency.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "cracking.efficiency", 
					"requirements": [{ "item": Items.PASSWORDS, "amount": 55 }],
					"amount": 0.08,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "cracking.overclock",
			"description": "Allows overclocking of Parsing, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "cracking.overclock", 
					"requirements": [{ "item": Items.PASSWORDS, "amount": 80 }, { "item": Items.STUDENT_DISCIPLINARY_RECORDS, "amount": 1 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var MATCHING = {
	"skill": Matching,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "matching.speed",
			"description": "Increases matching speed.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "matching.speed", 
					"requirements": [{"item": Items.CREDENTIALS, "amount": 25 }],
					"amount": 0.25,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Efficiency",
			"id": "matching.efficiency",
			"description": "Increases matching efficiency.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "matching.efficiency", 
					"requirements": [{ "item": Items.CREDENTIALS, "amount": 55 }],
					"amount": 0.08,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Overclock",
			"id": "matching.overclock",
			"description": "Allows overclocking of Parsing, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "matching.overclock", 
					"requirements": [{ "item": Items.CREDENTIALS, "amount": 100 }, { "item": Items.SCHOOL_BUDGET_EMBEZZLEMENT_LOGS, "amount": 1 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var PHISHING = {
	"skill": Phishing,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Lines",
			"id": "phishing.lines",
			"description": "Increases max number of lines.",
			"current": 0,
			"levels": [ 
				{
					"level": 1,
					"id": "phishing.lines", 
					"requirements": [{"item": Items.SQL_INJECTOR, "amount": 20 }],
					"amount": 1,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "phishing.lines", 
					"requirements":[ {"item": Items.SQL_INJECTOR, "amount": 50 }, {"item": Items.PACKET_SPOOF, "amount": 10 }],
					"amount": 1,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "phishing.overclock",
			"description": "Allows overclocking of Phishing, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "parsing.overclock", 
					"requirements": [{"item": Items.SQL_INJECTOR, "amount": 100 }, {"item": Items.PACKET_SPOOF, "amount": 25 }, {"item": Items.DISTRICT_WIDE_MASTER_PASSWORD, "amount": 1 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var HACKING = {
	"skill": Hacking,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Damage",
			"id": "hacking.damage",
			"description": "Adds additional damage that SQL Injector's do to enemy integrity.",
			"current": 0,
			"display percentage": false,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.damage", 
					"requirements": [{"item": Items.STUDENT_CACHE, "amount": 10 }],
					"amount": 3,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "hacking.damage", 
					"requirements":[ {"item": Items.ADMIN_CACHE, "amount": 10 }],
					"amount": 7,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "hacking.damage", 
					"requirements": [{"item": Items.VICE_PRINCIPAL_CACHE, "amount": 10 }],
					"amount": 10,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Firewall",
			"id": "hacking.firewall",
			"description": "Increases SQL Injector damage to firewall.",
			"current": 0,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.firewall", 
					"requirements": [{"item": Items.SQL_INJECTOR, "amount": 20 }, {"item": Items.LOGS, "amount": 55 }],
					"amount": 2,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "hacking.firewall", 
					"requirements":[{"item": Items.SQL_INJECTOR, "amount": 40 }, {"item": Items.LOGS, "amount": 85 }, {"item": Items.STUDENT_DISCIPLINARY_RECORDS, "amount": 1 }],
					"amount": 3,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "hacking.firewall", 
					"requirements": [{"item": Items.SQL_INJECTOR, "amount": 90 }, {"item": Items.LOGS, "amount": 200 }, {"item": Items.SCHOOL_BUDGET_EMBEZZLEMENT_LOGS, "amount": 1 }],
					"amount": 4,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Healing",
			"id": "hacking.healing",
			"description": "Increases amount of anonymity restored by Packet Spoofs.",
			"current": 0,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.firewall", 
					"requirements": [{"item": Items.PACKET_SPOOF, "amount": 15 }],
					"amount": 5,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "hacking.firewall", 
					"requirements":[ {"item": Items.PACKET_SPOOF, "amount": 30 }],
					"amount": 5,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "hacking.firewall", 
					"requirements": [{"item": Items.PACKET_SPOOF, "amount": 80 }],
					"amount": 5,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Bandwidth Recovery",
			"id": "hacking.bandwidth_recovery",
			"description": "Increases amount of bandwidth recoverd per second.",
			"current": 0,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.bandwidth_recovery", 
					"requirements": [{"item": Items.PACKET_SPOOF, "amount": 25 }, {"item": Items.SQL_INJECTOR, "amount": 25 }, {"item": Items.PARENTS_CREDIT_CARD, "amount": 1}],
					"amount": 2,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Max Bandwidth",
			"id": "hacking.max_bandwidth",
			"description": "Increases max bandwidth.",
			"current": 0,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.max_bandwidth", 
					"requirements": [{"item": Items.PASSWORDS, "amount": 100 }, {"item": Items.ENCRYPTED_PASSWORDS, "amount": 100 }],
					"amount": 10,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Max Anonymity",
			"id": "hacking.max_anonymity",
			"description": "Increases max anonymity.",
			"current": 100,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.max_anonymity", 
					"requirements": [{"item": Items.IP_ADDRESS, "amount": 150 }, {"item": Items.USERNAMES, "amount": 150 }],
					"amount": 100,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "hacking.overclock",
			"description": "Allows overclocking of Hacking, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "hacking.overclock", 
					"requirements": [{"item": Items.PARENTS_CREDIT_CARD, "amount": 3 }, {"item": Items.FALSIFIED_TRANSCRIPT_DATABASE, "amount": 3 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var DECODING = {
	"skill": Decoding,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "decoding.speed",
			"description": "Increases decoding speed.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "decoding.speed", 
					"requirements": [{"item": Items.STUDENT_CACHE, "amount": 10 }],
					"amount": 0.4,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Efficiency",
			"id": "decoding.efficiency",
			"description": "Increases decoding efficiency.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "decoding.efficiency", 
					"requirements": [{ "item": Items.ADMIN_CACHE, "amount": 10 }],
					"amount": 0.05,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "decoding.overclock",
			"description": "Allows overclocking of Parsing, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "decoding.overclock", 
					"requirements": [{"item": Items.STUDENT_CACHE, "amount": 10 }, {"item": Items.ADMIN_CACHE, "amount": 10 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var COMPILING = {
	"skill": Compiling,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Speed",
			"id": "compiling.speed",
			"description": "Increases compiling speed.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "compiling.speed", 
					"requirements": [{"item": Items.SCHOOL_PAYLOAD, "amount": 25 }],
					"amount": 0.25,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Efficiency",
			"id": "compiling.efficiency",
			"description": "Increases compiling efficiency.",
			"current": 0.0,
			"levels": [ 
				{
					"level": 1,
					"id": "compiling.efficiency", 
					"requirements": [{"item": Items.SCHOOL_PAYLOAD, "amount": 75 }],
					"amount": 0.07,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overclock",
			"id": "compiling.overclock",
			"description": "Allows overclocking of Parsing, increasing speed and heat output.",
			"current": false,
			"levels": [ 
				{
					"level": 1,
					"id": "compiling.overclock", 
					"requirements": [{"item": Items.SCHOOL_PAYLOAD, "amount": 33 }, {"item": Items.ADMIN_CACHE, "amount": 3 }, {"item": Items.STUDENT_DISCIPLINARY_RECORDS, "amount": 1 }],
					"amount": true,
					"unlocked": false
				},
			]
		}
	],
}

var SYSTEM = {
	"skill": System,
	"version": 0.1,
	"upgrades": [
		{ 
			"name": "Cooling Amount",
			"id": "system.cooling_amount",
			"description": "Increases amount cooled per second.",
			"current": -0.1,
			"display percentage": false,
			"levels": [ 
				{
					"level": 1,
					"id": "system.cooling_amount", 
					"requirements": [{"item": Items.LOGS, "amount": 20 }, {"item": Items.ENCRYPTED_PASSWORDS, "amount": 20 }, {"item": Items.IP_ADDRESS, "amount": 20 }],
					"amount": -0.1,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "system.cooling_amount", 
					"requirements":[{"item": Items.PASSWORDS, "amount": 50 }, {"item": Items.USERNAMES, "amount": 50 }, {"item": Items.CREDENTIALS, "amount": 50 }],
					"amount": -0.1,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "system.cooling_amount", 
					"requirements": [{"item": Items.PACKET_SPOOF, "amount": 30 }, {"item": Items.SCHOOL_BUDGET_EMBEZZLEMENT_LOGS, "amount": 1 }],
					"amount": -0.1,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "VM Windows",
			"id": "system.vm_windows",
			"description": "Increases max amount of VM windows that can be running at once.",
			"current": 1,
			"display percentage": false,
			"levels": [ 
				{
					"level": 1,
					"id": "system.vm_windows", 
					"requirements": [{"item": Items.VM_MINING_TOKEN, "amount": 3 }],
					"amount": 2,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "system.vm_windows", 
					"requirements":[ {"item": Items.VM_PARSING_TOKEN, "amount": 3 }, {"item": Items.VM_CRACKING_TOKEN, "amount": 3 }],
					"amount": 2,
					"unlocked": false
				},
				{
					"level": 3,
					"id": "system.vm_windows", 
					"requirements": [{"item": Items.VM_PHISHING_TOKEN, "amount": 5 }, {"item": Items.VM_MATCHING_TOKEN, "amount": 5 }, {"item": Items.VM_COMPILING_TOKEN, "amount": 5 }],
					"amount": 2,
					"unlocked": false
				}
			]
		},
		{ 
			"name": "Heat Reduction",
			"id": "system.heat_reduction",
			"description": "Applies base heat reduction to all heat applications.",
			"current": 0.0,
			"display percentage": false,
			"levels": [ 
				{
					"level": 1,
					"id": "system.vm_windows", 
					"requirements": [{"item": Items.STUDENT_CACHE, "amount": 10 }, {"item": Items.PARENTS_CREDIT_CARD, "amount": 1 }],
					"amount": 0.1,
					"unlocked": false
				},
				{
					"level": 2,
					"id": "system.vm_windows", 
					"requirements":[{"item": Items.ADMIN_CACHE, "amount": 15 }, {"item": Items.FALSIFIED_TRANSCRIPT_DATABASE, "amount": 2 }],
					"amount": 0.1,
					"unlocked": false
				},
			]
		},
		{ 
			"name": "Overheat Fan",
			"id": "system.overheat_fan",
			"description": "Optimize system fan to increase cooling while overeated by 0.3/second.",
			"current": false,
			"display percentage": false,
			"levels": [ 
				{
					"level": 1,
					"id": "system.overheat_fan", 
					"requirements": [{"item": Items.LOGS, "amount": 25 }],
					"amount": true,
					"unlocked": false
				}
			]
		},
	],
}

var all_upgrades = [ SYSTEM, MINING, PARSING, CRACKING, MATCHING, PHISHING, HACKING, DECODING, COMPILING ]


func save_data() -> Dictionary:
	var data := {}
	for skill_data in all_upgrades:
		for upgrade in skill_data["upgrades"]:
			var unlocked_levels := []
			for level in upgrade["levels"]:
				if level["unlocked"]:
					unlocked_levels.append(level["level"])
			data[upgrade["id"]] = {
				"current": upgrade["current"],
				"unlocked_levels": unlocked_levels
			}
	return data

func load_data(data: Dictionary) -> void:
	for skill_data in all_upgrades:
		for upgrade in skill_data["upgrades"]:
			if not data.has(upgrade["id"]):
				continue

			var saved: Dictionary = data[upgrade["id"]]

			if saved.has("current"):
				var loaded_value = saved["current"]
				var default_value = upgrade["current"]

				if default_value is bool:
					upgrade["current"] = bool(loaded_value)
				elif default_value is int:
					upgrade["current"] = int(loaded_value)
				elif default_value is float:
					upgrade["current"] = float(loaded_value)
				else:
					upgrade["current"] = loaded_value

			var unlocked_levels: Array = []
			for v in saved.get("unlocked_levels", []):
				unlocked_levels.append(int(v))

			for level in upgrade["levels"]:
				level["unlocked"] = level["level"] in unlocked_levels

			_apply_stat_effects(upgrade)

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


func get_current_effect_total_from_package(package) -> String:
	if package.current is float:
		if package.has('display percentage'):
			if package["display percentage"] == false:
				return str(package.current)
				
		return "%.2f%%" % (package.current * 100)
		
		return str(package.current)
	
	if package.current is bool or package.current is int:
		return str(package.current)

	return "?"

func get_next_effect_total_from_package(package) -> String:
	if package.current is float:
		for lvl in package.levels:
			if !lvl.unlocked:
				if package.has('display percentage'):
					if package["display percentage"] == false:
						return str(package.current + lvl.amount)
				return "%.2f%%" % ((package.current + lvl.amount) * 100)
				
				
		return "At max level"
	
	if package.current is bool:
		for lvl in package.levels:
			if !lvl.unlocked:
				return str(lvl.amount)
		return "At max level"
	
	if package.current is int:
		for lvl in package.levels:
			if !lvl.unlocked:
				return str(package.current + lvl.amount)
		return "At max level"
	return "?"
	

func get_upgrade_requirement_from_package(package) -> Array:
	for lvl in package.levels:
		if lvl.unlocked == false:
			return lvl.requirements
	return []

func is_valid_package(package_name: String) -> bool:
	for upgrade in all_upgrades:
		for package in upgrade.upgrades:
			if package.id == package_name:
				return true
	return false


func has_upgrade_requirements(package_name: String) -> bool:
	var package = get_package_info(package_name)
	for level in package.levels:
		if !level.unlocked:
			for req in level.requirements:
				if Inventory.get_amount(req.item) < req.amount:
					return false
			break
	return true

func is_at_max_level(package_name: String) -> bool:
	var package = get_package_info(package_name)
	for level in package.levels:
		if !level.unlocked:
			return false
	return true

func get_version_from_package(package) -> float:
	for upgrade in all_upgrades:
		for pack in upgrade.upgrades:
			if package == pack:
				return upgrade.version
	return -1.0

func increase_version_from_package(package):
	for upgrade in all_upgrades:
		for pack in upgrade.upgrades:
			if package == pack:
				upgrade.version += 0.1
				return

func get_skill_version(skill: Node) -> float:
	for upgrade in all_upgrades:
		if upgrade.skill == skill:
			return upgrade.version
	return 0.0

func unlock_next_level(package):
	for lvl in package.levels:
		if !lvl.unlocked:
			lvl.unlocked = true
			if package.current is float or package.current is int:
				if package.id == "mining.overclock":
					Tutorial.complete_event(Tutorial.TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT)
				package.current += lvl.amount
				
				#Specific upgrades that need to happen (cooling etc)
				match package.id:
					"system.cooling_amount":
						Stats.cooling_amount = package.current
						Stats.cooling_updated()
					"system.vm_windows":
						Stats.MAX_ALL_VMS = package.current
					"system.heat_reduction":
						Stats.HEAT_REDUCTION = package.current
					"hacking.max_anonymity":
						Stats.set_max_anon()
				return
			if package.current is bool:
				package.current = lvl.amount
				
				#Specific upgrades that need to happen (bool)
				match package.id:
					"system.overheat_fan":
						Stats.OVERHEAT_FAN = package.current
				return
			print("nothing returned: Upgrades.unlock_next_level()")

func _apply_stat_effects(package) -> void:
	match package.id:
		"system.cooling_amount":
			Stats.cooling_amount = package.current
			Stats.cooling_updated()
		"system.vm_windows":
			Stats.MAX_ALL_VMS = package.current
		"system.heat_reduction":
			Stats.HEAT_REDUCTION = package.current
		"hacking.max_anonymity":
			Stats.set_max_anon()
		"system.overheat_fan":
			Stats.OVERHEAT_FAN = package.current

func package_aquired(package):
	increase_version_from_package(package)
	unlock_next_level(package)

func get_completion_text(package: Dictionary) -> String:
	var version = get_version_from_package(package)
	var next_version = version + 0.1
	var skill_name = get_skill_from_package_id(package.id)
	var skill_level = get_skill_level_from_package_id(package.id)
	var current_effect = get_current_effect_total_from_package(package)
	var next_effect = get_next_effect_total_from_package(package)
	
	var upgrade_effect_text = "+" + current_effect + " -> +" + next_effect if current_effect is float else current_effect + " -> " + next_effect
	var stripped_skill_name_of_bbc = ContextCommands.strip_bbcode(skill_name)
	var skill_line = "+ " + skill_name + " ".repeat(15 - stripped_skill_name_of_bbc.length()) + "v" + str(version) + " -> v" + str(next_version)
	var upgrade_line = "+ " + package.name + " ".repeat(15 - package.name.length()) + upgrade_effect_text
	var return_text = """
────────────────────────────────────────
 UPGRADE PACKAGE INSTALLED SUCCESSFULLY
────────────────────────────────────────

%s
%s

""" % [skill_line, upgrade_line]
	return return_text

func can_overclock(skill: Node) -> bool:
	#return true
	for upgrade in all_upgrades:
		if upgrade.skill == skill:
			for u_type in upgrade.upgrades:
				if u_type.name == "Overclock":
					return u_type.current
	return false
