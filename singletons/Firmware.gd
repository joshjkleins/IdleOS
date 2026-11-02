extends Node
## 2026-11-02: Firmware - the end-game "capes". One per skill (the 7 process skills + Hacking + Defragging), won from
## the Government compromise like drivers (a random one you don't own, no repeats). Install it from inside its skill
## ('cd <skill>' -> 'firmware -install'; Hacking: in the hacking console) once the skill is level 99 and its apt
## tiers are all installed (Defragging: System's apt). A skill with its Firmware installed is "maxed": the header
## card gets a FW tag and an animated shader.

signal changed

const TIER := 6 # the Government compromise
const C_FW := "#c084fc"
const C_GOLD := "#ffc24a"

## id -> skill name (singleton name), apt group, effect text
const DEFS := {
	"mining":     {"skill": "Mining",     "apt": "Mining",    "effect": "Mining VMs cost no VM tokens, and Mining makes no heat."},
	"parsing":    {"skill": "Parsing",    "apt": "Parsing",   "effect": "Parsing VMs cost no VM tokens, and Parsing makes no heat."},
	"cracking":   {"skill": "Cracking",   "apt": "Cracking",  "effect": "Cracking VMs cost no VM tokens, and Cracking makes no heat."},
	"matching":   {"skill": "Matching",   "apt": "Matching",  "effect": "Matching VMs cost no VM tokens, and Matching makes no heat."},
	"phishing":   {"skill": "Phishing",   "apt": "Phishing",  "effect": "Phishing VMs cost no VM tokens, and Phishing makes no heat."},
	"decoding":   {"skill": "Decoding",   "apt": "Decoding",  "effect": "Decoding VMs cost no VM tokens, and Decoding makes no heat."},
	"compiling":  {"skill": "Compiling",  "apt": "Compiling", "effect": "Compiling VMs cost no VM tokens, and Compiling makes no heat."},
	"hacking":    {"skill": "Hacking",    "apt": "Hacking",   "effect": "Every SQL Injector hit is a critical hit, and hacking makes no heat."},
	"defragging": {"skill": "Defragging", "apt": "System",    "effect": "Adds 'defrag -all': one defrag that grants every unlocked bonus at once."},
}

var owned: Array = []      # ids won
var installed: Array = []  # ids installed

func save_data() -> Dictionary:
	return {"owned": owned, "installed": installed}

func load_data(d: Dictionary) -> void:
	owned = Array(d.get("owned", [])).filter(func(i): return DEFS.has(i))
	installed = Array(d.get("installed", [])).filter(func(i): return DEFS.has(i))
	changed.emit()

func name_of(id: String) -> String:
	return "%s Firmware" % DEFS[id].skill

func id_for(skill_name: String) -> String:
	return skill_name.to_lower() if DEFS.has(skill_name.to_lower()) else ""

func skill_node(id: String) -> Node:
	return get_node_or_null("/root/" + str(DEFS[id].skill))

func is_owned(id: String) -> bool:
	return id in owned

## true when <skill> (a skill node, its name, or a firmware id) has its Firmware installed
func active(skill) -> bool:
	if skill == null:
		return false
	var n = skill if skill is String else (str(skill.SKILL.name) if "SKILL" in skill else "")
	return n.to_lower() in installed

func ids() -> Array:
	return DEFS.keys()

func left() -> Array:
	return ids().filter(func(i): return !is_owned(i))

## the Government compromise prize: a random Firmware you don't own ("" when you have them all)
func roll() -> String:
	var l = left()
	if l.is_empty():
		return ""
	var id = l.pick_random()
	grant(id)
	return id

func grant(id: String) -> void:
	if DEFS.has(id) and !is_owned(id):
		owned.append(id)
		SaveManager.mark_dirty()
		changed.emit()

#region install
## Defragging has no levels (it never gains XP), so its Firmware only needs System's apt
func needs_level(id: String) -> bool:
	return id != "defragging"

func level_ok(id: String) -> bool:
	if !needs_level(id):
		return true
	var s = skill_node(id)
	return s != null and int(s.SKILL.get("level", 1)) >= Exp.MAX_LEVEL

func apt_ok(id: String) -> bool:
	return Upgrades.working_tier(str(DEFS[id].apt)) > 6

## "" when it can be installed now, otherwise why not
func install_problem(id: String) -> String:
	if !is_owned(id):
		return "You don't have the %s yet. It's a prize of the Government compromise." % name_of(id)
	if id in installed:
		return "%s is already installed." % name_of(id)
	var miss = []
	if !level_ok(id):
		miss.append("%s level 99" % DEFS[id].skill)
	if !apt_ok(id):
		miss.append("every %s apt tier installed (v6.0)" % DEFS[id].apt)
	if !miss.is_empty():
		return "%s needs %s." % [name_of(id), " and ".join(miss)]
	return ""

func install(id: String) -> String:
	var why = install_problem(id)
	if why != "":
		return why
	installed.append(id)
	SaveManager.save_game()
	changed.emit()
	return ""

## a skill is maxed out: level 99, every apt tier, Firmware installed (header shader)
func maxed(skill_name: String) -> bool:
	var id = id_for(skill_name)
	return id != "" and id in installed and level_ok(id) and apt_ok(id)
#endregion

#region text
func _check(ok: bool) -> String:
	return "[color=#4ec994]ok[/color]" if ok else "[color=#e26d5a]no[/color]"

## the block at the end of 'info <skill>' (and what 'cd <skill>' prints): stands out while a Firmware waits
func info_block(skill_name: String) -> String:
	var id = id_for(skill_name)
	if id == "":
		return ""
	if Ending.state == Ending.NONE and owned.is_empty(): # 2026-11-02 (Josh): no Firmware text before the first President breach
		return ""
	var nm = name_of(id)
	if id in installed:
		return "\n[color=%s]FIRMWARE INSTALLED[/color]  [color=%s]%s[/color]  [color=#888888]%s[/color]" % [C_FW, C_GOLD, nm, DEFS[id].effect]
	if !is_owned(id):
		if Compromise.is_unlocked("Government"):
			return "\n[color=#666666]FIRMWARE  not found yet · a prize of the Government compromise (in Hacking: recon government)[/color]"
		return ""
	var t = "\n[bgcolor=#2a1f3d][color=%s] FIRMWARE AVAILABLE [/color][/bgcolor]  [color=%s]%s[/color]\n" % [C_FW, C_GOLD, nm]
	t += "[color=#cccccc]%s[/color]\n" % DEFS[id].effect
	var s = skill_node(id)
	if needs_level(id):
		t += "%s %s level 99  [color=#888888](%d)[/color]     " % [_check(level_ok(id)), DEFS[id].skill, int(s.SKILL.get("level", 1)) if s else 0]
	t += "%s every %s apt tier (v6.0)  [color=#888888](%s)[/color]\n" % [_check(apt_ok(id)), DEFS[id].apt, Upgrades.version_text(str(DEFS[id].apt))]
	if install_problem(id) == "":
		t += "[color=#4ec994]Ready: run[/color] [color=%s]firmware -install[/color]" % C_GOLD
	elif needs_level(id):
		t += "[color=#e26d5a]Requires %s level 99 and every %s apt tier before it can be installed.[/color]" % [DEFS[id].skill, DEFS[id].apt]
	else:
		t += "[color=#e26d5a]Requires every %s apt tier before it can be installed.[/color]" % DEFS[id].apt
	return t

## 'firmware' / 'firmware -install' inside <skill_name> ("" = root: the overview)
func handle(text: String, skill_name: String) -> String:
	var t = text.strip_edges().to_lower()
	var id = id_for(skill_name)
	if t in ["firmware -install", "firmware install", "firmware -i"]:
		if id == "":
			return "Install a Firmware from inside its skill: 'cd <skill>' then 'firmware -install' (Hacking: in the hacking console)."
		var why = install(id)
		if why != "":
			return "[color=#e26d5a]%s[/color]" % why
		return "\n[bgcolor=#2a1f3d][color=%s] FIRMWARE INSTALLED [/color][/bgcolor]  [color=%s]%s[/color]\n[color=#cccccc]%s[/color]\n[color=#888888]%s is maxed out.[/color]" % [C_FW, C_GOLD, name_of(id), DEFS[id].effect, DEFS[id].skill]
	if id != "":
		var b = info_block(skill_name)
		return b if b != "" else "[color=#888888]No Firmware for %s yet.[/color]" % skill_name
	var out = "[color=%s]FIRMWARE[/color]  [color=#888888]%d/%d found · %d installed · Government compromise prize[/color]\n" % [C_FW, owned.size(), DEFS.size(), installed.size()]
	for i in ids():
		var state = "[color=%s]installed[/color]" % C_FW if i in installed else ("[color=%s]found[/color]  [color=#888888]('cd %s' -> firmware)[/color]" % [C_GOLD, i] if is_owned(i) else "[color=#555555]not found[/color]")
		out += "  %s  %s\n" % [DEFS[i].skill.rpad(11), state]
	return out
#endregion
