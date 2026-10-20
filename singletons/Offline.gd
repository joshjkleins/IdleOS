extends Node
## Offline progression. On save: the quit time + the process running in the MAIN terminal (VMs never run
## offline, Hacking never does). On load (before anything saves again) compute() works out what that process
## made while the game was closed and applies it: cycles at normal speed (no overclock, no modifiers, no VM
## bonuses) from a per-skill model of one cycle, limited by the time away (capped: 1 h base + Background
## Services, 24 h max) and by the inputs in the inventory. If a cycle's heat is more than the system cools in
## the same time, outputs are cut by OVERHEAT_PENALTY. Active uploads continue at UPLOAD_SPEED.
## idle_os_2 shows `report` as a download-style sequence, then resumes the process with its original command.

const BASE_CAP_HOURS := 1.0
const MAX_CAP_HOURS := 24.0
const MIN_AWAY_SECONDS := 60.0
const UPLOAD_SPEED := 0.5        # uploads run at half speed offline
const OVERHEAT_PENALTY := 0.10   # outputs lost when the process runs hotter than the system cools
const SAMPLES := 300             # virtual cycles averaged per model (random processes)

const MINING_SEGMENTS := 20      # data_mining_terminal.SEGMENTS
const PARSE_LINES := 10          # log_parsing_terminal.MAX_LOG_LINES
const PW_LENGTH := 4             # pw_cracking_terminal.PW_LENGTH
const MATCH_PAUSE := 0.3         # cred_matching_terminal: pause between matches

var session := {}   # from the save: {"saved_at": unix, "process": snapshot}
var report := {}    # what compute() did ({} = nothing to show)
var _match_steps := -1

func cap_seconds() -> float:
	return min(MAX_CAP_HOURS, BASE_CAP_HOURS + Upgrades.offline_cap_hours()) * 3600.0

#region save
func save_data() -> Dictionary:
	return {"saved_at": int(Time.get_unix_time_from_system()), "process": snapshot()}

func load_data(data: Dictionary) -> void:
	session = data.duplicate(true)

## The main terminal's process and what it was started with ({} when nothing that can run offline is running)
func snapshot() -> Dictionary:
	var os = get_tree().get_first_node_in_group("main_os") if get_tree() else null
	if os == null or !os.process_running or os.current_process == null or !is_instance_valid(os.current_process):
		return {}
	var t = os.current_process
	if !("skill" in t) or t.skill == null or t.in_vm or os.main_command.is_empty():
		return {}
	var skill = t.skill
	var p: Dictionary = t.process_data
	if skill == Hacking or skill == Defragging:
		return {}
	var snap = {"skill": skill.SKILL.name, "process": p.name, "context": int(os.main_command.context), "command": str(os.main_command.text)}
	match skill:
		Parsing:
			snap.items = t.items_to_parse.map(func(i): return i.id)
			snap.target = t.extraction_target.id if t.extraction_target else -1
		Cracking:
			if p == Cracking.VM:
				return {} # token conversion is online only
		Phishing:
			if p.get("style", "lines") == "trap":
				return {} # the Trap already fills on real time
			snap.bait = t.bait.id if t.bait else -1
			snap.target = Stats.target_key(t.smish_target) if !t.smish_target.is_empty() else ""
		Decoding:
			var kind = p.get("decode kind", "cache")
			if kind in ["salvage", "deep"]:
				return {} # VM token processes are online only
			snap.item = t.target_cache.id if t.target_cache else -1
			snap.target = Stats.target_key(t.target_arg) if t.target_arg is Dictionary else ""
			snap.limit = t.package_limit
		Compiling:
			snap.item = t.hacking_mod_item.id if t.hacking_mod_item else -1
			snap.target = Stats.target_key(t.access_target) if !t.access_target.is_empty() else ""
	return snap
#endregion

#region compute
## Call once after the save has loaded. Applies the offline gains and fills `report`.
func compute() -> void:
	report = {}
	if session.is_empty():
		return
	var saved_at = int(session.get("saved_at", 0))
	var snap: Dictionary = session.get("process", {})
	session = {}
	var away = Time.get_unix_time_from_system() - saved_at
	if saved_at <= 0 or away < MIN_AWAY_SECONDS:
		return
	var secs = min(away, cap_seconds())
	var inv_before = Inventory.inventory.duplicate()
	var up_before = Uploads.uploaded.duplicate()
	var staged_before = Uploads.staged.duplicate()
	var tiers_before = Uploads.completed_tiers.duplicate()
	var levels_before = {}
	var xp_before = {}
	for s in _skills():
		levels_before[s.SKILL.name] = int(s.SKILL.level)
		xp_before[s.SKILL.name] = int(s.SKILL.experience)
	report = {"away": away, "secs": secs, "capped": away > cap_seconds(), "process": "", "resume": {},
		"overheat": false, "notes": [], "gains": [], "spent": [], "uploaded": [], "staged": [], "levels": [], "ran": 0.0,
		"tiers": [], "trap": -1.0, "xp": [], "lost": {}}
	if !snap.is_empty():
		var skill = _skill(snap.skill)
		var p = _find_process(skill, snap.process)
		if skill and !p.is_empty():
			report.process = "%s %s" % [skill.SKILL.name, p.name]
			report.resume = {"context": int(snap.context), "command": str(snap.command)}
			report.ran = _run(skill, p, snap, secs)
	_run_uploads(secs)
	Stats.system_tempature = Stats.MIN_TEMP # it cooled down while you were away
	Stats.overheated = false
	# what changed
	for item in Inventory.inventory:
		var d = int(Inventory.inventory[item]) - int(inv_before.get(item, 0))
		if d > 0:
			report.gains.append({"item": item, "amount": d})
	for item in inv_before:
		var d = int(inv_before[item]) - Inventory.get_amount(item)
		if d > 0:
			report.spent.append({"item": item, "amount": d})
	for item in Uploads.uploaded:
		var d = int(Uploads.uploaded[item]) - int(up_before.get(item, 0))
		if d > 0:
			report.uploaded.append({"item": item, "amount": d, "done": Uploads.get_uploaded(item) >= Uploads.get_goal_amount(item)})
	for item in Uploads.staged:
		var d = int(Uploads.staged[item]) - int(staged_before.get(item, 0))
		if d > 0:
			report.staged.append({"item": item, "amount": d})
	for s in _skills():
		if int(s.SKILL.level) > int(levels_before[s.SKILL.name]):
			# each level up gives one of that skill's VM tokens (Exp.add_xp), already in the gains above
			var tokens = int(s.SKILL.level) - int(levels_before[s.SKILL.name]) if s != Hacking else 0
			report.levels.append({"skill": s.SKILL.name, "from": levels_before[s.SKILL.name], "to": int(s.SKILL.level),
				"tokens": tokens, "token": s.vm_token if s != Hacking else null})
	for s in _skills():
		var gained = int(s.SKILL.experience) - int(xp_before[s.SKILL.name])
		if gained > 0:
			report.xp.append({"skill": s.SKILL.name, "amount": gained})
	for t in Uploads.completed_tiers:
		if not t in tiers_before:
			report.tiers.append(int(t))
	if Phishing.has_trap():
		report.trap = Phishing.trap_progress() # the Trap fills on real time (offline too); collecting stays manual
	report.gains.sort_custom(func(a, b): return a.amount > b.amount)
	if report.gains.is_empty() and report.uploaded.is_empty() and report.staged.is_empty() and report.notes.is_empty() and report.trap < 0.0:
		report.notes.append("nothing was running in the main terminal")
	SaveManager.mark_dirty()

## Runs the process for up to <secs>; returns the seconds it actually ran. A job tied to one input
## ("repeat") moves on to the next input (next cache, next item to parse, bait -> no bait) when it runs out.
func _run(skill: Node, p: Dictionary, snap: Dictionary, secs: float) -> float:
	var left = secs
	for guard in 64:
		if left <= 0.5:
			break
		var job = _job(skill, p, snap)
		if job.is_empty() or float(job.get("seconds", 0.0)) <= 0.0:
			break
		var hot = _runs_hot(job)
		if hot:
			report.overheat = true
		var mult = 1.0 - (OVERHEAT_PENALTY if hot else 0.0)
		var time_cycles = int(floor(left / job.seconds))
		var cycles = time_cycles
		for item in job.get("inp", {}):
			var per = float(job.inp[item])
			if per > 0.0:
				cycles = min(cycles, int(floor(Inventory.get_amount(item) / per)))
		if job.has("limit"):
			cycles = min(cycles, int(job.limit))
		if cycles <= 0:
			break
		if job.has("apply"):
			cycles = int(job.apply.call(cycles, mult)) # custom processes say how many cycles they did
		else:
			for item in job.get("inp", {}):
				Inventory.remove_resource(item, int(round(float(job.inp[item]) * cycles)))
			for item in job.get("out", {}):
				var full = float(job.out[item]) * cycles
				var n = int(round(full * mult))
				if n > 0:
					Inventory.add_resource(item, n)
				if hot and int(round(full)) - n > 0: # what overheating cost (shown in the download)
					report.lost[item] = int(report.lost.get(item, 0)) + int(round(full)) - n
		if cycles <= 0:
			break
		if float(job.get("xp", 0.0)) > 0.0:
			Exp.add_xp(skill, p, int(round(float(job.xp) * cycles)))
		left -= cycles * float(job.seconds)
		if cycles >= time_cycles or !job.get("repeat", false):
			break
	return secs - left

## Hotter than the system cools over one cycle?
func _runs_hot(job: Dictionary) -> bool:
	var cool_per_s = -Stats.get_cooling_amount() / max(0.01, Stats.cooling_frequency)
	return float(job.get("heat", 0.0)) > cool_per_s * float(job.seconds)

## Heat one apply_heat(<h>) call adds (heat sink track, speed-neutral, % heat reduction, % defrag boost)
func _hc(skill: Node, h: float, tier_mult: float = 1.0) -> float:
	h *= 1.0 - Upgrades.cur(skill.SKILL.name.to_lower() + ".heat_sink")
	h /= _speed(skill)
	return max(0.0, h * tier_mult * (1.0 - Stats.HEAT_REDUCTION) * (1.0 - Defragging.get_heat_reduction()))

func _speed(skill: Node) -> float:
	return 1.0 + Upgrades.cur(skill.SKILL.name.to_lower() + ".speed")

func _base(p: Dictionary, key: String) -> float:
	if p.has(key):
		return float(p[key])
	return (float(p.get(key + " min", 1.0)) + float(p.get(key + " max", 1.0))) / 2.0

func _step(skill: Node, p: Dictionary) -> float:
	return _base(p, "base speed") / _speed(skill)
#endregion

#region per-skill cycle models
## One "job": {seconds, inp, out, xp, heat} for a cycle of <p> (+ "apply" for custom processes, "repeat"
## when the job is tied to one input and the next call may pick another).
func _job(skill: Node, p: Dictionary, snap: Dictionary) -> Dictionary:
	match skill:
		Mining:
			return _mining(p)
		Parsing:
			return _parsing(p, snap)
		Cracking:
			return _cracking(p)
		Matching:
			return _matching(p)
		Phishing:
			return _phishing(p, snap)
		Decoding:
			return _decoding(p, snap)
		Compiling:
			return _compiling(p, snap)
	return {}

func _mining(p: Dictionary) -> Dictionary:
	var segs = MINING_SEGMENTS - int(MINING_SEGMENTS * Upgrades.cur("mining.pipelining"))
	var eff = float(p.efficiency) + Upgrades.cur("mining.efficiency")
	var v = int(Upgrades.cur("mining.vein_detection"))
	var vein = 1.0 + (1.0 / (11 - v) if v > 0 else 0.0)
	return {"seconds": _step(Mining, p) * segs, "out": {p["resource gained"]: (1.0 + eff) * vein},
		"xp": float(p["experience per level"]), "heat": _hc(Mining, float(p.heat))}

func _parsing(p: Dictionary, snap: Dictionary) -> Dictionary:
	var target = Items.ITEM_MAP.get(int(snap.get("target", -1)))
	var item: ItemData = null
	for id in snap.get("items", []):
		var it = Items.ITEM_MAP.get(int(id))
		if it and Inventory.get_amount(it) > 0:
			if it is CacheData and Parsing.get_cache_transform_target(p, it) == null:
				continue
			item = it
			break
	if item == null:
		return {}
	var step = _step(Parsing, p)
	var base_eff = (float(p.efficiency) + Upgrades.cur("parsing.efficiency") * float(p.get("efficiency upgrade scale", 1.0)))
	var fast = Upgrades.cur("parsing.fast_skip")
	var out := {}
	var t := 0.0
	if item is CacheData:
		for k in SAMPLES:
			var red = PARSE_LINES
			while red > 0:
				var still = 0
				for i in red:
					if randf() < base_eff:
						t += step
					else:
						t += step * (1.0 - fast)
						still += 1
				red = still
		out[Parsing.get_cache_transform_target(p, item)] = 1.0
	else:
		var lines = PARSE_LINES + int(Upgrades.cur("parsing.rows"))
		var bonus = Parsing.get_line_chance_bonus(p, item)
		var pc = Upgrades.cur("parsing.pattern_cache")
		var miss = 0.0
		for k in SAMPLES:
			for i in lines:
				if randf() < base_eff + bonus + miss:
					miss = 0.0
					t += step
					var f = Parsing.roll_find(p, item, target)
					var a = Parsing.get_find_amount(p, item)
					if f and a > 0:
						out[f] = out.get(f, 0.0) + a
				else:
					miss += pc
					t += step * (1.0 - fast)
		for f in out:
			out[f] /= float(SAMPLES)
	return {"seconds": t / SAMPLES, "inp": {item: 1.0}, "out": out, "xp": float(p["experience per level"]),
		"heat": _hc(Parsing, float(p.heat), Stats.tier_heat(Parsing.HEAT_BY_TIER, Exploits.cache_tier(item) if item is CacheData else item.tier)), "repeat": true}

func _cracking(p: Dictionary) -> Dictionary:
	var eff = float(p.efficiency) + Upgrades.cur("cracking.efficiency")
	var dict = Upgrades.cur("cracking.dictionary")
	var rain = Upgrades.cur("cracking.rainbow_tables")
	var step = _step(Cracking, p)
	var t := 0.0
	var heat := 0.0
	var head := 0.0
	for k in SAMPLES:
		if randf() < eff:
			t += 0.1
			head = rain
		else:
			var h = head
			head = 0.0
			var waited = false
			for c in PW_LENGTH:
				if randf() < dict:
					continue
				t += step * (1.0 - h)
				waited = true
			if waited:
				heat += _hc(Cracking, float(p.heat))
	var inp := {}
	var keep = 1.0 - Upgrades.cur("cracking.recovery")
	for item in p.requirements:
		inp[item] = float(p.requirements[item]) * keep
	return {"seconds": t / SAMPLES, "inp": inp, "out": {p["resource gained"]: 1.0}, "xp": float(p["experience per level"]), "heat": heat / SAMPLES}

func _matching(p: Dictionary) -> Dictionary:
	if _match_steps < 0:
		var t = load("res://scenes/cred_matching_terminal.tscn").instantiate()
		_match_steps = 0
		for msgs in t.terminal_messages:
			_match_steps += msgs.size()
		t.free()
	var step = _step(Matching, p) * (1.0 - Upgrades.cur("matching.auto_correlate")) / (1.0 + Upgrades.cur("matching.hot_cache"))
	var eff = float(p.efficiency) + Upgrades.cur("matching.efficiency")
	var keep = 1.0 - Upgrades.cur("matching.recovery")
	var inp := {}
	for item in p.requirements:
		inp[item] = keep
	return {"seconds": step * _match_steps + MATCH_PAUSE, "inp": inp, "out": {p["resource gained"]: 1.0 + min(1.0, eff) * 6.5},
		"xp": float(p["experience per level"]), "heat": _hc(Matching, float(p.heat))}

## Expected catch for one roll of a weighted reward list: {item: avg amount}
func _expected_roll(list: Array) -> Dictionary:
	var total = 0.0
	for e in list:
		total += float(e.weight)
	var out := {}
	if total <= 0.0:
		return out
	for e in list:
		out[e.item] = out.get(e.item, 0.0) + float(e.weight) / total * (float(e.min) + float(e.max)) / 2.0
	return out

func _phishing(p: Dictionary, snap: Dictionary) -> Dictionary:
	var lines = Phishing.max_lines + int(Upgrades.cur("phishing.lines"))
	var bait = Items.ITEM_MAP.get(int(snap.get("bait", -1)))
	var baited = bait != null and Inventory.get_amount(bait) >= Phishing.BAIT_PER_CAST
	var s = _speed(Phishing)
	var qh = 1.0 - Upgrades.cur("phishing.quick_hook")
	var chance = min(1.0, Phishing.get_efficiency(p) * (Phishing.get_bait_multiplier(bait) if baited else 1.0))
	var cast = float(p["cast time"]) / s
	var wait = (float(p["wait time min"]) + float(p["wait time max"])) / 2.0 / s
	var mult = 2.0 if baited else 1.0
	var h = _hc(Phishing, float(p.heat), Stats.tier_heat(Phishing.HEAT_BY_TIER, bait.tier if bait else Upgrades.working_tier("Phishing")))
	var inp := {}
	var style = p.get("style", "lines")
	var casts = lines if style == "lines" else 1
	if baited:
		inp[bait] = Phishing.BAIT_PER_CAST * casts * (1.0 - Upgrades.cur("phishing.bait_recycling"))
	var job := {"inp": inp, "repeat": baited}
	match style:
		"whale":
			var dl = float(p["download time"]) / s * qh / max(1, lines)
			job.seconds = cast + wait + chance * dl + 2.0
			var per = _expected_roll(p["resource gained"])
			var units = (float(p["bundle min"]) + float(p["bundle max"])) / 2.0 * mult * chance
			job.out = {}
			for item in per:
				job.out[item] = per[item] * units
			job.xp = chance * float(p["experience per level"]) * mult
			job.heat = h * (1.0 + chance)
		"smish":
			var window = float(p["wait time max"]) / s * qh
			job.seconds = cast + window + 2.0
			var replies = float(p["texts per line"]) * lines * chance
			job.xp = replies * float(p["experience per level"]) * mult
			job.heat = h * 2.0
			var key = str(snap.get("target", ""))
			job.apply = func(cycles: int, m: float) -> int:
				var n = int(round(replies * mult * cycles * m))
				var chosen = _target(key)
				var sql = 0
				for i in n:
					var tg = Phishing.smish_target(chosen)
					if tg.is_empty():
						sql += n - i
						break
					Decoding.add_intel_point(tg)
				if sql > 0:
					Inventory.add_resource(Items.SQL_INJECTOR, sql)
				for it in inp:
					Inventory.remove_resource(it, int(round(inp[it] * cycles)))
				return cycles
		_:
			var dl = float(p["download time"]) / s * qh
			var attempt = cast + wait + chance * (dl + 1.0) + (1.0 - chance) * 1.5
			job.seconds = attempt
			var list = Phishing.mod_pool() if p == Phishing.MOD else (p["resource gained"] if p["resource gained"] is Array else [])
			var per = _expected_roll(list)
			job.out = {}
			for item in per:
				job.out[item] = per[item] * chance * lines * mult
			job.xp = chance * lines * float(p["experience per level"])
			job.heat = h * lines * (1.0 + chance)
	return job

func _decoding(p: Dictionary, snap: Dictionary) -> Dictionary:
	var step = _step(Decoding, p)
	var kind = p.get("decode kind", "cache")
	var bytes_row = CacheDecrypting.HEX_CHARACTERS_SIZE
	var h = _hc(Decoding, float(p.heat)) # x the tier of what's decoded (_dec_heat)
	match kind:
		"package":
			var item = Items.ITEM_MAP.get(int(snap.get("item", -1)))
			if item == null:
				return {}
			var eff = Decoding.get_efficiency(p)
			var per = 1.0 + eff
			var limit = int(snap.get("limit", 0))
			var job = {"seconds": bytes_row * step / Decoding.compression_multiplier(), "xp": float(p["experience per level"]), "heat": h * _dec_heat(item)}
			job.apply = func(cycles: int, _m: float) -> int:
				var room = Uploads.get_still_needed(item)
				if limit > 0:
					room = min(room, limit)
				var n = min(int(round(cycles * per)), Inventory.get_amount(item), room)
				if n <= 0:
					return 0
				Inventory.remove_resource(item, n)
				Uploads.stage(item, n)
				return int(ceil(n / per))
			return job
		"intel":
			var tg = _target(str(snap.get("target", "")))
			if tg.is_empty() or Decoding.is_intel_maxed(tg):
				return {}
			var finds = Decoding.INTEL_LINES * Decoding.get_efficiency(p)
			var job = {"seconds": Decoding.INTEL_LINES * bytes_row * step, "xp": float(p["experience per level"]), "heat": h * _dec_heat(null)}
			job.apply = func(cycles: int, m: float) -> int:
				var n = int(round(cycles * finds * m))
				var done = 0
				for i in n:
					if Decoding.is_intel_maxed(tg):
						break
					Decoding.add_intel_point(tg)
					done += 1
				return int(ceil(done / max(0.01, finds))) if done < n else cycles
			return job
		_:
			var cache: CacheData = null
			var only = Items.ITEM_MAP.get(int(snap.get("item", -1)))
			if only and Inventory.get_amount(only) > 0:
				cache = only
			elif only == null:
				for it in Inventory.inventory:
					if it is CacheData and Inventory.get_amount(it) > 0:
						cache = it
						break
			if cache == null:
				return {}
			var keep_tracker = Decoding.rare_tracker.duplicate()
			var keep_first = Decoding.first_cache_decoded
			var out := {}
			var bytes := 0.0
			for k in SAMPLES:
				var loot = Decoding.roll_loot(cache, p)
				bytes += bytes_row * max(CacheDecrypting.DUMP_SIZE, loot.size())
				for d in loot:
					out[d.item] = out.get(d.item, 0.0) + float(d.amount) / SAMPLES
			Decoding.rare_tracker = keep_tracker
			Decoding.first_cache_decoded = keep_first
			return {"seconds": bytes / SAMPLES * step, "inp": {cache: 1.0}, "out": out, "xp": float(p["experience per level"]), "heat": h * _dec_heat(cache), "repeat": true}
	return {}

## Decoding heat x the tier of <item> (as cache_decrypt_terminal.heat_tier_mult)
func _dec_heat(item) -> float:
	var t = Inventory.item_tier(item) if item else 0
	return Stats.tier_heat(Decoding.HEAT_BY_TIER, t if t > 0 else Upgrades.working_tier("Decoding"))

## Fills per second with bursts: a normal fill takes 100 / rate s; a burst (chance per fill) fills at 100x for 1 s
func _compile_seconds(p: Dictionary) -> Dictionary:
	var rate = float(p["base speed"]) * _speed(Compiling) # bar units per second
	var pb = min(1.0, Compiling.get_efficiency(p))
	var extra = pb * rate * Compiling.BURST_SPEED * Compiling.BURST_SECONDS / 100.0 # extra fills per normal fill
	var seconds = (100.0 / rate + pb * Compiling.BURST_SECONDS) / (1.0 + extra)
	return {"seconds": seconds, "heat_share": 1.0 / (1.0 + extra)}

func _compiling(p: Dictionary, snap: Dictionary) -> Dictionary:
	var c = _compile_seconds(p)
	var h = _hc(Compiling, float(p.heat)) * c.heat_share
	if p == Compiling.MOD or p == Compiling.ACCESS:
		h *= Stats.tier_heat(Compiling.HEAT_BY_TIER, Upgrades.working_tier("Compiling"))
	var keep = 1.0 - Upgrades.cur("compiling.recovery")
	if p == Compiling.MOD:
		var item = Items.ITEM_MAP.get(int(snap.get("item", -1)))
		if item == null:
			return {}
		var cost = Compiling.mod_fill_cost(item)
		var job = {"seconds": c.seconds, "xp": float(p["experience per level"]), "heat": h}
		job.apply = func(cycles: int, _m: float) -> int:
			var done = 0
			for i in cycles:
				var t = item.hacking_mod_type
				if HackingMods.has_mod(t) and int(HackingMods.current_mods[t].duration) >= Compiling.mod_cap(item):
					break
				if !Compiling.can_afford(cost) or (!HackingMods.has_mod(t) and HackingMods.at_max_mods()):
					break
				if randf() >= Upgrades.cur("compiling.recovery"):
					for it in cost:
						Inventory.remove_resource(it, cost[it])
				HackingMods.extend_mod(item, 1.0 + Upgrades.cur("compiling.mod_tuning"), Compiling.mod_cap(item))
				done += 1
			return done
		return job
	if p == Compiling.ACCESS:
		var tg = _target(str(snap.get("target", "")))
		if tg.is_empty() or tg.get("unlocked", false):
			return {}
		var job = {"seconds": c.seconds, "xp": float(p["experience per level"]), "heat": h}
		job.apply = func(cycles: int, _m: float) -> int:
			var done = 0
			for i in cycles:
				var cost = Compiling.access_stage_cost(tg, Compiling.access_done(tg))
				if cost.is_empty() or !Compiling.can_afford(cost):
					break
				var r = Stats.get_access_recipe(tg)
				var recovered = randf() < Upgrades.cur("compiling.recovery")
				for it in cost:
					if !recovered or it == r.get("rare"):
						Inventory.remove_resource(it, cost[it])
				done += 1
				if Compiling.complete_access_stage(tg):
					report.notes.append("compiled access to %s" % tg.name)
					break
			return done
		return job
	var inp := {}
	for item in p.requirements:
		inp[item] = float(p.requirements[item]) * keep
	return {"seconds": c.seconds, "inp": inp, "out": {p["resource gained"]: 1.0 + Upgrades.cur("compiling.linker")},
		"xp": float(p["experience per level"]), "heat": h}
#endregion

#region uploads
func _run_uploads(secs: float) -> void:
	for item in Uploads.active.keys():
		if !Uploads.active.has(item):
			continue
		Uploads.active[item] += secs * UPLOAD_SPEED / Uploads.get_upload_seconds(item)
		while Uploads.active.has(item) and Uploads.active[item] >= 1.0:
			Uploads.active[item] -= 1.0
			Uploads._upload_one(item)
	Uploads.changed.emit()
#endregion

#region helpers
func _skills() -> Array:
	return [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Hacking]

func _skill(name: String) -> Node:
	for s in _skills():
		if s.SKILL.name == name:
			return s
	return null

func _find_process(skill: Node, name: String) -> Dictionary:
	if skill == null:
		return {}
	for p in skill.minor_processes:
		if p.name == name:
			return p
	return {}

func _target(key: String) -> Dictionary:
	if key == "":
		return {}
	for loc in Stats.hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in Stats.hacking_targets[loc].get(list, []):
				if Stats.target_key(t) == key:
					return t
	return {}

static func format_time(s: float) -> String:
	var h = int(s) / 3600
	var m = (int(s) % 3600) / 60
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%dm" % max(1, m)
#endregion
