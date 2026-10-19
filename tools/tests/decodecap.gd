extends Node
## Decoding capstones through the real terminal commands
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 40) -> void:
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
	var out = os.lines.slice(seen)
	seen = os.lines.size()
	var txt = " / ".join(out.filter(func(l): return l.strip_edges() != "")).left(260)
	print(">>> %-28s %s" % [c, txt])
func _setpkg(id: String, n: int) -> void:
	var p = Upgrades.packages[id]; p.installed = min(n, p.levels.size()); Upgrades._recompute(p)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	Tutorial.completed_events.clear()
	for e in Tutorial.tutorial_tasks: Tutorial.completed_events.append(e)
	Decoding.first_cache_decoded = true
	Inventory.add_resource(Items.STUDENT_CACHE, 200)
	Inventory.add_resource(Items.LOGS, 200)
	for id in Upgrades.packages:
		if id.begins_with("decoding."): _setpkg(id, 0)
	seen = os.lines.size()
	await _cmd("cd decoding")
	await _cmd("decode -cache")
	await _cmd("index")
	await _cmd("overclock")
	await _cmd("kill")
	for id in Upgrades.packages:
		if id.begins_with("decoding."): _setpkg(id, 99)
	await _cmd("decode -cache")
	await _cmd("index")
	print("    terminal modifier: ", os.current_process.modifier.get("command", "none"), " | step ", os.current_process.get_step_time(BaseTerminal.Mode.NORMAL), " | heat ", os.current_process.get_heat(BaseTerminal.Mode.NORMAL), " (cooled ", os.current_process.is_cooled(), ")")
	await _cmd("forensics")
	await _cmd("index -kill")
	await _cmd("overclock")
	print("    overclocked: ", Stats.overclocked, " heat OC ", os.current_process.get_heat(BaseTerminal.Mode.OVERCLOCKED), " vs normal ", Decoding.CACHE.heat)
	await _cmd("overclock -kill")
	await _cmd("kill")
	await _cmd("decode -package=logs 5")
	await _cmd("survey")
	await _cmd("kill")
	await _cmd("apt decoding", 60)
	get_tree().quit()
