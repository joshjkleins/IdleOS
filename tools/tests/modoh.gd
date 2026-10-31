extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	for i in 10: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 200: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	for id in ["mining.sift", "mining.overclock"]:
		Upgrades.packages[id].installed = 1; Upgrades._recompute(Upgrades.packages[id])
	await _cmd("cd mining")
	await _cmd("mine -logs")
	await _cmd("overclock")
	await _cmd("overclock -kill")
	await _cmd("sift")
	print(">>> modifier before: ", os.current_process.modifier.get("name", "-"))
	Stats.update_tempature(100.0)
	for i in 20: await get_tree().process_frame
	print(">>> modifier after overheat: ", os.current_process.modifier.get("name", "-"))
	await _cmd("sift")
	print(">>> modifier after sift while overheated: ", os.current_process.modifier.get("name", "-"))
	var all = ""
	for n in os.find_children("*", "RichTextLabel", true, false): all += n.get_parsed_text() + "\n"
	for l in all.split("\n"):
		if "verclock on" in l or "overheated" in l.to_lower(): print(">>> L ", l.substr(0, 160))
	for l in os.lines: if "verclock on" in str(l) or "overheated" in str(l) or "Sift" in str(l): print(">>> ", str(l).substr(0, 160))
	var re = RegEx.new(); re.compile("\\[[^\\]]*\\]")
	for l in re.sub(ContextCommands.modifier_table(Mining) if ContextCommands.has_method("modifier_table") else "", "", true).split("\n"): if "Overclock" in l: print(">>> T ", l)
	get_tree().quit()
