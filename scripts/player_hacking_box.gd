extends Control


@export var title_text: String = "Console"
@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel
@onready var input_line = $PanelContainer/MarginContainer/VBoxContainer/InputLine
@onready var scrollback = $PanelContainer/MarginContainer/VBoxContainer/Scrollback

var lines: Array[String] = []

func _ready():
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
	input_line.grab_focus() #get rid of this after development of hacking mod


func _on_input_line_text_submitted(new_text):
	input_line.clear()
	add_line(">" + new_text)


#update previous lines
func set_line(index: int, text: String, scroll_to_line: bool = true):
	if index < lines.size():
		lines[index] = text
	update_terminal(scroll_to_line)

#Add new line 
func add_line(text: String):
	lines.append(text)
	update_terminal()

#apply updates to line or new line
func update_terminal(scroll_to_line: bool = true):
	scrollback.text = "\n".join(lines)
	if scroll_to_line:
		scrollback.scroll_to_line(scrollback.get_line_count() - 1)
