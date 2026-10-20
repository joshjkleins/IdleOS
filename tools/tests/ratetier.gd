extends Node
## Balance pass (HEAT=1: heat per second vs cooling instead): output per hour of each tier's processes, with every upgrade up to that tier installed,
## at process level 1 (just unlocked) and 99. Uses the Offline cycle models. Writes _to_delete/rates.tsv.
var rows := []
func _ready() -> void:
	_run.call_deferred()
func _set_tier(t: int) -> void:
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		p.installed = p.levels.filter(func(l): return int(l.tier) <= t).size()
		Upgrades._recompute(p)
	Upgrades.apply_effects()
func _set_level(skill: Node, p: Dictionary, lvl: int) -> void:
	var key = str(skill.SKILL.name) + "/" + str(p.name)
	p.level = lvl
	if p.has("efficiency"):
		p.efficiency = Exp._base_efficiency[key] + float(p.get("efficiency rate", 0.0)) * (lvl - 1)
var heat_mode := OS.get_environment("HEAT") == "1"
var cur_tier := 1
func _measure(t: int, skill: Node, p: Dictionary, snap: Dictionary, label: String) -> void:
	if heat_mode:
		_set_level(skill, p, 1)
		var cells = [t, skill.SKILL.name, label]
		for up in [t - 1, t]: # arriving at the tier (previous tier's upgrades) / tier's upgrades all in
			_set_tier(up)
			var job = Offline._job(skill, p, snap)
			if job.is_empty() or float(job.get("seconds", 0)) <= 0:
				cells.append("-"); continue
			var cool = -Stats.get_cooling_amount() / max(0.01, Stats.cooling_frequency)
			cells.append("%.2f/%.2f" % [float(job.heat) / float(job.seconds), cool])
		_set_tier(t)
		rows.append(cells)
		return
	for lvl in [1, 99]:
		_set_level(skill, p, lvl)
		var job = Offline._job(skill, p, snap)
		if job.is_empty() or float(job.get("seconds", 0)) <= 0:
			rows.append([t, skill.SKILL.name, label, lvl, "-", "no job", "", ""]); continue
		var cph = 3600.0 / float(job.seconds)
		var outs = []
		var o: Dictionary = job.get("out", {})
		var keys = o.keys(); keys.sort_custom(func(a, b): return o[a] > o[b])
		for it in keys:
			outs.append("%s %s" % [_n(o[it] * cph), it.name])
		var ins = []
		for it in job.get("inp", {}):
			ins.append("%s %s" % [_n(float(job.inp[it]) * cph), it.name])
		rows.append([t, skill.SKILL.name, label, lvl, _n(cph), " · ".join(outs), " · ".join(ins), "HOT" if Offline._runs_hot(job) else ""])
func _n(x: float) -> String:
	return str(snappedf(x, 0.1)) if x < 100 else str(int(round(x)))
func _run() -> void:
	for i in 10: await get_tree().process_frame
	Offline.report = {"lost": {}, "notes": []}
	for it in Items.ITEM_MAP.values():
		Inventory.add_resource(it, 1000000)
	var pays = Compiling.get_payload_processes()
	for t in range(1, 7):
		_set_tier(t)
		var mp: Dictionary = Mining.minor_processes[t - 1]
		var mined: ItemData = mp["resource gained"]
		_measure(t, Mining, mp, {}, mp.name)
		_measure(t, Parsing, Parsing.FOOTPRINT, {"items": [mined.id], "target": -1}, "Footprint " + mined.name)
		var enc: ItemData = null
		for c in mined.contained_items:
			for cp in Cracking.minor_processes:
				if cp.get("requirements") is Dictionary and cp.requirements.has(c):
					enc = c; _measure(t, Cracking, cp, {}, cp.name)
					var cracked = cp["resource gained"]
					for m in Matching.minor_processes:
						if m.get("requirements") is Dictionary and m.requirements.has(cracked):
							_measure(t, Matching, m, {}, m.name)
		_measure(t, Compiling, pays[t - 1], {"item": -1, "target": ""}, pays[t - 1].name + " payload")
		if heat_mode:
			for pp in [Parsing.CORRUPTION, Parsing.NETWORK]:
				_measure(t, Parsing, pp, {"items": [mined.id], "target": -1}, pp.name + " " + mined.name)
			_measure(t, Parsing, Parsing.EXTRACTION, {"items": [mined.id], "target": mined.contained_items[0].id}, "Extraction " + mined.name)
			_measure(t, Phishing, Phishing.MOD, {"bait": mined.id, "target": ""}, "Mod (bait " + mined.name + ")")
			_measure(t, Phishing, Phishing.SPEAR, {"bait": -1, "target": ""}, "Spear (no bait)")
			_measure(t, Compiling, Compiling.MOD, {"item": Items.LOGS.id, "target": ""}, "Mod compile")
		_measure(t, Phishing, Phishing.SPEAR, {"bait": mined.id, "target": ""}, "Spear (bait " + mined.name + ")")
		_measure(t, Phishing, Phishing.WHALING, {"bait": mined.id, "target": ""}, "Whale (bait " + mined.name + ")")
		var caches = []
		for it in Items.ITEM_MAP.values():
			if it is CacheData and it.get_variant() == CacheData.CacheVariant.BASE and Exploits.cache_tier(it) == t:
				caches.append(it)
		for c in caches:
			_measure(t, Decoding, Decoding.CACHE, {"item": c.id, "target": "", "limit": 0}, "Decode " + c.name)
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/%s.tsv" % ("heat" if heat_mode else "rates"), FileAccess.WRITE)
	f.store_string("tier\tskill\tprocess\tlevel\tcycles/h\tout/h\tin/h\thot\n" + "\n".join(rows.map(func(r): return "\t".join(r.map(func(x): return str(x))))))
	f.close()
	print(">>> %d rows" % rows.size())
	get_tree().quit()
