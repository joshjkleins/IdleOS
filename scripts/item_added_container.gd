extends VBoxContainer

@onready var item_added_label_scene = preload("res://scenes/item_added_label.tscn")

func _ready():
	Signals.item_added_signal.connect(add_label)

func add_label(item: ItemData, amount: int):
	var nl = item_added_label_scene.instantiate()
	nl.update(item.name, amount)
	add_child(nl)
	nl.display()
