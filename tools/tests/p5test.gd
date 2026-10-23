extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	# ssh whale
	Phishing.SKILL.level = 30; Exp.refresh_process_unlocks(Phishing)
	Inventory.add_resource(Phishing.vm_token, 1)
	var n0 = os.lines.size()
	os._on_input_line_text_submitted("ssh phishing whale")
	for i in 200: await get_tree().process_frame
	print("ssh whale: ", _strip("\n".join(os.lines.slice(n0))).substr(0, 300))
	print("salvage: ", Decoding.roll_salvage(Items.LOGS).filter(func(r): return r != null).map(func(r): return r.amount))
	print(_strip(ContextCommands.get_mod_command()).right(250))
	print(Defragging.VM.description)
	get_tree().quit()
