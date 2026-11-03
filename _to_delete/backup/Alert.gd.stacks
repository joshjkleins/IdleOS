extends Node
## 2026-11-02 (Josh): target alert. Every cache a target drops raises its alert one stack: the next win's cache chance is
## 100% - 10% per stack (10 stacks = 0%, nothing drops). A lost roll doesn't raise it. When a target first gets alerted
## it rolls one of its tier's processes (Mining, Parsing, Cracking, Matching, Compiling, Phishing) and keeps it until it's
## back to 100%. Each stack clears with a step of that process's work: about STEP_SECONDS at the tier's arrival speed,
## shown as a count ("crack -biometric x6"). Progress is that skill's XP (any process of the skill, main terminal, VMs,
## the queue and offline all count), so upgrades and VM windows clear it faster. XP goes to the alerted targets needing
## that skill in location order; what's left over moves on. Exempt: compromise fights, hacks before the tutorial is done.

signal changed

const STEP := 0.10
const MAX_STACKS := 10
const STEP_SECONDS := 240.0
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

var data := {} # target key -> {"stacks": int, "skill": String, "xp": float (XP toward the current step)}

#region rules
func exempt() -> bool:
	return !Tutorial.is_tutorial_complete()

func stacks(target: Dictionary) -> int:
	return int(data.get(Stats.target_key(target), {}).get("stacks", 0))

func chance(target: Dictionary) -> float:
	return clampf(1.0 - STEP * stacks(target), 0.0, 1.0)

## A won hack's cache roll. True: the cache drops (and the alert goes up a stack). False: no cache.
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
	if int(d.get("stacks", 0)) <= 0:
		d = {"stacks": 0, "skill": SKILLS.pick_random(), "xp": 0.0}
	d.stacks = mini(MAX_STACKS, int(d.stacks) + 1)
	data[key] = d
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
	return maxi(1, int(ceil(STEP_SECONDS / float(SEC_PER_UNIT[skill][tier - 1]))))

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
		var need = step_xp(skill, tier)
		while left > 0.0 and int(d.stacks) > 0:
			var take = min(left, need - float(d.xp))
			d.xp = float(d.xp) + take
			left -= take
			if float(d.xp) >= need - 0.001:
				d.stacks = int(d.stacks) - 1
				d.xp = 0.0
				if int(d.stacks) <= 0:
					data.erase(key)
					if !Offline.computing:
						Signals.system_message_signal.emit("[color=#4ec994]%s's alert is cleared: caches drop every time again.[/color]" % (t.name if !t.is_empty() else key))
					break
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

## "crack -biometric x6" (units left in this step)
func goal_text(target: Dictionary) -> String:
	var d: Dictionary = data.get(Stats.target_key(target), {})
	if d.is_empty():
		return ""
	var tier = _tier(target)
	var skill = str(d.skill)
	var per = _xp_per_unit(skill, tier)
	var left_units = int(ceil((step_xp(skill, tier) - float(d.xp)) / per))
	var p = _unit_process(skill, tier)
	var cmd = str(p.get("command", skill.to_lower()))
	match skill:
		"Parsing": cmd = "parse -footprint=" + Decoding.get_tier_resources(tier)[0].name.to_lower()
		"Phishing": return "land %d phishing catches" % left_units
	return "%s ×%d" % [cmd, left_units]

## 0..1 through the current step
func step_progress(target: Dictionary) -> float:
	var d: Dictionary = data.get(Stats.target_key(target), {})
	if d.is_empty():
		return 0.0
	return clampf(float(d.xp) / step_xp(str(d.skill), _tier(target)), 0.0, 1.0)

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
		var s = stacks(tg)
		var col = SKILL_COLORS.get(skill_of(tg), D)
		t += "  %s  [color=%s]alert %d%%[/color]  cache %d%%  [color=%s]%s[/color]  [color=%s]%d%% through this step[/color]\n" % [
			str(tg.name).rpad(24), R, s * 10, int(round(chance(tg) * 100)), col, goal_text(tg), D, int(step_progress(tg) * 100)]
	t += "\n[color=%s]Each cache a target drops raises its alert 10%% (its next cache chance drops 10%%; 100%% alert = no caches). Clear it a step at a time with the process shown (main terminal, VMs, the queue and offline all count).[/color]\n" % D
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
		if e is Dictionary and str(e.get("skill", "")) in SKILLS and int(e.get("stacks", 0)) > 0:
			data[str(k)] = {"stacks": clampi(int(e.stacks), 1, MAX_STACKS), "skill": str(e.skill), "xp": float(e.get("xp", 0.0))}
	changed.emit()
