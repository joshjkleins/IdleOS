extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	Stats.hacking_targets["Government"]["unlocked"] = true
	for p in Upgrades.group_packages("Hacking"):
		p.installed = p.levels.filter(func(l): return int(l.tier) < 6).size()
		Upgrades._recompute(p)
	var t = ContextCommands.get_skill_upgrades_text("Hacking")
	var rtl = RichTextLabel.new(); rtl.bbcode_enabled = true; add_child(rtl); rtl.text = t
	print(rtl.get_parsed_text())
	get_tree().quit()
