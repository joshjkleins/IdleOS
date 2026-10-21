extends Node
## Upload straight from the inventory: 'upload <item> <amount>', -a, cancel, tutorial guard, old decode -package.
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 30) -> void:
	seen = os.lines.size()
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
	print(">>> " + c)
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true
	for l in os.lines.slice(seen):
		rt.text = l
		print("    " + rt.get_parsed_text())
	rt.free()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	Offline.report = {}
	Inventory.add_resource(Items.LOGS, 40)
	Inventory.add_resource(Items.USERNAMES, 7)
	await _cmd("upload logs")
	await _cmd("upload logs 5")
	print("logs inv=%d queued=%d uploading=%s tut5=%s" % [Inventory.get_amount(Items.LOGS), Uploads.get_staged(Items.LOGS), Uploads.is_uploading(Items.LOGS), Tutorial.completed_events.has(Tutorial.TutorialEvent.PACKAGE_5_LOGS)])
	await _cmd("upload -a")
	await _cmd("upload cancel logs")
	print("logs inv=%d queued=%d" % [Inventory.get_amount(Items.LOGS), Uploads.get_staged(Items.LOGS)])
	for e in Tutorial.tutorial_tasks:
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	await _cmd("upload -a")
	await _cmd("upload passwords 3")
	await _cmd("upload -logs 2")
	await _cmd("cd decoding", 60)
	await _cmd("decode -package=logs 5")
	await _cmd("upload", 300)
	get_tree().quit()
