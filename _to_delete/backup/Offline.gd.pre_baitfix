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
const MIN_AWAY_SECONDS := 60.0  # below this the welcome is one quiet line instead of the download screen (2026-10-30)
const RESUME_ONLY_SECONDS := 5.0 # below this nothing is computed: the process just resumes (a plain restart)
const UPLOAD_SPEED := 0.5        # uploads run at half speed offline
const QUEUE_SPEED := 0.5         # 2026-11-02 (Josh): a running queue cycles its steps for half the (capped) away time
const QUEUE_VERBS := {"mine": "Mining", "parse": "Parsing", "crack": "Cracking", "match": "Matching", "phish": "Phishing", "decode": "Decoding", "compile": "Compiling"}
const OVERHEAT_PENALTY := 0.10   # outputs lost when the process runs hotter than the system cools
const SAMPLES := 300             # virtual cycles averaged per model (random processes)

const MINING_SEGMENTS := 20      # data_mining_terminal.SEGMENTS
const PARSE_LINES := 10          # log_parsing_terminal.MAX_LOG_LINES
const PW_LENGTH := 4             # pw_cracking_terminal.PW_LENGTH
const MATCH_PAUSE := 0.3         # cred_matching_terminal: pause between matches

var session := {}   # from the save: {"saved_at": unix, "process": snapshot}
var report := {}    # what compute() did ({} = nothing to show)
var computing := false
var limited_run_done := false # 2026-11-02: the last compute() finished a '<command> N' run (the queue moves on) # true while compute() runs: level / rank notices stay out of the terminal (the download shows them)
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
	if int(t.get("cycle_limit")) > 0: # 2026-10-31: '<command> N': only the cycles left run offline
		snap.cycles_left = max(0, int(t.cycle_limit) - int(t.session_cycles))
	match skill:
		Parsing:
			snap.items = t.items_to_parse.map(func(i): return i.id)
			snap.target = t.extraction_target.id if t.extraction_target else -1
			# 2026-10-30: time already spent on the item in progress (a cache's green lines), credited offline
			snap.item_seconds = float(t._item_seconds) if "_item_seconds" in t else 0.0
		Cracking:
			if p == Cracking.VM:
				return {} # token conversion is online only
		Phishing:
			if p.get("style", "lines") == "trap":
				return {} # the Trap already fills on real time
			snap.bait = t.bait.id if t.bait else -1
			snap.target = Stats.target_key(t.smish_target) if !t.smish_target.is_empty() else ""
			snap.mod_tier = t.mod_tier # 'phish -mod=school
		Decoding:
			# 2026-11-02: Salvage and Deep run offline too (they were online only: Josh, timeskip test)
			snap.item = t.target_cache.id if t.target_cache else -1
			snap.target = Stats.target_key(t.target_arg) if t.target_arg is Dictionary else ""
			if str(t.get("intel_location")) != "" and t.get("intel_location") != null:
				snap.intel_location = str(t.intel_location)
		Compiling:
			snap.item = t.hacking_mod_item.id if t.hacking_mod_item else -1
	return snap
#endregion

#region queue
## 2026-11-02 (Josh, queue stage 2): a running queue keeps cycling its steps offline, for QUEUE_SPEED of the away time
## (items, XP and tokens all halve together). The step that was running carries on from the session snapshot; each
## next step is built from its command text (snap_from_command). A step ends when its count is done or it can't do
## another cycle; a whole pass of steps doing nothing stops the queue, like online.
func _run_queue(snap: Dictionary, secs: float) -> void:
	var left = secs * QUEUE_SPEED
	var cur = snap.duplicate(true)
	var size = Queue.steps.size()
	Queue.index = clampi(Queue.index, 0, size - 1)
	var idle = 0
	var ran_steps := {}
	var stopped = false
	computing = true
	for guard in 256:
		if cur.is_empty():
			cur = snap_from_command(Queue.steps[Queue.index])
		var progressed = false
		var done = true
		if !cur.is_empty():
			var skill = _skill(cur.skill)
			var p = _find_process(skill, cur.process)
			if skill and !p.is_empty() and _can_cycle(skill, p, cur):
				var ran = _run(skill, p, cur, left)
				Flush.add(skill.SKILL.name, str(p.name), float(ran))
				left -= ran
				report.ran = float(report.ran) + ran
				progressed = ran > 0.0
				if progressed:
					ran_steps[Queue.index] = true
				done = (cur.has("cycles_left") and int(cur.cycles_left) <= 0) or !_can_cycle(skill, p, cur)
		if !done:
			break # time ran out part way through this step: it resumes from here
		cur = {}
		Queue.index = (Queue.index + 1) % size
		idle = 0 if progressed else idle + 1
		if idle >= size:
			stopped = true
			break
		if left <= 0.5:
			break
	computing = false
	limited_run_done = false # the queue's index is already where it should be
	report.process = "Queue (%d step%s ran, half speed)" % [ran_steps.size(), "" if ran_steps.size() == 1 else "s"]
	report.notes.append("the queue ran at half speed while you were away")
	if stopped:
		Queue.running = false
		Queue.changed.emit()
		report.resume = {}
		report.notes.append("the queue stopped: none of its steps could run (out of inputs?)")
		return
	var os = get_tree().get_first_node_in_group("main_os") if get_tree() else null
	var ctx = int(snap.context) if snap.has("context") else (int(os.current_context) if os else 0)
	var full = str(Queue.steps[Queue.index])
	if cur.is_empty(): # between steps: the next one starts fresh
		report.resume = {"context": ctx, "command": full}
	else:
		var cmd = str(cur.command)
		if cur.has("cycles_left"):
			cmd += " %d" % int(cur.cycles_left)
		var mod = _queue_modifier(full)
		if mod != "":
			cmd += " " + mod
		report.resume = {"context": int(cur.get("context", ctx)), "command": cmd}
	Queue.changed.emit()

## Could <p> do one more cycle now (inputs in stock, limits left)?
func _can_cycle(skill: Node, p: Dictionary, snap: Dictionary) -> bool:
	if snap.has("cycles_left") and int(snap.cycles_left) <= 0:
		return false
	var job = _job(skill, p, snap)
	if job.is_empty() or float(job.get("seconds", 0.0)) <= 0.0:
		return false
	if job.has("limit") and int(job.limit) <= 0:
		return false
	for item in job.get("inp", {}):
		if float(job.inp[item]) > 0.0 and Inventory.get_amount(item) < float(job.inp[item]):
			return false
	return true

## The modifier word in a step ('mine -logs 10 survey' -> "survey"), "" if none
func _queue_modifier(cmd: String) -> String:
	var w = cmd.strip_edges().to_lower().split(" ", false)
	if w.size() < 3 or !QUEUE_VERBS.has(w[0]):
		return ""
	var skill = _skill(QUEUE_VERBS[w[0]])
	var mods = ["overclock"]
	for m in (skill.get("MODIFIERS") if skill and skill.get("MODIFIERS") else []):
		mods.append(str(m.command))
	for k in range(w.size() - 1, 1, -1):
		if w[k] in mods:
			return w[k]
	return ""

## A snapshot like snapshot() makes, from a queue step's command text ({} if it couldn't start: locked, no such
## item, a VM or a Trap...). Same parsing as the main terminal's handlers.
func snap_from_command(cmd: String) -> Dictionary:
	var w = Array(cmd.strip_edges().to_lower().split(" ", false))
	if w.size() < 2 or !QUEUE_VERBS.has(w[0]):
		return {}
	var skill = _skill(QUEUE_VERBS[w[0]])
	if skill == null:
		return {}
	var mod = _queue_modifier(cmd)
	if mod != "":
		for k in range(w.size() - 1, 1, -1):
			if w[k] == mod:
				w.remove_at(k)
				break
	var count = 0
	if w.size() >= 3 and str(w[-1]).is_valid_int() and int(w[-1]) > 0:
		count = int(w[-1])
		w.pop_back()
	var text = " ".join(w)
	var p := {}
	var extra := {}
	match skill:
		Mining, Matching:
			for ms in skill.minor_processes:
				if text == ms.command:
					p = ms
					break
		Cracking:
			for ms in skill.minor_processes:
				if text.begins_with(ms.command):
					p = ms
					break
			if p == Cracking.VM:
				return {}
		Parsing:
			for ms in skill.minor_processes:
				if text.begins_with(ms.command):
					p = ms
					break
			if !p.is_empty():
				var r = Parsing.parse_through_parse_start_command(text, p)
				if !r.valid:
					return {}
				extra.items = Array(r.items_to_parse).map(func(i): return i.id)
				extra.target = r.target.id if r.target else -1
				extra.item_seconds = 0.0
		Phishing:
			var pb = Phishing.parse_bait(text)
			if str(pb.error) != "":
				return {}
			for ms in skill.minor_processes:
				if pb.command == ms.command:
					p = ms
					break
			if p.is_empty() or p.get("style", "lines") == "trap":
				return {}
			extra.bait = pb.bait.id if pb.bait else -1
			extra.target = Stats.target_key(pb.target) if pb.target is Dictionary and !pb.target.is_empty() else ""
			extra.mod_tier = pb.get("mod_tier", 0)
		Decoding:
			if text.begins_with("decode -package"):
				return {}
			for ms in skill.minor_processes:
				if text == ms.command or text.begins_with(ms.command + "="):
					p = ms
					break
			if !p.is_empty():
				var check = Decoding.validate_start(p, text.trim_prefix(p.command).trim_prefix("="))
				if !check.ok:
					return {}
				var arg = check.arg
				extra.item = -1
				extra.target = ""
				if arg is ItemData:
					extra.item = arg.id
				elif arg is Dictionary and arg.has("_intel_location"):
					extra.intel_location = str(arg._intel_location)
					var nt = Decoding.next_intel_target(extra.intel_location)
					extra.target = Stats.target_key(nt) if !nt.is_empty() else ""
				elif arg is Dictionary and !arg.is_empty():
					extra.target = Stats.target_key(arg)
		Compiling:
			for ms in skill.minor_processes:
				if text.begins_with(ms.command):
					p = ms
					break
			if !p.is_empty():
				extra.item = -1
				if p == Compiling.MOD:
					var check = Compiling.check_mod(text.substr(text.find("=") + 1) if text.contains("=") else "")
					if !check.ok:
						return {}
					extra.item = check.item.id
	if p.is_empty() or !p.get("unlocked", true):
		return {}
	var os = get_tree().get_first_node_in_group("main_os") if get_tree() else null
	var snap = {"skill": skill.SKILL.name, "process": p.name, "context": int(os.current_context) if os else 0, "command": text}
	if count > 0:
		snap.cycles_left = count
	snap.merge(extra)
	return snap
#endregion

#region flush
## 2026-11-02: 'flush' (Flush.use): <secs> of the main terminal's process right now, the offline way. The process keeps
## running. Returns {"ran", "gains": [{item, amount}], "spent": [...]} or {"error"}.
func flush(secs: float) -> Dictionary:
	var snap = snapshot()
	if snap.is_empty():
		return {"error": "Nothing in the main terminal can flush."}
	var skill = _skill(snap.skill)
	var p = _find_process(skill, snap.process)
	if skill == null or p.is_empty():
		return {"error": "Nothing in the main terminal can flush."}
	snap.erase("item_seconds") # (only for a resumed save)
	var before = Inventory.inventory.duplicate()
	var keep_report = report # _run notes overheat losses in `report`: give it a scratch one
	report = {"lost": {}, "overheat": false, "notes": []}
	computing = true
	var ran = _run(skill, p, snap, secs)
	computing = false
	report = keep_report
	var gains = []
	var spent = []
	for item in Inventory.inventory:
		var d = int(Inventory.inventory[item]) - int(before.get(item, 0))
		if d > 0:
			gains.append({"item": item, "amount": d})
	for item in before:
		var d = int(before[item]) - Inventory.get_amount(item)
		if d > 0:
			spent.append({"item": item, "amount": d})
	gains.sort_custom(func(a, b): return a.amount > b.amount)
	return {"ran": ran, "gains": gains, "spent": spent}
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
	if saved_at <= 0:
		return
	# 2026-10-30: short absences still resume the process (before, under a minute it stayed stopped)
	if away < RESUME_ONLY_SECONDS:
		if !snap.is_empty():
			var cmd = str(snap.command)
			if snap.has("cycles_left"):
				cmd = "%s %d" % [cmd, int(snap.cycles_left)] if int(snap.cycles_left) > 0 else ""
			if cmd != "":
				report = {"resume_only": true, "away": away, "resume": {"context": int(snap.context), "command": cmd}}
		return
	var secs = min(away, cap_seconds())
	if secs >= MAX_CAP_HOURS * 3600.0 - 1.0: # 2026-11-03: a full 24 h offline session
		Achievements.event("OFFLINE_24")
	var inv_before = Inventory.inventory.duplicate()
	var up_before = Uploads.uploaded.duplicate()
	var staged_before = Uploads.staged.duplicate()
	var tiers_before = Uploads.completed_tiers.duplicate()
	var levels_before = {}
	var xp_before = {}
	var drivers_before = Drivers.owned.duplicate() # equipped drivers earn skill XP offline too (Exp.add_xp)
	for s in _skills():
		levels_before[s.SKILL.name] = int(s.SKILL.level)
		xp_before[s.SKILL.name] = int(s.SKILL.experience)
	report = {"away": away, "secs": secs, "capped": away > cap_seconds(), "process": "", "resume": {}, "short": away < MIN_AWAY_SECONDS,
		"overheat": false, "notes": [], "gains": [], "spent": [], "uploaded": [], "staged": [], "levels": [], "ran": 0.0,
		"tiers": [], "trap": -1.0, "xp": [], "lost": {}, "drivers": []}
	if Queue.running and !Queue.steps.is_empty():
		_run_queue(snap, secs)
	elif !snap.is_empty():
		var skill = _skill(snap.skill)
		var p = _find_process(skill, snap.process)
		if skill and !p.is_empty():
			report.process = "%s %s" % [skill.SKILL.name, p.name]
			report.resume = {"context": int(snap.context), "command": str(snap.command)}
			computing = true
			report.ran = _run(skill, p, snap, secs)
			computing = false
			Flush.add(skill.SKILL.name, str(p.name), float(report.ran)) # 2026-11-02: flush buffers fill offline too
			if snap.has("cycles_left"): # a limited run resumes with what's left of it, or not at all
				if int(snap.cycles_left) > 0:
					report.resume.command = "%s %d" % [str(snap.command), int(snap.cycles_left)]
				else:
					report.resume = {}
					report.notes.append("your limited run finished while you were away")
					limited_run_done = true
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
	for id in Drivers.owned:
		var gained = int(Drivers.owned[id]) - int(drivers_before.get(id, 0))
		if gained > 0:
			var was = Drivers.owned[id]
			Drivers.owned[id] = int(drivers_before.get(id, 0))
			var r_from = Drivers.rank(id)
			Drivers.owned[id] = was
			if r_from >= Drivers.MAX_RANK:
				continue # 2026-11-02 (Josh): a maxed driver's XP isn't news
			report.drivers.append({"name": Drivers.DEFS[id].name, "skill": Drivers.DEFS[id].skill, "xp": gained, "from": r_from, "to": Drivers.rank(id)})
	for t in Uploads.completed_tiers:
		if not t in tiers_before:
			report.tiers.append(int(t))
	if Phishing.has_trap():
		report.trap = Phishing.trap_progress() # the fullest trap (they fill on real time, offline too); collecting stays manual
		report["traps_full"] = Phishing.full_traps()
		report["traps_set"] = Phishing.traps.size()
	report.gains.sort_custom(func(a, b): return a.amount > b.amount)
	if report.gains.is_empty() and report.drivers.is_empty() and report.uploaded.is_empty() and report.staged.is_empty() and report.notes.is_empty() and report.trap < 0.0:
		report.notes.append("nothing was running in the main terminal")
	SaveManager.mark_dirty()

## Runs the process for up to <secs>; returns the seconds it actually ran. A job tied to one input
## ("repeat") moves on to the next input (next cache, next item to parse, bait -> no bait) when it runs out.
## 2026-10-30: long cycles (a cache's Network conversion takes minutes) no longer lose the part-done item: the time
## already spent on it before quitting counts, and a last partial cycle completes with the chance of how far along it is.
const LONG_CYCLE_SECONDS := 20.0
func _run(skill: Node, p: Dictionary, snap: Dictionary, secs: float) -> float:
	var credit = float(snap.get("item_seconds", 0.0))
	var left = secs + credit
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
		if float(job.seconds) >= LONG_CYCLE_SECONDS and randf() < (left - time_cycles * float(job.seconds)) / float(job.seconds):
			time_cycles += 1 # the part-done last cycle, by how far along it got
		var cycles = time_cycles
		for item in job.get("inp", {}):
			var per = float(job.inp[item])
			if per > 0.0:
				cycles = min(cycles, int(floor(Inventory.get_amount(item) / per)))
		if job.has("limit"):
			cycles = min(cycles, int(job.limit))
		if snap.has("cycles_left"):
			cycles = min(cycles, int(snap.cycles_left))
		if cycles <= 0:
			break
		if job.has("apply"):
			cycles = int(job.apply.call(cycles, mult)) # custom processes say how many cycles they did
		else:
			for item in job.get("inp", {}):
				Inventory.remove_resource(item, int(round(float(job.inp[item]) * cycles)))
			for item in job.get("out", {}):
				var full = float(job.out[item]) * cycles
				var n = _stochastic(full * mult) # 2026-11-02: was round(): rare outputs (0.3 Exploits) always came out 0
				if n > 0:
					Inventory.add_resource(item, n)
				if hot and int(round(full)) - n > 0: # what overheating cost (shown in the download)
					report.lost[item] = int(report.lost.get(item, 0)) + int(round(full)) - n
		if cycles <= 0:
			break
		if float(job.get("xp", 0.0)) > 0.0:
			Exp.add_xp(skill, p, int(round(float(job.xp) * cycles)))
		left -= cycles * float(job.seconds)
		if snap.has("cycles_left"):
			snap.cycles_left = max(0, int(snap.cycles_left) - cycles)
			if int(snap.cycles_left) <= 0:
				break
		if cycles >= time_cycles or !job.get("repeat", false):
			break
	return clamp(secs + credit - left, 0.0, secs)

## x.3 -> x, plus 1 with a 30% chance (expected value kept for rare / slow outputs; round() lost anything under 0.5)
static func _stochastic(v: float) -> int:
	var whole = floor(v)
	return int(whole) + (1 if randf() < v - whole else 0)

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
	var tm = Parsing.item_time_mult(p, item)
	var step = _step(Parsing, p) * tm
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
		var fm = Parsing.item_find_mult(p, item)
		var pc = Upgrades.cur("parsing.pattern_cache") if Parsing.pattern_cache_applies(p) else 0.0 # not Network
		var miss = 0.0
		for k in SAMPLES:
			for i in lines:
				var flat = Parsing.flat_line_chance(p, item) # Corruption: flat chance (2026-10-29)
				if randf() < (flat if flat >= 0.0 else (base_eff + bonus + miss) * fm):
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
	return {"seconds": t / SAMPLES, "inp": {item: 1.0}, "out": out, "xp": round(float(p["experience per level"]) * tm),
		"heat": _hc(Parsing, float(p.heat), Stats.tier_heat(Parsing.HEAT_BY_TIER, Exploits.cache_tier(item) if item is CacheData else item.tier) * tm), "repeat": true}

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
	var baited = bait != null and Inventory.get_amount(bait) >= Phishing.bait_cost(bait)
	var rare_bait = baited and Phishing.is_rare_bait(bait) # 'phish -mod' with a rare: every cast lands a mod
	var s = _speed(Phishing)
	var qh = 1.0 - Upgrades.cur("phishing.quick_hook")
	var chance = 1.0 if rare_bait else min(1.0, Phishing.get_efficiency(p) * (Phishing.get_bait_multiplier(bait) if baited else 1.0))
	var cast = float(p["cast time"]) / s
	var wait = (float(p["wait time min"]) + float(p["wait time max"])) / 2.0 / s
	var mult = 2.0 if baited and !rare_bait else 1.0
	var h = _hc(Phishing, float(p.heat), 1.0 if p.get("flat heat", false) else Stats.tier_heat(Phishing.HEAT_BY_TIER, Phishing.bait_tier(bait) if bait else Upgrades.working_tier("Phishing")))
	var inp := {}
	var style = p.get("style", "lines")
	var casts = lines if style == "lines" else 1
	if baited:
		inp[bait] = Phishing.bait_cost(bait) * casts * (1.0 - Upgrades.cur("phishing.bait_recycling"))
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
			# 2026-10-30: landed whales also roll their Exploit chance (30% since big-game whaling)
			var whales = chance
			var ex_chance = float(p.get("exploit chance", 0.0))
			var whale_out = job.out
			job.apply = func(cycles: int, m: float) -> int:
				for item in whale_out:
					var n = int(round(float(whale_out[item]) * cycles * m))
					if n > 0:
						Inventory.add_resource(item, n)
				var total = whales * ex_chance * cycles * m
				var ne = int(floor(total)) + (1 if randf() < total - floor(total) else 0)
				for i in ne:
					var ex = Phishing.roll_exploit_item()
					if ex:
						Inventory.add_resource(ex, 1)
				for it in inp:
					Inventory.remove_resource(it, int(round(inp[it] * cycles)))
				return cycles
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
			var mt = int(snap.get("mod_tier", 0))
			var list = (Phishing.tier_mod_pool(Inventory.item_tier(bait)) if rare_bait else (Phishing.tier_mod_pool(mt) if mt > 0 else Phishing.mod_pool())) if p == Phishing.MOD else (p["resource gained"] if p["resource gained"] is Array else [])
			var per = _expected_roll(list)
			job.out = {}
			for item in per:
				job.out[item] = per[item] * chance * lines * mult
			if p == Phishing.MOD and !list.is_empty():
				# 2026-10-24: rolled as whole catches. Spread as averages over every mod in the pool, each one
				# rounded to 0 on a big pool (2 h offline with all tiers open gave XP and no mods)
				var catches = chance * lines * mult
				job.apply = func(cycles: int, m: float) -> int:
					var total = catches * cycles * m
					var n = int(floor(total)) + (1 if randf() < total - floor(total) else 0)
					var wsum = 0.0
					for e in list:
						wsum += float(e.weight)
					for i in n:
						var r = randf() * wsum
						for e in list:
							r -= float(e.weight)
							if r <= 0.0:
								Inventory.add_resource(e.item, 1)
								break
					for it in inp:
						Inventory.remove_resource(it, int(round(inp[it] * cycles)))
					return cycles
			job.xp = chance * lines * float(p["experience per level"])
			job.heat = h * lines * (chance if p.get("flat heat", false) else 1.0 + chance) # Mod: only catches heat
	return job

func _decoding(p: Dictionary, snap: Dictionary) -> Dictionary:
	var step = _step(Decoding, p)
	var kind = p.get("decode kind", "cache")
	var bytes_row = CacheDecrypting.HEX_CHARACTERS_SIZE
	var h = _hc(Decoding, float(p.heat)) # x the tier of what's decoded (_dec_heat)
	match kind:
		"intel":
			var tg = Decoding.next_intel_target(str(snap.intel_location)) if snap.has("intel_location") else _target(str(snap.get("target", "")))
			if tg.is_empty() or Decoding.is_intel_maxed(tg):
				return {}
			var finds = Decoding.INTEL_LINES * Decoding.get_efficiency(p)
			var job = {"seconds": Decoding.INTEL_LINES * bytes_row * step, "xp": float(p["experience per level"]), "heat": h * _dec_heat(null), "repeat": snap.has("intel_location")}
			job.apply = func(cycles: int, m: float) -> int:
				var n = int(round(cycles * finds * m))
				var done = 0
				for i in n:
					if Decoding.is_intel_maxed(tg):
						break
					Decoding.add_intel_point(tg)
					done += 1
				if done > 0: # shown in the download (intel isn't an item, so it never showed up in the gains)
					report["intel"] = {"target": str(tg.name), "points": int(report.get("intel", {}).get("points", 0)) + done, "text": Decoding.intel_text(tg)}
				return int(ceil(done / max(0.01, finds))) if done < n else cycles
			return job
		"salvage": # 2026-11-02: 100 of the item per run, its lines' VM tokens (sampled)
			var item: ItemData = Items.ITEM_MAP.get(int(snap.get("item", -1)))
			if item == null or Inventory.get_amount(item) < Decoding.SALVAGE_COST:
				return {}
			var outs := {}
			for k in SAMPLES:
				for row in Decoding.roll_salvage(item, ""):
					if row != null:
						outs[row.item] = outs.get(row.item, 0.0) + float(row.amount) / SAMPLES
			return {"seconds": bytes_row * max(CacheDecrypting.DUMP_SIZE, Decoding.SALVAGE_LINES) * step, "inp": {item: float(Decoding.SALVAGE_COST)}, "out": outs,
				"xp": float(p["experience per level"]), "heat": h * _dec_heat(item), "repeat": true}
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
			var inp := {cache: 1.0}
			if int(p.get("token cost", 0)) > 0: # Deep Scan: VM Decoding tokens per cache (2026-11-02: offline too)
				if Inventory.get_amount(Items.VM_DECODING_TOKEN) < int(p.get("token cost", 0)):
					return {}
				inp[Items.VM_DECODING_TOKEN] = float(p.get("token cost", 0))
			return {"seconds": bytes / SAMPLES * step, "inp": inp, "out": out, "xp": float(p["experience per level"]), "heat": h * _dec_heat(cache), "repeat": true}
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
	if p == Compiling.MOD:
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
	if s < 60.0: # 2026-10-30: short absences show seconds ("away 42s")
		return "%ds" % max(1, int(s))
	return "%dm" % m
#endregion
