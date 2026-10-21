extends Node
## Skills run from any directory ('mine -logs' at root, 'crack -password' from Mining), which, overclock from root.
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 40) -> void:
	seen = os.lines.size()
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
	print(">>> " + c + "   [ctx " + str(os.current_context) + " running " + str(os.process_running) + "]")
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true
	for l in os.lines.slice(seen + 1):
		rt.text = l
		var t = rt.get_parsed_text().strip_edges()
		if t != "": print("    " + t.left(160))
	rt.free()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	Offline.report = {}
	Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 10)
	await _cmd("which mine")
	await _cmd("which ls")
	await _cmd("ls /usr/local/bin")
	await _cmd("mine -logs", 60)
	await _cmd("overclock")
	await _cmd("overclock -kill")
	await _cmd("kill")
	await _cmd("cd mining")
	await _cmd("crack -password", 60)
	await _cmd("kill")
	await _cmd("cd ..")
	await _cmd("hack student")
	await _cmd("mine -nope")
	get_tree().quit()
