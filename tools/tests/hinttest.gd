extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _show(tag: String) -> void:
	print("== ", tag, _strip(HintEngine.text(os)))
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	_show("A fresh game (tutorial)")
	for e in Tutorial.TUTORIAL_ORDER:
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	_show("B tutorial done, empty")
	Inventory.add_resource(Items.LOGS, 40)
	_show("C some logs")
	Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 10); Inventory.add_resource(Items.USERNAMES, 10); Inventory.add_resource(Items.PASSWORDS, 10)
	Inventory.add_resource(Items.IP_ADDRESS, 10); Inventory.add_resource(Items.CREDENTIALS, 10)
	_show("D chain stocked")
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 3)
	_show("E payload, no SQL")
	Inventory.add_resource(Items.SQL_INJECTOR, 60); Inventory.add_resource(Items.PACKET_SPOOF, 20)
	_show("F ready to hack")
	Inventory.add_resource(Items.STUDENT_CACHE, 4)
	_show("G caches waiting")
	Inventory.remove_resource(Items.STUDENT_CACHE, 4)
	var stu = Stats.hacking_targets["School"].targets[0]; var adm = Stats.hacking_targets["School"].targets[1]
	var vp = HintEngine._locked_targets()[0]; print("next locked: ", vp.name); var r = Stats.get_access_recipe(vp); Inventory.add_resource(r.rare, r.rare_amount + 5)
	Inventory.add_resource(Items.LOGS, 6000); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 20)
	os.process_running = true; os.current_process_info = Mining.minor_processes[0]
	_show("H access affordable + lots of logs")
	print("reserved: ", HintEngine.reserved().keys().map(func(k): return "%s %d" % [k.name, HintEngine.reserved()[k]]))
	print("rec sql student (estimate): ", HintEngine.recommended_sql(stu))
	Stats.record_usage(stu, 14, 3); Stats.record_usage(stu, 18, 5)
	print("rec sql student (history): ", HintEngine.recommended_sql(stu), "  usage ", Stats.get_usage(stu))
	Inventory.add_resource(Items.VM_MINING_TOKEN, 3); Inventory.add_resource(Items.VM_COMPILING_TOKEN, 2)
	_show("I tokens")
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	var n0 = os.lines.size()
	os._on_input_line_text_submitted("asdf")
	os._on_input_line_text_submitted("qwer")
	os._on_input_line_text_submitted("ls")
	os._on_input_line_text_submitted("zzz")
	for i in 200: await get_tree().process_frame
	var nudges = os.lines.slice(n0).filter(func(l): return "lost?" in l).size()
	print("nudges: ", nudges, " (expect 1)")
	get_tree().quit()
