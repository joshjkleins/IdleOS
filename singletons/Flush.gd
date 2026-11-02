extends Node
## 2026-11-02 (Josh): flush (was "burst"). Every process of a skill has a buffer (the bar on its card in the skill's
## header, unused since process levels were retired). A buffer fills while ITS process runs in the main terminal
## (offline too, never in a VM), FILL_SECONDS of running to fill, the same pace for every process. 'flush' empties one
## full buffer of the running process's skill (its own first) to instantly run FLUSH_SECONDS of the main terminal's
## process (Offline's simulation: the same gains, inputs used, XP).

signal changed

const FILL_SECONDS := 3600.0 # 60 min of running per bar
const FLUSH_SECONDS := 300.0  # what one full buffer runs instantly

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
			Signals.system_message_signal.emit("[color=#4ec994]%s %s buffer full:[/color] 'flush' runs 5 minutes of the main terminal's %s process instantly." % [skill_name, process_name, skill_name])

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

## 'flush': the result text
func use() -> String:
	var m = _main_process()
	if m.is_empty():
		return help_text("[color=#d29922]Nothing to flush: start a process in the main terminal first (not Hacking or Defragging, not in a VM).[/color]")
	var sk = str(m[0].SKILL.name)
	var pn = str(m[1].name)
	var keys = full_keys(sk, pn)
	if keys.is_empty():
		return help_text("[color=#d29922]No %s buffer is full yet.[/color]" % sk)
	var r = Offline.flush(FLUSH_SECONDS)
	if r.has("error"): # processes that don't run offline (Cracking VM conversion, setting a Trap)
		return "[color=#d29922]%s %s can't be flushed: it only runs live. Start another %s process to use the buffer.[/color]" % [sk, pn, sk]
	charge[keys[0]] = 0.0
	SaveManager.mark_dirty()
	drained.emit(str(keys[0]).get_slice("/", 0), str(keys[0]).get_slice("/", 1))
	changed.emit()
	var parts = r.gains.map(func(g): return "+%d %s" % [g.amount, g.item.name])
	var used = r.spent.map(func(g): return "-%d %s" % [g.amount, g.item.name])
	var t = "[color=#4ec994]FLUSH[/color]  5 minutes of %s %s  [color=#888888](%s buffer)[/color]\n" % [sk, pn, str(keys[0]).get_slice("/", 1)]
	t += ("  " + ", ".join(parts) if !parts.is_empty() else "  nothing came out (missing inputs?)")
	if !used.is_empty():
		t += "\n  [color=#888888]used: %s[/color]" % ", ".join(used)
	return t

const _SKILLS = ["Mining", "Parsing", "Cracking", "Matching", "Phishing", "Decoding", "Compiling"]

## 'flush -h' (and 'flush' when nothing can flush): what it does, how to use it, and what's ready in every skill
func help_text(note: String = "") -> String:
	var G = "#4ec994"; var D = "#888888"; var Y = "#e3b341"
	var t = "\n[bgcolor=#1a2a1a][color=%s] FLUSH [/color][/bgcolor]\n" % G
	if note != "":
		t += note + "\n"
	t += "[color=#cccccc]Flush a full process buffer to run %d minutes of the process in the main terminal instantly: the same items, XP and VM token chances as %d minutes of running, with its inputs used. The process keeps running.[/color]\n\n" % [int(FLUSH_SECONDS / 60), int(FLUSH_SECONDS / 60)]
	t += "[color=%s]HOW IT FILLS[/color]\n" % Y
	t += "  [color=#cccccc]Every process has its own buffer: the bar on its card in its skill's header ('cd <skill>').[/color]\n"
	t += "  [color=#cccccc]A buffer fills while its process runs in the main terminal, offline included: %d minutes to fill.[/color]\n" % int(FILL_SECONDS / 60)
	t += "  [color=%s]VMs, Hacking and Defragging don't fill buffers.[/color]\n\n" % D
	t += "[color=%s]HOW TO USE IT[/color]\n" % Y
	t += "  [color=%s]flush[/color]  [color=#cccccc]while a process runs in the main terminal. It empties a full buffer from the same skill: the running process's own first, otherwise any other process of that skill.[/color]\n" % G
	t += "  [color=%s]e.g. Logs' buffer is full while you mine Databases: 'flush' runs 5 minutes of Databases.[/color]\n\n" % D
	t += "[color=%s]FULL NOW[/color]\n" % Y
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
			line += "[color=%s]%d full[/color] [color=%s](%s)[/color]" % [G, ready.size(), D, ", ".join(ready)]
		else:
			line += "[color=%s]none full[/color]" % D
		if best_name != "":
			line += "  [color=%s]next: %s %d%%[/color]" % [D, best_name, int(best * 100)]
		t += line + "\n"
	return t

func save_data() -> Dictionary:
	return {"charge": charge}

## a buffer was just flushed (skill_header drains its bar)
signal drained(skill_name: String, process_name: String)

func load_data(d: Dictionary) -> void:
	charge = {}
	var c = d.get("charge", {})
	if c is Dictionary:
		for k in c:
			charge[str(k)] = float(c[k])
	changed.emit()
