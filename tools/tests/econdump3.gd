extends Node
## 2026-11-02: per-tier economy data for tools/balance/tier_time.py -> $HOME/econ/dump.json
## For each tier, two states: arrive (previous tiers' apt, skill level L_ARR) and done (this tier's apt too, L_DONE).
const L_ARR = [1, 15, 30, 45, 60, 75]
const L_DONE = [15, 30, 45, 60, 75, 90]
const CRAFT = ["Mining", "Parsing", "Cracking", "Matching", "Compiling", "Phishing", "Decoding"]
func _ready() -> void:
	_run.call_deferred()
func _n(x) -> String:
	return x.name if x is ItemData else str(x)
func _d(d: Dictionary) -> Dictionary:
	var o = {}
	for k in d:
		o[_n(k)] = float(d[k])
	return o
func _set_state(t: int, done: bool) -> void:
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		var n = 0
		for lv in p.levels:
			if int(lv.tier) < t or (done and int(lv.tier) == t):
				n += 1
		p.installed = n
		Upgrades._recompute(p)
	Upgrades.apply_effects()
	var L = L_DONE[t - 1] if done else L_ARR[t - 1]
	for s in [Mining, Parsing, Cracking, Matching, Compiling, Phishing, Decoding, Hacking]:
		s.SKILL.level = L
		s.SKILL.experience = Exp.xp_for_level(L)
		Exp.refresh_efficiency(s)
	Exp.refresh_all_process_unlocks()
func _rate(skill: Node, p: Dictionary, snap: Dictionary) -> Dictionary:
	var j = Offline._job(skill, p, snap)
	if j.is_empty() or float(j.get("seconds", 0)) <= 0:
		return {}
	return {"seconds": float(j.seconds), "inp": _d(j.get("inp", {})), "out": _d(j.get("out", {})), "xp": float(j.get("xp", 0)), "heat": float(j.get("heat", 0))}
func _run() -> void:
	var out = {"tiers": []}
	var keys = Stats.hacking_targets.keys()
	for t in range(1, 7):
		for i in t:
			Stats.unlock_location(keys[i])
			for tg in Stats.hacking_targets[keys[i]].targets:
				tg.unlocked = true
		var res = Decoding.get_tier_resources(t)
		for it in res:
			Inventory.add_resource(it, 100000)
		var T = {"tier": t, "location": keys[t - 1], "resources": res.map(func(i): return i.name), "states": {}}
		T.goals = Uploads.get_goals(t).map(func(g): return {"item": g.item.name, "amount": g.amount, "rare": g.rare, "upload_s": Uploads.get_upload_seconds(g.item)})
		T.targets = []
		var idx = 0
		for tg in Stats.hacking_targets[keys[t - 1]].targets:
			var rec = Stats.get_access_recipe(tg)
			var c = tg.get("loot")
			T.targets.append({"name": tg.name, "payload": int(tg.requirements.amount), "exp": int(tg.exp), "cache": c.name if c else "",
				"rare": (c.rare_pool[0].item.name if c is CacheData and !c.rare_pool.is_empty() else ""),
				"access_rare": _n(rec.get("rare", "")), "access_rare_n": int(rec.get("rare_amount", 0)), "access_payload_n": int(rec.get("payload_amount", 0))})
			if c:
				Inventory.add_resource(c, 1000)
			idx += 1
		for st in ["arrive", "done"]:
			_set_state(t, st == "done")
			var S = {"procs": {}, "caches": {}, "vms": Stats.MAX_ALL_VMS, "offline_cap_h": Offline.cap_seconds() / 3600.0, "cooling": -Stats.get_cooling_amount() / max(0.01, Stats.cooling_frequency)}
			S.procs["mine"] = _rate(Mining, Mining.minor_processes[t - 1], {})
			S.procs["parse"] = _rate(Parsing, Parsing.FOOTPRINT if "FOOTPRINT" in Parsing else Parsing.minor_processes[0], {"items": [res[0].id], "target": -1})
			var cr = Cracking.minor_processes.filter(func(p): return p != Cracking.VM)
			S.procs["crack"] = _rate(Cracking, cr[t - 1], {})
			S.procs["match"] = _rate(Matching, Matching.minor_processes[t - 1], {})
			S.procs["compile"] = _rate(Compiling, Compiling.minor_processes[t - 1], {})
			for ph in Phishing.minor_processes:
				if ph.get("style", "lines") in ["lines", "whale"] and ph != Phishing.MOD and ph.get("unlocked", false):
					S.procs["phish_" + str(ph.name).to_lower()] = _rate(Phishing, ph, {"bait": -1})
					S.procs["phish_" + str(ph.name).to_lower() + "_baited"] = _rate(Phishing, ph, {"bait": res[0].id})
			S.fp = {}
			for tg in T.targets:
				var c = Items.ITEM_MAP.values().filter(func(i): return i is ItemData and i.name == tg.cache)
				if !c.is_empty():
					S.caches[tg.cache] = _rate(Decoding, Decoding.minor_processes[0], {"item": c[0].id})
					# 2026-11-02: Footprint variant: parse the cache (x2 basics, no rare), then decode the variant
					var v = Parsing.get_cache_transform_target(Parsing.FOOTPRINT, c[0])
					if v:
						Inventory.add_resource(v, 1000)
						S.fp[tg.cache] = {"parse": _rate(Parsing, Parsing.FOOTPRINT, {"items": [c[0].id], "target": -1}), "decode": _rate(Decoding, Decoding.minor_processes[0], {"item": v.id})}
			S.unlocked = []
			for sk in [Mining, Parsing, Cracking, Matching, Compiling, Phishing, Decoding]:
				for p in sk.minor_processes:
					if p.get("unlocked", false):
						S.unlocked.append(sk.SKILL.name + "/" + str(p.name))
			T.states[st] = S
		out.tiers.append(T)
	var f = FileAccess.open(OS.get_environment("HOME") + "/econ/dump.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	print(">>> dumped")
	get_tree().quit()
