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
var item_to_transform_to: CacheData = null

func set_parse_type(p_type: Dictionary, items_for_parsing: Array[ItemData], i_window = false):
	type = p_type
	is_window = i_window
	items_to_parse = items_for_parsing
	
	#Hide all labels to dynamically build them based on related items (found and in player inventory)
	for i in player_total_labels.get_children():
		i.visible = false
	
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
		
		var current_item = get_current_item_to_parse() #gets item passed to process, if multiple items then it will loop through until all of them are empty from player inventory
		
		if current_item == null:
			#finishes naturally by running out of items to parse
			if is_window: #vm window ran out > shutdown
				stop()
			else:
				Signals.end_log_parsing_safely()
			break
		
		if current_item is CacheData:
			item_to_transform_to = Parsing.get_cache_transform_target(type, current_item)
		#update labels (current amount of parsed item, items to be found, % rates)
		set_labels(current_item) #updates visibility / item names / amounts
		
		while Inventory.get_amount(current_item) > 0 and process_running and !end_safely:
			_reset_logs()
			#main reason to split these loops is because of item removal. Cache item isn't removed/added until its looped multiple times, item loop is removed right away
			if current_item is CacheData:
				await parsing_cache_loop(current_item)
			else:
				await parsing_item_loop(current_item)

func parsing_item_loop(item: ItemData):
	Inventory.remove_resource(item, 1)
	update_top_row_player_amount(item)
	
	var heat_used
	#LOOP 10 TIMES FOR EACH 'PARSE' ITEM
	for i in range(MAX_LOG_LINES):
		var new_log_line = log_line_scene.instantiate()
		var eff = _get_total_effeciency()
		var item_found = null
		
		#ITEM FOUND
		if randf() < eff:
			item_found = item.contained_items.pick_random()
			Inventory.add_resource(item_found, 1)
			update_bottom_row_player_amount(item)
			if item_found == Items.ENCRYPTED_PASSWORDS:
				Tutorial.track_event(Tutorial.TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS, 1)
			if item_found == Items.USERNAMES:
				Tutorial.track_event(Tutorial.TutorialEvent.OBTAIN_3_USERNAMES, 1)
			if item_found == Items.IP_ADDRESS:
				Tutorial.track_event(Tutorial.TutorialEvent.OBTAIN_3_IP_ADDRESSES, 1)
		
		#CREATE AND ADD LOG LINE TO LIST
		new_log_line.update(Parsing.LOG_LINES.pick_random(), item_found, 1)
		logs_container.add_child(new_log_line)
		
		#APPLY WAIT FOR LOG LINE AND MEASURE HEAT
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
	
	if process_running:
		if randf() <= 0.01:
			Inventory.add_resource(Items.VM_PARSING_TOKEN, 1)
		if process_running:
			_finished_log(heat_used)

func parsing_cache_loop(item: ItemData):
	update_top_row_player_amount(item)
	
	var heat_used
	#INITIAL LOOP OF 10 LINES
	for i in range(MAX_LOG_LINES):
		var new_log_line = log_line_scene.instantiate()
		var eff = _get_total_effeciency()		
		
		#DETERMINES IF LINE IS TRUE OR FALSE HERE
		new_log_line.cache_update(randf() < eff)
		logs_container.add_child(new_log_line)
		
		#APPLY WAIT FOR LOG LINE AND MEASURE HEAT
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
		
	while !is_log_finished() and process_running:
		var remaining_logs = get_red_logs()
		var eff = _get_total_effeciency()
		for log_line in remaining_logs:
			log_line.cache_update(randf() < eff)
			
			#APPLY WAIT FOR LOG LINE AND MEASURE HEAT
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
	
	if process_running:
		if is_log_finished():
			Inventory.remove_resource(item, 1)
			Inventory.add_resource(item_to_transform_to, 1)
			update_top_row_player_amount(item)
			update_bottom_row_player_amount(item_to_transform_to)
		
		if randf() <= 0.01:
			Inventory.add_resource(Items.VM_PARSING_TOKEN, 1)
		if process_running:
			_finished_log(heat_used)

func get_red_logs() -> Array:
	var remaining_logs = []
	for log_line in logs_container.get_children():
		if !log_line.is_green:
			remaining_logs.append(log_line)
	return remaining_logs

func is_log_finished() -> bool:
	for log_line in logs_container.get_children():
		if !log_line.is_green:
			return false
	return true

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
	#if !end_safely:
		#_reset_logs()

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
		var percent_drop = int((100.0 / item.contained_items.size()))
		var percent_drop1 = int(item.contained_items.size() / 100.0 * 100.0)
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
			player_current_amount_labels[i].visible = true
	else: #CACHE ITEM
		var percent_drop = 100
		#item_to_transform_to
		
		item_labels[0].get_child(0).text = item_to_transform_to.name.to_upper()
		item_labels[0].get_child(1).text = "100%"
		item_labels[0].visible = true
		
		#name
		player_current_amount_labels[0].get_child(0).text = item_to_transform_to.name.to_upper()
		#amount
		player_current_amount_labels[0].get_child(1).text = str(Inventory.get_amount(item_to_transform_to))
		player_current_amount_labels[0].visible = true


#This function assumes visiblilities have been set appropriately and just updates amounts
func update_bottom_row_player_amount(item: ItemData):
	#var item = get_current_item_to_parse()
	if item is not CacheData:
		var player_current_amount_labels = player_total_labels.get_children()
		for i in range(item.contained_items.size()):
			var potential_item = item.contained_items[i]
			#BOTTOM ROW LABELS SHOWING HOW MUCH PLAYER ALREADY HAS
			#amount
			player_current_amount_labels[i].get_child(1).text = str(Inventory.get_amount(potential_item))
	else:
		var player_current_amount_labels = player_total_labels.get_children()
		player_current_amount_labels[0].get_child(1).text = str(Inventory.get_amount(item))
		for i in range(item.contained_items.size()):
			var potential_item = item.contained_items[i]
			#BOTTOM ROW LABELS SHOWING HOW MUCH PLAYER ALREADY HAS
			#amount
			player_current_amount_labels[i].get_child(1).text = str(Inventory.get_amount(potential_item))
		

func update_top_row_player_amount(item: ItemData):
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
