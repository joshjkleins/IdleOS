extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	for l in ["School", "Lawfirm"]: Stats.unlock_location(l)
	Exp.refresh_all_process_unlocks()
	Burst.charge["Mining/Logs"] = 3600.0; Burst.charge["Mining/Archives"] = 1500.0; Burst.charge["Parsing/Footprint"] = 900.0
	var r = RichTextLabel.new(); r.bbcode_enabled = true; add_child(r); r.text = Burst.use()
	print(r.get_parsed_text())
	print(">>> firmware text (no ending yet): '", Firmware.info_block("Mining"), "'")
	Ending.state = Ending.DONE
	print(">>> firmware text (after): '", Firmware.info_block("Mining").left(80), "'")
	get_tree().quit()
