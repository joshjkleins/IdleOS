extends Node
## 2026-11-02: launcher -> 'boot <SLOT>' -> the game scene loads that slot
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var dummy = Node.new() # the scene changes free the current scene: make that a dummy, not this runner
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	get_tree().create_timer(40.0).timeout.connect(func(): print(">>> timed out"); get_tree().quit())
	get_tree().change_scene_to_file("res://scenes/launcher.tscn")
	for i in 40: await get_tree().process_frame
	var l = get_tree().current_scene
	l._on_submit("boot " + OS.get_environment("SLOT"))
	for i in 120: await get_tree().process_frame
	var os = get_tree().get_first_node_in_group("main_os")
	print(">>> scene %s, slot %d, session %s, location %s, path %s" % [get_tree().current_scene.name, SaveManager.slot, SaveManager.session_active, Uploads.get_location_name(Uploads.current_tier()), SaveManager.SAVE_PATH])
	get_tree().quit()
