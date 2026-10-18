class_name PhishingTerminal
extends BaseTerminal
## Phishing terminal. "lines" processes (Spear, Mod) run Phishing.max_lines + "phishing.lines" lines that
## each cast on their own. Whaling / Smish / Trap run one line that uses every line at once (see
## phishing_line.gd). Lines ask this terminal for mode / timing / heat / bite chance / bait / tokens so the
## rules match every other skill.

@onready var phishing_line = preload("res://scenes/phishing_line.tscn")
@onready var phishing_total_col = preload("res://scenes/phishing_total_col.tscn")
@onready var active_lines_container = $ActiveLines/MarginContainer/VBoxContainer/ActiveLinesContainer
@onready var totals_row = $ActiveLines/MarginContainer/VBoxContainer/TotalsRow
@onready var slots_label = $ActiveLines/MarginContainer/VBoxContainer/SlotsLabel
@onready var title_label = $ActiveLines/MarginContainer/VBoxContainer/TitleRow/Title

var vm_lines = []
var bait: ItemData = null       # Mining item, Phishing.BAIT_PER_CAST used per cast: bite chance up, catch doubled
var smish_target: Dictionary = {} # Smish: chosen target ({} = random unlocked target that isn't maxed)

## Main terminal lines live in Phishing.current_lines; a VM keeps its own.
func _my_lines() -> Array:
	return vm_lines if in_vm else Phishing.current_lines

func style() -> String:
	return process_data.get("style", "lines")

## Main terminal entry point (idle_os_2.cast_line). Always casts every available line.
func cast_lines(p_type: Dictionary, _lines: int = -1, p_bait: ItemData = null, p_target: Dictionary = {}):
	bait = p_bait
	smish_target = p_target
	_start(p_type, false)

## VM window entry point.
func vm_cast_all_lines(p_type: Dictionary, window: bool = false, p_bait: ItemData = null, p_target: Dictionary = {}):
	bait = p_bait
	smish_target = p_target
	_start(p_type, window)

func _start(p_type: Dictionary, window: bool) -> void:
	setup_process(Phishing, p_type, window)
	begin_run()
	_connect_upgrade_signal()
	_update_title()
	if style() == "lines":
		while _my_lines().size() < _get_max_lines_count():
			_spawn_line()
	else:
		_spawn_line()
	# totals row so the player sees inventory counts of everything they can catch
	var shown = []
	for entry in reward_list() if style() != "smish" else []:
		if !(entry.item in shown):
			shown.append(entry.item)
			var new_col = phishing_total_col.instantiate()
			new_col.set_item(entry.item)
			totals_row.add_child(new_col)
	update_eff_label(p_type)

## What a "lines" catch rolls from (Mod: only mods whose tier is unlocked)
func reward_list() -> Array:
	if process_data == Phishing.MOD:
		return Phishing.mod_pool()
	return process_data["resource gained"] if process_data["resource gained"] is Array else []

func _spawn_line() -> void:
	var new_line = phishing_line.instantiate()
	_my_lines().append(new_line)
	active_lines_container.add_child(new_line)
	new_line.line_ended_signal.connect(line_ended)
	new_line.caught_something.connect(update_eff_label)
	new_line.begin(process_data, self)

func _connect_upgrade_signal() -> void:
	if not Signals.phishing_lines_increase_upgrade_while_running_signal.is_connected(lines_upgrade_while_running):
		Signals.phishing_lines_increase_upgrade_while_running_signal.connect(lines_upgrade_while_running)

func _disconnect_upgrade_signal() -> void:
	if Signals.phishing_lines_increase_upgrade_while_running_signal.is_connected(lines_upgrade_while_running):
		Signals.phishing_lines_increase_upgrade_while_running_signal.disconnect(lines_upgrade_while_running)

func _update_title() -> void:
	match style():
		"whale": title_label.text = "Whaling"
		"smish": title_label.text = "Smishing"
		"trap": title_label.text = "Setting a trap"
		_: title_label.text = "Active lines"
	if !modifier.is_empty():
		title_label.text += " · " + modifier.name.to_upper()

func update_eff_label(_p_type = null):
	var eff_text = str(get_bite_chance(false) * 100.0).pad_decimals(1)
	var lines = _get_max_lines_count()
	match style():
		"whale":
			var reel: float = step_seconds(get_mode(), "download time", "overclocked download time", "overheated download time", true)
			slots_label.text = "%d lines on one whale: reeling takes %ds (%ds split across %d lines)\n" % [lines, roundi(reel / lines), roundi(reel), lines]
			slots_label.text += "[color=#888888][font_size=12]EFF: " + eff_text + "% chance the whale bites."
		"smish":
			slots_label.text = "%d texts per blast (%d per line)  ·  intel on %s\n" % [Phishing.SMISH["texts per line"] * lines, Phishing.SMISH["texts per line"], smish_target.name if !smish_target.is_empty() else "random targets"]
			slots_label.text += "[color=#888888][font_size=12]EFF: " + eff_text + "% reply chance per text."
		"trap":
			slots_label.text = "Trap fills over %s of real time (even offline)\n" % Phishing.format_minutes(Phishing.trap_seconds_total())
			slots_label.text += "[color=#888888][font_size=12]EFF: " + eff_text + "% rare roll chance on a full trap."
		_:
			slots_label.text = str(_my_lines().size()) + "/" + str(lines) + " lines in use\n"
			slots_label.text += "[color=#888888][font_size=12]EFF: " + eff_text + "% chance for bite."
	if bait:
		var baited = str(get_bite_chance(true) * 100.0).pad_decimals(1)
		slots_label.text += "  BAIT: %s x%d (-%d/cast, %s%%, catch x2)" % [bait.name, Inventory.get_amount(bait), Phishing.BAIT_PER_CAST, baited]
	slots_label.text += "[/font_size][/color]"

## A line finished. Lines only end on their own after stop_safely() (or a trap is set); once all are done, finish.
func line_ended():
	if !running:
		return # killed: stop() already cleaned up
	for line in _my_lines():
		if line.active:
			return
	finish_safely()

## Each line finishes its current attempt, then ends.
func stop_safely():
	super()
	for line in _my_lines():
		line.stop_safely()

func _on_stopped():
	_disconnect_upgrade_signal()
	for line in _my_lines():
		if is_instance_valid(line):
			line.stop()
	_my_lines().clear()

func _get_max_lines_count() -> int:
	return Phishing.max_lines + int(Upgrades.cur("phishing.lines"))

## Lines working this process (whale / smish put every line on their one attempt)
func line_count() -> int:
	return _get_max_lines_count()

func _get_total_eff() -> float:
	return Phishing.get_efficiency(process_data)

## Bite chance for one cast, capped at 100%. Bait multiplies it (so rare catches stay rare).
func get_bite_chance(baited: bool) -> float:
	var chance = _get_total_eff() * (Phishing.get_bait_multiplier(bait) if baited else 1.0)
	return min(chance, 1.0)

## Called as a line casts: uses Phishing.BAIT_PER_CAST bait if there's that much left.
## Bait Recycling: a chance the cast is baited without using any.
func take_bait() -> bool:
	if bait and Inventory.get_amount(bait) >= Phishing.BAIT_PER_CAST:
		if randf() >= Upgrades.cur("phishing.bait_recycling"):
			Inventory.remove_resource(bait, Phishing.BAIT_PER_CAST)
		update_eff_label()
		return true
	return false

## Seconds for one step, picked by mode. Speed upgrades and the modifier speed shorten normal and
## overclock steps (overheat is a fixed penalty, like every skill). reel: Quick Hook also shortens it.
func step_seconds(mode: Mode, normal_key: String, overclock_key: String, overheat_key: String, reel: bool = false) -> float:
	var t: float = pick_by_mode(mode, normal_key, overclock_key, overheat_key)
	if mode != Mode.OVERHEATED:
		t = t / (1.0 + get_speed_upgrade()) / modifier_speed()
	if reel:
		t *= 1.0 - Upgrades.cur("phishing.quick_hook")
	return t

## Waiting for a response: the process's random wait, shortened by speed like the other steps
func wait_seconds(mode: Mode) -> float:
	var t = randf_range(process_data["wait time min"], process_data["wait time max"])
	if mode != Mode.OVERHEATED:
		t = t / (1.0 + get_speed_upgrade()) / modifier_speed()
	return t

## What a catch of <amount> becomes: bait x2, Chum x2, Survey halves it (coin flip on odd amounts).
func catch_amount(amount: int, baited: bool) -> int:
	amount *= (2 if baited else 1) * (2 if has_modifier("chum") else 1)
	if has_modifier("survey"):
		amount = amount / 2 + (1 if amount % 2 == 1 and randf() < 0.5 else 0)
	return amount

## XP for a catch (Survey doubles it)
func catch_xp(xp: int) -> int:
	return xp * (2 if has_modifier("survey") else 1)

## Lure: a chance per catch to also hook a hacking mod from the unlocked pool. Returns it or null.
func roll_lure() -> ItemData:
	if !has_modifier("lure") or randf() >= Phishing.LURE_CHANCE:
		return null
	var pool = Phishing.mod_pool()
	return pool.pick_random().item if !pool.is_empty() else null

## Modifiers don't apply to setting a Trap
func modifier_block_reason() -> String:
	return "Modifiers don't work while setting a trap." if style() == "trap" else ""

## VM tokens for an attempt that took <seconds>: a bonus on top of the catch. The process's chance is for
## one base-speed attempt, scaled by how long this one took (speed doesn't change tokens per hour);
## "lines" processes scale by 3 / lines so extra lines don't either.
func roll_tokens(seconds: float) -> void:
	var share = float(Phishing.BASE_LINES) / max(1.0, float(_my_lines().size())) if style() == "lines" else 1.0
	var expected = float(process_data.get("vm token chance", 0.01)) * seconds / Phishing.base_attempt_seconds(process_data) * share
	if Upgrades.has("phishing.tackle_box"):
		expected *= 2.0
	if has_modifier("chum"):
		expected *= 2.0
	var n = Phishing.roll_tokens(expected)
	if n > 0:
		Inventory.add_resource(Items.VM_PHISHING_TOKEN, n)

func lines_upgrade_while_running():
	if !running or stop_requested or style() != "lines":
		return
	# while, not if, so an upgrade of +2 (or a desynced count) fills every slot
	while _my_lines().size() < _get_max_lines_count():
		_spawn_line()
	update_eff_label()
