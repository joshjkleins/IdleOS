extends Node

## the one Discord invite used everywhere (welcome, discord, discord -c, tutorial end). Never-expiring invite.
const DISCORD_LINK := "https://discord.gg/eaAqGG5FPZ"

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
	# only real bbcode tags, so literal brackets like "decode -cache[=<cache item>]" are measured as shown
	_bbcode_regex.compile("\\[/?(color|bgcolor|fgcolor|font_size|font|outline_size|outline_color|b|i|u|s|code|url|center|right|left|fill|indent|wave|shake|rainbow|pulse|tornado|fade|img|hint|lb|rb)(=[^\\]]*)?( [^\\]]*)?\\]")

func strip_bbcode(text: String) -> String:
	return _bbcode_regex.sub(text, "", true)

func pad_text(text: String, width: int, strip_bbc: bool = true) -> String:
	var visible_length = text.length()
	if strip_bbc:
		visible_length = strip_bbcode(text).length()

	if visible_length >= width:
		return text

	return text + " ".repeat(width - visible_length)

func tab_space() -> String:
	return "  "

func get_modifier_info_text(skill: Node) -> String:
	if skill == Defragging:
		return ""
	var l_mod = 16
	var l_status = 18 # fits "at Compiling v1.0" + a gap
	var l_cmd = 41
	var l_effect = 44
	var text = ""
	text += "┌────────────────────────────────────────────────────── MODIFIERS ───────────────────────────────────────────────────────┐\n"
	text += "│ " + pad_text('MODIFIER', l_mod) + pad_text('STATUS', l_status) + pad_text('COMMAND', l_cmd) + pad_text('EFFECT', l_effect) + '│\n'
	text += "├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤\n"
	# overclock first, then the skill's capstone modifiers (one at a time per process)
	var group = skill.SKILL.name
	var entries = [{"name": "Overclock", "unlocked": Upgrades.can_overclock(skill), "package": group.to_lower() + ".overclock",
		"command": "overclock", "effect": "Increase speed & heat output."}]
	for m in skill.get("MODIFIERS") if skill.get("MODIFIERS") else []:
		entries.append({"name": m.name, "unlocked": Upgrades.has(m.package), "package": m.package, "command": m.command, "effect": m.effect})
	# only modifiers you've unlocked; nothing at all until the first one
	entries = entries.filter(func(e): return e.unlocked)
	if entries.is_empty():
		return ""
	for e in entries:
		var p = Upgrades.get_package_info(e.package)
		var unlock_at = ("at %s v%d.0" % [group, int(p.levels[0].tier)]) if p.has("levels") else ""
		var status = ["UNLOCKED"] if e.unlocked else ["LOCKED", unlock_at]
		var command = ["While process is active use '%s'" % e.command, "Stop with '%s -kill'" % e.command]
		var effect = _wrap_words(e.effect, l_effect - 2)
		var cols = [[e.name], status, command, effect]
		var widths = [l_mod, l_status, l_cmd, l_effect]
		var dim = !e.unlocked
		for i in range(find_largest_array(cols).size()):
			var line = ""
			for c in range(cols.size()):
				line += pad_text(cols[c][i] if i < cols[c].size() else "", widths[c])
			text += "│ " + ("[color=#666666]%s[/color]" % line if dim else line) + "│\n"
		if e != entries[-1]:
			text += "│" + " ".repeat(120) + "│\n"
	text += "└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘\n"
	if entries.size() > 1:
		text += "[color=#666666]One modifier at a time per process (overclock included).[/color]\n"
	return text

## splits text into lines of at most <width> characters at word boundaries
func _wrap_words(text: String, width: int) -> Array:
	var lines = []
	var cur = ""
	for w in text.split(" ", false):
		if cur.length() + w.length() + (1 if cur != "" else 0) > width:
			lines.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		lines.append(cur)
	return lines


func find_largest_array(matrix: Array) -> Array:
	if matrix.is_empty():
		return [] # Return an empty array if the main array is empty

	var largest_arr: Array = matrix[0]

	for i in range(1, matrix.size()):
		if matrix[i].size() > largest_arr.size():
			largest_arr = matrix[i]

	return largest_arr


## Max characters per terminal line, kept up to date by idle_os_2 when the terminal resizes.
## Tables built with build_table() shrink to fit this.
var max_line_chars: int = 999

## Builds a bordered table that fits max_line_chars.
## columns: [{"title": String, "drop": int}] - drop 0 = always keep; higher numbers are dropped first when space runs out.
## rows: Array of Array[String] (cells may contain bbcode). row_colors: optional hex per row ("" = none).
## Fitting order: tighten gaps -> drop columns with drop >= 3 -> trim columns to their "min" -> drop the rest -> trim anything.
## Optional per column: "min" (int) = how far it may be trimmed (with "~") before optional columns are dropped.
func build_table(columns: Array, rows: Array, row_colors: Array = []) -> String:
	var active: Array = range(columns.size())
	var widths: Array = []
	for c in columns.size():
		var w = columns[c].title.length()
		for row in rows:
			w = max(w, strip_bbcode(str(row[c])).length())
		widths.append(w)

	var gap = 5
	var line_len = func(cols: Array, g: int) -> int:
		var total = 2 + 1 # "│ " ... "│"
		for i in cols.size():
			total += widths[cols[i]] + g + (2 if i < cols.size() - 1 else 0)
		return total

	# 1) tighten gaps
	while line_len.call(active, gap) > max_line_chars and gap > 1:
		gap -= 1
	# 2) shrink to fit: drop low-value columns (drop >= 3) first, then trim columns that allow it
	#    (down to their "min"), then drop the remaining optional columns, then trim anything.
	while line_len.call(active, gap) > max_line_chars:
		var victim = -1
		for c in active:
			if columns[c].get("drop", 0) > 0 and (victim == -1 or columns[c].drop > columns[victim].drop):
				victim = c
		if victim != -1 and columns[victim].drop >= 3:
			active.erase(victim)
			continue
		var trim = -1
		for c in active:
			var min_w = columns[c].get("min", widths[c])
			if widths[c] > min_w and (trim == -1 or widths[c] > widths[trim]):
				trim = c
		if trim != -1:
			widths[trim] -= 1
			continue
		if victim != -1:
			active.erase(victim)
			continue
		var widest = active[0]
		for c in active:
			if widths[c] > widths[widest]:
				widest = c
		if widths[widest] <= 6:
			break
		widths[widest] -= 1

	var inner = line_len.call(active, gap) - 2
	var text = "┌" + "─".repeat(inner) + "┐\n"
	var header_cells = []
	for c in active:
		header_cells.append(columns[c].title)
	text += _table_row(header_cells, active, widths, gap) + "\n"
	text += "├" + "─".repeat(inner) + "┤\n"
	for r in rows.size():
		var cells = []
		for c in active:
			cells.append(rows[r][c])
		var line = _table_row(cells, active, widths, gap)
		var col = row_colors[r] if r < row_colors.size() else ""
		text += ("[color=%s]%s[/color]" % [col, line] if col != "" else line) + "\n"
	text += "└" + "─".repeat(inner) + "┘\n"
	return text

func _table_row(cells: Array, active: Array, widths: Array, gap: int) -> String:
	var line = "│ "
	for i in active.size():
		var w = widths[active[i]]
		var cell = str(cells[i])
		var plain = strip_bbcode(cell)
		if plain.length() > w:
			cell = plain.substr(0, max(1, w - 1)) + "~"
		line += pad_text(cell, w) + " ".repeat(gap) + ("| " if i < active.size() - 1 else "│")
	return line

func get_help_text(skill: Node) -> String:
	var text = get_ascii_text(skill)
	# one line when every process uses efficiency the same way, otherwise a per-process list under the table
	var eff_lines = []
	var distinct = {}
	var ordered = info_process_order(skill)
	for p in ordered:
		if !p.get("unlocked", false):
			continue # only processes the player can run
		var d = p.get("efficiency description", skill.SKILL["efficiency description"])
		distinct[d] = true
		eff_lines.append([p.name, d])
	if distinct.size() <= 1:
		text += "[font_size=12]Efficiency (EFF): " + skill.SKILL["efficiency description"] + "[/font_size]\n"

	var columns = [
		{"title": "PROCESS", "drop": 0},
		{"title": "STATUS", "drop": 0},
		{"title": "UNLOCK", "drop": 2},
		{"title": "EFF", "drop": 0},
		{"title": "EFF/LVL", "drop": 3},
		{"title": "RUN COMMAND", "drop": 0, "min": 16},
		{"title": "INFO COMMAND", "drop": 4},
		{"title": "REQUIRED ITEMS", "drop": 1, "min": 20},
	]
	var rows = []
	var row_colors = []
	for p in ordered:
		var status
		status = "ONLINE" if p.unlocked else "LOCKED"
		var efficiency = "-"
		var efficiency_rate = "-"
		var run_command = "-"
		var info_cmd = "-"
		var req_items = "-"
		if true: # details shown for every process (unlock level is in the UNLOCK column)
			efficiency = "%.1f%%" % (p.efficiency * 100.0)
			var r = p["efficiency rate"] * 100.0
			efficiency_rate = ("%.2f%%" if r < 0.1 else "%.1f%%") % r
			run_command = p['display command'] if p.has('display command') else p.command
			info_cmd = "info " + skill.SKILL.name.to_lower() + " " + p.name.to_lower().replace(" ", "-")
			req_items = get_requirements_text(p)
		rows.append([p.name, status, str(p['unlock level']), efficiency, efficiency_rate, run_command, info_cmd, req_items])
		row_colors.append("" if p.unlocked else "#666666")

	text += build_table(columns, rows, row_colors)
	if distinct.size() > 1:
		text += "\nEFFICIENCY (EFF) BY PROCESS\n"
		for line in eff_lines:
			text += "  %-12s %s\n" % line
	return text + Exp.level_bonus_text(skill) + "\n\n" + get_modifier_info_text(skill)



## Info table order: tier processes by unlock level, then utilities ("UTILITY | ...", "UPLOAD | ...") in their own order
static func info_process_order(skill: Node) -> Array:
	var tiers = skill.minor_processes.filter(func(p): return str(p.get("tier name", "TIER")).begins_with("TIER"))
	var others = skill.minor_processes.filter(func(p): return !str(p.get("tier name", "TIER")).begins_with("TIER"))
	tiers.sort_custom(func(a, b): return int(a.get("unlock level", 1)) < int(b.get("unlock level", 1)))
	return tiers + others

func get_requirements_text(p: Dictionary) -> String:
	if p.requirements is String:
		return p.requirements
	if p.requirements.is_empty():
		return "-"
	
	var requirements = []
	
	for item in p.requirements:
		requirements.append("%s x%s" % [item.name, p.requirements[item]])
	
	return ", ".join(requirements)

func get_help_text_defragging(skill: Node) -> String:
	var text = get_ascii_text(skill)
	var columns = [
		{"title": "PROCESS"},
		{"title": "DURATION", "drop": 1},
		{"title": "BONUS", "min": 20},
		{"title": "COMMAND"},
	]
	var rows = []
	var colors = []
	for p in skill.minor_processes:
		var active = Defragging.is_active(p)
		rows.append([p.name, Stats.boost_minutes_text() + (" (ACTIVE " + Stats.get_bonus_time_text(p) + ")" if active else ""), p.get("bonus text", p.get("bonus label", "-")), p.command])
		colors.append("#ffc24a" if active else ("" if p.unlocked else "#666666"))
	text += build_table(columns, rows, colors)
	text += "\n[color=#666666]One boost at a time: defragging shares a %d minute cooldown.[/color]" % int(Defragging.get_cooldown_minutes())
	return text + "\n\n" + get_modifier_info_text(skill)

func get_help_text_hacking(skill: Node) -> String:
	var text = get_ascii_text(skill)
	text += "┌─────────────────────────────────────────────────────────────────────────────────────┐\n"
	text += "│ LOCATION                  REQ                      INFO                             │\n"
	text += "├─────────────────────────────────────────────────────────────────────────────────────┤\n"
	
	var locations = Stats.hacking_targets.values()

	for location in locations:
		var info_text = "info %s %s" % [skill.SKILL.name.to_lower(), location["name"].to_lower()]
		text += "│ %-25s %-25s %-31s │\n" % [
			location["name"],
			location["required payload"].name,
			info_text
		]
	text += "└─────────────────────────────────────────────────────────────────────────────────────┘\n"
	var final_text = text + "\n\n" + get_modifier_info_text(skill)
	return final_text

func get_help_text_2(skill: Node) -> String:
	var text = get_ascii_text(skill)
	if skill != Defragging:
		text += "[font_size=12]Efficiency (EFF): " + skill.SKILL["efficiency description"] + "[/font_size]\n"
	if skill == Defragging:
		text += "┌───────────────────────────────────────────────────────────────────────────────────────┐\n"
		text += "│ PROCESS        REQUIREMENT                DURATION     BONUS     COMMAND              │\n"
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
		var locations = Stats.hacking_targets.values()

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
	
	var final_text = text + "\n\n" + get_modifier_info_text(skill)
	return final_text

func _wrap_center(text: String) -> String:
	return "[center]" + text + "[/center]"

func _wrap_pad_left(text: String) -> String:
	return "[indent]" + text + "[/indent]"

func _wrap_center_lines(text: String) -> String:
	var lines = text.split("\n")
	for i in range(lines.size()):
		if lines[i] != "":  # skip empty trailing line from the final \n
			lines[i] = _wrap_center(lines[i])
	return "\n".join(lines)

func _build_defrag_process_row(p: Dictionary, skill: Node):
	var name = p.name
	var req = p.requirements.item.name + " x" + str(p.requirements.amount)
	var duration = Stats.boost_minutes_text()
	var eff = p.get("bonus label", "-")
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
		var time = Stats.boost_minutes_text()
		#var eff = "x" + str(p["bonus efficiency"])
		var eff = p.get("bonus label", "-")
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
		var frag_bonus = 1.0 # defrag no longer boosts skills
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
	if process.get("requirements", {}).is_empty():
		return_text += "└─ none (limited by the shared cooldown)\n"
	else:
		return_text += "└─ " + process.requirements.item.name + " x" + str(process.requirements.amount) + "\n"
	
	return_text += "\n\n"
	
	##Rewards
	return_text += "REWARDS\n"
	return_text += "└─ " + process.description + " Lasts " + Stats.boost_minutes_text() + "."
	
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
	if process["requirements"] is Dictionary:
		requirements_list = process["requirements"]
	elif process["requirements"] is ItemData:
		requirements_list[process["requirements"].name] = 1
	elif process["requirements"] is String:
		requirements_list[process["requirements"]] = 1
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
		if item is String:
			return_text += prefix + item + "\n"
		else:
			return_text += prefix + item.name + " x" + str(requirements_list[item]) + "\n"
		i += 1
	
	
	return_text += "\n"
	
	###REWARDS
	if skill != Decoding:
		return_text += "REWARDS\n"
		#Items gained
		if process["resource gained"] is Array:
			# Mod Phishing: only the mods that can be caught now (unlocked tiers), as a share of the pool
			var pool: Array = Phishing.mod_pool() if process == Phishing.MOD else process["resource gained"]
			var total_w = 0.0
			for r in pool:
				if r is Dictionary:
					total_w += float(r.weight)
			for resource in pool:
				if resource is Dictionary:
					var item = resource.item
					var share = float(resource.weight) / max(1.0, total_w) * 100.0
					var item_name = item.name + " (" + ("%.1f" % share).trim_suffix(".0") + "%)"
					var dots_amount = 35 - item_name.length()
					return_text += "├─ " + item_name + ".".repeat(dots_amount) + item.description + "\n"
			

			#parsing
		elif process["resource gained"] is ItemData:
			var item = process["resource gained"]
			var item_name = item.name + " (100%)"
			var dots_amount = 35 - item_name.length()
			return_text += "├─ " + item_name + ".".repeat(dots_amount) + item.description + "\n"
		
		elif process["resource gained"] is String:
			var text = process["resource gained"]
			return_text += "├─ " + text + "\n"
		
		var vm = skill.vm_token
		var vm_name = vm.name + " (%s%s)" % [_pct_text(float(process.get("vm token chance", 0.01)) + Exp.vm_token_level_bonus(skill)), (" " + process["vm token per"]) if process.has("vm token per") else ""]
		var dots_amount = max(2, 35 - vm_name.length())
		return_text += "└─ " + vm_name + ".".repeat(dots_amount) + vm.description + "\n"
	
	if process.has('example commands'):
		return_text += "\nEXAMPLE COMMANDS\n"
		
		var j = 0
		for example_text in process['example commands']:
			var prefix = "├─"
			if j == process['example commands'].size() - 1:
				prefix = "└─"
			var dots_length = 45 - example_text.cmd.length()
			return_text += prefix + " " +  example_text.cmd + ".".repeat(dots_length) + example_text.description + "\n"
			j += 1
	return return_text

## 0.0033 -> "0.33%", 0.05 -> "5%", 1.0 -> "100%"
func _pct_text(chance: float) -> String:
	var pct = chance * 100.0
	if is_equal_approx(pct, round(pct)):
		return "%d%%" % roundi(pct)
	return ("%.2f%%" if pct < 1.0 else "%.1f%%") % pct

func info_command_text():
	var return_string = ""
	var l_name = 15
	var l_upgrades = 10
	var l_lvl = 6
	var l_exp = 18
	var l_cmd = 20
	return_string += pad_text("SKILL", l_name) + pad_text("VERSION", l_upgrades) + pad_text("LVL", l_lvl) + pad_text("COMMAND(from root)", l_cmd) + "\n"
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
			var version = Upgrades.get_skill_version(s)
			var name_s = "[color=#%s]%s[/color]" % [color_string, s.SKILL.name]
			return_string += pad_text(name_s, l_name) + pad_text(version, l_upgrades) + pad_text(str(s.SKILL.level), l_lvl) + pad_text(s.SKILL.command, l_cmd) + "\n"
	
	if Tutorial.is_tutorial_complete():
		return_string += "\n\nUse 'apt <skill>' to see version upgrades. [color=#666666]example: apt mining[/color]\n"
		return_string += "Use 'apt system' to see general system upgrades.\n"
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
		var reboot_text = "[font_size=12]Firewall reboot: %ds[/font_size]" % int(tar.get("firewall reboot", 10))
		var intel_text = "[font_size=12]Intel: up to -10% on every stat[/font_size]"
		return_text += "\t" + pad_text(reboot_text, pad_text_length) + intel_text + "\n"
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
		if mp.unlocked:
			var run_command = "ssh " + str(mp.get("display command", mp.get("command", ""))) # same as the main terminal's command
			return_text += pad_text(mp.name, first_col) + pad_text(run_command, second_col) + "\n"
		else:
			return_text += "[color=#666666]" + pad_text(mp.name, first_col) + pad_text("LOCKED (lvl %d)" % mp['unlock level'], second_col) + "[/color]\n"
			
			
	return return_text

func ssh_commands(major_processes: Array) -> String:
	var first_col = 15
	var second_col = 20
	var third_col = 25

	var return_text = "\n\nSSH Commands\n\n"
	return_text += pad_text("Skill", first_col) + pad_text("VM Tokens", second_col) + pad_text("VM commands", third_col) + "\n"
	return_text += "-".repeat(first_col + second_col + third_col) + "\n"
	
	for p in major_processes:
		var c = p.SKILL.color.to_html()
		var s_name = "[color=#%s]%s[/color]" % [c, p.SKILL.name]
		var info_command = "ssh " + p.SKILL.name.to_lower()
		var tokens = str(Inventory.get_amount(p.vm_token))
		return_text += pad_text(s_name, first_col) + pad_text(tokens, second_col) + pad_text(info_command, third_col) + "\n"
		
	return_text += "\nRun any process in a VM window: 'ssh' + the process command, e.g. [color=#4ec994]ssh mine -logs[/color], [color=#4ec994]ssh crack -password[/color].\n"
	return_text += "VM Tokens run processes in a separate pop-up window. Each window consumes a VM token to run for 30 seconds.\n"
	return_text += "If there are additional VM tokens they will be consumed to run for an additional 30 seconds until the window is exited out of or you run out of VM Tokens for that skill."
	return return_text
	

func ssh_help_commands() -> String:
	var text := """
 ____________________________________________________________________
|                                                                    |
|                            SSH COMMANDS                            |
|____________________________________________________________________|
|                                                                    |
|   ssh                          Your VM tokens for each skill       |
|   ssh <skill>                  A skill's VM commands               |
|                                e.g. ssh mining                     |
|   ssh <process command>        Run that process in a VM window     |
|                                (uses one VM token)                 |
|                                e.g. ssh mine -logs                 |
|                                e.g. ssh parse -footprint=logs      |
|   ssh -h                       Show this list of commands          |
|____________________________________________________________________|
"""
	return text

## 'intel -h' (and the top of 'intel'): same box as ssh -h / process -h
func intel_help_commands() -> String:
	return """
 ____________________________________________________________________
|                                                                    |
|                           INTEL COMMANDS                           |
|____________________________________________________________________|
|                                                                    |
| Intel weakens a target's next hacks: integrity, firewall, counter  |
| damage and counter speed, up to -10% each, for a set number of     |
| hacks. Gather it with Decoding.                                    |
|                                                                    |
|   intel                        Intel on every unlocked target      |
|   intel <location>             Intel on one location's targets     |
|                                e.g. intel school                   |
|   intel <target>               One target's intel in detail        |
|                                e.g. intel student                  |
|   intel <target> hard          The hard-mode version               |
|   decode -intel=<target>       Gather intel on a target            |
|                                e.g. decode -intel=student          |
|   intel -h                     Show this list of commands          |
|____________________________________________________________________|
"""

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
|   kill -s                      Stop it after the current cycle     |
|   stop                         Stop currently running process      |
|   stop -s                      Stop it after the current cycle     |
|                                                                    |
| DISPLAY & CONTROL                                                  |
|   focus                        Bring currently running process     |
|                                to bottom of terminal               |
|   ps                           List running process                |
|   pin                          Pin process to top of terminal      |
|   unpin                        Remove pinned process from top      |
|                                                                    |
| DOCUMENTATION                                                      |
|   process -h                   Show this list of commands          |
|____________________________________________________________________|
"""
	return text

func get_help() -> String:
	var text := """
 _____________________________________________________________________
|                                                                     |
|                          IDLEOS COMMANDS                            |
|_____________________________________________________________________|
|                                                                     |
| SKILLS / TRAVERSAL                                                  |
|   cd <skill>                   Navigate to a skill                  |
|   Tab                          Auto-complete a command              |
|   cd ..                       Move up one directory                 |
|   cd root                     Return to root from anywhere          |
|   tree                         Display skill hierarchy              |
|   flow                         Chart of resources to hacking        |
|   hint                         Suggestions on what to run next      |
|   utility                      Helper commands (sticky, track..)    |
|   info                         Display additional skill info        |
|   info <skill>                 A skill's processes + their commands |
|                                                                     |
| ITEMS                                                               |
|   ls                           List items                           |
|   ls <item>                    Item details                         |
|   track <item>, <item>         Track item(s) (comma separated)      |
|   untrack <item>               Remove tracking                      |
|                                                                     |
| VIRTUAL MACHINES                                                    |
|   ssh                          Your VM tokens for each skill        |
|   ssh <process command>        Run it in a VM (ssh mine -logs)      |
|   vm -h                        Manage VM windows                    |
|                                                                     |
| UPGRADES                                                            |
|   apt                          Upgrade package manager              |
|   mod                          Hacking mod manager                  |
|                                                                     |
| PROGRESS                                                            |
|   upload                       Upload goal + what's uploading       |
|   intel                        Intel on hacking targets (intel -h)  |
|                                                                     |
| DOCUMENTATION                                                       |
|   tutorial                     Show tutorial checklist              |
|   -h                           Display this list                    |
|   process -h                   List process commands                |
|   ssh -h                       List ssh commands                    |
|                                                                     |
| SETTINGS                                                            |
|   settings                     Player settings menu                 |
|   music                        Now playing · music next/off/on      |
|                                                                     |
| SYSTEM                                                              |
|   date                         Show date and time                   |
|   version                      Show the game version                |
|   clear                        Clear terminal                       |
|   system                       Show system information              |
|   panel                        Collapse / expand the side panel     |
|   vm -h                        List VM window commands              |
|   quit -s                      Save and quit                        |
|_____________________________________________________________________|
"""
	return text

## 'version': the build players are on. The number is Project Settings > Application > Config > Version
## (application/config/version in project.godot): bump it with every Steam build.
func version_text() -> String:
	var v = str(ProjectSettings.get_setting("application/config/version", "dev"))
	var t = "\n[color=#33ff33]IdleOS v%s[/color]\n" % v
	t += "[color=#888888]save format %d  ·  Godot %s  ·  %s[/color]\n" % [SaveManager.SAVE_VERSION, Engine.get_version_info().string, OS.get_name()]
	t += "[color=#666666]Include this in bug reports. If Steam hasn't updated the game yet, restart Steam.[/color]"
	return t

## 'utility': the helper commands, in the same box as '-h'
func utility_commands() -> String:
	var rows = [
		["", "PROCESSES"],
		["focus", "Bring the running process to the bottom of the terminal"],
		["pin / unpin", "Pin the running process to the top of the terminal / unpin it"],
		["kill / kill -s", "Stop the running process (-s: finish its current cycle first)"],
		["", ""],
		["", "ITEMS"],
		["track <item>, <item>", "Keep a live count of items in the side panel"],
		["untrack <item> / -a", "Stop tracking one / all"],
		["ls <item>", "Item details: where it comes from, what it's used for"],
		["", ""],
		["", "LOOKUP"],
		["info", "Every skill: version and level"],
		["info <skill>", "A skill's processes and the commands that run them"],
		["tree", "Skill hierarchy"],
		["flow", "Chart of resources to hacking"],
		["hint", "Suggestions on what to run next"],
		["", ""],
		["", "TERMINAL"],
		["history", "Commands you've typed"],
		["clear", "Clear the terminal"],
		["date / system", "Date and time / system info"],
		["version", "The game version (handy for bug reports)"],
		["panel", "Collapse / expand the side panel"],
	]
	var W = 96
	var t = "\n " + "_".repeat(W) + "\n|" + " ".repeat(W) + "|\n|" + (" ".repeat(36) + "IDLEOS UTILITY COMMANDS").rpad(W) + "|\n|" + "_".repeat(W) + "|\n|" + " ".repeat(W) + "|\n"
	for r in rows:
		var line = (" " + r[1]) if r[0] == "" else ("   " + r[0].rpad(29) + r[1])
		t += "|" + line.rpad(W).left(W) + "|\n"
	t += "|" + "_".repeat(W) + "|\n"
	return t

func get_ascii_tree(current_context: String) -> String:
	var skills = [
		Mining,
		Parsing,
		Cracking,
		Matching,
		Phishing,
		Compiling,
		Hacking,
		Decoding,
		Defragging
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

#region apt (upgrade package manager)
const APT_DIM := "#666666"
const APT_OK := "#4ec994"
const APT_BAD := "#e24b4a"
const APT_GOLD := "#ffc24a"

## 10-cell bar from background-colored spaces (no special glyphs needed)
func apt_bar(done: int, total: int = 10, color: String = APT_OK) -> String:
	var t = ""
	if done > 0:
		t += "[bgcolor=%s]%s[/bgcolor]" % [color, " ".repeat(done)]
	if done < total:
		t += "[bgcolor=#2a2f36]%s[/bgcolor]" % " ".repeat(total - done)
	return t

func _apt_group_name(group: String) -> String:
	return "[color=#%s]%s[/color]" % [Upgrades.group_color(group).to_html(false), group]

func _apt_cost_text(level: Dictionary) -> String:
	var parts = []
	for r in Upgrades.cost_rows(level):
		parts.append("%s [color=%s]%s/%s[/color]" % [r.name, APT_OK if r.have >= r.need else APT_BAD, _short_num(r.have), _short_num(r.need)])
	return ", ".join(parts)

func _short_num(n: int) -> String:
	if n >= 100000:
		return "%dk" % int(n / 1000)
	return str(n)

## 'apt': every group with its version and current tier
func get_root_upgrades_text() -> String:
	var t = "\nIDLEOS PACKAGE MANAGER\n"
	t += "[color=%s]Every install is +0.1 version. Finish a tier's 10 installs for a MAJOR release (v1.0, v2.0 ...). New tiers open with new locations.[/color]\n\n" % APT_DIM
	var columns = [
		{"title": "SKILL"}, {"title": "VERSION"}, {"title": "TIER"}, {"title": "PROGRESS", "drop": 1},
		{"title": "READY"}, {"title": "COMMAND", "drop": 2},
	]
	var rows = []
	var colors = []
	for g in Upgrades.groups:
		var wt = Upgrades.working_tier(g)
		# tier done but the next one isn't open yet: show the finished tier as up to date (10/10)
		var waiting = wt <= 6 and wt > 1 and !Upgrades.tier_unlocked(wt)
		var st = wt - 1 if waiting else wt
		var tier_text = "complete" if wt > 6 else "%d · %s" % [st, Upgrades.tier_name(st)]
		var done = 0 if wt > 6 else Upgrades.tier_installed(g, st)
		var ready = 0
		var status = ""
		if !Upgrades.is_wired(g):
			status = "[color=%s]coming soon[/color]" % APT_DIM
		elif waiting:
			status = "[color=%s]up to date[/color]" % APT_OK
		elif wt <= 6 and !Upgrades.tier_unlocked(wt):
			status = "[color=%s]tier locked[/color]" % APT_DIM
		else:
			for p in Upgrades.group_packages(g):
				if Upgrades.install_block_reason(p) == "":
					ready += 1
			status = ("[color=%s]%d ready[/color]" % [APT_OK, ready]) if ready > 0 else "[color=%s]-[/color]" % APT_DIM
		rows.append([_apt_group_name(g), Upgrades.version_text(g), tier_text,
			(apt_bar(done, 10, APT_GOLD if waiting else APT_OK) + " %d/10" % done) if wt <= 6 else apt_bar(10, 10, APT_GOLD), status, "apt " + g.to_lower()])
		colors.append("")
	t += build_table(columns, rows, colors)
	t += "\n[color=%s]apt <skill>[/color] lists a skill's packages · [color=%s]apt install <skill>[/color] installs everything ready · [color=%s]apt install all[/color] for every skill" % [APT_OK, APT_OK, APT_OK]
	t += "\n[color=%s]example: apt system · apt install system · apt install system.cooling_amount[/color]" % APT_DIM
	return t

## 'apt <group>': the tier being worked on in full, finished tiers as one line each, then one line
## for what opens next (later tiers stay hidden so this doesn't become a wall of text).
func get_skill_upgrades_text(group: String) -> String:
	var t = "\n[color=#%s]%s[/color]  %s\n" % [Upgrades.group_color(group).to_html(false), group.to_upper(), Upgrades.version_text(group)]
	if !Upgrades.is_wired(group):
		t += "[color=%s]%s upgrades can be installed once this skill is migrated.[/color]\n" % [APT_GOLD, group]
	var wt = Upgrades.working_tier(group)
	# finished a tier, next one not open yet: list what's installed in the finished tier, then what opens next
	var waiting = wt <= 6 and wt > 1 and !Upgrades.tier_unlocked(wt)
	var locked_next = wt
	if waiting:
		wt -= 1
	for tier in range(1, min(wt, 7)):
		t += "[color=%s]TIER %d · %s[/color]  %s  [color=%s]complete · v%d.0[/color]\n" % [APT_DIM, tier, Upgrades.tier_name(tier).to_upper(), apt_bar(10, 10, APT_GOLD), APT_DIM, tier]
	if wt > 6:
		t += "\n[color=%s]Fully upgraded.[/color]" % APT_GOLD
		return t
	var done = Upgrades.tier_installed(group, wt)
	var head = "TIER %d · %s" % [wt, Upgrades.tier_name(wt).to_upper()]
	if !waiting and !Upgrades.tier_unlocked(wt):
		t += "\n[color=%s]%s  locked · opens with %s access (upload goal)[/color]\n" % [APT_DIM, head, Upgrades.tier_name(wt)]
		return t
	t += "\n%s  %s %d/10%s\n" % [head, apt_bar(done, 10, APT_GOLD if waiting else APT_OK), done, ("  [color=%s]up to date · v%d.0[/color]" % [APT_OK, wt]) if waiting else ""]
	var columns = [{"title": "PACKAGE"}, {"title": "UPGRADE"}, {"title": "CHANGE", "min": 18}, {"title": "COST", "min": 20}, {"title": "STATUS"}]
	var rows = []
	var colors = []
	var ready = 0
	for p in Upgrades.group_packages(group):
		var in_tier = p.levels.filter(func(l): return int(l.tier) == wt)
		if in_tier.is_empty():
			continue
		var have_in_tier = 0
		for i in p.installed:
			if int(p.levels[i].tier) == wt:
				have_in_tier += 1
		var label = p.name + (" (MAJOR)" if p.type == "capstone" else "") + ("  %d/%d" % [have_in_tier, in_tier.size()] if in_tier.size() > 1 else "")
		if have_in_tier >= in_tier.size():
			rows.append([p.id, label, in_tier[-1].after, "", "installed"])
			colors.append(APT_DIM)
			continue
		var lvl = Upgrades.next_level(p)
		var reason = Upgrades.install_block_reason(p)
		if reason == "":
			ready += 1
		var status = "[color=%s]READY[/color]" % APT_OK if reason == "" else ("[color=%s]missing items[/color]" % APT_BAD if reason == "Missing requirements." else "[color=%s]-[/color]" % APT_DIM)
		var change = ("%s -> %s" % [lvl.before, lvl.after]) if p.type != "capstone" else str(lvl.effect)
		rows.append([p.id, label, change, _apt_cost_text(lvl), status])
		colors.append("")
	t += build_table(columns, rows, colors)
	if waiting:
		t += "[color=%s]Next: Tier %d · %s opens with %s access (upload goal)[/color]\n" % [APT_DIM, locked_next, Upgrades.tier_name(locked_next), Upgrades.tier_name(locked_next)]
	elif wt < 6:
		var nt = wt + 1
		var opens = "after v%d.0" % wt if Upgrades.tier_unlocked(nt) else "with %s access and v%d.0" % [Upgrades.tier_name(nt), wt]
		t += "[color=%s]Next: Tier %d · %s opens %s[/color]\n" % [APT_DIM, nt, Upgrades.tier_name(nt), opens]
	if ready > 1:
		t += "\n[color=%s]apt install %s[/color] installs all %d ready packages at once" % [APT_OK, group.to_lower(), ready]
	t += "\n[color=%s]apt install <package>[/color] installs one · [color=%s]apt <package>[/color] for details" % [APT_OK, APT_OK]
	return t

## 'apt <package>'
func get_upgrades_package_info(package_id: String) -> String:
	if !Upgrades.is_valid_package(package_id):
		return "Package id not found"
	var p = Upgrades.get_package_info(package_id)
	var t = "\n%s  ·  %s  ·  %s\n" % [p.id, _apt_group_name(p.group), Upgrades.version_text(p.group)]
	t += "%s%s\n" % [p.name, "  (MAJOR release capstone)" if p.type == "capstone" else ""]
	t += "[color=%s]%s[/color]\n\n" % [APT_DIM, p.effect]
	var columns = [{"title": "TIER"}, {"title": "VALUE"}, {"title": "AFTER", "min": 16}, {"title": "STATUS"}]
	var rows = []
	var colors = []
	for i in p.levels.size():
		var l = p.levels[i]
		var status = "installed" if i < p.installed else ("NEXT" if i == p.installed else "")
		if i >= p.installed and !Upgrades.tier_unlocked(int(l.tier)):
			status = "locked"
		rows.append(["%d · %s" % [int(l.tier), Upgrades.tier_name(int(l.tier))], str(l.label), str(l.after), status])
		colors.append(APT_DIM if i < p.installed or status == "locked" else ("" if i == p.installed else APT_DIM))
	t += build_table(columns, rows, colors)
	var lvl = Upgrades.next_level(p)
	if lvl.is_empty():
		t += "\n[color=%s]Fully upgraded.[/color]" % APT_GOLD
		return t
	t += "\nNext: %s -> %s\n" % [lvl.before, lvl.after] if p.type != "capstone" else "\nNext: %s\n" % lvl.effect
	t += "Cost: %s\n" % _apt_cost_text(lvl)
	var reason = Upgrades.install_block_reason(p)
	t += ("[color=%s]apt install %s[/color]" % [APT_OK, p.id]) if reason == "" else "[color=%s]%s[/color]" % [APT_DIM, reason]
	return t
#endregion

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
|   mine -logs, crack ...        Skills run from any directory       |
|   Tab                          Auto-complete a command             |
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
	
	return_string += "Type 'tutorial' at any time to view progress. [color=#666666]'tutorial reset' starts it over.[/color]\n"
	
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
Current temp: %.1f °C/s
Cooling amount: %s °C/s
Current time: %s
Virtual Machines (VMS): %s/%s
Anonymity: %s
Max Bandwidth: %s
Bandwidth Restore: +%s/second
""" % [tempature, cooling_amount, time, current_vms, max_vms, max_anon, m_band, bw_recov]


func demo_welcome_message():
	return """
WELCOME TO IDLEOS

Your first job: prepare and hack your first target, a [color=#e3b341]Student[/color] at the local School. The tutorial
walks you through it one terminal command at a time, and teaches you the operating system on the way.
Hacking is where the big hauls come from: every breached target drops a cache full of resources,
far more than your processes make on their own. Your processes keep the hacks supplied.

Thoughts or suggestions? Join the Discord: """ + DISCORD_LINK + """  ('discord -c' copies it)

Stuck? 'hint' suggests what to run next.

To view this message again, use the 'welcome' command.
"""

func discord_message():
	return """
Discord link: """ + DISCORD_LINK + """

To copy the discord link to your clipboard use 'discord -c'
"""

func get_build_version() -> String:
	return "IdleOS v" + str(ProjectSettings.get_setting("application/config/version", "dev"))

func get_mod_command() -> String:
	#if HackingMods.current_mods.is_empty():
		#return "No active Hacking Mods. Use the Mod process in the [color=" + Compiling.SKILL.color.to_html() + "]Compiling[/color] skill to Compile items into Hacking Mods."

	var return_text = ""
	var id_col = 5
	var mod_col = 27
	var eff_col = 32
	var mod_val = 8
	
	var active_mods_title = "\n| ACTIVE MODS " + str(HackingMods.current_mods.size()) + "/" + str(HackingMods.max_mods)  + " |\n"
	
	return_text += "\n------------------"
	return_text += active_mods_title
	return_text += "------------------\n\n"
	return_text += pad_text("ID", id_col) + pad_text("MOD", mod_col) + pad_text("EFFECT", eff_col) + pad_text("VALUE", mod_val) + "REMAINING\n"
	return_text += "-----------------------------------------------------------------------------------\n"

	if HackingMods.current_mods.is_empty():
		return_text += pad_text("-", id_col)
		return_text += pad_text("-", mod_col)
		return_text += pad_text("-", eff_col)
		return_text += pad_text("-", mod_val)
		return_text += "-\n"
	
	else:

		for i in range(HackingMods.current_mods.size()):
			var mod_type = HackingMods.current_mods.keys()[i]
			var mod = HackingMods.current_mods[mod_type]

			var hmv = HackingMods.get_mod_value_text(mod_type, mod.value)
			var hmn = HackingMods.get_mod_name(mod_type)
			var hmd = mod.duration

			return_text += pad_text("[" + str(i) + "]", id_col, false)
			return_text += pad_text(hmn, mod_col)
			return_text += pad_text(HackingMods.get_mod_stat(mod_type), eff_col)
			return_text += pad_text(hmv, mod_val)
			return_text += str(hmd) + " hacks\n"
	
	return_text += "\n\n\n-------------"
	return_text += "\n| MOD ITEMS |\n"
	return_text += "-------------\n"
	
	
	var mod_id_col = 5
	var mod_name_col = 27
	var mod_mod_col = 32
	var mod_val_col = 8
	
	return_text += "\n" + pad_text("ID", mod_id_col) + pad_text("NAME", mod_name_col) + pad_text("EFFECT", mod_mod_col) + pad_text("VALUE", mod_val_col) + "REMAINING\n"
	return_text += "----------------------------------------------------------------------------------\n"
	if Inventory.has_mod_item():
		var player_hacking_mods = Inventory.get_hacking_mods_items()
		
		if !player_hacking_mods.is_empty():
			for i in player_hacking_mods.size(): #loop through hacking items
				var mod = player_hacking_mods[i]
				var mod_type = mod.hacking_mod_type

				var hmv = HackingMods.get_mod_value_text(mod_type, mod.hacking_mod_value)
				var hmd = HackingMods.mod_duration(mod) # + Kernel Modules

				return_text += pad_text("[" + str(i) + "]", mod_id_col, false)
				return_text += pad_text(mod.name, mod_name_col)
				return_text += pad_text(HackingMods.get_mod_stat(mod_type), mod_mod_col)
				return_text += pad_text(hmv, mod_val_col)
				return_text += str(hmd) + " hacks\n"
		
	else:
		return_text += pad_text("-", mod_id_col)
		return_text += pad_text("-", mod_name_col)
		return_text += pad_text("-", mod_mod_col)
		return_text += pad_text("-", mod_val_col)
		return_text += "-"

	return_text += "\n\n\nuse 'mod -add <ID>' to add mod items to active mods.\n"
	return_text += "use 'mod -rm <ID>' to remove active mod. WARNING: this mod will be deleted.\n"
	return_text += "Mod items are found with 'phish -mod', by parsing Mining items with Corruption, and in caches. Each lasts a few hacks.\n\n"
	return return_text


func upload_info():
	var return_text = "\n\nAquire and upload the Parents Credit Card item. Obtain from Hacking the Student and Decoding the Student Cache.\n\nUse 'upload parents credit card' to upload once aquired."
	return return_text


func not_built_text(minor_process: Dictionary) -> String:
	return "[color=#888888]" + str(minor_process.name) + " isn't built yet — it arrives with a later tier.[/color]"


## 'upload': the current tier's goal, what's uploaded, queued and uploading.
## Banner when a location's upload goal completes: what the next location opens up (online and in the offline download)
func tier_complete_text(tier: int) -> String:
	var done = Uploads.get_location_name(tier)
	var t = "[color=#33ff33]════════════════════════════════════════\nUPLOAD GOAL COMPLETE  ·  %s\n════════════════════════════════════════[/color]\n" % done.to_upper()
	if tier >= Uploads.MAX_TIER:
		return t + "Every location's goal is uploaded. The whole network is yours."
	var next = Uploads.get_location_name(tier + 1)
	var loc = Stats.hacking_targets.get(next, {})
	var first = loc.get("targets", [{}])[0].get("name", "?") if !loc.get("targets", []).is_empty() else "?"
	t += "[color=#e3b341]%s UNLOCKED[/color]\n" % next.to_upper()
	t += "  · new target: %s  [color=#666666](in Hacking: view %s)[/color]\n" % [first, next.to_lower()]
	t += "  · Tier %d upgrades  [color=#666666](apt: each skill's v%d.0 installs open once v%d.0 is done)[/color]\n" % [tier + 1, tier + 1, tier]
	t += "  · next upload goal: %s  [color=#666666]('upload')[/color]" % next
	return t

func upload_goal_text() -> String:
	var tier = Uploads.current_tier()
	var columns = [{"title": "ITEM"}, {"title": "UPLOADED"}, {"title": "QUEUED"}, {"title": "IN INVENTORY", "drop": 1}, {"title": "STATUS"}]
	var rows = []
	var colors = []
	for g in Uploads.get_goals(tier):
		var up = Uploads.get_uploaded(g.item)
		var status = "done" if up >= g.amount else ("uploading" if Uploads.is_uploading(g.item) else ("queued" if Uploads.get_staged(g.item) > 0 else ("ready" if Inventory.get_amount(g.item) > 0 else "-")))
		rows.append([g.item.name + (" (rare)" if g.rare else ""), "%d/%d" % [up, g.amount], str(Uploads.get_staged(g.item)), str(Inventory.get_amount(g.item)), status])
		colors.append("#4ec994" if up >= g.amount else ("#e0c068" if g.rare else ""))
	var header = "UPLOAD GOAL  |  TIER %d: %s%s\n" % [tier, Uploads.get_location_name(tier).to_upper(), "  (COMPLETE)" if Uploads.is_tier_complete(tier) else ""]
	var hints = [
		["upload <item> [amount]", "upload from your inventory; no amount = all the goal still needs  (ex. upload logs 5)"],
		["upload -a", "upload every goal item you have"],
		["upload cancel <item>", "return queued items to your inventory"],
	]
	var footer = "\n"
	for h in hints:
		footer += "  [color=#33ff33]%s[/color] [color=#666666]%s[/color]\n" % [h[0].rpad(24), h[1]]
	footer += "  [color=#666666]%ds per resource, %ds per rare. Uploads run in the background and add heat.[/color]" % [int(Uploads.UPLOAD_SECONDS_BY_TIER[Uploads.current_tier() - 1]), int(Uploads.RARE_UPLOAD_SECONDS)]
	return header + build_table(columns, rows, colors) + footer
