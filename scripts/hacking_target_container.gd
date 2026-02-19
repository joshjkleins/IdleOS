extends Control

#to add art: make pixel art image
# convert to image to ascii
# download png and remove background
# import to project, assign to Stats.hacking_target art property

func update_info(info):
	$PanelContainer/MarginContainer/VBoxContainer/FirstRow/command.text = "Command " + info["command"]
	$PanelContainer/MarginContainer/VBoxContainer/FirstRow/title.text = info["title"]
	$PanelContainer/MarginContainer/VBoxContainer/SecondRow/difficulty.text = "Difficulty " + info["difficulty"]
	$PanelContainer/TextureRect.texture = info["art"]
