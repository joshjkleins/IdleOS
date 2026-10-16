class_name PhishingTerminal
extends BaseTerminal
## Phishing terminal: runs several independent lines at once (Phishing.max_lines + "phishing.lines"
## upgrades). Each line casts, waits for a response, rolls efficiency for a bite, downloads the catch
## and recasts. Lines ask this terminal for mode / timing / heat so the rules match every other skill.

@onready var phishing_line = preload("res://scenes/phishing_line.tscn")
@onready var phishing_total_col = preload("res://scenes/phishing_total_col.tscn")
@onready var active_lines_container = $ActiveLines/MarginContainer/VBoxContainer/ActiveLinesContainer
@onready var totals_row = $ActiveLines/MarginContainer/VBoxContainer/TotalsRow
@onready var slots_label = $ActiveLines/MarginContainer/VBoxContainer/SlotsLabel

var vm_lines = []

## Main terminal lines live in Phishing.current_lines; a VM keeps its own.
func _my_lines() -> Array:
	return vm_lines if in_vm else Phishing.current_lines

## Main terminal entry point (idle_os_2.cast_line). Always casts every available line.
func cast_lines(p_type: Dictionary, _lines: int = -1):
	_start(p_type, false)

## VM window entry point.
func vm_cast_all_lines(p_type: Dictionary, window: bool = false):
	_start(p_type, window)

func _start(p_type: Dictionary, window: bool) -> void:
	setup_process(Phishing, p_type, window)
	begin_run()
	_connect_upgrade_signal()
	while _my_lines().size() < _get_max_lines_count():
		_spawn_line()
	# totals row so the player sees inventory counts of everything they can catch
	for item in p_type["resource gained"]:
		var new_col = phishing_total_col.instantiate()
		new_col.set_item(item.item)
		totals_row.add_child(new_col)
	update_eff_label(p_type)

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

func update_eff_label(p_type = null):
	var eff_text = str(_get_total_eff() * 100.0).pad_decimals(1)
	slots_label.text = str(_my_lines().size()) + "/" + str(_get_max_lines_count()) + " lines in use\n"
	slots_label.text += "[color=#888888][font_size=12]EFF: " + eff_text + "% chance for bite.[/font_size][/color]"

## A line finished. Lines only end on their own after stop_safely(); once all are done, finish.
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
	return Phishing.max_lines + Upgrades.get_package_info("phishing.lines").current

func _get_total_eff() -> float:
	###NOTE : NO PHISHING EFFICIENCY UPGRADE YET. if efficiency upgrade is added to APT then need to add here too
	var defrag_bonus = Defragging.PHISHING["bonus efficiency"] if Stats.has_bonus(Phishing) else 1.0
	return process_data["efficiency"] * defrag_bonus

func lines_upgrade_while_running():
	if !running or stop_requested:
		return
	# while, not if, so an upgrade of +2 (or a desynced count) fills every slot
	while _my_lines().size() < _get_max_lines_count():
		_spawn_line()
	update_eff_label()
