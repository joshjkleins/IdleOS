extends HBoxContainer

func update_labels(skill): #dictionary (minor process)
	$MarginContainer/VBoxContainer/NameLabel.text = skill.name
	$MarginContainer/VBoxContainer/NameLabel.add_theme_color_override("font_color", skill.skill.SKILL.color)
	if skill.unlocked:
		$MarginContainer/VBoxContainer/Locked.visible = false
		$MarginContainer/VBoxContainer/InfoContainer.visible = true
		$MarginContainer/VBoxContainer/InfoContainer/VBoxContainer/DurationDesc.text = str(skill["bonus time"]) + " min"
		$MarginContainer/VBoxContainer/InfoContainer/VBoxContainer2/EffectDesc.text = "efficiency x" + str(skill["bonus efficiency"])
	else:
		$MarginContainer/VBoxContainer/Locked.visible = true
		$MarginContainer/VBoxContainer/InfoContainer.visible = false
