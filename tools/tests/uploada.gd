extends Node
## 2026-11-03: 'upload -a 10' queues up to 10 of every goal item (less if you have less)
var os
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	for e in Tutorial.TUTORIAL_ORDER:
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	for k in Uploads.staged.keys(): Uploads.unpack(k)
	Inventory.add_resource(Items.LOGS, 50); Inventory.add_resource(Items.USERNAMES, 4)
	var before = {}
	for g in Uploads.get_goals(): before[g.item] = Uploads.get_staged(g.item) + Uploads.get_uploaded(g.item)
	os._on_input_line_text_submitted("upload -a 10")
	for i in 60: await get_tree().process_frame
	var ls = Array(os.current_scrollback.get_parsed_text().split("\n", false))
	print(">>> ", ls.filter(func(l): return "Queued" in l or "Nothing" in l).back())
	get_tree().quit()
