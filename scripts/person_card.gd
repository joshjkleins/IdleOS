extends PanelContainer

var target

func update_info(info):
	target = info
	$MarginContainer/VBoxContainer/VBoxContainer/Title.text = info["name"]
	$MarginContainer/VBoxContainer/VBoxContainer/Command.text = "Command " + info["command"]
	$MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/Difficulty.text = "Difficulty " + info["difficulty"]
	
	var loot_text = ""
	for loot in info.loot:
		loot_text += loot + "\n"
	$MarginContainer/VBoxContainer/VBoxContainer/Loot.text = loot_text

func flash_green():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#3dff95"), 0.15)
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished
