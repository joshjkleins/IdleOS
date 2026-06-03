extends VBoxContainer
class_name PhishingTerminal

@onready var phishing_line = preload("res://scenes/phishing_line.tscn")
@onready var active_lines_container = $ActiveLines/MarginContainer/VBoxContainer/ActiveLinesContainer


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
		
		$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text = str(Phishing.current_lines.size()) + "/" + str( Phishing.max_lines + Phishing.process_upgrades["max lines"]["amount"]) + " lines in use"

#casts all remaining available lines
func cast_all_lines(type: Dictionary):
	var line_added = []
	while Phishing.current_lines.size() < Phishing.max_lines + Phishing.process_upgrades["max lines"]["amount"]:
		var new_line = phishing_line.instantiate()
		Phishing.current_lines.append(new_line)
		active_lines_container.add_child(new_line)
		new_line.line_ended_signal.connect(line_ended)
		line_added.append(new_line)
	for line in line_added:
		line.begin(type)
	
	$ActiveLines/MarginContainer/VBoxContainer/SlotsLabel.text = str(Phishing.current_lines.size()) + "/" + str( Phishing.max_lines + Phishing.process_upgrades["max lines"]["amount"]) + " lines in use"

func _clear_lines():
	if active_lines_container.get_child_count() > 0:
		for node in active_lines_container.get_children():
			node.queue_free()

func line_ended():
	for lines in Phishing.current_lines:
		if lines.active:
			return
	remove_lines()
	print('lines removed')
	Signals.end_phishing_safely()

func stop():
	if Phishing.current_lines.is_empty():
		return
	for line in Phishing.current_lines:
		line.stop()

func stop_safely():
	if Phishing.current_lines.is_empty():
		return
	for line in Phishing.current_lines:
		line.stop_safely()

func remove_lines():
	if Phishing.current_lines.is_empty():
		return
	Phishing.current_lines.clear()
