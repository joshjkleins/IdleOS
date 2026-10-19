extends Node
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 150) -> void:
	seen = os.lines.size()
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
	print(">>> " + c)
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true
	for l in os.lines.slice(seen + 1):
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
	Offline.report = {}
	for it in [Items.LOGS, Items.USERNAMES, Items.IP_ADDRESS, Items.CREDENTIALS, Items.SCHOOL_PAYLOAD, Items.SQL_INJECTOR, Items.PACKET_SPOOF, Items.STUDENT_CACHE, Items.ADMIN_CACHE, Items.PARENTS_CREDIT_CARD, Items.VM_MINING_TOKEN, Items.SQL_BOOSTER, Items.LAWFIRM_PAYLOAD]:
		Inventory.add_resource(it, 1234)
	Inventory.add_resource(Exploits.get_item("lag_spike"), 2)
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true; add_child(rt)
	var show = func(label, t):
		rt.text = t
		print(">>> " + label + "\n" + rt.get_parsed_text())
	show.call("ls", Inventory.list_inventory_grouped())
	for a in ["-caches", "t2", "-mining", "-tokens -exploits"]:
		show.call("ls " + a, Inventory.list_filtered(a).text)
	Inventory.remove_resource(Items.PASSWORDS, Inventory.get_amount(Items.PASSWORDS))
	Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 40)
	show.call("info compiling school (recipe)", Inventory.recipe_text(Compiling.SCHOOL))
	show.call("info matching (recipe)", Inventory.recipe_text(Matching.minor_processes[0]))
	show.call("info cracking (recipe)", Inventory.recipe_text(Cracking.minor_processes[0]))
	show.call("ls -parsing", Inventory.list_filtered("-parsing").text)
	show.call("ls -compiling", Inventory.list_filtered("-compiling").text)
	for n in ["school payload"]:
		show.call("ls " + n, Inventory.list_specific_item(Inventory.get_item_by_name(n)))
	get_tree().quit()
