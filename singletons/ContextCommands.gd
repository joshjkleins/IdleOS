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
	text += "[font_size=12]Efficiency (EFF): [/font_size]\n"
	text += "[font_size=12]" + skill.SKILL["efficiency description"] + "[/font_size]\n"
	if skill == Defragging:
		text += "┌────────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS        STATUS      DURATION     EFF       COMMAND              │\n"
		text += "├────────────────────────────────────────────────────────────────────────┤\n"
	else:
		text += "┌────────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS        STATUS      REQ     EFF     EFF/LVL    COMMAND          │\n"
		text += "├────────────────────────────────────────────────────────────────────────┤\n"
	
	for p in skill.minor_processes:
		text += _build_process_row(p, skill, p["unlocked"])
	
	text += "└────────────────────────────────────────────────────────────────────────┘\n"
	if skill == Defragging:
		return text

	
	text += "\n"
	text += "[font_size=12]For additional details[/font_size]\n"
	text += "[font_size=12]PROCESS             COMMAND[/font_size]\n"
	text += "[font_size=12]------------------------------------------------[/font_size]\n"
	for s in skill.minor_processes:
		text += "[font_size=12]" + pad_text(s.name, 20) + "info " + skill.SKILL.name.to_lower() + " " + s.name.to_lower() + "[/font_size]\n"
	return text

func _build_process_row(p: Dictionary, skill: Node, unlocked: bool) -> String:
	var status = "ONLINE"

	if not p["unlocked"]:
		status = "LOCKED"
	
	if skill == Defragging:
		var time = str(p["bonus time"]) + " min"
		var eff = "x" + str(p["bonus efficiency"])
		if unlocked:
			return "│ %-14s %-11s %-12s %-9s %-20s │\n" % [
				p["name"],
				status,
				time,
				eff,
				p["command"]
			]
		else:
			return "[color=666666]│ %-14s %-11s %-12s %-9s %-20s │[/color]\n" % [
				p["name"],
				status,
				time,
				eff,
				p["command"]
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
		if !unlocked:
			return "[color=666666]│ %-14s %-11s %-7d %-7s %-10s %-15s  │[/color]\n" % [
				p["name"],
				status,
				p["unlock level"],
				eff,
				effr,
				p["command"]
			]
		else:
			return "│ %-14s %-11s %-7d %-7s %-10s %-15s  │\n" % [
				p["name"],
				status,
				p["unlock level"],
				eff,
				effr,
				p["command"]
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
		_:
			return ""

#Update INFO command on each process to show specifics of skill and minor processes: 
# just generic 'info' command should be base info for all major skills (lvl, exp, description, commands)
# info [major skill] should be overview of that specific skill "info mining" (name, lvl, description, commands, minor processes, locked/unlocked, upgrades (vm duration/windows))
# info [major skill] [minor skill] "info mining logs" should be details of minor skill 
# (name, exp, description, what is generated, requirements, requirement locations, upgrades(speed, eff))
#should show the following:
	#requirements (skill.requirements)
	#items received (skill.items)
	#where to get required items
	#lvl (skill.lvl)
	#efficiency (skill.eff)
	#upgrades, upgrade costs/recipes (skill.upgrade)
	
	
# LOGS (mining) - LVL 12 - Finds logs that can be parsed for a random assortment of items.
# Item(s) gained
# =====================
# Logs (100%)..............Used in Parsing to receive various items.
# VM Mining Token (1%).....Consume to create a seperate window for mining.
# 
# Requirements
# =====================
# Mining level 1


func get_mp_info(skill: Node, process: Dictionary):
	var return_string = "\n" + process.name + " (" + skill.SKILL.name.to_lower() + ") - LVL " + str(process.level) + " - " + process.description + "\n"
	
	#Requirements
	return_string += "\nRequirements\n"
	return_string += "=======================\n"
	return_string += skill.SKILL.name + " level " + str(process["unlock level"]) + "\n"
	if process["requirements"] is Array:
		for item in process["requirements"]:
			if item is Dictionary:
				return_string += item.name + " x" + str(item.amount) + "\n"
			else:
				return_string += item.name + " x1\n"
	elif process["requirements"] is ItemData:
		return_string += process["requirements"].name + " x1\n"
	elif process["requirements"] == "cache":
		return_string += "Any cache x1\n"
	else:
		return_string += "???"

	if skill != Decoding:
		return_string += "\nItem(s) gained\n"
		#Items gained
		return_string += "========================\n"
		if process["resource gained"] is Array:
			for resource in process["resource gained"]:
				if resource is Dictionary:
					var item = resource.item
					var item_name = item.name + " (" + str(resource.weight) + "%)"
					var dots_amount = 35 - item_name.length()
					return_string += item_name + ".".repeat(dots_amount) + item.description + "\n"
			

			#parsing
		elif process["resource gained"] is ItemData:
			var item = process["resource gained"]
			var item_name = item.name + " (100%)"
			var dots_amount = 35 - item_name.length()
			return_string += item_name + ".".repeat(dots_amount) + item.description + "\n"
		
		var vm = skill.vm_token
		var vm_name = vm.name + " (1%)"
		var dots_amount = 35 - vm_name.length()
		return_string += vm_name + ".".repeat(dots_amount) + vm.description + "\n"
	return return_string

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
