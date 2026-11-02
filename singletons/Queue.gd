extends Node
## 2026-11-02 (Josh): the command queue. Up to slots() main-terminal commands that run one after another and repeat:
## when a step's process ends (its N cycles are done, or it ran out of inputs) the next starts; a step that can't
## start is skipped; a pass where nothing could start stops the queue. Opens with the Lawfirm (School's upload goal
## done): 2 slots, +1 per location after (6 at Government). Steps are any skill command (not hacking, not defrag),
## with an optional cycle count and modifier ('mine -logs 10 survey'). A step without a count runs as long as its
## process does - 'mine -logs' never ends (the queue does exactly what it's told).
## While it runs it owns the main terminal: no other process, no Hacking ('queue -kill' first: stops the step at once,
## the queue waits on it - 'queue run' restarts it, 'queue run <n>' starts at step n). Offline (Offline._run_queue):
## the queue keeps cycling its steps for half the capped away time, then resumes the step it got to.

signal changed

const VERBS = ["mine", "parse", "crack", "match", "phish", "decode", "compile"]

var steps: Array = []   # command strings
var running := false
var index := 0          # the step running (or next to start)
var _active := false    # the current step's process was started by the queue and is running
var _fails := 0         # steps skipped in a row (a whole pass of them stops the queue)
var _accum := 0.0
var _starting := false
var _resume_pending := false # loaded running: wait for the welcome back (and its resume of the step) first

func unlocked() -> bool:
	return 1 in Uploads.completed_tiers

func slots() -> int:
	return 0 if !unlocked() else clampi(Uploads.current_tier() if Uploads.completed_tiers.size() < Uploads.MAX_TIER else Uploads.MAX_TIER, 2, 6)

func _os() -> Node:
	return get_tree().get_first_node_in_group("main_os") if get_tree() else null

## "" when <cmd> can be a step, otherwise why not
func step_problem(cmd: String) -> String:
	var words = cmd.strip_edges().to_lower().split(" ", false)
	if words.is_empty():
		return "Give a command to queue, e.g. 'queue -add mine -logs 25'."
	if words[0] in ["hack", "defrag", "cd", "ssh"]:
		return "Only skill processes can be queued (mine, parse, crack, match, phish, decode, compile): no Hacking, Defragging or VMs."
	if !(words[0] in VERBS):
		return "'%s' isn't a process command. Queue things like 'mine -logs 25' or 'crack -password'." % words[0]
	if words.size() < 2:
		return "Say which process: e.g. '%s -%s'." % [words[0], "logs" if words[0] == "mine" else "..."]
	return ""

#region commands
## 'queue ...' from the main terminal: the text to print
func handle(text: String) -> String:
	var t = text.strip_edges()
	# 2026-11-02 (Josh): flags take a dash like every other command ('queue -add', '-rm', '-run', '-pause', '-kill',
	# '-ls'); the bare words still work
	for w in ["add", "rm", "run", "pause", "kill", "ls", "start", "stop", "list", "resume", "set", "ins"]:
		if t.to_lower().begins_with("queue -" + w):
			t = "queue " + t.substr(7)
			break
	var low = t.to_lower()
	if !unlocked():
		return "The queue opens with Lawfirm access (complete the School upload goal)."
	if low in ["queue", "queue -h", "queue help", "queue ls", "queue list"]:
		return status_text(low != "queue ls" and low != "queue list")
	if low.begins_with("queue add "):
		var cmd = t.substr(10).strip_edges().to_lower()
		var why = step_problem(cmd)
		if why != "":
			return "[color=#e26d5a]%s[/color]" % why
		if steps.size() >= slots():
			return "[color=#e26d5a]All %d queue slots are used. 'queue -rm <n>' or 'queue -rm -a' to make room.[/color]" % slots()
		steps.append(cmd)
		_changed()
		return "Queued [color=#4ec994]%s[/color] as step %d (%d of %d slots)." % [cmd, steps.size() - 1, steps.size(), slots()]
	# 2026-11-02 (Josh): edit in place - 'queue -set <n> <command>' replaces step n, 'queue -ins <n> <command>' inserts
	# at n and pushes the rest down (the list never has holes)
	if low.begins_with("queue set ") or low.begins_with("queue ins "):
		var is_set = low.begins_with("queue set ")
		var parts = t.substr(10).strip_edges().split(" ", false, 1)
		var top = steps.size() - 1 if is_set else steps.size()
		if parts.size() < 2 or !parts[0].is_valid_int() or int(parts[0]) < 0 or int(parts[0]) > top:
			if is_set and steps.is_empty():
				return "The queue is empty: 'queue -add <command>' first."
			return "usage: queue -%s <n> <command>  (n: 0-%d)" % ["set" if is_set else "ins", max(0, top)]
		var n = int(parts[0])
		var cmd = parts[1].strip_edges().to_lower()
		var why = step_problem(cmd)
		if why != "":
			return "[color=#e26d5a]%s[/color]" % why
		if is_set:
			var old = steps[n]
			steps[n] = cmd
			_changed()
			return "Step %d is now [color=#4ec994]%s[/color] (was %s)%s." % [n, cmd, old, " - from its next run (it's running now)" if running and n == index and _active else ""]
		if steps.size() >= slots():
			return "[color=#e26d5a]All %d queue slots are used. 'queue -set <n> <command>' replaces a step instead.[/color]" % slots()
		steps.insert(n, cmd)
		if running and n <= index and steps.size() > 1:
			index += 1 # keep pointing at the step that's running
		_changed()
		return "Inserted [color=#4ec994]%s[/color] as step %d (%d of %d slots)." % [cmd, n, steps.size(), slots()]
	if low.begins_with("queue rm"):
		var arg = low.trim_prefix("queue rm").strip_edges()
		if arg in ["-a", "-all", "all"]:
			if running:
				return "Stop the queue first ('queue -kill')."
			steps.clear()
			index = 0
			_changed()
			return "Queue cleared."
		if !arg.is_valid_int() or int(arg) < 0 or int(arg) >= steps.size(): # steps count from 0 (2026-11-02, Josh)
			return "usage: queue -rm <n> (0-%d)  ·  queue -rm -a" % max(0, steps.size() - 1)
		if running and int(arg) == index:
			return "Step %d is running. Stop the queue first ('queue -kill')." % int(arg)
		var n = int(arg)
		var gone = steps[n]
		steps.remove_at(n)
		if n < index:
			index -= 1
		index = 0 if steps.is_empty() else index % steps.size()
		_changed()
		return "Removed step %d (%s)." % [n, gone]
	if low in ["queue run", "queue start", "queue resume"]:
		return start()
	if low.begins_with("queue run "): # 'queue run 3': start at step 3
		var n = low.trim_prefix("queue run ").strip_edges()
		if !n.is_valid_int() or int(n) < 0 or int(n) >= steps.size():
			return "usage: queue -run <n> (0-%d)" % max(0, steps.size() - 1)
		if running:
			return "The queue is already running. 'queue -kill' first."
		index = int(n)
		return start()
	if low in ["queue -kill", "queue kill", "queue stop", "queue -k"]:
		return kill()
	if low in ["queue pause", "queue -s"]:
		return pause()
	return "Unknown queue command. 'queue -h' lists them."

func start() -> String:
	if steps.is_empty():
		return "The queue is empty. Add steps with 'queue -add <command>'."
	if running:
		return "The queue is already running."
	var os = _os()
	if os and os.process_running:
		return "A process is running in the main terminal. Stop it first ('stop'), then 'queue -run'."
	running = true
	_active = false
	_fails = 0
	index = clampi(index, 0, steps.size() - 1)
	_changed()
	return "[color=#4ec994]Queue running[/color] from step %d. It owns the main terminal until 'queue -kill'." % index

## 'queue -kill' (and 'stop'): the queue stops and the running step is killed right away (overheated or mid-way
## through a long cycle, control comes back at once). The step it was on starts again on 'queue run'.
func kill() -> String:
	if !running:
		return "The queue isn't running."
	running = false
	var was_active = _active
	_active = false
	var os = _os()
	if was_active and os and os.process_running:
		os.kill_main_process()
	_changed()
	return "Queue stopped: step %d was killed. 'queue -run' restarts it, 'queue -run <n>' starts at another step." % index

## 'queue pause' / 'stop -s': stops the queue after the current step's cycle; the step it was on resumes next time
func pause(quiet: bool = false) -> String:
	if !running:
		return "The queue isn't running."
	running = false
	var os = _os()
	if _active and os and os.process_running and os.current_process and os.current_process.has_method("stop_safely"):
		os.current_process.stop_safely()
	_active = false
	_changed()
	return "" if quiet else "Queue paused: the current step finishes its cycle, then the main terminal is free ('queue -kill' stops it now). 'queue -run' resumes at step %d." % index
#endregion

#region running
func _process(delta: float) -> void:
	if !running or _starting:
		return
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	var os = _os()
	if os == null or !os.accepting_player_inputs or get_tree().paused:
		return
	if os.get("_hold_unlocks") or os.get("_booting") or os.get("_ending_playing"):
		return # 2026-11-02: the boot / welcome back is still on screen (the step used to start over it)
	if _resume_pending: # the welcome back resumed the step it was on (or nothing ran): carry on from there
		_resume_pending = false
		_active = os.process_running
		if !_active and Offline.limited_run_done: # the step's count finished while away: on to the next one
			Offline.limited_run_done = false
			index = (index + 1) % max(1, steps.size())
		_changed()
		return
	if os.process_running:
		return # the current step is still going
	if _active: # the step's process ended: next one
		_active = false
		index = (index + 1) % max(1, steps.size())
		_changed()
	_start_step(os)

func _start_step(os: Node) -> void:
	if steps.is_empty():
		running = false
		_changed()
		return
	_starting = true
	index = index % steps.size()
	var cmd = steps[index]
	os.run_queued(cmd, index, steps.size())
	await get_tree().process_frame
	_starting = false
	if !running:
		return
	if os.process_running:
		_active = true
		_fails = 0
	else:
		_fails += 1
		if _fails >= steps.size():
			running = false
			os.add_line("[color=#d29922]Queue stopped: none of its %d step%s could run (out of inputs?).[/color]" % [steps.size(), "" if steps.size() == 1 else "s"])
		else:
			index = (index + 1) % steps.size()
	_changed()

func _changed() -> void:
	SaveManager.mark_dirty()
	changed.emit()
#endregion

#region text
func status_text(help: bool = true) -> String:
	var G = "#4ec994"; var D = "#888888"; var Y = "#e3b341"
	var t = "\n[bgcolor=#1a2a1a][color=%s] QUEUE [/color][/bgcolor]  [color=%s]%d/%d slots · %s[/color]\n" % [G, D, steps.size(), slots(), ("running step %d" % index) if running else "paused"]
	if steps.is_empty():
		t += "  [color=%s](empty)[/color]\n" % D
	for i in steps.size():
		var cur = running and i == index
		t += "  [color=%s]%d[/color]  [color=%s]%s[/color]%s\n" % [Y if cur else D, i, G if cur else "#cccccc", steps[i], "  [color=%s]< running[/color]" % G if cur else ""]
	if !help:
		return t
	t += "\n[color=%s]Steps run one after another in the main terminal, then the queue starts over. A step ends when its count is done ('mine -logs 25') or its process runs out of inputs; without a count, a step runs as long as its process would ('mine -logs' never ends). A step that can't start is skipped; if none can, the queue stops.[/color]\n" % D
	t += "[color=%s]While it runs, the queue owns the main terminal: no other process, and no Hacking until 'queue -kill'.[/color]\n\n" % D
	for row in [["queue -add <command>", "add a step: 'queue -add mine -logs 25', 'queue -add parse -footprint=logs 25 survey'"],
			["queue -set <n> <command>", "replace step n"], ["queue -ins <n> <command>", "insert at step n (the rest move down)"],
			["queue -rm <n>", "remove step n  ·  'queue -rm -a' clears it"], ["queue -run", "start (or resume) at the step it's on"], ["queue -run <n>", "start at step n"],
			["queue -kill", "stop now: the running step is killed ('stop' does the same)"], ["queue -pause", "stop after the current cycle"], ["queue -ls", "the steps"]]:
		t += "  [color=%s]%s[/color]  [color=%s]%s[/color]\n" % [G, row[0].rpad(25), D, row[1]]
	return t
#endregion

func save_data() -> Dictionary:
	return {"steps": steps, "running": running, "index": index}

func load_data(d: Dictionary) -> void:
	steps = Array(d.get("steps", [])).map(func(s): return str(s))
	index = int(d.get("index", 0))
	running = bool(d.get("running", false))
	_active = false
	_resume_pending = running # the welcome back resumes the step; the queue picks up once it's done
	_fails = 0
	changed.emit()
