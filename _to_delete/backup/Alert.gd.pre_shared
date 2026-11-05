extends Node
## 2026-11-02 (Josh): target alert (0-100%). The next win's cache chance is 100% - alert (100% alert = nothing drops).
## Each cache that drops raises it: the first cache of a run +10%, every further cache in the same run +4% (2026-11-03:
## runs are cheaper per cache). A lost roll doesn't raise it; a run that ends traced refunds the alert it added (its
## caches are lost too). When a target first gets alerted
## it rolls one of its tier's processes (Mining, Parsing, Cracking, Matching, Compiling, Phishing) and keeps it until it's
## back to 100%. Each stack clears with a step of that process's work: about STEP_SECONDS at the tier's arrival speed,
## shown as a count to the next 10% ("crack -biometric x6"). Cleanup lowers it smoothly: one step = 10%. Progress is that skill's XP (any process of the skill, main terminal, VMs,
## the queue and offline all count), so upgrades and VM windows clear it faster. XP goes to the alerted targets needing
## that skill in location order; what's left over moves on. Exempt: compromise fights, hacks before the tutorial is done.

signal changed

const FIRST := 10.0       # % the first cache of a run adds
const MORE := 4.0         # % each further cache in the same run adds (2026-11-03, Josh)
const STEP := 10.0        # % one cleanup step removes
const PIPS := 10
const STEP_SECONDS := [40.0, 46.0, 53.0, 61.0, 70.0, 80.0] # 2026-11-03 (Josh): T1 40 s per 10% (parse 10 logs), +15% per tier after (more VMs / queue / offline)
const SKILLS := ["Mining", "Parsing", "Cracking", "Matching", "Compiling", "Phishing"]
## seconds per unit at each tier's arrival (previous tiers' apt, arrival level), from tools/tests/econdump3.gd 2026-11-02.
## Units: mining / cracking / matching / compiling cycles of the tier's process, parsed items of its mining item, phishing catches.
const SEC_PER_UNIT := {
	"Mining": [8.0, 11.03, 13.16, 16.02, 17.0, 19.23],
	"Parsing": [4.0, 4.3, 4.45, 4.75, 5.61, 6.47],
	"Cracking": [11.21, 15.04, 19.86, 22.14, 30.05, 37.99],
	"Matching": [12.12, 15.46, 19.2, 23.27, 27.71, 32.58],
	"Compiling": [9.1, 9.35, 9.6, 9.84, 10.09, 10.37],
	"Phishing": [8.73, 4.40, 2.34, 1.32, 0.78, 0.49],
}

var data := {} # target key -> {"alert": float 0-100, "skill": String}
var _run := {}  # this hacking run: target key -> % it added (refunded if the run is traced), "_n" -> caches dropped

#region rules
func exempt() -> bool:
	return !Tutorial.is_tutorial_complete()

func alert_pct(target: Dictionary) -> float:
	return float(data.get(Stats.target_key(target), {}).get("alert", 0.0))

func pips(target: Dictionary) -> int:
	return int(ceil(alert_pct(target) / STEP - 0.0001))

func chance(target: Dictionary) -> float:
	return clampf(1.0 - alert_pct(target) / 100.0, 0.0, 1.0)

## hacking_game.setup: a new run (single hacks are runs of one)
func begin_run() -> void:
	_run = {}

## The run's caches were kept (rewards granted): its alert stays
func end_run() -> void:
	_run = {}

## The run ended traced: its caches are lost, so is the alert they added
func refund_run() -> float:
	var back = 0.0
	for key in _run:
		if key == "_n" or !data.has(key):
			continue
		back += float(_run[key])
		data[key].alert = float(data[key].alert) - float(_run[key])
		if float(data[key].alert) <= 0.001:
			data.erase(key)
	_run = {}
	if back > 0.0:
		_changed()
	return back

## % the next cache that drops in this run would add (+10% first of a run, +4% after; Clean Exit lowers the 4%)
func next_add() -> float:
	return FIRST if int(_run.get("_n", 0)) == 0 else more()

## a run's later caches: 4%, or Clean Exit's 3 / 2.5 / 2% (the cool_head driver id)
func more() -> float:
	var ce = Drivers.value("cool_head") * 100.0
	return ce if ce > 0.0 else MORE

var last_ghost := false # the last drop was hidden by Ghost Protocol (hacking_game logs it)

## A won hack's cache roll. True: the cache drops (and the alert goes up). False: no cache.
func roll_cache(target: Dictionary) -> bool:
	if exempt():
		return true
	var c = chance(target)
	if c <= 0.0 or randf() >= c:
		return false
	_raise(target)
	return true

func _raise(target: Dictionary) -> void:
	var key = Stats.target_key(target)
	var d: Dictionary = data.get(key, {})
	if float(d.get("alert", 0.0)) <= 0.0:
		d = {"alert": 0.0, "skill": SKILLS.pick_random()}
	var add = next_add()
	last_ghost = Drivers.value("payload_recycler") > 0.0 and randf() < Drivers.value("payload_recycler") # Ghost Protocol
	if last_ghost:
		add = 0.0
	add = min(add, 100.0 - float(d.alert))
	d.alert = float(d.alert) + add
	if float(d.alert) >= 100.0 - 0.001:
		d["maxed"] = true # (ALERT_CLEARED achievement once it's cleared)
	if float(d.alert) <= 0.0:
		_run["_n"] = int(_run.get("_n", 0)) + 1 # (Ghost Protocol on a clean target: still counts as the run's cache)
		return
	data[key] = d
	_run["_n"] = int(_run.get("_n", 0)) + 1
	_run[key] = float(_run.get(key, 0.0)) + add
	_changed()

func _tier(target: Dictionary) -> int:
	var p = Stats.target_place(target)
	return clampi(Stats.hacking_targets.keys().find(p.get("location", "")) + 1, 1, 6) if !p.is_empty() else 1

## The process (dict) a skill's unit counts in at <tier>, and the XP one unit gives
func _unit_process(skill: String, tier: int) -> Dictionary:
	var i = tier - 1
	match skill:
		"Mining": return Mining.minor_processes[i]
		"Cracking": return Cracking.minor_processes.filter(func(p): return p != Cracking.VM)[i]
		"Matching": return Matching.minor_processes[i]
		"Compiling": return Compiling.minor_processes[i]
		"Parsing": return Parsing.FOOTPRINT
		"Phishing": return Phishing.minor_processes[0] # Spear
	return {}

func _xp_per_unit(skill: String, tier: int) -> float:
	var p = _unit_process(skill, tier)
	var xp = float(p.get("experience per level", 1))
	if skill == "Parsing":
		xp = round(xp * Parsing.item_time_mult(Parsing.FOOTPRINT, Decoding.get_tier_resources(tier)[0]))
	return max(1.0, xp)

func step_units(skill: String, tier: int) -> int:
	return maxi(1, int(round(float(STEP_SECONDS[tier - 1]) / float(SEC_PER_UNIT[skill][tier - 1])))) # nearest (ceil overshot long cycles)

func step_xp(skill: String, tier: int) -> float:
	return step_units(skill, tier) * _xp_per_unit(skill, tier)
#endregion

#region progress
## Exp.add_xp: a skill's XP clears steps
func on_xp(major, amount: int) -> void:
	if amount <= 0 or data.is_empty() or major == null or !("SKILL" in major):
		return
	var skill = str(major.SKILL.name)
	if !(skill in SKILLS):
		return
	var left = float(amount)
	for key in _ordered_keys():
		var d: Dictionary = data[key]
		if d.skill != skill:
			continue
		var t = _target_of(key)
		var tier = _tier(t) if !t.is_empty() else 1
		var need = step_xp(skill, tier) # XP per 10%
		var drop = STEP * left / need
		if drop >= float(d.alert) - 0.001:
			left -= float(d.alert) / STEP * need
			if d.get("maxed", false):
				Achievements.event("ALERT_CLEARED")
			data.erase(key)
			if !Offline.computing:
				Signals.system_message_signal.emit("[color=#4ec994]%s's alert is cleared: caches drop every time again.[/color]" % (t.name if !t.is_empty() else key))
		else:
			d.alert = float(d.alert) - drop
			left = 0.0
		if left <= 0.0:
			break
	_changed()

func _ordered_keys() -> Array:
	var keys = data.keys()
	var order = func(k): # location order, then target order
		var t = _target_of(k)
		var p = Stats.target_place(t) if !t.is_empty() else {}
		return (Stats.hacking_targets.keys().find(p.get("location", "")) * 10 + int(p.get("index", 9))) if !p.is_empty() else 999
	keys.sort_custom(func(a, b): return order.call(a) < order.call(b))
	return keys

func _target_of(key: String) -> Dictionary:
	for loc in Stats.hacking_targets:
		for t in Stats.hacking_targets[loc].get("targets", []):
			if Stats.target_key(t) == key:
				return t
	return {}
#endregion

#region text
const SKILL_COLORS := {"Mining": "#7a4a2e", "Parsing": "#ec4899", "Cracking": "#f2600c", "Matching": "#eab308", "Compiling": "#8b5cf6", "Phishing": "#3b82f6"}

## "crack -biometric x6": units left to clear the whole alert (2026-11-03: was "to the next 10%", which jumped
## from x2 back to x20 at 10% and read as a bug with 4% steps)
func goal_text(target: Dictionary) -> String:
	var d: Dictionary = data.get(Stats.target_key(target), {})
	if d.is_empty():
		return ""
	var tier = _tier(target)
	var skill = str(d.skill)
	var left_units = maxi(1, int(ceil(float(d.alert) / STEP * step_units(skill, tier) - 0.0001)))
	var p = _unit_process(skill, tier)
	var cmd = str(p.get("command", skill.to_lower()))
	match skill:
		"Parsing": cmd = "parse -footprint=" + Decoding.get_tier_resources(tier)[0].name.to_lower()
		"Phishing": return "land %d phishing catches" % left_units
	return "%s ×%d" % [cmd, left_units]

## % left above the next lower 10% mark (37 -> 7, 30 -> 10)
func _chunk(a: float) -> float:
	if a <= 0.0:
		return 0.0
	var below = floor((a - 0.0001) / STEP) * STEP
	return a - below

## A command that clears the whole alert ('parse -footprint=logs 22', 'crack -password 8', 'phish -spear'), for hints
func goal_command(target: Dictionary) -> String:
	var d: Dictionary = data.get(Stats.target_key(target), {})
	if d.is_empty():
		return ""
	var tier = _tier(target)
	var skill = str(d.skill)
	var n = maxi(1, int(ceil(float(d.alert) / STEP * step_units(skill, tier) - 0.0001)))
	match skill:
		"Parsing": return "parse -footprint=%s %d" % [Decoding.get_tier_resources(tier)[0].name.to_lower(), n]
		"Phishing": return "phish -spear"
	return "%s %d" % [str(_unit_process(skill, tier).get("command", skill.to_lower())), n]

func skill_node(target: Dictionary) -> Node:
	var s = skill_of(target)
	return get_node_or_null("/root/" + s) if s != "" else null

## 0..1 through the current 10% step
func step_progress(target: Dictionary) -> float:
	var a = alert_pct(target)
	if a <= 0.0:
		return 0.0
	return clampf(1.0 - _chunk(a) / STEP, 0.0, 1.0)

func skill_of(target: Dictionary) -> String:
	return str(data.get(Stats.target_key(target), {}).get("skill", ""))

## 'alert': every alerted target and its chore
func list_text() -> String:
	var G = "#4ec994"; var D = "#888888"; var R = "#e26d5a"
	var t = "\n[bgcolor=#2a1a1a][color=%s] TARGET ALERT [/color][/bgcolor]\n" % R
	if data.is_empty():
		t += "[color=%s]No target is on alert: every won hack drops its cache.[/color]\n" % G
	for key in _ordered_keys():
		var tg = _target_of(key)
		if tg.is_empty():
			continue
		var col = SKILL_COLORS.get(skill_of(tg), D)
		t += "  %s  [color=%s]alert %d%%[/color]  cache %d%%  [color=%s]%s[/color]  [color=%s]to clear[/color]\n" % [
			str(tg.name).rpad(24), R, int(round(alert_pct(tg))), int(round(chance(tg) * 100)), col, goal_text(tg), D]
	t += "\n[color=%s]Each cache a target drops raises its alert (cache chance = 100%% - alert): +10%% for the first cache of a run, +4%% for each one after it in the same run. A traced run refunds its alert. Clear it with the process shown: every 10%% takes the same work, and the main terminal, VMs, the queue and offline all count.[/color]\n" % D
	return t
#endregion

func _changed() -> void:
	SaveManager.mark_dirty()
	changed.emit()

func save_data() -> Dictionary:
	return {"targets": data}

func load_data(d: Dictionary) -> void:
	data = {}
	var raw: Dictionary = d.get("targets", {})
	for k in raw:
		var e = raw[k]
		if !(e is Dictionary) or !(str(e.get("skill", "")) in SKILLS):
			continue
		var a = float(e.get("alert", float(e.get("stacks", 0)) * STEP)) # (saved as stacks on 2026-11-02)
		if a > 0.0:
			data[str(k)] = {"alert": clampf(a, 0.0, 100.0), "skill": str(e.skill), "maxed": bool(e.get("maxed", false))}
	changed.emit()
