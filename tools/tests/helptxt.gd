extends Node
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	for i in 30: await get_tree().process_frame
	print(ContextCommands.get_help())
	print(ContextCommands.process_commands().substr(0, 700))
	print(Decoding.intel_command_text("-h"))
	print(_strip(Decoding.intel_command_text("")).left(200))
	for e in Tutorial.TUTORIAL_ORDER: if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	print(_strip(HintEngine.text(null)))
	get_tree().quit()
