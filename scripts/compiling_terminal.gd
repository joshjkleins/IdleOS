extends PanelContainer

@onready var item_container_scene = preload("res://scenes/ingredients_row.tscn")

@onready var payload_name = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PayloadName
#@onready var payload_name = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/PayloadName
@onready var ingredients_container = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/IngredientsContainer
@onready var sl_top = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ScrambleRow/ScrambleLeft/SLTop
@onready var sl_bottom = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ScrambleRow/ScrambleLeft/SLBottom
@onready var sr_top = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ScrambleRow/ScrambleRight/SRTop
@onready var sr_bottom = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ScrambleRow/ScrambleRight/SRBottom
@onready var fill_bar = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/FillBar
@onready var payload_item = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Summary/PayloadItem
@onready var amount_gained_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Summary/AmountGainedLabel
@onready var eff_timer = $EffTimer
@onready var eff_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/EffLabel

var scramble_interval: float = 0.05
var charset: String = "01#$%&*"
var scramble_length: int = 6

# session-token reveal targets — top row is a fixed label, bottom row is a
# randomized hex pair regenerated each cycle so the "token" varies
var target_sl_top: String = "SESS::"
var target_sr_top: String = "ACTIVE"
var target_sl_bottom: String = ""
var target_sr_bottom: String = ""
var hex_charset: String = "0123456789ABCDEF"

# reveal state colors
const COLOR_DIM := Color(0.290, 0.314, 0.353)   # unrevealed / scrambling
const COLOR_MID := Color(0.478, 0.510, 0.557)   # partially locked
const COLOR_LOCKED := Color(0.925, 0.925, 0.925) # fully locked this segment
const COLOR_DONE := Color(0.310, 0.847, 0.541)   # full payload resolved

var _time_accum: float = 0.0

var scrambling: bool = false
var paused: bool = false
var type: Dictionary
var amount_gained: int = 0
var vm_window: bool = false
var did_overclock_this_cycle: bool = false

var final_cycle: bool = false

var eff_proc: bool = false

var speed: float = 0.0
var overheat_speed: float = 0.0
var overclock_speed: float = 0.0

func start(p_type: Dictionary, is_window: bool = false):
	vm_window = is_window
	fill_bar.value = 0.0
	type = p_type
	_build_item_containers(p_type)
	_update_labels()
	_generate_targets()
	
	var speed_compiling_package = Upgrades.get_package_info("compiling.speed")
	var speed_upgrade = speed_compiling_package.current
	speed = type["base speed"] * (1.0 + speed_upgrade)
	overclock_speed = type["overclock speed"] * (1.0 + speed_upgrade)
	overheat_speed = type["overheat speed"]
	 
	eff_label.text = "eff: " + str(_get_current_eff() * 100.0) + "%"

	if _has_resources_for_more():
		_begin_scramble()

func _vm_finish():
	if vm_window:
		Stats.remove_vm_count(1)
		Compiling.CURRENT_VMS -= 1
		get_parent().queue_free()

func stop():
	scrambling = false

func _begin_scramble():
	scrambling = true

func _process(delta: float) -> void:
	if scrambling and not paused:
		_time_accum += delta

		#PROGRESS BAR FILL
		if Stats.overheated:
			fill_bar.value += delta * overheat_speed
			did_overclock_this_cycle = false
		else:
			var oc_speed
			if Stats.overclocked and Upgrades.can_overclock(Compiling):
				oc_speed = overclock_speed
				did_overclock_this_cycle = true
			else:
				oc_speed = speed
				
			var eff = 100.0 if eff_proc else 1.0
			fill_bar.value += delta * oc_speed * eff

		if fill_bar.value >= fill_bar.max_value:
			fill_bar.value = fill_bar.max_value
			_update_scramble_labels() # snap to fully resolved token
			_compile_payload()

			if _has_resources_for_more() and !final_cycle:
				_pause_then_restart()
			else:
				_stop_compiling()
			return

		#SCRAMBLED CHARS LABELS, revealing in tandem with fill_bar
		if Stats.overheated:
			if _time_accum >= scramble_interval + 0.5:
				_time_accum -= scramble_interval + 0.5
				_update_scramble_labels()
		else:
			if _time_accum >= scramble_interval:
				_time_accum -= scramble_interval
				_update_scramble_labels()

func _pause_then_restart() -> void:
	paused = true
	#await get_tree().create_timer(0.1).timeout
	fill_bar.value = 0.0
	_generate_targets()
	paused = false

func _update_labels():
	payload_item.text = type["resource gained"].name
	amount_gained_label.text = "x" + str(amount_gained)
	for container in ingredients_container.get_children():
		container.update_amount()

func _generate_targets() -> void:
	target_sl_bottom = _random_string(scramble_length, hex_charset)
	target_sr_bottom = _random_string(scramble_length, hex_charset)

func _update_scramble_labels() -> void:
	var progress: float = fill_bar.value / fill_bar.max_value
	var full_done: bool = progress >= 1.0

	sl_top.text = _scrambled_reveal(target_sl_top, progress, sl_top, full_done)
	sl_bottom.text = _scrambled_reveal(target_sl_bottom, progress, sl_bottom, full_done)
	sr_top.text = _scrambled_reveal(target_sr_top, progress, sr_top, full_done)
	sr_bottom.text = _scrambled_reveal(target_sr_bottom, progress, sr_bottom, full_done)

func _scrambled_reveal(target: String, progress: float, label: Label, full_done: bool) -> String:
	var length := target.length()
	var lock_count := int(round(progress * length))
	var result := ""
	for i in range(length):
		if i < lock_count:
			result += target[i]
		else:
			result += charset[randi() % charset.length()]

	if full_done:
		label.modulate = COLOR_DONE
	elif lock_count >= length:
		label.modulate = COLOR_LOCKED
	elif lock_count > 0:
		label.modulate = COLOR_MID
	else:
		label.modulate = COLOR_DIM

	return result

func _compile_payload():
	#TAKETH
	for req in type.requirements:
		Inventory.remove_resource(req.item, req.amount)

	#GIVETH
	var amount_to_gain = 1
	Inventory.add_resource(type["resource gained"], amount_to_gain)
	Tutorial.track_event(Tutorial.TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS, 1)
	amount_gained += amount_to_gain
	if randf() <= 0.01:
		Inventory.add_resource(Items.VM_COMPILING_TOKEN, 1)

	#UPDATETH
	type.signal.emit(1)
	Exp.add_xp(Compiling, type, type["experience per level"])
	Signals.update_hud(Compiling)

	#HEATETH
	if !eff_proc:
		if Stats.overheated:
			Stats.update_tempature(type["overheat heat"])
		elif did_overclock_this_cycle:
			Stats.update_tempature(type["overclock heat"])
			did_overclock_this_cycle = false
		else:
			Stats.update_tempature(type["heat"])
	
	#EFFICIENCY	
	var eff = _get_current_eff()
	if randf() <= eff:
		_efficiency_trigger()
	eff_label.text = "eff: " + str(eff * 100.0) + "%"

	_update_labels()

func _efficiency_trigger():
	if eff_proc:
		return
	
	eff_proc = true
	eff_timer.wait_time = 1.0
	eff_timer.start()
	

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
		ingredients_container.add_child(container)

func _random_string(length: int, source_charset: String) -> String:
	var result := ""
	for i in range(length):
		result += source_charset[randi() % source_charset.length()]
	return result


func _on_eff_timer_timeout():
	eff_proc = false

func _get_current_eff() -> float:
	var efficiency_compiling_package = Upgrades.get_package_info("compiling.efficiency")
	var efficiency_upgrade = efficiency_compiling_package.current
	
	var frag_bonus = Defragging.COMPILING["bonus efficiency"] if Stats.has_bonus(Compiling) else 1.0
	
	return (type["efficiency"] + efficiency_upgrade) * frag_bonus
