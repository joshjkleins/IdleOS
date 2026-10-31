extends Node
func _ready() -> void:
	_run.call_deferred()
func _all_text(n: Node) -> String:
	var t = ""
	if n is RichTextLabel: t += n.get_parsed_text() + "\n"
	elif n is Label: t += n.text + "\n"
	for c in n.get_children(): t += _all_text(c)
	return t
func _run() -> void:
	var os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 60: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 300: await get_tree().process_frame
	os.accepting_player_inputs = true
	for c in ["tutorial complete", "cd hacking"]:
		os._on_input_line_text_submitted(c)
		for i in 40: await get_tree().process_frame
	var pay = Items.SCHOOL_PAYLOAD
	Inventory.remove_resource(pay, Inventory.get_amount(pay)); Inventory.add_resource(pay, 3)
	Inventory.add_resource(Items.SQL_INJECTOR, 100)
	var hk = get_tree().root.find_children("*", "", true, false).filter(func(n): return n.has_method("handle_hack_command"))
	print(">>> hacking nodes ", hk.size())
	await hk[0].open_location("School", false)
	for i in 900: await get_tree().process_frame
	print(">>> ctx after view ", hk[0].current_context)
	hk[0].current_context = 1
	hk[0].handle_hack_command("hack student=5")
	for i in 600: await get_tree().process_frame
	var lines = _all_text(os).split("\n")
	for l in lines:
		if "enough" in l.to_lower() or "go until" in l.to_lower() or "hack student" in l.to_lower(): print(">>> ", l.substr(0, 150))
	var ht = _all_text(hk[0]).split("\n")
	for l in ht.slice(max(0, ht.size() - 25)): if l.strip_edges() != "": print(">>> HB ", l.substr(0, 160))
	print(">>> ctx ", hk[0].current_context, " accept ", hk[0].can_accept_inputs)
	print(">>> hacking now: ", Hacking.get("is_hacking"), " payloads ", Inventory.get_amount(Items.SCHOOL_PAYLOAD))
	get_tree().quit()
