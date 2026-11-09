extends Node
## 2026-11-02: launcher popups - rename / delete (typed confirm) / new profile; focus after a command. SHOTS env = png folder
func _ready() -> void:
	_run.call_deferred()
func _f(n := 8) -> void:
	for i in n: await get_tree().process_frame
func _shot(name: String) -> void:
	if OS.get_environment("SHOTS") != "":
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOTS") + "/" + name + ".png")
func _field(l) -> LineEdit:
	return l._modal.find_children("*", "LineEdit", true, false)[0]
func _run() -> void:
	var l = load("res://scenes/launcher.tscn").instantiate()
	add_child(l)
	await _f(60)
	l._on_submit("ls")
	await _f()
	print(">>> focus after a command: ", l._input_line.has_focus())
	l._on_submit("rename 1 hacker_01")
	await _f()
	print(">>> renamed: ", SaveManager.read_meta(1).get("name"), " | ", l._out.get_parsed_text())
	l._on_submit("rename 1 bad name!")
	await _f()
	print(">>> bad name: ", l._out.get_parsed_text())
	l._on_submit("rm 2")
	await _f()
	await _shot("pop_delete")
	var le = _field(l)
	var ok = l._modal.find_children("*", "Button", true, false)[1]
	print(">>> delete button disabled before typing: ", ok.disabled)
	le.text = "wrong"; le.text_changed.emit("wrong")
	print(">>> with a wrong name: ", ok.disabled)
	le.text = "rm josh"; le.text_changed.emit("rm josh")
	print(">>> with only rm: ", ok.disabled)
	le.text = "sudo rm -rf josh"; le.text_changed.emit("sudo rm -rf josh")
	print(">>> with the name: ", ok.disabled)
	ok.pressed.emit()
	await _f()
	print(">>> slot 2 exists: %s, modal %s, out: %s" % [SaveManager.slot_exists(2), l._modal, l._out.get_parsed_text()])
	print(">>> deleted folder: ", DirAccess.get_files_at("user://saves/deleted"))
	l._on_submit("new 3")
	await _f()
	await _shot("pop_new")
	print(">>> new popup field: ", _field(l).text)
	l._close_modal()
	await _f()
	print(">>> focus after closing: ", l._input_line.has_focus())
	await _shot("cards_after")
	get_tree().quit()
