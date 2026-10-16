extends BaseTerminal
## Compiling terminal: the bar fills at a RATE (units/sec) while the hex labels resolve; a full bar
## consumes the ingredients and produces the payload (or applies a hacking mod once for MOD).

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
const COLOR_DIM := Color(0.290, 0.314, 0.353)   # unrevealed / running
const COLOR_MID := Color(0.478, 0.510, 0.557)   # partially locked
const COLOR_LOCKED := Color(0.925, 0.925, 0.925) # fully locked this segment
const COLOR_DONE := Color(0.310, 0.847, 0.541)   # full payload resolved

var _time_accum: float = 0.0

var paused: bool = false
var amount_gained: int = 0

var eff_proc: bool = false
var _cycle_mode: Mode = Mode.NORMAL # worst mode seen this cycle (decides heat)


var hacking_mod_item: ItemData = null

func start(p_type: Dictionary, is_window: bool = false, resource_to_compile: ItemData = null):
	setup_process(Compiling, p_type, is_window)
	hacking_mod_item = resource_to_compile
	fill_bar.value = 0.0
	_build_item_containers(p_type)
	_update_labels()
	_generate_targets()
	
	eff_label.text = "eff: " + str(_get_current_eff() * 100.0) + "%"

	begin_run()
	_cycle_mode = Mode.NORMAL
	if !_has_resources_for_more():
		finish_safely() # nothing to compile (previously it would sit idle forever)

func _process(delta: float) -> void:
	super(delta)
	if running and not paused:
		_time_accum += delta

		#PROGRESS BAR FILL (rate-based: speed upgrade multiplies the fill rate)
		var mode := get_mode()
		_cycle_mode = worst_mode(_cycle_mode, mode)
		var eff_boost = 100.0 if (eff_proc and mode != Mode.OVERHEATED) else 1.0
		fill_bar.value += delta * get_fill_rate(mode) * eff_boost

		if fill_bar.value >= fill_bar.max_value:
			fill_bar.value = fill_bar.max_value
			_update_scramble_labels() # snap to fully resolved token
			_compile_payload()

			if _has_resources_for_more() and !stop_requested and process_data != Compiling.MOD:
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
	if process_data == Compiling.MOD:
		var hacking_mod_value = HackingMods.get_mod_value_text(hacking_mod_item.hacking_mod_type, hacking_mod_item.hacking_mod_value)
		var hacking_mod_name = HackingMods.get_mod_name(hacking_mod_item.hacking_mod_type)
		var hacking_mod_duration = "Duration: " + str(hacking_mod_item.hacking_mod_duration) + " hack(s)"
		
		payload_item.text = hacking_mod_name + " " + hacking_mod_value
		amount_gained_label.text = hacking_mod_duration
	else:
		payload_item.text = process_data["resource gained"].name
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
	#Double check player has enough and wasnt spent somewhere else
	if process_data == Compiling.MOD:
		if Inventory.get_amount(hacking_mod_item) < hacking_mod_item.hacking_mod_consumed:
			return
		Inventory.remove_resource(hacking_mod_item, hacking_mod_item.hacking_mod_consumed)
		HackingMods.add_mod(hacking_mod_item)
	else:
		for req in process_data.requirements:
			Inventory.remove_resource(req, process_data.requirements[req])

		#GIVETH
		var amount_to_gain = 1
		Inventory.add_resource(process_data["resource gained"], amount_to_gain)
		Tutorial.track_event(Tutorial.TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS, 1)
		amount_gained += amount_to_gain
	if randf() <= 0.01:
		Inventory.add_resource(Items.VM_COMPILING_TOKEN, 1)

	#UPDATETH
	process_data.signal.emit(1)
	Exp.add_xp(Compiling, process_data, process_data["experience per level"])
	Signals.update_hud(Compiling)

	#HEATETH (efficiency-boosted cycles add no heat)
	if !eff_proc:
		apply_heat(_cycle_mode)
	_cycle_mode = Mode.NORMAL
	record_cycle(1)
	
	#EFFICIENCY
	var eff = _get_current_eff()
	if randf() <= eff and process_data != Compiling.MOD:
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
	if process_data == Compiling.MOD:
		if Inventory.get_amount(hacking_mod_item) >= hacking_mod_item.hacking_mod_consumed:
			return true
	else:
		for req in process_data.requirements:
			if Inventory.get_amount(req) < process_data.requirements[req]:
				return false
		return true
	return false

func _stop_compiling():
	finish_safely()

func _build_item_containers(p_type: Dictionary):
	if p_type == Compiling.MOD:
		var container = item_container_scene.instantiate()
		container.set_labels({"item": hacking_mod_item, "amount": hacking_mod_item.hacking_mod_consumed})
		ingredients_container.add_child(container)
	else:
		for req in p_type.requirements:
			var container = item_container_scene.instantiate()
			container.set_labels({"item": req, "amount": p_type.requirements[req]})
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
	
	return (process_data["efficiency"] + efficiency_upgrade) * frag_bonus
