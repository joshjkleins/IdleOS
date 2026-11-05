extends Node
## 2026-11-05: 'run queue' starts the queue like 'queue -run'
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
	os._on_input_line_text_submitted("tutorial complete")
	await _f(20)
	if !(1 in Uploads.completed_tiers): Uploads.completed_tiers.append(1)
	print(">>> rm: ", Queue.handle("queue -rm -a"))
	print(">>> add: ", Queue.handle("queue -add mine -logs 5"))
	await _f(5)
	os._on_input_line_text_submitted("run queue")
	await _f(20)
	print(">>> running=%s  steps=%d" % [Queue.running, Queue.steps.size()])
	os._on_input_line_text_submitted("queue -kill")
	await _f(10)
	get_tree().quit()
