extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 120:
		await get_tree().process_frame
	var shots = [["none", -1.0], ["filling", 0.62], ["ready", 1.2]]
	for s in shots:
		if s[1] < 0:
			Phishing.trap = {}
		else:
			Phishing.set_trap(null)
			Phishing.trap.set_at -= int(Phishing.trap_seconds_total() * s[1])
		Phishing.trap_changed.emit()
		for i in 30:
			await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/trap_%s.png" % s[0])
	print(">>> done ", get_viewport().get_visible_rect().size)
	get_tree().quit()
