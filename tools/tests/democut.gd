extends Node
## demo-nextfest-2 cut: level cap, School goal, kept upgrades, demo targets, full-game messages, send-off.
var os
var seen := 0
func _ready() -> void:
	_run.call_deferred()
func _cmd(c: String, frames: int = 40) -> void:
	seen = os.lines.size()
	os._on_input_line_text_submitted(c)
	for i in frames: await get_tree().process_frame
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
	print("max level ", Exp.MAX_LEVEL, " | goals ", Uploads.get_goals().map(func(g): return "%s %d" % [g.item.name, g.amount]))
	for g in Upgrades.groups:
		var ids = Upgrades.group_packages(g).map(func(p): return "%s x%d (%s)" % [p.id, p.levels.size(), ", ".join(p.levels.map(func(l): return "%s %d" % [l.costs[0].item, int(l.costs[0].amount)]))])
		print(g, ": ", ids, " hidden ", Upgrades.demo_hidden.get(g, 0))
	var unl = []
	for loc in Stats.hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in Stats.hacking_targets[loc].get(list, []):
				if t.get("unlocked", false): unl.append(Stats.target_key(t))
	print("unlocked: ", unl)
	print(Stats.buy_access(Stats.find_target_by_name("vice principal")).message)
	var adm = Stats.find_target_by_name("administrator")
	Inventory.add_resource(Items.PARENTS_CREDIT_CARD, 2); Inventory.add_resource(Items.SCHOOL_PAYLOAD, 4)
	print(Stats.buy_access(adm).message)
	for i in 6: Stats.record_win(adm)
	print("admin hard unlocked: ", Stats.get_hard_counterpart(adm).get("unlocked", false))
	await _cmd("cd decoding")
	await _cmd("decode -skim")
	await _cmd("cd ..")
	await _cmd("apt mining")
	await _cmd("overclock")
	await _cmd("welcome")
	Uploads.tier_completed.emit(1)
	for i in 400: await get_tree().process_frame
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true; rt.text = os.current_scrollback.get_parent().get_child(os.current_scrollback.get_index() - 1).text if os.current_scrollback.get_index() > 0 else ""
	print(">>> send-off: ", rt.get_parsed_text().substr(0, 300))
	get_tree().quit()
