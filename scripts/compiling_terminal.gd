extends BaseTerminal
## Compiling terminal: the bar fills at a RATE (units/sec) while the hex labels resolve. Every full bar is
## one "fill": a payload (School ... Government) or one hack of a hacking mod (MOD). Bursts (efficiency) fill at
## 100x for 1 second with no heat; progress past a full bar carries into the next fill.

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
var _reqs: Dictionary = {}         # what one compile consumes

## arg: the item to turn into a mod (MOD).
func start(p_type: Dictionary, is_window: bool = false, arg = null):
	setup_process(Compiling, p_type, is_window)
	if arg is ItemData:
		hacking_mod_item = arg
	_reqs = {}
	if p_type.requirements is Dictionary:
		_reqs = p_type.requirements
	_refresh_reqs()
	fill_bar.value = 0.0
	_fill = 0.0
	_build_item_containers(p_type)
	_update_labels()
	_generate_targets()
	_update_eff_label()

	begin_run()
	_cycle_mode = Mode.NORMAL
	if !_has_resources_for_more():
		finish_safely() # nothing to compile (previously it would sit idle forever)

var _fill := 0.0          # bar progress (0..100+), kept apart from the bar so it can carry past 100
var _fill_seconds := 0.0  # time the current fill took (VM tokens roll on time)
const MAX_FILLS_PER_FRAME := 20

## What the next fill consumes: payload recipe or the mod's per-hack cost
func _refresh_reqs() -> void:
	if process_data == Compiling.MOD and hacking_mod_item:
		_reqs = Compiling.mod_fill_cost(hacking_mod_item)


## Per modifier: Debug only does something on Mod
func modifier_refuses(command: String) -> String:
	if command == "debug" and process_data != Compiling.MOD:
		return "Debug only works on Mod ('compile -mod=<item>'): it lets the mod build up to +50% more hacks."
	return ""

## Mod heat follows the working tier
func heat_tier_mult() -> float:
	if process_data == Compiling.MOD:
		return Stats.tier_heat(Compiling.HEAT_BY_TIER, Upgrades.working_tier("Compiling"))
	return 1.0

func _mod_cap() -> int:
	return Compiling.mod_cap(hacking_mod_item, has_modifier("debug")) if hacking_mod_item else 0

func _update_eff_label() -> void:
	eff_label.text = "eff: %.2f%%" % (_get_current_eff() * 100.0)

func _process(delta: float) -> void:
	super(delta)
	if running and process_data == Compiling.MOD and _waiting_for_debug():
		amount_gained_label.text = "%d/%d hacks  ·  'debug' builds up to %d" % [int(HackingMods.current_mods[hacking_mod_item.hacking_mod_type].duration), Compiling.mod_cap(hacking_mod_item), Compiling.mod_cap(hacking_mod_item, true)]
		if stop_requested:
			_stop_compiling()
		return # at the normal cap: wait (no inputs spent) until Debug is turned on
	if running and not paused:
		_time_accum += delta

		#PROGRESS BAR FILL (rate-based: speed upgrade multiplies the fill rate)
		var mode := get_mode()
		_cycle_mode = worst_mode(_cycle_mode, mode)
		var eff_boost = Compiling.BURST_SPEED if (eff_proc and mode != Mode.OVERHEATED) else 1.0
		_fill += delta * get_fill_rate(mode) * eff_boost
		_fill_seconds += delta # real time only: bursts and speed don't change tokens per hour
		var fills := 0
		while _fill >= fill_bar.max_value and fills < MAX_FILLS_PER_FRAME:
			_fill -= fill_bar.max_value
			fills += 1
			_update_scramble_labels() # snap to fully resolved token
			_compile_payload()
			if !_has_resources_for_more() or stop_requested or _reached_goal():
				fill_bar.value = fill_bar.max_value
				_stop_compiling()
				return
			_generate_targets()
			if _waiting_for_debug():
				_fill = 0.0
				break
		if fills >= MAX_FILLS_PER_FRAME:
			_fill = min(_fill, fill_bar.max_value - 0.01)
		fill_bar.value = _fill

		#SCRAMBLED CHARS LABELS, revealing in tandem with fill_bar
		if Stats.overheated:
			if _time_accum >= scramble_interval + 0.5:
				_time_accum -= scramble_interval + 0.5
				_update_scramble_labels()
		else:
			if _time_accum >= scramble_interval:
				_time_accum -= scramble_interval
				_update_scramble_labels()

## Mod at its normal cap with the Debug capstone installed but Debug off: the terminal waits instead of stopping
func _waiting_for_debug() -> bool:
	if hacking_mod_item == null or has_modifier("debug") or !Upgrades.has("compiling.debug_build"):
		return false
	var t = hacking_mod_item.hacking_mod_type
	if !HackingMods.has_mod(t):
		return false
	var d = int(HackingMods.current_mods[t].duration)
	return d >= Compiling.mod_cap(hacking_mod_item) and d < Compiling.mod_cap(hacking_mod_item, true)

## Mod: stop once the mod is at its cap.
func _reached_goal() -> bool:
	if process_data == Compiling.MOD and hacking_mod_item:
		var t = hacking_mod_item.hacking_mod_type
		return HackingMods.has_mod(t) and int(HackingMods.current_mods[t].duration) >= _mod_cap() and !_waiting_for_debug()
	return false

func _update_labels():
	if process_data == Compiling.MOD:
		payload_name.text = "HACKING MOD"
	else:
		payload_name.text = str(process_data["resource gained"].name).to_upper()
	if process_data == Compiling.MOD:
		var t = hacking_mod_item.hacking_mod_type
		var value = HackingMods.current_mods[t].value if HackingMods.has_mod(t) else hacking_mod_item.hacking_mod_value * _mod_value_mult()
		var hacks = int(HackingMods.current_mods[t].duration) if HackingMods.has_mod(t) else 0
		payload_item.text = HackingMods.get_mod_name(t) + " " + HackingMods.get_mod_value_text(t, value)
		amount_gained_label.text = "%d/%d hacks" % [hacks, _mod_cap()]
		for container in ingredients_container.get_children():
			container.update_amount()
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

## Recovery: chance a fill's inputs aren't consumed (never the access rares)
func _take_inputs(cost: Dictionary, keep_rares_for: ItemData = null) -> void:
	var recovered = randf() < Upgrades.cur("compiling.recovery")
	for req in cost:
		if recovered and req != keep_rares_for:
			continue
		Inventory.remove_resource(req, cost[req])

func _mod_value_mult() -> float:
	return 1.0 + Upgrades.cur("compiling.mod_tuning")

## One full bar
func _compile_payload():
	_refresh_reqs()
	if !Compiling.can_afford(_reqs):
		return # spent somewhere else meanwhile
	if process_data == Compiling.MOD:
		var cap = _mod_cap()
		if !HackingMods.has_mod(hacking_mod_item.hacking_mod_type) and HackingMods.at_max_mods():
			return
		_take_inputs(_reqs)
		# Survey: half output (each hack is a coin flip)
		if !has_modifier("survey") or randf() < 0.5:
			HackingMods.extend_mod(hacking_mod_item, _mod_value_mult(), cap)
			SaveManager.mark_dirty()
	else:
		_take_inputs(_reqs)
		#GIVETH: Linker can build two at once; Survey halves (coin flip on odd amounts)
		var amount_to_gain = 2 if randf() < Upgrades.cur("compiling.linker") else 1
		if has_modifier("survey"):
			amount_to_gain = amount_to_gain / 2 + (1 if amount_to_gain % 2 == 1 and randf() < 0.5 else 0)
		if amount_to_gain > 0:
			Inventory.add_resource(process_data["resource gained"], amount_to_gain)
			Tutorial.track_event(Tutorial.TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS, amount_to_gain)
		amount_gained += amount_to_gain
	if randf() <= _token_chance():
		Inventory.add_resource(Items.VM_COMPILING_TOKEN, 1)
	_fill_seconds = 0.0

	#UPDATETH
	process_data.signal.emit(1)
	Exp.add_xp(Compiling, process_data, process_data["experience per level"] * (2 if has_modifier("survey") else 1))
	Signals.update_hud(Compiling)

	#HEATETH (burst fills add no heat)
	if !eff_proc:
		apply_heat(_cycle_mode)
	_cycle_mode = Mode.NORMAL
	record_cycle(1)

	#EFFICIENCY: a burst can start on any process (payloads, Mod hacks)
	if randf() <= _get_current_eff():
		_efficiency_trigger()
	_update_eff_label()

	_update_labels()

## VM token chance for the fill just finished, rolled on time spent (speed, bursts and overclock don't change
## tokens per hour): "vm token chance" is for a base-speed fill. Build Cache and Optimize double it.
func _token_chance() -> float:
	var base = 100.0 / max(0.001, float(process_data["base speed"]))
	var chance = (float(process_data.get("vm token chance", 0.01)) + Exp.vm_token_level_bonus(skill)) * (_fill_seconds / base)
	if Upgrades.has("compiling.build_cache"):
		chance *= 2.0
	if has_modifier("optimize"):
		chance *= 2.0
	return chance

func _efficiency_trigger():
	if eff_proc:
		return
	
	eff_proc = true
	eff_timer.wait_time = Compiling.BURST_SECONDS
	eff_timer.start()
	

func _has_resources_for_more() -> bool:
	if process_data == Compiling.MOD and hacking_mod_item == null:
		return false
	_refresh_reqs()
	return Compiling.can_afford(_reqs)

func _stop_compiling():
	finish_safely()

func _rebuild_item_containers() -> void:
	for c in ingredients_container.get_children():
		c.queue_free()
	_build_item_containers(process_data)

func _build_item_containers(_p_type: Dictionary):
	if true:
		for req in _reqs:
			var container = item_container_scene.instantiate()
			container.set_labels({"item": req, "amount": _reqs[req]})
			ingredients_container.add_child(container)

func _random_string(length: int, source_charset: String) -> String:
	var result := ""
	for i in range(length):
		result += source_charset[randi() % source_charset.length()]
	return result


func _on_eff_timer_timeout():
	eff_proc = false

## Burst chance: the process's efficiency with the (relative) Efficiency track; Optimize doubles it
func _get_current_eff() -> float:
	return min(1.0, Compiling.get_efficiency(process_data) * (2.0 if has_modifier("optimize") else 1.0))
