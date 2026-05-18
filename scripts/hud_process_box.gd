extends PanelContainer

func update(process: Dictionary, major: bool = true):
	if !major:
		$MarginContainer/VBoxContainer/Label.text = process.name + " " + str(process.level) + "/99"
	else:
		$MarginContainer/VBoxContainer/Label.text = process.name + " LVL" + str(process.level)
	var experience = Exp.get_xp_display(process)
	$MarginContainer/VBoxContainer/ProgressBar.max_value = experience["needed"]
	$MarginContainer/VBoxContainer/ProgressBar.value = experience["current"]
