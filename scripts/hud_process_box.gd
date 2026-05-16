extends PanelContainer

func update(process: Dictionary):
	$MarginContainer/VBoxContainer/Label.text = process.name + " LVL " + str(process.level)
	
	var experience = Stats.get_xp_display(process)
	$MarginContainer/VBoxContainer/ProgressBar.max_value = experience["needed"]
	$MarginContainer/VBoxContainer/ProgressBar.value = experience["current"]
