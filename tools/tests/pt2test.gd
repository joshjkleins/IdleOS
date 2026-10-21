extends Node
## 2026-10-20 playthrough notes #2: VM cache, ssh forms, vm -a, apt cascade, tutorial titles/tokens, hack bank.
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/screens/%s.png" % name)
func _cmd(c: String, frames: int = 40, show := true) -> void:
	seen = os.lines.size()
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
	if !show: return
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
	print("titles: ", Tutorial.steps().map(func(e): return Tutorial.step_title(e)))
	# tokens per step
	var before = Inventory.get_amount(Items.VM_PARSING_TOKEN)
	for e in Tutorial.steps():
		if e == Tutorial.TutorialEvent.PARSE_20_LOGS: break
		Tutorial.complete_event(e)
	print("parsing token on parse step: ", Inventory.get_amount(Items.VM_PARSING_TOKEN) - before, " current=", Tutorial.step_title(Tutorial.steps()[TutorialWindow.current_page()]))
	# VM cache
	print("vm cache table: ", Decoding.get_drop_table(Items.VM_CACHE))
	var got = {}
	for i in 400:
		for d in Decoding.roll_vm_cache():
			got[d.item.name] = got.get(d.item.name, 0) + d.amount
	print("400 vm caches: ", got)
	var n = 0
	for i in 1000:
		for d in Decoding.roll_loot(Items.STUDENT_CACHE):
			if d.item == Items.VM_CACHE: n += 1
	print("vm cache per 1000 student caches: ", n)
	Decoding.first_cache_decoded = false
	var cd = CacheDecrypting.new()
	print("first cache: ", cd.get_potential_items(Items.STUDENT_CACHE).map(func(d): return d.item.name))
	print("student table: ", Decoding.get_drop_table(Items.STUDENT_CACHE).map(func(r): return "%s %d-%d %.2f" % [r.name, r.min, r.max, r.chance]))
	# ssh forms
	await _cmd("ssh cracking -password")
	await _cmd("ssh matching credentials")
	await _cmd("ssh mining log")
	await _cmd("vm hide -a")
	await _cmd("vm show -a")
	# apt cascade
	Inventory.add_resource(Items.LOGS, 3000)
	await _cmd("apt install mining", 30)
	await _cmd("y", 200)
	await _shot("pt2_apt")
	# decoding labels
	Inventory.add_resource(Items.STUDENT_CACHE, 5)
	await _cmd("clear", 10, false)
	await _cmd("cd decoding", 30, false)
	await _cmd("decode -cache=student cache", 120, false)
	await _shot("pt2_decode")
	await _cmd("kill", 30, false)
	await _cmd("cd ..", 30, false)
	# root header xp with VMs
	Inventory.add_resource(Items.VM_PARSING_TOKEN, 2)
	await _cmd("ssh parsing footprint=logs", 20, false)
	for i in 200: await get_tree().process_frame
	await _shot("pt2_root_xp")
	get_tree().quit()
