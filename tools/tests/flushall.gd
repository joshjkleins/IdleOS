extends Node
## 2026-11-02: 'flush' against every process: start it in the main terminal, fill its buffer, flush, list what came
## out / went in. SKILLS=Mining,Parsing (env) picks the skills (the whole list takes too long for one device call).
var os
const CMDS = {
	"Mining": ["mine -logs", "mine -archives", "mine -metadata", "mine -cookies", "mine -repos", "mine -databases"],
	"Parsing": ["parse -footprint=logs", "parse -corruption=logs", "parse -network=student cache", "parse -extraction=student cache target=parents credit card"],
	"Cracking": ["crack -password", "crack -signature", "crack -badge", "crack -pin", "crack -keys", "crack -biometric", "crack -vm use=mining create=parsing"],
	"Matching": ["match -cred", "match -cert", "match -badge", "match -account", "match -officer", "match -clearance"],
	"Phishing": ["phish -spear", "phish -spear bait=logs", "phish -smish", "phish -whale", "phish -mod", "phish -trap"],
	"Decoding": ["decode -cache", "decode -skim", "decode -intel=student", "decode -salvage=logs", "decode -deep"],
	"Compiling": ["compile -school", "compile -lawfirm", "compile -hospital", "compile -bank", "compile -police", "compile -government"],
}
func _ready() -> void:
	_run.call_deferred()
func _secs(s: float) -> void:
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await get_tree().process_frame
func _cmd(c: String, wait := 1.0) -> void:
	os._on_input_line_text_submitted(c)
	await _secs(wait)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 60: await get_tree().process_frame
	os.accepting_player_inputs = true
	await _cmd("tutorial complete")
	for l in Stats.hacking_targets:
		Stats.unlock_location(l)
		for t in Stats.hacking_targets[l].targets: Stats.unlock_target(t)
	Exp.refresh_all_process_unlocks()
	for t in range(1, 7):
		for it in Decoding.get_tier_resources(t): Inventory.add_resource(it, 20000)
	for it in Decoding.vm_tokens(): Inventory.add_resource(it, 200)
	Inventory.add_resource(Items.STUDENT_CACHE, 400); Inventory.add_resource(Items.SQL_INJECTOR, 2000)
	var want = OS.get_environment("SKILLS").split(",", false)
	for sk in CMDS:
		if !want.is_empty() and !(sk in want): continue
		for c in CMDS[sk]:
			await _cmd(c, 1.5)
			if !os.process_running or os.current_process == null:
				print(">>> %-48s NOT RUNNING: %s" % [c, os.current_scrollback.get_parsed_text().strip_edges().right(140).replace("\n", " | ")])
				continue
			var p = os.current_process.get("process_data")
			var pname = str(p.name) if p is Dictionary and p.has("name") else "?"
			Flush.charge[Flush.key(sk, pname)] = Flush.FILL_SECONDS
			var before = Inventory.inventory.duplicate()
			var intel0 = Decoding.intel_text(Stats.hacking_targets["School"].targets[0]) if c.contains("intel") else ""
			var out = Flush.use()
			if c.contains("intel"): print(">>> intel before: ", intel0.left(120), "\n>>> intel after:  ", Decoding.intel_text(Stats.hacking_targets["School"].targets[0]).left(120))
			var gains = []
			var spent = []
			for it in Inventory.inventory:
				var d = Inventory.get_amount(it) - int(before.get(it, 0))
				if d > 0: gains.append("+%d %s" % [d, it.name])
				elif d < 0: spent.append("%d %s" % [d, it.name])
			var flushed = !float(Flush.charge.get(Flush.key(sk, pname), 0.0)) > 0.0
			print(">>> %-48s %s | %s | used %s%s" % [c, "FLUSHED" if flushed else "not flushed", ", ".join(gains).left(170), ", ".join(spent).left(90), "" if flushed else " | " + out.left(90).replace("\n", " ")])
			await _cmd("stop", 0.5)
	print(">>> done")
	get_tree().quit()
