extends MarginContainer

@onready var item_container_scene = preload("res://scenes/compiling_item_container.tscn")

@onready var payload_name = $VBoxContainer/PanelContainer/TitleRow/HBoxContainer/PayloadName
@onready var item_containers = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/ItemContainers
@onready var rcl_top = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/MarginContainer/HBoxContainer/RandomCharsLeft/RCLTop
@onready var rcl_bottom = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/MarginContainer/HBoxContainer/RandomCharsLeft/RCLBottom
@onready var rcr_top = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/MarginContainer/HBoxContainer/RandomCharsRight/RCRTop
@onready var rcr_bottom = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/MarginContainer/HBoxContainer/RandomCharsRight/RCRBottom
@onready var fill_bar = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/FillBar
@onready var payload_item = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/PayloadItem
@onready var amount_gained_label = $VBoxContainer/PanelContainer2/MarginContainer2/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/AmountGained

var scramble_interval: float = 0.2
var charset: String = "01#$%&*"
var scramble_length: int = 6

var _time_accum: float = 0.0

var scrambling: bool = false
var type: Dictionary
var amount_gained: int = 0
var vm_window: bool = false
var did_overclock_this_cycle: bool = false

var final_cycle: bool = false

func start(p_type: Dictionary, is_window: bool = false):
	vm_window = is_window
	fill_bar.value = 0.0
	type = p_type
	_build_item_containers(p_type)
	_update_labels()
	
	if _has_resources_for_more():
		_begin_scramble()

func _vm_finish():
	if vm_window:
		Compiling.CURRENT_VMS -= 1
		get_parent().queue_free()

func stop():
	scrambling = false

func _begin_scramble():
	scrambling = true

func _process(delta: float) -> void:
	##TODO: EFFICIENCY
	if scrambling:
		_time_accum += delta
		
		#PROGRESS BAR FILL
		var oc_speed = type["overclock speed"] if Stats.overclocked else 1.0
		if Stats.overclocked:
			did_overclock_this_cycle = true
		fill_bar.value += delta * type["base speed"] * oc_speed
		if fill_bar.value >= fill_bar.max_value:
			_compile_payload()
			if _has_resources_for_more() and !final_cycle:
				fill_bar.value = 0.0
			else:
				_stop_compiling()
		
		#SCRAMBLED CHARS LABELS
		if _time_accum >= scramble_interval:
			_time_accum -= scramble_interval
			
			rcl_bottom.text = _random_scramble_string(scramble_length, charset)
			rcl_top.text = _random_scramble_string(scramble_length, charset)
			rcr_bottom.text = _random_scramble_string(scramble_length, charset)
			rcr_top.text = _random_scramble_string(scramble_length, charset)

func _update_labels():
	payload_item.text = type["resource gained"].name
	amount_gained_label.text = "x" + str(amount_gained)
	for container in item_containers.get_children():
		container.update_amount()

func _compile_payload():
	#TAKETH
	for req in type.requirements:
		Inventory.remove_resource(req.item, req.amount)
	
	#GIVETH
	var amount_to_gain = 1
	Inventory.add_resource(type["resource gained"], amount_to_gain)
	amount_gained += amount_to_gain
	if randf() <= 0.01:
		Inventory.add_resource(Items.VM_COMPILING_TOKEN, 1)
		
	#UPDATETH
	type.signal.emit(1)
	Exp.add_xp(Compiling, type, type["experience per level"])
	Signals.update_hud(Compiling)
	
	#HEATETH
	if did_overclock_this_cycle:
		Stats.update_tempature(type["overclock heat"])
		did_overclock_this_cycle = false
	else:
		Stats.update_tempature(type["heat"])
		
	_update_labels()

func _has_resources_for_more() -> bool:
	for req in type.requirements:
		if Inventory.get_amount(req.item) < req.amount:
			return false
	return true

func _stop_compiling():
	if vm_window:
		_vm_finish()
	else:
		Signals.end_cache_decrypting_safely()
	
	scrambling = false

func stop_safely():
	final_cycle = true

func _build_item_containers(type: Dictionary):
	for req in type.requirements:
		var item = req.item
		var container = item_container_scene.instantiate()
		container.set_labels(req)
		item_containers.add_child(container)

func _random_scramble_string(length: int = 6, charset: String = "01#$%&*") -> String:
	var result := ""
	for i in range(length):
		result += charset[randi() % charset.length()]
	return result
