extends VBoxContainer
class_name PhishingTerminal

@onready var phishing_line = preload("res://scenes/phishing_line.tscn")
@onready var active_lines_container = $ActiveLines/MarginContainer/VBoxContainer/ActiveLinesContainer

var is_window: bool = false
var vm_lines = []

func cast_lines(type: Dictionary, lines: int):
	if lines == -1:
		cast_all_lines(type)
	else:
		var line_added = []
		for i in range(lines):
			var new_line = phishing_line.instantiate()
			Phishing.current_lines.append(new_line)
			active_lines_container.add_child(new_line)
			new_line.line_ended_signal.connect(line_ended)
			line_added.append(new_line)
		for line in line_added:
			line.begin(type)
		
		var defrag_bonus = Defragging.PHISHING["bonus efficiency"] if Stats.has_bonus(Phishing) else 1.0
		var base_eff = type["efficiency"] + Phishing.process_upgrades["efficiency"]["amount"]
		var eff_text = str(base_eff * defrag_bonus * 100.0).pad_decimals(1)
		var max_lines = _get_max_lines_count()
		$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text = str(Phishing.current_lines.size()) + "/" + str(max_lines) + " lines in use"
		$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text += "[color=#888888][font_size=12](eff: " + eff_text + "%)[/font_size][/color]"

#vm token specific
func vm_cast_all_lines(type: Dictionary, window: bool = false):
	is_window = window
	var max_lines = _get_max_lines_count()
	for i in range(max_lines):
		var new_line = phishing_line.instantiate()
		active_lines_container.add_child(new_line)
		new_line.line_ended_signal.connect(line_ended)
		vm_lines.append(new_line)
	for line in vm_lines:
		line.begin(type)
	
	$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text = str(Phishing.current_lines.size()) + "/" + str(max_lines) + " lines in use"

#casts all remaining available lines
func cast_all_lines(type: Dictionary, window: bool = false):
	is_window = window
	var line_added = []
	var max_lines = _get_max_lines_count()
	while Phishing.current_lines.size() < max_lines:
		var new_line = phishing_line.instantiate()
		Phishing.current_lines.append(new_line)
		active_lines_container.add_child(new_line)
		new_line.line_ended_signal.connect(line_ended)
		line_added.append(new_line)
	for line in line_added:
		line.begin(type)
		line.caught_something.connect(update_eff_label)
	
	update_eff_label(type)

func update_eff_label(type):
	var defrag_bonus = Defragging.PHISHING["bonus efficiency"] if Stats.has_bonus(Phishing) else 1.0
	var base_eff = type["efficiency"] + Phishing.process_upgrades["efficiency"]["amount"]
	var eff_text = str(base_eff * defrag_bonus * 100.0).pad_decimals(1)
	var max_lines = _get_max_lines_count()
	$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text = str(Phishing.current_lines.size()) + "/" + str(max_lines) + " lines in use\n"
	$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text += "[color=#888888][font_size=12]EFF: " + eff_text + "% chance for bite.[/font_size][/color]"

func _clear_lines():
	if active_lines_container.get_child_count() > 0:
		for node in active_lines_container.get_children():
			node.queue_free()

func line_ended():
	if is_window:
		for lines in vm_lines:
			if lines.active:
				return
		vm_lines.clear()
		Phishing.CURRENT_VMS -= 1
		get_parent().queue_free()
	else:
		for lines in Phishing.current_lines:
			if lines.active:
				return
		remove_lines()
		Signals.end_phishing_safely()

func stop():
	if is_window:
		for line in vm_lines:
			line.stop()
	else:
		if Phishing.current_lines.is_empty():
			return
		for line in Phishing.current_lines:
			line.stop()

func stop_safely():
	if is_window:
		for line in vm_lines:
			line.stop_safely()
	else:
		if Phishing.current_lines.is_empty():
			return
		for line in Phishing.current_lines:
			line.stop_safely()

func remove_lines():
	if Phishing.current_lines.is_empty():
		return
	Phishing.current_lines.clear()

func _get_max_lines_count() -> int:
	var base = Phishing.max_lines
	var upgrades = Upgrades.get_package_info("phishing.lines")
	return base + upgrades.current
