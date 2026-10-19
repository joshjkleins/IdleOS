extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	var t := 0.0
	while t < 3.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	var all := "\n".join(os.lines)
	print(">>> intro=%s lines=%d first=%s" % [Tutorial.show_intro, os.lines.size(), str(os.lines.slice(0,3))]); print(">>> loaded_version=%d should_show=%s notice in terminal=%s welcome=%s" % [SaveManager.loaded_version, Tutorial.should_show_old_save_notice(), all.contains("WELCOME BACK"), all.contains("WELCOME TO IDLEOS")])
	get_tree().quit()
