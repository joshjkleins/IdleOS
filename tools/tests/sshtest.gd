extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 90: await get_tree().process_frame
	for e in Tutorial.TUTORIAL_ORDER: if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	os.RICHTEXT_LABEL_LINE_LIMIT = 100000
	for tok in Decoding.vm_tokens(): Inventory.add_resource(tok, 5)
	Inventory.add_resource(Items.LOGS, 50); Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 20); Inventory.add_resource(Items.USERNAMES, 20); Inventory.add_resource(Items.PASSWORDS, 20)
	Inventory.add_resource(Items.CREDENTIALS, 20); Inventory.add_resource(Items.IP_ADDRESS, 20); Inventory.add_resource(Items.STUDENT_CACHE, 3)
	Upgrades.packages["system.vm_windows"].installed = 0
	for cmd in ["ssh mine -logs", "ssh mining logs", "ssh parse -footprint=logs", "ssh parsing footprint=logs", "ssh crack -password", "ssh cracking password", "ssh match -cred", "ssh matching credential", "ssh compile -school", "ssh phish -spear", "ssh decode -cache", "ssh decoding cache"]:
		var n0 = VMManager.vms.size()
		os._on_input_line_text_submitted(cmd)
		for i in 20: await get_tree().process_frame
		var ok = VMManager.vms.size() > n0
		var why = ""
		if !ok: why = _strip(os.lines[-1] if os.lines.size() > 0 else "")
		print(">>> %-30s %s %s" % [cmd, "VM started" if ok else "no VM", why])
		os._on_input_line_text_submitted("vm kill -a")
		for i in 10: await get_tree().process_frame
	for t in ["ssh mi", "ssh mine -", "ssh parse -footprint=", "ssh cr"]:
		var r = CommandRegistry.complete(t); print("tab '%s' -> '%s' %s" % [t, r.text, r.options])
	print(_strip(ContextCommands.list_vm_terminals_for_skill(Mining)))
	print(_strip(Parsing.list_vm_commands()))
	get_tree().quit()
