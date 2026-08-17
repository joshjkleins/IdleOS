extends Node

func all_commands() -> String:
	var cmd_text = "MODULES\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("load [module]", 20) +  "Loads specific module [color=888888]example usage: load mining[/color][/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("info [module]", 20) +  "Get current module information [color=888888]example usage: mining info[/color][/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("stick", 20) +  "Stick a process to the top of the screen. Only available if a process is running.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("unstick", 20) +  "Unsticks a process from top of screen. Only works if process is running and stuck to top.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("overclock", 20) +  "Overclocks a running process, increasing speed and heat output.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("overclock -kill", 20) +  "Kills overclock.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("list -m", 20) +  "Lists all available modules.[/font_size]\n\n"
	
	cmd_text += "INVENTORY\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("list -a", 20) +  "Lists all items you have.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("list -r", 20) +  "Lists all resource items.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("list -c", 20) +  "Lists all cache items.[/font_size]\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("list -v", 20) +  "Lists all valuable items.[/font_size]\n\n"
	
	cmd_text += "VM TOKENS\n"
	cmd_text += "[font_size=12]" + tab_space() + pad_text("vm [module] [process]", 30) +  "Consume a VM token to run specific process. [color=#888888]example: vm mining logs[/color][/font_size]\n"
	
	
	
	return cmd_text

var _bbcode_regex := RegEx.new()

func _ready():
	_bbcode_regex.compile("\\[[^\\]]+\\]")

func strip_bbcode(text: String) -> String:
	return _bbcode_regex.sub(text, "", true)

func pad_text(text: String, width: int) -> String:
	var visible_length = strip_bbcode(text).length()

	if visible_length >= width:
		return text

	return text + " ".repeat(width - visible_length)

func tab_space() -> String:
	return "  "

func get_help_text(skill: Node) -> String:
	var text = get_ascii_text(skill)
	if skill != Defragging:
		text += "[font_size=12]Efficiency (EFF): " + skill.SKILL["efficiency description"] + "[/font_size]\n"
	if skill == Defragging:
		text += "┌───────────────────────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS        REQUIREMENT                DURATION     EFF       COMMAND              │\n"
		text += "├───────────────────────────────────────────────────────────────────────────────────────┤\n"
	elif skill == Hacking:
		text += "┌─────────────────────────────────────────────────────────────────────────────────────┐\n"
		text += "│ LOCATION                  REQ                      INFO                             │\n"
		text += "├─────────────────────────────────────────────────────────────────────────────────────┤\n"
	else:
		text += "┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS           STATUS      REQ     EFF     EFF/LVL    RUN COMMAND                 INFO                              │\n"
		text += "├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤\n"
	
	if skill == Hacking:
		var locations = [Stats.hacking_targets["School"], Stats.hacking_targets["Library"], Stats.hacking_targets["Small Business"]]
		
		
		for location in locations:
			var info_text = "info %s %s" % [skill.SKILL.name.to_lower(), location["name"].to_lower()]
			text += "│ %-25s %-25s %-31s │\n" % [
				location["name"],
				location["required payload"].name,
				info_text
			]
	else:
		for p in skill.minor_processes:
			if skill == Defragging:
				text += _build_defrag_process_row(p, skill)
			else:
				text += _build_process_row(p, skill, p["unlocked"])
	
	if skill == Hacking:
		text += "└─────────────────────────────────────────────────────────────────────────────────────┘\n"
	elif skill == Defragging:
		text +=     "└───────────────────────────────────────────────────────────────────────────────────────┘\n"
	else:
		text +=     "└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘\n"
	if skill == Defragging: #return early since all relavent info is in base info command
		return text
	
	return text

func _build_defrag_process_row(p: Dictionary, skill: Node):
	var name = p.name
	var req = p.requirements.item.name + " x" + str(p.requirements.amount)
	var duration = str(p["bonus time"]) + " min"
	var eff = "x" + str(p["bonus efficiency"])
	var command = p.command
	
	return "│ %-14s %-26s %-12s %-9s %-20s │\n" % [
				name,
				req,
				duration,
				eff,
				command
			]

func _build_process_row(p: Dictionary, skill: Node, unlocked: bool) -> String:
	var status = "ONLINE"

	if not p["unlocked"]:
		status = "LOCKED"
	
	if skill == Defragging:
		var time = str(p["bonus time"]) + " min"
		var eff = "x" + str(p["bonus efficiency"])
		if unlocked:
			return "│ %-14s %-11s %-12s %-9s %-35s %-40s │\n" % [
				p["name"],
				status,
				time,
				eff,
				p["command"],
				"info " + skill.SKILL.name.to_lower() + " " + p["name"].to_lower().replace(" ", "-")
			]
		else:
			return "[color=666666]│ %-14s %-11s %-12s %-9s %-35s │[/color]\n" % [
				p["name"],
				status,
				time,
				eff,
				p["command"],
				"info " + skill.SKILL.name.to_lower() + " " + p["name"].to_lower().replace(" ", "-")
			]
	else:
		var frag_bonus = 1.0
		if Stats.has_bonus(skill):
			for ms in Defragging.minor_processes:
				if ms["skill"] == skill:
					frag_bonus = ms["bonus efficiency"]
		#var frag_bonus = Defragging.skill["bonus efficiency"] if Stats.has_bonus(skill) else 1.0
		var base_eff = p["efficiency"] + skill.process_upgrades["efficiency"]["amount"]
		var effr = str(p["efficiency rate"] * 100.0) + "%"
		var eff = str(base_eff * frag_bonus * 100.0) + "%"
		var info_text_mp = p["name"].to_lower().replace(" ", "-")
		var info_text = "info %s %s" % [skill.SKILL.name.to_lower(), info_text_mp]
		if !unlocked:
			return "[color=666666]│ %-17s %-11s %-7d %-7s %-10s %-27s %-32s  │[/color]\n" % [
				p["name"],
				status,
				p["unlock level"],
				eff,
				effr,
				p["command"],
				info_text
			]
		else:
			return "│ %-17s %-11s %-7d %-7s %-10s %-27s %-32s  │\n" % [
				p["name"],
				status,
				p["unlock level"],
				eff,
				effr,
				p["command"],
				info_text
			]

func get_ascii_text(skill: Node) -> String:
	match skill:
		Mining:
			return Ascii.mining
		Parsing:
			return Ascii.parsing
		Cracking:
			return Ascii.cracking
		Matching:
			return Ascii.matching
		Phishing:
			return Ascii.phishing
		Decoding:
			return Ascii.decoding
		Defragging:
			return Ascii.defragging
		Hacking:
			return Ascii.hacking
		Compiling:
			return Ascii.compiling
		_:
			return ""

func get_mp_dfg_info(skill: Node, process: Dictionary):
	###INFO
	var return_text = "\nPROCESS\n"
	var color_string = skill.SKILL.color.to_html()
	var colored_name = "[color=#%s]%s[/color]" % [color_string, skill.SKILL.name]
	return_text += "├─ Skill: %s\n" % colored_name
	return_text += "├─ Process: " + process.name + "\n"
	return_text += "└─ Description: " + process.description + "\n"
	
	return_text += "\n\n"
	
	##Requirements
	return_text += "REQUIREMENTS\n"
	return_text += "└─ " + process.requirements.item.name + " x" + str(process.requirements.amount) + "\n"
	
	return_text += "\n\n"
	
	##Rewards
	return_text += "REWARDS\n"
	return_text += "└─ " + process.name + " efficiency x" + str(process["bonus efficiency"]) + " for " + str(process["bonus time"]) + " minutes."
	
	return return_text


func get_mp_info(skill: Node, process: Dictionary) -> String:
	###INFO
	var return_text = "\nPROCESS\n"
	var color_string = skill.SKILL.color.to_html()
	var colored_name = "[color=#%s]%s[/color]" % [color_string, skill.SKILL.name]
	return_text += "├─ Skill: %s\n" % colored_name
	return_text += "├─ Process: " + process.name + "\n"
	return_text += "├─ Level: " + str(process.level) + "\n"
	return_text += "└─ Description: " + process.description + "\n"
	
	return_text += "\n"
	
	###REQUIREMENTS
	return_text += "REQUIREMENTS\n"
	
	var requirements_list = {}
	
	if process["requirements"] is Array:
		for item in process["requirements"]:
			if item is Dictionary:
				requirements_list[item.item.name] = item.amount
			else:
				requirements_list[item.name] = 1
	elif process["requirements"] is ItemData:
		requirements_list[process["requirements"].name] = 1
	elif process["requirements"] == "cache":
		requirements_list["Any cache"] = 1
	else:
		requirements_list["???"] = 1
	
	if requirements_list.is_empty():
		return_text += "└─ " + colored_name + " level " + str(process["unlock level"]) + "\n"
	else:
		return_text += "├─ " + colored_name + " level " + str(process["unlock level"]) + "\n"
		
	var i = 0
	for item in requirements_list.keys():
		var prefix = "├─ "
		if i == requirements_list.size() - 1:
			prefix = "└─ "
		return_text += prefix + item + " x" + str(requirements_list[item]) + "\n"
		i += 1
		
	return_text += "\n"
	
	###REWARDS
	if skill != Decoding:
		return_text += "REWARDS\n"
		#Items gained
		if process["resource gained"] is Array:
			for resource in process["resource gained"]:
				if resource is Dictionary:
					var item = resource.item
					var item_name = item.name + " (" + str(resource.weight) + "%)"
					var dots_amount = 35 - item_name.length()
					return_text += "├─ " + item_name + ".".repeat(dots_amount) + item.description + "\n"
			

			#parsing
		elif process["resource gained"] is ItemData:
			var item = process["resource gained"]
			var item_name = item.name + " (100%)"
			var dots_amount = 35 - item_name.length()
			return_text += "├─ " + item_name + ".".repeat(dots_amount) + item.description + "\n"
		
		var vm = skill.vm_token
		var vm_name = vm.name + " (1%)"
		var dots_amount = 35 - vm_name.length()
		return_text += "└─ " + vm_name + ".".repeat(dots_amount) + vm.description + "\n"
	
	return return_text

func info_command_text():
	var return_string = ""
	var l_name = 15
	var l_lvl = 6
	var l_exp = 18
	var l_cmd = 20
	return_string += pad_text("SKILL", l_name) + pad_text("LVL", l_lvl) + pad_text("EXP", l_exp) + pad_text("COMMAND(from root)", l_cmd) + "\n"
	return_string += "-".repeat(l_name + l_lvl + l_exp + l_cmd) + "\n"
	var skills = [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling, Defragging]
	for s in skills:
		if s.name == "Defragging":
			var color_string = s.SKILL.color.to_html()
			var name_s = "[color=#%s]%s[/color]" % [color_string, s.SKILL.name]
			return_string += pad_text(name_s, l_name) + pad_text("n/a", l_lvl) + pad_text("n/a", l_exp) + pad_text(s.SKILL.command, l_cmd) + "\n"
		else:
			var experience = Exp.get_xp_display(s.SKILL)
			var color_string = s.SKILL.color.to_html()
			var name_s = "[color=#%s]%s[/color]" % [color_string, s.SKILL.name]
			return_string += pad_text(name_s, l_name) + pad_text(str(s.SKILL.level), l_lvl) + pad_text(experience["display"], l_exp) + pad_text(s.SKILL.command, l_cmd) + "\n"
	
	return return_string

func get_hack_target_info(location: Dictionary):
	var return_text = ""
	return_text += location.name + "\n"
	for tar in location["targets"]:
		return_text += tar.name + "\n"
		var integrity_text = "[font_size=12]♥Integrity: " + str(tar.integrity) + "[/font_size]"
		var firewall_text = "[font_size=12]🛡Firewall: " + str(tar.firewall) + "[/font_size]"
		var require_text = "[font_size=12]Requirements: " + str(tar.requirements.item.name) + " x" + str(tar.requirements.amount) + "[/font_size]"
		var counter_atk_text = "[font_size=12]⚔Counter attack: " + str(tar.counter) + "[/font_size]"
		var counter_spd_text = "[font_size=12]Counter speed: " + str(tar["counter speed"]) + "[/font_size]"
		var exp_text = "[font_size=12]Exp: " + str(tar.exp) + "[/font_size]"
		var pad_text_length = 30
		return_text += "\t" + pad_text(integrity_text, pad_text_length) + pad_text(firewall_text, pad_text_length) + pad_text(require_text, pad_text_length) + "\n"
		return_text += "\t" + pad_text(counter_atk_text, pad_text_length) + pad_text(counter_spd_text, pad_text_length) + pad_text(exp_text, pad_text_length) + "\n"
		return_text += "\n"
		
	
	return return_text


func get_help() -> String:
	var text := """
 ____________________________________________________________________
|                                                                    |
|                          IDLEOS COMMANDS                           |
|____________________________________________________________________|
|                                                                    |
| SKILLS / TRAVERSAL                                                 |
|   cd <skill>                   Navigate to a skill                 |
|   cd ..                        Return to root                      |
|   tree                         Display skill hierarchy             |
|   info                         Display additional skill info       |
|                                                                    |
| SYSTEM                                                             |
|   ps                           List running processes              |
|   kill                         Stop the running process            |
|   ssh <skill> <process>        Connect to a virtual machine        |
|   history                      Show command history                |
|   date                         Show date and time                  |
|   clear                        Clear terminal                      |
|                                                                    |
| ITEMS                                                              |
|   ls                           List items                          |
|   ls <item>                    Item info                           |
|                                                                    |
| UPGRADES                                                           |
|   apt                          Open upgrade manager                |
|                                                                    |
| DOCUMENTATION                                                      |
|   tutorial                     Show tutorial checklist             |
|   -h                           Display this list                   |
|____________________________________________________________________|
"""
	return text
#|   apt upgrade                  List available upgrades             |
#|   apt upgrade <x>              Upgrade a package                   |

func get_ascii_tree(current_context: String) -> String:
	var skills = [
		Mining,
		Parsing,
		Cracking,
		Matching,
		Phishing,
		Compiling,
		Hacking,
		Decoding
	]
	
	var text = "\nIDLEOS\n"
	
	for i in skills.size():
		var skill = skills[i]
		var c = skill.SKILL.color.to_html()
		var is_last_skill = i == skills.size() - 1
		var skill_branch = "└── " if is_last_skill else "├── "
		
		text += "%s[color=#%s]%s[/color]" % [skill_branch, c, skill.SKILL.name]
		
		if skill.SKILL.name == current_context:
			text += "  <----- YOU ARE HERE"
		
		text += "\n"
		
		for j in skill.minor_processes.size():
			var ms = skill.minor_processes[j]
			var is_last_process = j == skill.minor_processes.size() - 1
			
			var prefix = "    " if is_last_skill else "│   "
			var branch = "└── " if is_last_process else "├── "
			
			text += "%s%s%s\n" % [prefix, branch, ms.name]
	
	return text

func get_history_commands(command_history) -> String:
	var text = ""
	for i in command_history:
		text += i + "\n"
	return text

func get_date_command() -> String:
	var date = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [
		date.year,
		date.month,
		date.day
	]

func get_root_upgrades_text() -> String:
	var return_text = ""
	
	return_text += "\nIDLEOS PACKAGE MANAGER\n"
	return_text += "────────────────────────────────────────────────────────\n\n"
	return_text += "Available upgrades:\n\n"
	
	##LOOPING THROUGH MAJOR SKILLS
	for upgrade in Upgrades.all_upgrades:
		var skill = upgrade.skill
		var color_string = skill.SKILL.color.to_html()
		var colored_name = "[color=#%s]%s[/color]" % [color_string, skill.SKILL.name]
		return_text += colored_name + " v" + str(upgrade.version) + "\n"
		
		##LOOPING THROUGH UPGRADES ARRAY [SPEED, EFFICIENCY, ETC]
		
		var i = 0
		for upgrade_info in upgrade.upgrades:
			#get current level
			var current_level = 0
			for lvl in upgrade_info.levels:
				if lvl.unlocked:
					current_level += 1
			#get prefix
			var prefix = "├─ "
			if i == upgrade.upgrades.size() - 1:
				prefix = "└─ "
			
			#get dots
			var u_name_w_dots = upgrade_info.id + ".".repeat(30 - upgrade_info.id.length())
		
			return_text += prefix + u_name_w_dots + str(current_level) + "/" + str(upgrade_info.levels.size()) + "\n"
			i += 1
		return_text += "\n"
	
	return_text += "────────────────────────────────────────────────────────\n\n"
	return_text += "Use 'apt info <package>' for package information.\n"
	return_text += "Use 'apt install <package>' to install.\n"
	
	return return_text

func get_upgrades_package_info(package_id: String) -> String:
	var package = Upgrades.get_package_info(package_id)
	var skill_name = Upgrades.get_skill_from_package_id(package_id)
	var skill_level = Upgrades.get_skill_level_from_package_id(package_id)
	var current_effect = Upgrades.get_current_effect_total_from_package(package)
	var next_effect = Upgrades.get_next_effect_total_from_package(package)
	var requirements = Upgrades.get_upgrade_requirement_from_package(package)
	
	
	if package == null:
		return "Package id not found"
	
	var return_text = "────────────────────────────────────────────────────────\n"
	return_text += "Package: %s\n" % package_id
	return_text += "Skill: %s\n" % skill_name 
	return_text += "Level: %s\n" % skill_level 
	
	return_text += "\nDescription:\n"
	return_text += package.description + "\n"
	
	
	return_text += "\nCurrent effect\n"
	return_text += "└─ " + package.name + ": " + current_effect + "\n\n"
		
		
	return_text += "Next upgrade\n"
	return_text += "└─ " + package.name + ": " + next_effect + "\n\n"
	
	if !Upgrades.is_at_max_level(package_id):
		return_text += "Requirements\n"
		var i = 0
		for r in requirements:
			var prefix = "├─ "
			if i == requirements.size() - 1:
				prefix = "└─ "
			var player_amount = Inventory.get_amount(r.item)
			if player_amount < r.amount: #not enough
				return_text += prefix + r.item.name + " [color=red]" + str(Inventory.get_amount(r.item)) + "/" + str(r.amount) + "[/color]\n"
			else: #enough
				return_text += prefix + r.item.name + " [color=green]" + str(Inventory.get_amount(r.item)) + "/" + str(r.amount) + "[/color]\n"
			i += 1
		
		return_text += "\nInstall\n"
		return_text += "└─ " + "apt install " + package.id + "\n"
		
		
	return_text += "────────────────────────────────────────────────────────\n\n"
	
	
	return return_text


func cd_not_at_root() -> String:
	return "Return to root before navigating to different directory. \t[color=#666666]example: cd ..[/color]"
