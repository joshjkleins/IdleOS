extends Node
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 60) -> void:
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
	var out = os.lines.slice(seen)
	seen = os.lines.size()
	var txt = " / ".join(out.filter(func(l): return l.strip_edges() != "" and !l.begins_with("IdleOS/"))).left(230)
	print(">>> %-30s %s" % [c, txt])
func _setpkg(id: String, n: int) -> void:
	var p = Upgrades.packages[id]; p.installed = min(n, p.levels.size()); Upgrades._recompute(p)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	os.accepting_player_inputs = true
	for e in Tutorial.tutorial_tasks: if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	for r in Compiling.SCHOOL.requirements: Inventory.add_resource(r, 5000)
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, 50); Inventory.add_resource(Items.LOGS, 5000); Inventory.add_resource(Items.SQL_INJECTOR, 500)
	var admin = Stats.hacking_targets["School"].targets[1]; admin.unlocked = false
	for id in Upgrades.packages:
		if id.begins_with("compiling."): _setpkg(id, 99)
	for i in 30: await get_tree().process_frame
	seen = os.lines.size()
	await _cmd("cd compiling")
	await _cmd("compile -school")
	await _cmd("debug")
	await _cmd("optimize")
	await _cmd("optimize -kill")
	await _cmd("kill")
	await _cmd("compile -access=administrator", 90)
	await _cmd("survey")
	await _cmd("overclock")
	await _cmd("kill", 90)
	await _cmd("compile -access=administrator", 30)
	await _cmd("kill", 90)
	await _cmd("compile -mod", 20)
	await _cmd("compile -mod=logs", 30)
	await _cmd("debug")
	await _cmd("kill", 120)
	await _cmd("info compiling", 120)
	get_tree().quit()
