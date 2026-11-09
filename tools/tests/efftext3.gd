extends Node
func _ready() -> void:
	var t = ContextCommands.strip_bbcode(ContextCommands.get_help_text_hacking(Hacking))
	print(">>> HACKING top-line@%d" % t.find("Efficiency (EFF):"))
	print(t.substr(t.find("└"), 200))
	for s in [Matching, Compiling, Mining]:
		var u = ContextCommands.strip_bbcode(ContextCommands.get_help_text(s))
		print(">>> ==== %s top-line@%d" % [s.SKILL.name, u.find("Efficiency (EFF):")])
		print(u.substr(u.find("EFFICIENCY (EFF) BY"), 260))
	get_tree().quit()
