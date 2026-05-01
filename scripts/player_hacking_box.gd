extends Control
signal command_entered
@export var title_text: String = "Console"
@export var line_delay: float = 0.05  # seconds between lines

@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel
@onready var scrollback = $PanelContainer/MarginContainer/VBoxContainer/Scrollback
@onready var input_line: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InputLine

var lines: Array[String] = []
var _print_queue: Array[String] = []
var _is_printing: bool = false
#past commands using up/down
var command_history = []
var history_index = -1
#end past commands

func _ready():
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
	input_line.grab_focus()

func grab():
	input_line.grab_focus()

func clear():
	lines.clear()
	update_terminal()

func _on_input_line_text_submitted(new_text):
	if new_text == "":
		return
	input_line.clear()
	add_line(">" + new_text)
	command_history.append(new_text)
	var text = new_text.to_lower().strip_edges()
	command_entered.emit(text)

func set_line(index: int, text: String, scroll_to_line: bool = true):
	if index < lines.size():
		lines[index] = text
	update_terminal(scroll_to_line)

# splits on \n and queues each line individually
func add_line(text: String):
	var split = text.split("\n")
	for line in split:
		_print_queue.append(line)
	if not _is_printing:
		_process_queue()

func _process_queue():
	if _print_queue.is_empty():
		_is_printing = false
		return
	
	_is_printing = true
	var next_line = _print_queue.pop_front()
	lines.append(next_line)
	update_terminal()
	
	await get_tree().create_timer(line_delay).timeout
	_process_queue()

func update_terminal(scroll_to_line: bool = true):
	scrollback.text = "\n".join(lines)
	if scroll_to_line:
		scrollback.scroll_to_line(scrollback.get_line_count() - 1)

func add_line_header(text: String, return_string: bool = false) -> String:
	var result = "[bgcolor=#1a2a1a][color=#4ec994] " + text + " [/color][/bgcolor]"
	if return_string:
		return result
	add_line(result)
	return ""

func add_line_success(text: String):
	add_line("[color=#4ec994]" + text + "[/color]")  # green

func add_line_error(text: String):
	add_line("[color=#e24b4a]" + text + "[/color]")  # red

func add_line_warning(text: String):
	add_line("[color=#ef9f27]" + text + "[/color]")  # amber

func add_line_system(text: String):
	add_line("[color=#888888]" + text + "[/color]")  # muted gray

func add_line_highlight(text: String):
	add_line("[color=#7f77dd]" + text + "[/color]")  # purple

func add_separator():
	add_line("[color=#333333]" + "─".repeat(30) + "[/color]")


func _input(event):
	if visible:
		if event is InputEventKey and event.pressed:
			if event.keycode == Key.KEY_UP:
				navigate_history(-1)
			elif event.keycode == Key.KEY_DOWN:
				navigate_history(1)

#command history functionality
func navigate_history(delta: int):
	if command_history.size() == 0:
		return
	
	if history_index == -1:
		history_index = command_history.size()
	
	history_index = clamp(history_index + delta, 0, command_history.size() - 1)
	
	input_line.text = command_history[history_index]

	call_deferred("_move_caret_to_end")


#used when navigating past commands with up/down arrows
func _move_caret_to_end():
	input_line.caret_column = input_line.text.length()
