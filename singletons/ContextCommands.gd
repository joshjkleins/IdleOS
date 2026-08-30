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
		text += "└───────────────────────────────────────────────────────────────────────────────────────┘\n"
	else:
		text += "└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘\n"

	return _wrap_center_lines(text)

func _wrap_center(text: String) -> String:
	return "[center]" + text + "[/center]"

func _wrap_center_lines(text: String) -> String:
	var lines = text.split("\n")
	for i in range(lines.size()):
		if lines[i] != "":  # skip empty trailing line from the final \n
			lines[i] = _wrap_center(lines[i])
	return "\n".join(lines)

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
		var base_eff = p["efficiency"]
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
	if skill == Defragging:
		return get_mp_dfg_info(skill, process)
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
	var l_upgrades = 10
	var l_lvl = 6
	var l_exp = 18
	var l_cmd = 20
	return_string += pad_text("SKILL", l_name) + pad_text("UPGRADE", l_upgrades) + pad_text("LVL", l_lvl) + pad_text("COMMAND(from root)", l_cmd) + "\n"
	return_string += "-".repeat(l_name + l_upgrades + l_lvl + l_cmd) + "\n"
	var skills = [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling, Defragging]
	for s in skills:
		if s.name == "Defragging":
			var color_string = s.SKILL.color.to_html()
			var name_s = "[color=#%s]%s[/color]" % [color_string, s.SKILL.name]
			return_string += pad_text(name_s, l_name) + pad_text("n/a", l_upgrades) + pad_text("n/a", l_lvl) + pad_text(s.SKILL.command, l_cmd) + "\n"
		else:
			var experience = Exp.get_xp_display(s.SKILL)
			var color_string = s.SKILL.color.to_html()
			var version = "v" + str(Upgrades.get_skill_version(s)) 
			var name_s = "[color=#%s]%s[/color]" % [color_string, s.SKILL.name]
			return_string += pad_text(name_s, l_name) + pad_text(version, l_upgrades) + pad_text(str(s.SKILL.level), l_lvl) + pad_text(s.SKILL.command, l_cmd) + "\n"
	
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
		var counter_spd_text = "[font_size=12]Counter speed: " + get_speed_text(tar["counter speed"]) + "/s[/font_size]"
		var exp_text = "[font_size=12]Exp: " + str(tar.exp) + "[/font_size]"
		var pad_text_length = 30
		return_text += "\t" + pad_text(integrity_text, pad_text_length) + pad_text(firewall_text, pad_text_length) + pad_text(require_text, pad_text_length) + "\n"
		return_text += "\t" + pad_text(counter_atk_text, pad_text_length) + pad_text(counter_spd_text, pad_text_length) + pad_text(exp_text, pad_text_length) + "\n"
		return_text += "\n"
		
	
	return return_text

func get_speed_text(speed: float) -> String:
	var sp = 1.0 / (100.0 / speed)
	return "%.2f" % sp

func list_vm_terminals_for_skill(skill: Node):
	var first_col = 20
	var second_col = 30
	var return_text = ""
	return_text += skill.name + "\n\n"
	return_text += pad_text("Process", first_col) + pad_text("Run command", second_col) + "\n"
	return_text += "-".repeat(first_col + second_col) + "\n"
	for mp in skill.minor_processes:
		var run_command = "ssh " + skill.name.to_lower() + " " + mp.name.to_lower()
		return_text += pad_text(mp.name, first_col) + pad_text(run_command, second_col) + "\n"
	return return_text

func ssh_commands(major_processes: Array) -> String:
	var first_col = 15
	var second_col = 20
	var third_col = 25
	var return_text = "SSH Commands\n\n"
	return_text += pad_text("Skill", first_col) + pad_text("Tokens", second_col) + pad_text("Info", third_col) + "\n"
	return_text += "-".repeat(first_col + second_col + third_col) + "\n"
	
	for p in major_processes:
		var c = p.SKILL.color.to_html()
		var s_name = "[color=#%s]%s[/color]" % [c, p.SKILL.name]
		var info_command = "ssh " + p.SKILL.name.to_lower()
		var tokens = str(Inventory.get_amount(p.vm_token))
		return_text += pad_text(s_name, first_col) + pad_text(tokens, second_col) + pad_text(info_command, third_col) + "\n"

	return return_text
	

func ssh_help_commands() -> String:
	var text := """
 ____________________________________________________________________
|                                                                    |
|                            SSH COMMANDS                            |
|____________________________________________________________________|
|                                                                    |
|   ssh                          List available VM tokens            |
|   ssh <skill>                  List ssh run commands               |
|   ssh <skill> <process>        Consume VM token to run process     |
|                                in seperate window                  |
|   ssh -h                       Show this list of commands          |
|____________________________________________________________________|
"""
	return text

func process_commands() -> String:
	var text := """
 ____________________________________________________________________
|                                                                    |
|                          PROCESS COMMANDS                          |
|____________________________________________________________________|
|                                                                    |
| STARTING / STOPPING                                                |
|   <skill> -<process>           Run a process                       |
|   kill                         Stop currently running process      |
|   stop                         Stop currently running process      |
|                                                                    |
| DISPLAY & CONTROL                                                  |
|   focus                        Bring currently running process     |
|                                to bottom of terminal               |
|   ps                           List running process                |
|   sticky                       Anchor process to top of terminal   |
|   stick                        Anchor process to top of terminal   |
|   unsticky                     Remove anchored process from top    |
|   unstick                      Remove anchored process from top    |
|                                                                    |
| DOCUMENTATION                                                      |
|   process -h                   Show this list of commands          |
|____________________________________________________________________|
"""
	return text

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
| ITEMS                                                              |
|   ls                           List items                          |
|   ls <item>                    Item details                        |
|   track <item>, <item>         Track item(s) (comma seperated)     |
|   untrack <item>               Remove tracking                     |
|                                                                    |
| UPGRADES                                                           |
|   apt                          Upgrade package manager             |
|                                                                    |
| DOCUMENTATION                                                      |
|   tutorial                     Show tutorial checklist             |
|   -h                           Display this list                   |
|   process -h                   List process commands               |
|   ssh -h                       List ssh commands                   |
|                                                                    |
| SYSTEM                                                             |
|   date                         Show date and time                  |
|   clear                        Clear terminal                      |
|   system                       Show system information             |
|____________________________________________________________________|
"""
	return text

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
	var date = Time.get_datetime_dict_from_system()
	
	var weekday_names = [
		"Sunday",
		"Monday",
		"Tuesday",
		"Wednesday",
		"Thursday",
		"Friday",
		"Saturday"
	]
	
	var month_names = [
		"",
		"January",
		"February",
		"March",
		"April",
		"May",
		"June",
		"July",
		"August",
		"September",
		"October",
		"November",
		"December"
	]
	
	var hour = date.hour
	var period = "AM"
	
	if hour >= 12:
		period = "PM"
	
	if hour == 0:
		hour = 12
	elif hour > 12:
		hour -= 12
	
	return "%s, %s %d, %d %d:%02d:%02d %s" % [
		weekday_names[date.weekday],
		month_names[date.month],
		date.day,
		date.year,
		hour,
		date.minute,
		date.second,
		period
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

func get_skill_upgrades_text(upgrade):
	var return_text = ""
	return_text += "\nAvailable upgrades:\n\n"
	
	var skill = upgrade.skill
	var color_string = skill.SKILL.color.to_html()
	var colored_name = "[color=#%s]%s[/color]" % [color_string, skill.SKILL.name]
	return_text += colored_name + " v" + str(upgrade.version) + "\n"
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

func returned_to_root() -> String:
	var text := """  
 ____________________________________________________________________
|                                                                    |
|                            ROOT COMMANDS                           |
|____________________________________________________________________|
|                                                                    |
| SKILLS / TRAVERSAL                                                 |
|   cd <skill>                   Navigate to a skill                 |
|   info                         Display additional skill info       |
|                                                                    |
| SYSTEM                                                             |
|   clear                        Clear terminal                      |
|                                                                    |
| ITEMS                                                              |
|   ls                           List items                          |
|   ls <item>                    Item details                        |
|                                                                    |
| UPGRADES                                                           |
|   apt                          Upgrade package manager             |
|                                                                    |
| DOCUMENTATION                                                      |
|   tutorial                     Show tutorial checklist             |
|   -h                           Display expanded commands list      |
|____________________________________________________________________|
"""
	return text

func get_hacking_tutorial() -> String:
	var return_string = "PROGRESS: " + Tutorial.get_tutorial_progress_string() + "\n"
	
	return_string += "\nCURRENT TASK\n"
	return_string += "\t[>] " +  Tutorial.get_current_task() + "\n\n"
	
	return_string += "NEXT\n"
	var next_tasks = Tutorial.get_next_tasks(1)
	for task in next_tasks:
		return_string += "\t[?] " + task + "\n"
	
	return_string += "───────────────────────────────────\n\n"
	
	return_string += "Type 'tutorial' at any time to view progress.\n"
	
	return return_string

func get_tutorial() -> String:
	var return_string = "IDLEOS // TUTORIAL\n\n"
	
	return_string += "PROGRESS: " + Tutorial.get_tutorial_progress_string() + "\n\n"
	
	var completed_tasks = Tutorial.get_completed_tasks()
	
	return_string += "COMPLETED\n"
	for task in completed_tasks:
		return_string += "\t[✓] " + task + "\n"
	
	return_string += "\nCURRENT TASK\n"
	return_string += "\t[>] " +  Tutorial.get_current_task() + "\n\n"
	
	return_string += "NEXT\n"
	var next_tasks = Tutorial.get_next_tasks(4)
	for task in next_tasks:
		return_string += "\t[?] " + task + "\n"
	
	return_string += "────────────────────────────────────────────────────────\n\n"
	
	return_string += "Type 'tutorial' at any time to view progress.\n"
	
	return return_string

func process_already_running_text() -> String:
	#hint: use kill to stop or 'ps' to bring current process to bottom 
	var hint = "\n[color=666666]hint: use 'kill' to stop current process\nuse 'ps' for current process info.[/color]"
	return "Process already running." + hint

func system_commands() -> String:
	var cooling_amount = Stats.cooling_amount
	var tempature = Stats.system_tempature
	var time = get_date_command()
	var max_vms = Stats.MAX_ALL_VMS
	var current_vms = Stats.CURRENT_ALL_VMS
	var anonymity = Stats.current_anon
	var max_anon = Stats.max_anon
	var bandwidth = Hacking.current_bandwidth
	var m_band = Hacking.max_bandwidth
	var bw_recov = Hacking.bandwidth_recovery_rate
	
	return """
Current temp: %s °C/s
Cooling amount: %s °C/s
Current time: %s
Virtual Machines (VMS): %s/%s
Anonymity: %s
Max Bandwidth: %s
Bandwidth Restore: +%s/second
""" % [tempature, cooling_amount, time, current_vms, max_vms, max_anon, m_band, bw_recov]
