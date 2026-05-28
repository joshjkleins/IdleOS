extends PanelContainer

@onready var amount_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer2/AmountLabel
@onready var status_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/StatusLabel
@onready var logs_container = $MarginContainer/VBoxContainer/MarginContainer3/LogsContainer
@onready var chance_per_line_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer3/ChancePerLineLabel

@onready var item_find_container = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer
@onready var item_find_container_2 = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer2
@onready var item_find_container_3 = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer3
@onready var item_find_container_4 = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer4

@onready var log_line_scene = preload("res://scenes/log_line.tscn")

const MAX_LOG_LINES = 10

var process_running: bool = false
var end_safely: bool = false

var type: Dictionary

func set_parse_type(p_type: Dictionary):
	type = p_type
	
	var item_labels = [item_find_container, item_find_container_2, item_find_container_3, item_find_container_4]
	var item_chance = int(100.0 / type["item pool"].size())
	for i in item_labels:
		i.visible = false
	for i in range(type["item pool"].size()):
		var cont = item_labels[i]
		var item = type["item pool"][i]
		cont.get_child(0).text = item["item"]["name"].to_upper()
		cont.get_child(1).text = str(item_chance) + "%"
		item_labels[i].visible = true
	chance_per_line_label.text = "%.1f%%" % (type["efficiency"] * 100)

func start():
	end_safely = false
	_reset_logs()
	process_running = true

	while process_running and Inventory.get_amount(type["requirements"]) > 0:
		if end_safely:
			process_running = false
			Signals.end_log_parsing_safely()
			break
		else:
			Inventory.remove_resource(type["requirements"], 1)
			amount_label.text = "x" + str(Inventory.get_amount(type["requirements"]))
			
			var heat_used = 0
			for i in range(MAX_LOG_LINES):
				#get random log
				var new_log_line = log_line_scene.instantiate()
				var item = null
				var amount = 0
				if randf() < type["efficiency"]:
					var item_info = type["item pool"].pick_random()
					item = item_info["item"]
					amount = randi_range(item_info["min"], item_info["max"])
					Inventory.add_resource(item, amount)
				
				new_log_line.update(Parsing.LOG_LINES.pick_random(), item, amount)
				logs_container.add_child(new_log_line)
				
				if Stats.overheated:
					await get_tree().create_timer(type["overheat speed"]).timeout
					heat_used = type["overheat heat"]
				elif Stats.overclocked:
					await get_tree().create_timer(type["overclock speed"]).timeout
					heat_used = type["overclock heat"]
				else:
					await get_tree().create_timer(type["base speed"]).timeout
					heat_used = type["heat"]
				if !process_running:
					Stats.update_tempature(heat_used)
					break
			if process_running:
				_finished_log(heat_used)
	#finishes naturally
	if process_running:
		Signals.end_log_parsing_safely()

func stop():
	end_safely = false
	process_running = false

func stop_safely():
	end_safely = true

func _finished_log(heat_used: int):
	type.signal.emit(1)
	Exp.add_xp(Parsing, type, type["experience per level"])
	Signals.update_hud(Parsing)
	chance_per_line_label.text = "%.1f%%" % (type["efficiency"] * 100)
	Stats.update_tempature(heat_used)
	if Inventory.get_amount(type["requirements"]) > 0 and !end_safely:
		_reset_logs()

func _reset_logs():
	for n in logs_container.get_children():
		n.queue_free()
