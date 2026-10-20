extends Node
## Rare items needed per tier (upgrades, upload goal, target access), rare chance inputs, target XP, XP curve.
## Writes _to_delete/raredemand.json for tools/balance/xp_plan.py.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var out := {"tiers": [], "xp_for_level": [], "decoding": {}, "tracks": {}}
	for l in range(1, 100): out.xp_for_level.append(Exp.xp_for_level(l))
	out.decoding = {"efficiency": Exp._base_efficiency.get("Decoding/" + Decoding.CACHE.name, Decoding.CACHE.efficiency), "rate": Decoding.CACHE["efficiency rate"]}
	for id in ["decoding.efficiency", "decoding.rare_tracker"]:
		var p = Upgrades.packages.get(id)
		if p: out.tracks[id] = p.levels.map(func(l): return [int(l.tier), float(l.get("value", 0))])
	var locs = Stats.hacking_targets.keys()
	for t in range(1, 7):
		var L = Stats.hacking_targets[locs[t - 1]]
		var tier = {"location": locs[t - 1], "targets": []}
		for i in L.targets.size():
			var tg = L.targets[i]
			var rare = tg.loot.rare_pool[0].item if tg.loot is CacheData and !tg.loot.rare_pool.is_empty() else null
			var up := 0
			var up_by_group := {}
			for id in Upgrades.packages:
				var p = Upgrades.packages[id]
				for lv in p.levels:
					for c in lv.get("costs", []):
						if rare and str(c.item).to_lower() == rare.name.to_lower():
							up += int(c.amount)
							up_by_group[p.group] = int(up_by_group.get(p.group, 0)) + int(c.amount)
			var access = 0
			if i + 1 < L.targets.size(): access = Stats.ACCESS_RARE_AMOUNT # the next target's access takes 5 of this one's rare
			# lower caches inside this cache (top caches hold the tier's other caches)
			var lower := 0.0
			for e in tg.loot.entries:
				if e.item is CacheData: lower += (e.min_quantity + e.max_quantity) / 2.0 * e.drop_chance
			tier.targets.append({"name": tg.name, "exp": tg.exp, "rare": rare.name if rare else "", "upgrades": up, "by_group": up_by_group,
				"upload": Uploads.RARE_GOALS[t - 1], "access": access, "lower_caches": lower, "mod_full": rare.hacking_mod_consumed if rare else 0})
		out.tiers.append(tier)
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/raredemand.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " ")); f.close()
	print(">>> ok")
	get_tree().quit()
