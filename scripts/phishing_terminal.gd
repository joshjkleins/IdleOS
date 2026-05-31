extends VBoxContainer

@onready var active_line = preload("res://scenes/phishing_line.tscn")
@onready var active_lines_container = $ActiveLines/MarginContainer/VBoxContainer/ActiveLinesContainer

func _ready():
	_clear_lines()
	add_line()

func _clear_lines():
	if active_lines_container.get_child_count() > 0:
		for node in active_lines_container.get_children():
			node.queue_free()

func add_line():
	var new_line = active_line.instantiate()
	new_line.set_info()
	active_lines_container.add_child(new_line)
