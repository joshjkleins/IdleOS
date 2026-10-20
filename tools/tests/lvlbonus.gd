extends Node
## Level bonus text in 'info <skill>' at a few levels, + the VM token chance shown in 'info <skill> <process>'.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true; add_child(rt)
	for lvl in [1, 4, 23, 95, 99]:
		Mining.SKILL.level = lvl
		rt.text = Exp.level_bonus_text(Mining)
		print(">>> Mining L%d%s" % [lvl, rt.get_parsed_text()])
	Mining.SKILL.level = 23
	rt.text = ContextCommands.get_mp_info(Mining, Mining.minor_processes[0])
	print(">>> info mining logs (L23):\n" + rt.get_parsed_text().right(220))
	print(">>> hacking applies: %s  decoding bonus at L99: %s" % [Exp.level_bonus_applies(Hacking), Exp.vm_token_level_bonus(Decoding)])
	get_tree().quit()
