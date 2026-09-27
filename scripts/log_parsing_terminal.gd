extends PanelContainer

###MAJOR CHANGE
#Need to update how parsing works when its parsing a cache vs a Mine item
#When it's a cache it should go through each line and turn it green on 'successful item find per line'
#When it has been parsed it should repeat and skip green lines until all lines are green, then it will be considered 'finished' and transform to a cache+

@onready var amount_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer2/AmountLabel
@onready var status_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/StatusLabel
@onready var logs_container = $MarginContainer/VBoxContainer/MarginContainer3/LogsContainer
@onready var chance_per_line_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer3/ChancePerLineLabel
@onready var req_item_label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer2/ReqItemLabel

@onready var item_find_container = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer
@onready var item_find_container_2 = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer2
@onready var item_find_container_3 = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer3
@onready var item_find_container_4 = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ItemFindContainer4

@onready var player_total_labels = $MarginContainer/VBoxContainer/MarginContainer4/PlayerTotalLabels

@onready var log_line_scene = preload("res://scenes/log_line.tscn")

const MAX_LOG_LINES = 10

var process_running: bool = false
var end_safely: bool = false
var is_window: bool = false

var type: Dictionary

var base_speed
var overclock_speed
var overheat_speed

var stopped_once: bool = false
var items_to_parse: Array[ItemData] = []
var item_to_parse_index: int = 0

func set_parse_type(p_type: Dictionary, items_for_parsing: Array[ItemData], i_window = false):
	type = p_type
	is_window = i_window
	items_to_parse = items_for_parsing
	
	#ITEM LABELS = LABELS OF POTENTIAL ITEMS TO BE FOUND WITHIN THE ITEM BEING PARSED, CHANGE TO USE SOMETHING ELSE FOR CACHE PARSING
	#var item_labels = [item_find_container, item_find_container_2, item_find_container_3, item_find_container_4]
	
	#Hide all labels to dynamically build them based on related items (found and in player inventory)
	for i in player_total_labels.get_children():
		i.visible = false
	#for i in item_labels:
		#i.visible = false
		
	#update_total_player_labels()
	
	#req_item_label.text = type.requirements.keys()[0].name.to_upper() #ONLY ONE REQUIREMENT
	
	
	#for i in range(type["resource gained"].size()):
		#var cont = item_labels[i]
		#var item = type["resource gained"][i]
		#cont.get_child(0).text = item["item"]["name"].to_upper()
		#cont.get_child(1).text = str(type["resource gained"][i]["weight"]) + "%" #str(item_chance) + "%"
		#
		#item_labels[i].visible = true
		#player_total_labels.get_child(i).visible = true
	
	var eff = _get_total_effeciency()
	chance_per_line_label.text = "%.1f%%" % (eff * 100.0)
	#speed
	var speed_parsing_package = Upgrades.get_package_info("parsing.speed")
	var speed_upgrade = speed_parsing_package.current
	base_speed = type["base speed"] / (1.0 + speed_upgrade)
	overclock_speed = type["overclock speed"] / (1.0 + speed_upgrade)
	overheat_speed = type["overheat speed"]

func begin():
	#reset properties
	end_safely = false
	_reset_logs()
	process_running = true
	
	while process_running:
		if end_safely:
			end_process_safely()
			break
		
		var current_item = get_current_item_to_parse()
		
		if current_item == null:
			#finishes naturally by running out of items to parse
			if is_window: #vm window ran out > shutdown
				stop()
			else:
				Signals.end_log_parsing_safely()
		
		#update labels (current amount of parsed item, items to be found, % rates)
		set_labels(current_item) #updates visibility / item names / amounts
		#update_top_row_player_amount()
		#update_bottom_row_player_amount()
		
		while Inventory.get_amount(current_item) > 0:
			#main reason to split these loops is because of item removal. Cache item isn't removed/added until its looped multiple times, item loop is removed right away
			if current_item is CacheData:
				await parsing_cache_loop() #BUILD THIS OUT STILL
			else:
				await parsing_item_loop() #BUILD THIS OUT STILL

func start():
	end_safely = false
	_reset_logs()
	process_running = true
	
	var current_parse_target = get_current_item_to_parse()

	while process_running and has_requirements():
		if end_safely:
			process_running = false
			if !is_window:
				Signals.end_log_parsing_safely()
			stop()
			break
		else:
			remove_requirements()
			amount_label.text = "x" + str(Inventory.get_amount(type.requirements.keys()[0]))
			
			var heat_used = 0
			for i in range(MAX_LOG_LINES):
				#get random log
				var new_log_line = log_line_scene.instantiate()
				var item = null
				var amount = 0
				var eff = _get_total_effeciency()
				
				if randf() < eff:
					var item_info = Parsing.get_weighted_item(type["resource gained"])
					item = item_info["item"]
					amount = randi_range(item_info["min"], item_info["max"])
					Inventory.add_resource(item, amount)
					update_total_player_labels()
					if item == Items.ENCRYPTED_PASSWORDS:
						Tutorial.track_event(Tutorial.TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS, 1)
					if item == Items.USERNAMES:
						Tutorial.track_event(Tutorial.TutorialEvent.OBTAIN_3_USERNAMES, 1)
					if item == Items.IP_ADDRESS:
						Tutorial.track_event(Tutorial.TutorialEvent.OBTAIN_3_IP_ADDRESSES, 1)
						
				
				new_log_line.update(Parsing.LOG_LINES.pick_random(), item, amount)
				logs_container.add_child(new_log_line)
				
				if Stats.overheated:
					await get_tree().create_timer(overheat_speed).timeout
					heat_used = type["overheat heat"]
				elif Stats.overclocked and Upgrades.can_overclock(Parsing):
					await get_tree().create_timer(overclock_speed).timeout
					heat_used = type["overclock heat"]
				else:
					await get_tree().create_timer(base_speed).timeout
					heat_used = type["heat"]
				if !process_running:
					Stats.update_tempature(heat_used)
					break
			
			if randf() <= 0.01:
				Inventory.add_resource(Items.VM_PARSING_TOKEN, 1)
			if process_running:
				_finished_log(heat_used)
	#finishes naturally
	if is_window: #vm window ran out of logs > shutdown
		stop()
	if process_running and !is_window:
		Signals.end_log_parsing_safely()

func parsing_item_loop():
	pass

func parsing_cache_loop():
	pass

func stop():
	if stopped_once:
		return
	
	stopped_once = true
	end_safely = false
	process_running = false
	if is_window:
		Parsing.CURRENT_VMS -= 1
		Stats.remove_vm_count(1)
		get_parent().queue_free()

func stop_safely():
	end_safely = true

func _finished_log(heat_used: float):
	type.signal.emit(1)
	Tutorial.track_event(Tutorial.TutorialEvent.PARSE_20_LOGS, 1)
	Exp.add_xp(Parsing, type, type["experience per level"])
	Signals.update_hud(Parsing)

	var eff = _get_total_effeciency()
	chance_per_line_label.text = "%.1f%%" % (eff * 100)
	Stats.update_tempature(heat_used)
	if has_requirements() and !end_safely:
		_reset_logs()

func _reset_logs():
	for n in logs_container.get_children():
		n.queue_free()

func _get_total_effeciency() -> float:
	var base = type["efficiency"]
	var upgrades = Upgrades.get_package_info("parsing.efficiency")
	var defragging_bonus = Defragging.PARSING["bonus efficiency"] if Stats.has_bonus(Parsing) else 1.0
	
	return (base + upgrades.current) * defragging_bonus


func update_total_player_labels():
	for i in range(type["resource gained"].size()):
		var item = type["resource gained"][i]
		var total_label = player_total_labels.get_child(i)
		total_label.get_child(0).text = item.item.name.to_upper() + " TOTAL"
		total_label.get_child(1).text = str(Inventory.get_amount(item.item))
		total_label.visible = true


func set_labels(item: ItemData):
	req_item_label.text = item.name
	
	#ITEM LABELS = LABELS OF POTENTIAL ITEMS TO BE FOUND WITHIN THE ITEM BEING PARSED, CHANGE TO USE SOMETHING ELSE FOR CACHE PARSING
	var item_labels = [item_find_container, item_find_container_2, item_find_container_3, item_find_container_4]
	#PLAYER_CURRENT_AMOUNT_LABELS = HOW MUCH OF EACH ITEM PLAYER CURRENTLY HAS IN INVENTORY
	var player_current_amount_labels = player_total_labels.get_children()
	for i in item_labels:
		i.visible = false
	for i in player_current_amount_labels:
		i.visible = false
	
	if item is not CacheData:
		var percent_drop = int(item.contained_items.size() / 100)
		for i in range(item.contained_items.size()):
			var potential_item = item.contained_items[i]
			
			#TOP ROW LABELS SHOWING % CHANCE OF GETTING
			item_labels[i].get_child(0).text = potential_item["name"].to_upper()
			item_labels[i].get_child(1).text = str(percent_drop) + "%"
			item_labels[i].visible = true
			
			
			#BOTTOM ROW LABELS SHOWING HOW MUCH PLAYER ALREADY HAS
			#name
			player_current_amount_labels[i].get_child(0).text = potential_item.name.to_upper()
			#amount
			player_current_amount_labels[i].get_child(1).text = str(Inventory.get_amount(potential_item))
			player_current_amount_labels[i].get_child(i).visible = true
	else: #CACHE ITEM
		return

#This function assumes visiblilities have been set appropriately and just updates amounts
func update_bottom_row_player_amount():
	var item = get_current_item_to_parse()
	if item is not CacheData:
		var player_current_amount_labels = player_total_labels.get_children()
		for i in range(item.contained_items.size()):
			var potential_item = item.contained_items[i]
			#BOTTOM ROW LABELS SHOWING HOW MUCH PLAYER ALREADY HAS
			#amount
			player_current_amount_labels[i].get_child(1).text = str(Inventory.get_amount(potential_item))

func update_top_row_player_amount():
	var item = get_current_item_to_parse()
	if item != null:
		amount_label.text = "x" + str(Inventory.get_amount(item))

func has_requirements() -> bool:
	var requirements = type.requirements
	for item in requirements:
		if Inventory.get_amount(item) < requirements[item]:
			return false
	
	return true

func remove_requirements() -> void:
	var requirements = type.requirements
	for item in requirements:
		if Inventory.get_amount(item) >= requirements[item]:
			Inventory.remove_resource(item, requirements[item])

func end_process_safely():
	process_running = false
	if !is_window:
		Signals.end_log_parsing_safely()
	stop()

func get_current_item_to_parse() -> ItemData:
	if items_to_parse.is_empty():
		return null

	var count := items_to_parse.size()
	for i in count:
		var index := (item_to_parse_index + i) % count
		var item := items_to_parse[index]
		if Inventory.get_amount(item) > 0:
			item_to_parse_index = index
			return item

	return null
