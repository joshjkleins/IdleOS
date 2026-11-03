extends Node
func _ready():
	_run.call_deferred()
func _run():
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	os._on_input_line_text_submitted("school")
	for i in 60: await get_tree().process_frame
	var txt = os.current_scrollback.get_parsed_text()
	var ls = Array(txt.split("\n", false))
	var i0 = -1
	for i in ls.size():
		if "Principal" in ls[i] and i0 == -1 and i > ls.size() - 60: i0 = i
	print(">>> ", "\n>>> ".join(ls.slice(max(0, ls.size() - 40))))
	os._on_input_line_text_submitted("ls principal cache")
	for i in 30: await get_tree().process_frame
	var l2 = Array(os.current_scrollback.get_parsed_text().split("\n", false))
	print(">>> ls: ", " | ".join(l2.slice(max(0, l2.size() - 6))))
	get_tree().quit()
