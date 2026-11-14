extends Node
## 2026-11-14: 'phish -trap bait=<item> 3' sets 3 traps (or stops when the slots are full)
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _try(slots: int, n: int) -> void:
	Phishing.traps.clear()
	var p = Upgrades.packages["phishing.extra_trap"]
	p.installed = 0
	p.current = 0.0
	var lv = 0
	while 1 + int(round(Upgrades.cur("phishing.extra_trap"))) < slots and lv < p.levels.size():
		lv += 1
		p.installed = lv
		p.current = 0.0
		for i in lv: p.current += float(p.levels[i].value)
	if os.process_running: os.kill_main_process()
	await _f(5)
	os._on_input_line_text_submitted("phish -trap bait=logs" + (" %d" % n if n > 0 else ""))
	var t0 = Time.get_ticks_msec()
	await _f(10)
	while os.process_running and Time.get_ticks_msec() - t0 < 90000:
		await get_tree().process_frame
	print(">>> %d slots, asked %d: traps set %d  (%.0fs)" % [Phishing.max_traps(), n, Phishing.traps.size(), (Time.get_ticks_msec() - t0) / 1000.0])
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	for e in Tutorial.steps():
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	Phishing.TRAP.unlocked = true
	Phishing.TRAP["cast time"] = 1.0 # test only (60 s in the game)
	Inventory.add_resource(Items.LOGS, 1000)
	var keep = Phishing.traps.duplicate(true)
	await _try(3, 3)
	await _try(2, 3)
	await _try(3, 0)
	Phishing.traps = keep
	get_tree().quit()
