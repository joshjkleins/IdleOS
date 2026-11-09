extends Node
## 2026-11-06: table trim keeps colors
func _ready() -> void:
	var c = "Logs [color=#e24b4a]17/51[/color], IP address [color=#e24b4a]6/53[/color], Passwords [color=#e24b4a]8/21[/color]"
	print(">>> ", ContextCommands.trim_bbcode(c, 41))
	print(">>> ", ContextCommands.strip_bbcode(ContextCommands.trim_bbcode(c, 41)).length())
	print(">>> ", ContextCommands.trim_bbcode("plain text here", 5))
	get_tree().quit()
