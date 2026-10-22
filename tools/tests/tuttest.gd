extends Node
var os
var seen := 0
var out: Array = []
func _ready() -> void:
	_run.call_deferred()
func _poll() -> void:
	if os.lines.size() < seen: seen = 0
	while seen < os.lines.size():
		out.append(os.lines[seen]); seen += 1
func _wait(sec: float) -> void:
	var t = 0.0
	while t < sec:
		await get_tree().process_frame
		_poll()
		t += get_process_delta_time() / Engine.time_scale
func _cmd(c: String, w: float = 1.0) -> void:
	out.append("##CMD " + c)
	os._on_input_line_text_submitted(c)
	await _wait(w)
func _cur() -> String:
	return Tutorial.get_current_task().left(70)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _wait(1.0)
	os._finish_boot() if Tutorial.show_intro else null
	os.accepting_player_inputs = true
	Tutorial.completed_events.clear(); Tutorial.tutorial_progress.clear()
	# pretend the player finished the Mining section
	for e in Tutorial.TUTORIAL_ORDER.slice(0, Tutorial.TUTORIAL_ORDER.find(Tutorial.TutorialEvent.UPLOAD_INFO)):
		Tutorial.completed_events.append(e)
	print(">>> order count %d, tasks %d | current: %s" % [Tutorial.TUTORIAL_ORDER.size(), Tutorial.tutorial_tasks.size(), _cur()])
	Inventory.add_resource(Items.LOGS, 30)
	Inventory.add_resource(Items.IP_ADDRESS, 5)
	await _cmd("upload")
	print(">>> after 'upload': ", _cur())
	Engine.time_scale = 10.0
	await _cmd("upload logs 5", 2.0) # packaging was removed: uploads come straight from the inventory
	print(">>> queued logs %d, logs left %d | current: %s" % [Uploads.get_staged(Items.LOGS), Inventory.get_amount(Items.LOGS), _cur()])
	print(">>> uploading logs=%s | current: %s" % [Uploads.is_uploading(Items.LOGS), _cur()])
	# jump to the IP step
	for e in [Tutorial.TutorialEvent.NAVIGATE_PARSING, Tutorial.TutorialEvent.PARSE_20_LOGS, Tutorial.TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS, Tutorial.TutorialEvent.OBTAIN_3_USERNAMES, Tutorial.TutorialEvent.OBTAIN_3_IP_ADDRESSES]:
		Tutorial.completed_events.append(e)
	print(">>> current: ", _cur())
	await _cmd("upload ip address 1", 2.0)
	print(">>> queued/uploading ip %d/%s, IP left %d | current: %s" % [Uploads.get_staged(Items.IP_ADDRESS), Uploads.is_uploading(Items.IP_ADDRESS), Inventory.get_amount(Items.IP_ADDRESS), _cur()])
	Engine.time_scale = 1.0
	# mining upgrade step
	Inventory.add_resource(Items.LOGS, 500)
	await _cmd("apt install mining.speed")
	await _cmd("y", 6.0)
	print(">>> mining upgrade step done: ", Tutorial.completed_events.has(Tutorial.TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT))
	# old save: legacy events through HACK_STUDENT completed, none of the new ones
	var legacy = []
	for e in Tutorial.TUTORIAL_ORDER.slice(0, Tutorial.TUTORIAL_ORDER.find(Tutorial.TutorialEvent.DECODE_1_STUDENT_CACHE)):
		if e <= Tutorial.TutorialEvent.UPLOAD_PARENTS_CC: legacy.append(int(e))
	Tutorial.load_data({"completed_events": legacy, "tutorial_progress": {}, "show_intro": false})
	print(">>> old save (%d legacy done): %d done, current: %s" % [legacy.size(), Tutorial.completed_events.size(), _cur()])
	var rx = RegEx.new(); rx.compile("\\[[^\\]]*\\]")
	for l in out:
		var t = rx.sub(str(l), "", true).strip_edges()
		if t != "" and !t.begins_with("│") and !t.begins_with("┌") and !t.begins_with("└") and !t.begins_with("├"):
			print("| ", t.left(140))
	get_tree().quit()
