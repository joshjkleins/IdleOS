extends Node
## 2026-11-14: history skips blanks / repeats, caps at 200, 'history' shows the last 50, 'history -c' copies
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	os.command_history.clear()
	for c in ["date", "date", "   ", "version", "date", "date"]:
		os._on_input_line_text_submitted(c)
	print(">>> after date,date,blank,version,date,date: %s" % [os.command_history])
	for i in 250:
		ContextCommands.record_history(os.command_history, "cmd %d" % i)
	print(">>> after 250 more: size %d, first '%s', last '%s'" % [os.command_history.size(), os.command_history[0], os.command_history[-1]])
	var shown = ContextCommands.strip_bbcode(ContextCommands.get_history_commands(os.command_history)).strip_edges().split("\n")
	print(">>> 'history' lines %d: first '%s'  last '%s'" % [shown.size(), shown[0], shown[-1]])
	os._on_input_line_text_submitted("history -c")
	await _f(3)
	var clip = DisplayServer.clipboard_get().split("\n")
	print(">>> clipboard lines %d: first '%s' last '%s'" % [clip.size(), clip[0], clip[-1]])
	os.command_history.clear()
	os._on_input_line_text_submitted("spoof")
	os._on_input_line_text_submitted("spoof")
	os._on_input_line_text_submitted("date")
	os._navigate_history(-1)
	var a = os.input_line.text
	os._navigate_history(-1)
	print(">>> up, up after spoof,spoof,date: '%s' then '%s'" % [a, os.input_line.text])
	get_tree().quit()
