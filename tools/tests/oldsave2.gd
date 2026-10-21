extends Node
## Loads a save into this build (SAVE env: res path of the json, copied to user://savegame.json first) and prints the state.
var os
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 90: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	print(">>> loaded v%d | levels mining %d parsing %d decoding %d | logs %d pcc %d" % [SaveManager.loaded_version, Mining.SKILL.level, Parsing.SKILL.level, Decoding.SKILL.level, Inventory.get_amount(Items.LOGS), Inventory.get_amount(Items.PARENTS_CREDIT_CARD)])
	print(">>> staged ", Uploads.staged.keys().map(func(k): return "%s %d" % [k.name, Uploads.staged[k]]), " uploading ", Uploads.active.keys().map(func(k): return k.name))
	print(">>> upgrades ", Upgrades.installed_package_ids().map(func(id): return "%s %d" % [id, Upgrades.packages[id].installed]))
	print(">>> tutorial %d/%d current: %s | notice %s" % [Tutorial.steps_done(), Tutorial.steps().size(), Tutorial.step_title(Tutorial.steps()[TutorialWindow.current_page()]), Tutorial.should_show_old_save_notice()])
	var unl = []
	for loc in Stats.hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in Stats.hacking_targets[loc].get(list, []):
				if t.get("unlocked", false): unl.append(Stats.target_key(t))
	print(">>> unlocked ", unl, " wins ", Stats.wins)
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true
	for l in os.lines.slice(max(0, os.lines.size() - 12)):
		rt.text = l; print("    " + rt.get_parsed_text().left(200))
	SaveManager.save_game()
	print(">>> resaved ok")
	get_tree().quit()
