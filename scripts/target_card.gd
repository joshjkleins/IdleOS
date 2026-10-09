extends PanelContainer

var target

func update_info(info):
	target = info
	if info.unlocked:
		var reg_cmd = "Command: '" + info["command"] + "'"
		var hm_cmd = "\n" + "[color=#666666]Hard mode command: '" + info['hard mode command'] + "'[/color]"
		if info['hard mode unlocked']:
			hm_cmd = "\n" + "Hard mode command: '" + info['hard mode command'] + "'"
			
		$MarginContainer/VBoxContainer/VBoxContainer/Command.text = reg_cmd + hm_cmd
	else:
		$MarginContainer/VBoxContainer/VBoxContainer/Command.text = "DEMO LOCKED"
	$MarginContainer/VBoxContainer/VBoxContainer/Title.text = info["name"]
	$MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/Difficulty.text = "Difficulty " + info["difficulty"]
	$MarginContainer/VBoxContainer/TextureRect.texture = info["art"]

func selected():
	pass

func flash_green():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#3dff95"), 0.15)
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished

func flash_red():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#ff5a3d"), 0.15)
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished
