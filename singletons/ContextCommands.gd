extends Node

func all_commands() -> String:
	var cmd_text = "MODULES\n"
	cmd_text += tab_space() + pad_text("load [module]", 20) +  "Loads specific module [color=888888]example usage: load mining[/color]\n"
	cmd_text += tab_space() + pad_text("info [module]", 20) +  "Get current module information [color=888888]example usage: mining info[/color]\n"
	cmd_text += tab_space() + pad_text("stick", 20) +  "Stick a process to the top of the screen. Only available if a process is running.\n"
	cmd_text += tab_space() + pad_text("unstick", 20) +  "Unsticks a process from top of screen. Only works if process is running and stuck to top.\n"
	cmd_text += tab_space() + pad_text("overclock", 20) +  "Overclocks a running process, increasing speed and heat output.\n"
	cmd_text += tab_space() + pad_text("overclock -kill", 20) +  "Kills overclock.\n"
	cmd_text += tab_space() + pad_text("list -m", 20) +  "Lists all available modules.\n\n"
	
	cmd_text += "INVENTORY\n"
	cmd_text += tab_space() + pad_text("list -a", 20) +  "Lists all items you have.\n"
	cmd_text += tab_space() + pad_text("list -r", 20) +  "Lists all resource items.\n"
	cmd_text += tab_space() + pad_text("list -c", 20) +  "Lists all cache items.\n"
	cmd_text += tab_space() + pad_text("list -v", 20) +  "Lists all valuable items.\n\n"
	
	cmd_text += "VM TOKENS\n"
	cmd_text += tab_space() + pad_text("vm [module] [process]", 30) +  "Consume a VM token to run specific process. [color=888888]example: vm mining logs[/color]\n"
	
	
	
	return cmd_text

func pad_text(text: String, width: int) -> String:
	if text.length() >= width:
		return text.substr(0, width)
	return text + " ".repeat(width - text.length())

func tab_space() -> String:
	return "  "

func get_help_text(skill: Node) -> String:
	var text = get_ascii_text(skill)
	if skill == Defragging:
		text += "┌───────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS        STATUS      DURATION     EFF       COMMAND             │\n"
		text += "├───────────────────────────────────────────────────────────────────────┤\n"
	else:
		text += "┌───────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS        STATUS      REQ     EFF     EFF/LVL    COMMAND         │\n"
		text += "├───────────────────────────────────────────────────────────────────────┤\n"
	
	for p in skill.minor_processes:
		if p["unlocked"]:
			text += _build_process_row(p, skill)
		else:
			text += "[color=#666666]" + _build_process_row(p, skill) + "[/color]"
	
	text += "└───────────────────────────────────────────────────────────────────────┘\n"
	if skill == Defragging:
		return text
	text += "[font_size=12]Efficiency (EFF): \n" + skill.SKILL["efficiency description"] + "[/font_size]\n"
	return text

func _build_process_row(p: Dictionary, skill: Node) -> String:
	var status = "ONLINE"

	if not p["unlocked"]:
		status = "LOCKED"
	
	if skill == Defragging:
		var time = str(p["bonus time"]) + " min"
		var eff = "x" + str(p["bonus efficiency"])
		return "│ %-14s %-11s %-12s %-9s %-19s │\n" % [
		p["name"],
		status,
		time,
		eff,
		p["command"]
	]
	else:
		var frag_bonus = Defragging.skill["bonus efficiency"] if Stats.has_bonus(skill) else 1.0
		var base_eff = p["efficiency"] + skill.process_upgrades["efficiency"]["amount"]
		var effr = str(p["efficiency rate"] * 100.0) + "%"
		var eff = str(base_eff * frag_bonus * 100.0) + "%"

		return "│ %-14s %-11s %-7d %-7s %-10s %-14s  │\n" % [
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
