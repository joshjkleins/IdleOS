extends Node
func _ready() -> void:
	for s in [Hacking]:
		print(">>> ==== ", s.SKILL.name, "\n", ContextCommands.strip_bbcode(ContextCommands.get_help_text_2(s)).substr(0, 1400))
	for s in [Mining, Matching, Compiling, Cracking]:
		var t = ContextCommands.strip_bbcode(ContextCommands.get_help_text(s))
		var i = t.find("Efficiency")
		var j = t.find("EFFICIENCY (EFF) BY")
		print(">>> ==== ", s.SKILL.name, "  oneline@", i, "  byprocess@", j)
		if j >= 0: print(t.substr(j, 400))
		elif i >= 0: print(t.substr(i, 120))
	get_tree().quit()
