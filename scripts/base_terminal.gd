class_name BaseTerminal
extends Container # Container so PanelContainer and VBoxContainer terminals can both extend it
## Shared lifecycle for skill terminals (Mining, Parsing, ...), whether they run in the
## main terminal or inside a VM window. Subclasses keep their own mechanics and UI and
## use these helpers for speed, heat, stopping and session stats.
##
## Lifecycle:
##   setup_process(skill, data, in_vm)   -> store which skill/process this terminal runs
##   begin_run()                         -> mark running + reset session stats
##   ...subclass loop: get_mode(), get_step_time(mode), apply_heat(mode), record_cycle(yield)
##   stop_safely()  sets stop_requested; subclass calls finish_safely() at a safe point
##   stop()         kills immediately (and frees the VM window when in a VM)

enum Mode { NORMAL, OVERCLOCKED, OVERHEATED }

var skill: Node                  # Mining, Parsing, ...
var process_data: Dictionary     # the minor process dict (Mining.LOGS, ...)
var in_vm: bool = false
var running: bool = false
var stop_requested: bool = false
var _stopped: bool = false       # stop() may be called twice (safe stop + "stop" command)

# session stats, reset by begin_run()
var session_time: float = 0.0
var session_cycles: int = 0
var session_yield: int = 0

func setup_process(p_skill: Node, data: Dictionary, p_in_vm: bool = false) -> void:
	skill = p_skill
	process_data = data
	in_vm = p_in_vm

func begin_run() -> void:
	running = true
	stop_requested = false
	_stopped = false
	session_time = 0.0
	session_cycles = 0
	session_yield = 0

func _process(delta: float) -> void:
	if running:
		session_time += delta

#region speed & heat
## Current system state for this skill. Overclock only counts if this skill has it unlocked.
func get_mode() -> Mode:
	if Stats.overheated:
		return Mode.OVERHEATED
	if Stats.overclocked and Upgrades.can_overclock(skill):
		return Mode.OVERCLOCKED
	return Mode.NORMAL

## Of two modes seen during one cycle, the one that decides its heat (overheat wins, then overclock).
static func worst_mode(a: Mode, b: Mode) -> Mode:
	return max(a, b)

## Seconds per step from the process dict. Speed upgrades shorten normal + overclock steps,
## overheat speed is a fixed penalty.
## Supports fixed speeds ("base speed") or random ranges ("base speed min" / "base speed max").
func get_step_time(mode: Mode) -> float:
	var speed_upgrade = get_speed_upgrade()
	match mode:
		Mode.OVERHEATED:
			return _speed_value("overheat speed")
		Mode.OVERCLOCKED:
			return _speed_value("overclock speed") / (1.0 + speed_upgrade)
		_:
			return _speed_value("base speed") / (1.0 + speed_upgrade)

func _speed_value(key: String) -> float:
	if process_data.has(key):
		return process_data[key]
	return randf_range(process_data[key + " min"], process_data[key + " max"])

## For terminals whose speed is a fill RATE (units per second, e.g. Compiling's bar) instead of
## seconds per step: the speed upgrade multiplies the rate so the bar fills faster.
func get_fill_rate(mode: Mode) -> float:
	match mode:
		Mode.OVERHEATED:
			return _speed_value("overheat speed")
		Mode.OVERCLOCKED:
			return _speed_value("overclock speed") * (1.0 + get_speed_upgrade())
		_:
			return _speed_value("base speed") * (1.0 + get_speed_upgrade())

## Pick one of three process values by mode, for terminals with their own key names
## (e.g. Phishing: "cast time" / "overclock cast time" / "overheat cast time").
func pick_by_mode(mode: Mode, normal_key: String, overclock_key: String, overheat_key: String):
	match mode:
		Mode.OVERHEATED:
			return process_data[overheat_key]
		Mode.OVERCLOCKED:
			return process_data[overclock_key]
		_:
			return process_data[normal_key]

func get_speed_upgrade() -> float:
	var package = Upgrades.get_package_info(skill.SKILL.name.to_lower() + ".speed")
	return package.current if package else 0.0

func get_heat(mode: Mode) -> float:
	match mode:
		Mode.OVERHEATED:
			return process_data["overheat heat"]
		Mode.OVERCLOCKED:
			return process_data["overclock heat"]
		_:
			return process_data["heat"]

func apply_heat(mode: Mode) -> void:
	Stats.update_tempature(get_heat(mode))
#endregion

#region stopping
## Finish the current cycle, then stop. Subclasses check stop_requested at a safe point.
func stop_safely() -> void:
	stop_requested = true

## Call at the safe point after stop_safely(): tells the main terminal it ended (when not in a VM), then stops.
func finish_safely() -> void:
	if !in_vm:
		Signals.process_ended_safely(skill)
	stop()

## Stop immediately. In a VM this also closes the window.
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	running = false
	_on_stopped()
	if in_vm:
		VMManager.release(self) # frees the VM window (and this terminal)

## Override for terminal-specific cleanup (timers, tweens...).
func _on_stopped() -> void:
	pass
#endregion

func record_cycle(amount_gained: int) -> void:
	session_cycles += 1
	session_yield += amount_gained

static func format_time(total_seconds: float) -> String:
	var seconds: int = int(total_seconds) % 60
	var minutes: int = int(total_seconds / 60) % 60
	var hours: int = int(total_seconds / 3600)
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
