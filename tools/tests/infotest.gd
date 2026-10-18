extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	await get_tree().process_frame
	var rx = RegEx.new(); rx.compile("\\[[^\\]]*\\]")
	for mp in [Phishing.SPEAR, Phishing.WHALING, Phishing.SMISH, Phishing.TRAP, Phishing.MOD]:
		for l in rx.sub(ContextCommands.get_mp_info(Phishing, mp), "", true).split("\n"):
			if "token" in l:
				print("%-8s %s" % [mp.name, l.strip_edges().left(60)])
		var share = 3.0 if mp.style == "lines" else 1.0
		print("         expected tokens/hr at base speed: %.2f" % (mp["vm token chance"] * 3600.0 / Phishing.base_attempt_seconds(mp) * share))
	for l in rx.sub(ContextCommands.get_mp_info(Cracking, Cracking.BADGE), "", true).split("\n"):
		if "token" in l: print("Cracking badge ", l.strip_edges().left(60))
	print("trap eff L99: ", Phishing.TRAP.efficiency)
	var t = Phishing.terminal_scene.instantiate(); add_child(t); t.cast_lines(Phishing.WHALING)
	await get_tree().process_frame
	print("whale label: ", rx.sub(t.slots_label.text, "", true).replace("\n", " / "))
	t.stop()
	get_tree().quit()
