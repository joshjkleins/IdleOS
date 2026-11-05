extends Node
## 2026-11-05: launcher boot sequence frames (OUT = png prefix) + card position check when the help text changes
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var l = load("res://scenes/launcher.tscn").instantiate()
	add_child(l)
	var out = OS.get_environment("OUT")
	var t0 = Time.get_ticks_msec()
	for shot in [0.5, 1.4]:
		while Time.get_ticks_msec() - t0 < shot * 1000.0: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out + "_%d.png" % int(shot * 10))
	while l._booting: await get_tree().process_frame
	print(">>> boot took %.2fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	for i in 20: await get_tree().process_frame
	var y0 = l._cards[0].global_position.y
	get_viewport().get_texture().get_image().save_png(out + "_menu.png")
	l._on_submit("ls")
	for i in 5: await get_tree().process_frame
	var y1 = l._cards[0].global_position.y
	l._on_submit("help")
	for i in 5: await get_tree().process_frame
	var y2 = l._cards[0].global_position.y
	l._on_submit("nonsense")
	for i in 5: await get_tree().process_frame
	print(">>> card y: help %.1f  ls %.1f  help %.1f  error %.1f" % [y0, y1, y2, l._cards[0].global_position.y])
	get_tree().quit()
