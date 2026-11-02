extends Node
## 2026-11-02 (Josh): burst. Every process of a skill has a bar (the process cards in the skill's header, which had no
## use since process levels were retired). A bar fills while ITS process runs in the main terminal (offline too, never
## in a VM), FILL_SECONDS of running for a full bar, the same pace for every process. 'burst' spends one full bar of
## the running process's skill (its own first) to instantly run BURST_SECONDS of the main terminal's process
## (Offline's simulation: the same gains, inputs used, XP).

signal changed

const FILL_SECONDS := 3600.0 # 60 min of running per bar
const BURST_SECONDS := 300.0  # what one bar runs instantly

var charge := {} # "Skill/Process" -> seconds stored (0..FILL_SECONDS)
var _accum := 0.0

func key(skill_name: String, process_name: String) -> String:
	return "%s/%s" % [skill_name, process_name]

func progress(skill_name: String, process_name: String) -> float:
	return clamp(float(charge.get(key(skill_name, process_name), 0.0)) / FILL_SECONDS, 0.0, 1.0)

func is_full(k: String) -> bool:
	return float(charge.get(k, 0.0)) >= FILL_SECONDS

func add(skill_name: String, process_name: String, secs: float) -> void:
	if secs <= 0.0:
		return
	var k = key(skill_name, process_name)
	var before = float(charge.get(k, 0.0))
	charge[k] = min(FILL_SECONDS, before + secs)
	if before < FILL_SECONDS and charge[k] >= FILL_SECONDS:
		changed.emit()
		if !Offline.computing:
			Signals.system_message_signal.emit("[color=#4ec994]%s %s burst ready:[/color] 'burst' runs 5 minutes of the main terminal's %s process instantly." % [skill_name, process_name, skill_name])

## full bars of <skill_name>, the running process's own first
func full_keys(skill_name: String, own_process: String = "") -> Array:
	var out = []
	var own = key(skill_name, own_process)
	if own_process != "" and is_full(own):
		out.append(own)
	for k in charge:
		if k != own and str(k).begins_with(skill_name + "/") and is_full(k):
			out.append(k)
	return out

## the main terminal's process (skill node, process dict), or [] when nothing can burst / fill
func _main_process() -> Array:
	var os = get_tree().get_first_node_in_group("main_os") if get_tree() else null
	if os == null or !os.process_running or os.current_process == null or !is_instance_valid(os.current_process):
		return []
	var t = os.current_process
	if !("skill" in t) or t.skill == null or t.in_vm or t.skill == Hacking or t.skill == Defragging:
		return []
	if !("process_data" in t) or !(t.process_data is Dictionary) or t.process_data.is_empty():
		return []
	return [t.skill, t.process_data]

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 1.0:
		return
	var secs = _accum
	_accum = 0.0
	var m = _main_process()
	if !m.is_empty():
		add(str(m[0].SKILL.name), str(m[1].name), secs)

## 'burst': "" + the result text
func use() -> String:
	var m = _main_process()
	if m.is_empty():
		return help_text("[color=#d29922]Nothing to burst: start a process in the main terminal first (not Hacking or Defragging, not in a VM).[/color]")
	var sk = str(m[0].SKILL.name)
	var pn = str(m[1].name)
	var keys = full_keys(sk, pn)
	if keys.is_empty():
		return help_text("[color=#d29922]No %s burst is ready yet.[/color]" % sk)
	var r = Offline.burst(BURST_SECONDS)
	if r.has("error"):
		return str(r.error)
	charge[keys[0]] = 0.0
	SaveManager.mark_dirty()
	changed.emit()
	var parts = r.gains.map(func(g): return "+%d %s" % [g.amount, g.item.name])
	var used = r.spent.map(func(g): return "-%d %s" % [g.amount, g.item.name])
	var t = "[color=#4ec994]BURST[/color]  5 minutes of %s %s  [color=#888888](%s charge)[/color]\n" % [sk, pn, str(keys[0]).get_slice("/", 1)]
	t += ("  " + ", ".join(parts) if !parts.is_empty() else "  nothing came out (missing inputs?)")
	if !used.is_empty():
		t += "\n  [color=#888888]used: %s[/color]" % ", ".join(used)
	return t

const _SKILLS = ["Mining", "Parsing", "Cracking", "Matching", "Phishing", "Decoding", "Compiling"]

## 'burst -h' (and 'burst' when nothing can burst): what it does, how to use it, and what's ready in every skill
func help_text(note: String = "") -> String:
	var G = "#4ec994"; var D = "#888888"; var Y = "#e3b341"
	var t = "\n[bgcolor=#1a2a1a][color=%s] BURST [/color][/bgcolor]\n" % G
	if note != "":
		t += note + "\n"
	t += "[color=#cccccc]Spend a full process bar to run %d minutes of the process in the main terminal instantly: the same items, XP and VM token chances as %d minutes of running, with its inputs used. The process keeps running.[/color]\n\n" % [int(BURST_SECONDS / 60), int(BURST_SECONDS / 60)]
	t += "[color=%s]HOW IT FILLS[/color]\n" % Y
	t += "  [color=#cccccc]Every process has its own bar: the process cards in its skill's header ('cd <skill>').[/color]\n"
	t += "  [color=#cccccc]A bar fills while its process runs in the main terminal, offline included: %d minutes for a full bar.[/color]\n" % int(FILL_SECONDS / 60)
	t += "  [color=%s]VMs, Hacking and Defragging don't fill bars.[/color]\n\n" % D
	t += "[color=%s]HOW TO USE IT[/color]\n" % Y
	t += "  [color=%s]burst[/color]  [color=#cccccc]while a process runs in the main terminal. It uses a full bar from the same skill: the running process's own first, otherwise any other process of that skill.[/color]\n" % G
	t += "  [color=%s]e.g. Logs' bar is full while you mine Databases: 'burst' runs 5 minutes of Databases.[/color]\n\n" % D
	t += "[color=%s]READY NOW[/color]\n" % Y
	for sk in _SKILLS:
		var node = get_node_or_null("/root/" + sk)
		if node == null:
			continue
		var ready = []
		var best_name = ""
		var best = 0.0
		for p in node.minor_processes:
			if !p.get("unlocked", false):
				continue
			var pr = progress(sk, str(p.name))
			if pr >= 1.0:
				ready.append(str(p.name))
			elif pr > best:
				best = pr
				best_name = str(p.name)
		var line = "  [color=#cccccc]%s[/color]" % sk.rpad(10)
		if !ready.is_empty():
			line += "[color=%s]%d ready[/color] [color=%s](%s)[/color]" % [G, ready.size(), D, ", ".join(ready)]
		else:
			line += "[color=%s]none ready[/color]" % D
		if best_name != "":
			line += "  [color=%s]next: %s %d%%[/color]" % [D, best_name, int(best * 100)]
		t += line + "\n"
	return t

func save_data() -> Dictionary:
	return {"charge": charge}

func load_data(d: Dictionary) -> void:
	charge = {}
	var c = d.get("charge", {})
	if c is Dictionary:
		for k in c:
			charge[str(k)] = float(c[k])
	changed.emit()
