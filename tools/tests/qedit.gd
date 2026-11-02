extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	Uploads.completed_tiers = [1, 2, 3]
	for l in Stats.hacking_targets: Stats.unlock_location(l)
	Exp.refresh_all_process_unlocks()
	for c in ["queue -add mine -logs 10", "queue -add parse -footprint=logs 10", "queue -add crack -password", "queue -rm 1", "queue -set 1 match -cred", "queue -ins 1 parse -corruption=logs 5", "queue -ins 3 compile -school", "queue -ins 9 mine -logs", "queue -set 5 x", "queue -ls"]:
		var r = RichTextLabel.new(); r.bbcode_enabled = true; add_child(r); r.text = Queue.handle(c)
		print(">>> ", c, "  ->  ", r.get_parsed_text().strip_edges().replace("\n", " | "))
	for t in ["queue -s", "queue -set ", "queue -set 1 cr", "queue -ins 0 parse -netw", "queue -set 1 mine -logs 5 su"]:
		var rr = CommandRegistry.complete(t)
		print(">>> tab '%s' -> '%s' %s" % [t, rr.text, rr.options if !rr.options.is_empty() else ""])
	get_tree().quit()
