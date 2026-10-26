extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if os._booting or Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	# tutorial done
	Tutorial.show_intro = false
	for e in Tutorial.TUTORIAL_ORDER:
		if !(e in Tutorial.completed_events): Tutorial.completed_events.append(e)
	# every location, target and hard mode open
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		l["unlocked"] = true
		l["hard mode unlocked"] = true
		for list in ["targets", "hard mode targets"]:
			for t in l.get(list, []):
				t["unlocked"] = true
	# School..Police upload goals done (Government's is the one left)
	for t in range(1, 6):
		for g in Uploads.get_goals(t):
			Uploads.uploaded[g.item] = max(int(Uploads.uploaded.get(g.item, 0)), int(g.amount))
		if !(t in Uploads.completed_tiers): Uploads.completed_tiers.append(t)
	# every skill and process maxed and unlocked
	Exp._dev_max_all()
	Exp.refresh_all_process_unlocks()
	# a stockpile to try everything with
	var goal_items = {}
	for t in range(1, 7):
		for g in Uploads.get_goals(t): goal_items[g.item] = true
	for it in goal_items:
		Inventory.add_resource(it, 10 if Inventory.item_type(it) == "rare" else 3000)
	for p in Compiling.get_payload_processes():
		Inventory.add_resource(p["resource gained"], 300)
	Inventory.add_resource(Items.SQL_INJECTOR, 3000)
	Inventory.add_resource(Items.PACKET_SPOOF, 800)
	for it in Items.ITEM_MAP.values():
		if it == null: continue
		match Inventory.item_type(it):
			"cache":
				if it.get_variant() == CacheData.CacheVariant.BASE: Inventory.add_resource(it, 5)
			"exploit": Inventory.add_resource(it, 3)
			"token": Inventory.add_resource(it, 10)
	for it in HackingMods.pool_items():
		Inventory.add_resource(it, 2)
	# upgrade tiers 1-5 installed (v5.0 everywhere); Tier 6 left to install
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		p.installed = p.levels.filter(func(l): return int(l.tier) <= 5).size()
		Upgrades._recompute(p)
	Upgrades.apply_effects()
	Stats.unlocks_changed.emit()
	HackingMods.refresh_slots() if HackingMods.has_method("refresh_slots") else null
	SaveManager.save_game()
	print(">>> saved: tiers ", Uploads.completed_tiers, " levels ", Mining.SKILL.level, " items ", Inventory.inventory.size())
	get_tree().quit()
