extends Node
## Economy pass input: per tier, what upgrades (all groups), the upload goal, hacking payloads and target access
## cost, by item. Writes _to_delete/econ.json.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var out := []
	var locs = Stats.hacking_targets.keys()
	for t in range(1, 7):
		var T := {"upgrades": {}, "upgrades_by_group": {}, "upload": {}, "targets": [], "tier_resources": []}
		for id in Upgrades.packages:
			var p = Upgrades.packages[id]
			for lv in p.levels:
				if int(lv.tier) != t: continue
				for c in lv.get("costs", []):
					var k = str(c.item)
					T.upgrades[k] = int(T.upgrades.get(k, 0)) + int(c.amount)
					var g = T.upgrades_by_group.get_or_add(p.group, {})
					g[k] = int(g.get(k, 0)) + int(c.amount)
		for g in Uploads.get_goals(t):
			T.upload[g.item.name] = g.amount
		T.tier_resources = Decoding.get_tier_resources(t).map(func(i): return i.name)
		for tg in Stats.hacking_targets[locs[t - 1]].targets:
			var r = Stats.get_access_recipe(tg)
			T.targets.append({"name": tg.name, "payload": tg.requirements.item.name, "per_hack": tg.requirements.amount,
				"access_payloads": int(r.get("payload_amount", 0)), "access_rare": int(r.get("rare_amount", 0))})
		out.append(T)
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/econ.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " ")); f.close()
	print(">>> ok")
	get_tree().quit()
