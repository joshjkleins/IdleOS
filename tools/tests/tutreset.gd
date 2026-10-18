extends Node
## Old Oct 8 demo save -> one-time notice -> 'tutorial reset' -> resave/reload keeps the reset (no auto-skip)
var os
func _ready() -> void:
	_run.call_deferred()
func _txt() -> String:
	return "\n".join(os.lines)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 120: await get_tree().process_frame
	print(">>> loaded_version=%d tutorial %d/%d" % [SaveManager.loaded_version, Tutorial.completed_events.size(), Tutorial.tutorial_tasks.size()])
	print(">>> notice shown: ", _txt().contains("WELCOME BACK"))
	os._on_input_line_text_submitted("tutorial reset")
	for i in 200: await get_tree().process_frame
	var t := _txt()
	print(">>> reset output:\n", t.substr(t.find("TUTORIAL RESTARTED") - 20))
	print(">>> after reset %d/%d, current: %s" % [Tutorial.completed_events.size(), Tutorial.tutorial_tasks.size(), Tutorial.get_current_task().left(60)])
	print(">>> baseline ", Tutorial.upload_baseline)
	SaveManager.save_game()
	var n := Tutorial.completed_events.size()
	SaveManager.load_game()
	print(">>> reload: loaded_version=%d done %d (was %d) notice-next-launch=%s" % [SaveManager.loaded_version, Tutorial.completed_events.size(), n, Tutorial.should_show_old_save_notice()])
	os._on_input_line_text_submitted("tutorial")
	for i in 120: await get_tree().process_frame
	print(">>> tutorial cmd has hint: ", _txt().contains("starts it over"))
	get_tree().quit()
