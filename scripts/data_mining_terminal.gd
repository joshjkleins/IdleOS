extends PanelContainer


@onready var blinking_timer = $BlinkingTimer
@onready var breadcrumbs = $MarginContainer/VBoxContainer/FirstRow/Breadcrumbs
@onready var running_label = $MarginContainer/VBoxContainer/FirstRow/HBoxContainer/RunningLabel
@onready var title = $MarginContainer/VBoxContainer/SecondRow/Title
@onready var tier = $MarginContainer/VBoxContainer/SecondRow/HBoxContainer/Tier
@onready var progress_row = $MarginContainer/VBoxContainer/ProgressRow
@onready var percent_label = $MarginContainer/VBoxContainer/FourthRow/HBoxContainer/PercentLabel
@onready var data_yield_label = $MarginContainer/VBoxContainer/InfoRow/DataCol/DataYield
#@onready var data_rate_label = $MarginContainer/VBoxContainer/InfoRow/RateCol/DataRate
@onready var cycles_label = $MarginContainer/VBoxContainer/InfoRow/CyclesCol/Cycles
@onready var time_label = $MarginContainer/VBoxContainer/InfoRow/TimeCol/Time
@onready var efficiency_label = $MarginContainer/VBoxContainer/InfoRow/EffeciencyCol/EfficiencyLabel
@onready var level_label = $MarginContainer/VBoxContainer/InfoRow/LevelCol/LevelLabel
@onready var yield_title_label = $MarginContainer/VBoxContainer/InfoRow/DataCol/YieldTitleLabel



# Data Mining – color scheme
# Backgrounds
const COLOR_CARD_BG       = Color("#060910")
const COLOR_CARD_BORDER   = Color("#0e1a30")

# Segments
const COLOR_SEG_EMPTY     = Color("#0a1520")
const COLOR_SEG_EMPTY_BDR = Color("#0e2238")
const COLOR_SEG_FILLED    = Color("#1a6496")
const COLOR_SEG_FILLED_BDR= Color("#2580b8")
const COLOR_SEG_HEAD      = Color("#3ab0f0")
const COLOR_SEG_HEAD_BDR  = Color("#6eceff")

# Text hierarchy
const COLOR_TEXT_NAME     = Color("#7fccff")
const COLOR_TEXT_ACCENT   = Color("#3ab0f0")
const COLOR_TEXT_STAT     = Color("#4a9ac0")
const COLOR_TEXT_DIM      = Color("#1a4a6a")
const COLOR_TEXT_LOG      = Color("#1a5570")
const COLOR_TEXT_LOG_NEW  = Color("#2a80a0")

# Status
const COLOR_STATUS_RUNNING  = Color("#3ab0f0")
const COLOR_STATUS_COMPLETE = Color("#1dbc7a")

# Dividers
const COLOR_DIVIDER         = Color("#0e1e30")
const COLOR_DIVIDER_LOG     = Color("#0a1820")

const SEGMENTS = 20

var styleEmpty    : StyleBoxFlat
var styleFilled   : StyleBoxFlat
var styleHead     : StyleBoxFlat

var panel_segments: Array = []
var percent_label_tween: Tween

var process_running: bool = false
var blink_on: bool = false
var session_yield: int = 0
var session_rate: float = 0.0
var session_cycle: int = 0
var session_time: float = 0.0

var end_safely: bool = false

var BASE_SPEED: float = 0.0
var OVERCLOCK_SPEED: float = 0.0
var OVERHEAT_SPEED: float = 0.0
var HEAT: int = 0
var OVERCLOCK_HEAT: int = 0
var OVERHEAT_HEAT: int = 0
var RESOURCE_GAIN: ItemData
var EXP_PER_COMPLETION: int = 0
var EFFICIENCY_RATE: float = 0.0
var TYPE: Dictionary
var is_window: bool = false

func _process(delta):
	if process_running:
		session_time += delta
		time_label.text = _format_time(session_time)

func set_mine_type(type: Dictionary, window: bool = false):
	is_window = window
	TYPE = type
	BASE_SPEED = type["base speed"] / Mining.process_upgrades["speed"]["amount"]
	OVERCLOCK_SPEED = type["overclock speed"] / Mining.process_upgrades["speed"]["amount"]
	OVERHEAT_SPEED = type["overheat speed"] / Mining.process_upgrades["speed"]["amount"]
	HEAT = type["heat"]
	OVERCLOCK_HEAT = type["overclock heat"]
	OVERHEAT_HEAT = type["overheat heat"]
	RESOURCE_GAIN = type["resource gained"]
	EXP_PER_COMPLETION = type["experience per level"]
	EFFICIENCY_RATE = type["efficiency rate"] + (Mining.process_upgrades["efficiency"]["amount"] - 1.0)
	tier.text = type["tier name"]
	yield_title_label.text = type["name"].to_upper() + " YIELD"
	title.text = "MINING " + type["name"].to_upper()

func start_data_mining():
	process_running = true
	_reset_info()
	_create_progress_row()
	blinking_timer.start()
	end_safely = false
	while process_running:
		if end_safely:
			if !is_window:
				Signals.end_data_mining_safely()
			stop()
			break
		var overclocked = false
		var overheated = false
		for i in range(SEGMENTS):
			_set_progress(i)
			
			#_update_rate_label()
			if Stats.overheated:
				await get_tree().create_timer(OVERHEAT_SPEED).timeout
				overheated = true
			elif Stats.overclocked and !is_window:
				await get_tree().create_timer(OVERCLOCK_SPEED).timeout
				overclocked = true
			else:
				await get_tree().create_timer(BASE_SPEED).timeout
			if !process_running:
				break
		if process_running:
			_cycle_complete(overclocked, overheated)

func stop():
	process_running = false
	blinking_timer.stop()
	if is_window:
		Mining.CURRENT_VMS -= 1
		get_parent().queue_free()

func stop_safely():
	end_safely = true

func _cycle_complete(overclocked: bool, overheated: bool):
	if !is_window:
		if overheated:
			Stats.update_tempature(OVERHEAT_HEAT)
		elif overclocked and !is_window:
			Stats.update_tempature(OVERCLOCK_HEAT)
		else:
			Stats.update_tempature(HEAT)
	
	var reward_quantity_gained = _get_reward_quantity()
	Inventory.add_resource(RESOURCE_GAIN, reward_quantity_gained)
	TYPE.signal.emit(reward_quantity_gained)
	Exp.add_xp(Mining, TYPE, EXP_PER_COMPLETION  * Mining.process_upgrades["experience"]["amount"])
	Signals.update_hud(Mining)
	session_cycle += 1
	session_yield += reward_quantity_gained
	cycles_label.text = str(session_cycle)
	data_yield_label.text = str(session_yield)
	var eff_label_text = ""
	var frag_bonus = Defragging.MINING["bonus efficiency"] if Stats.has_bonus(Mining) else 0.0

	eff_label_text = str((TYPE["efficiency"] + Mining.process_upgrades["efficiency"]["amount"] + frag_bonus)  * 100.0) + "%"

	efficiency_label.text = eff_label_text
	level_label.text = str(Mining.SKILL["level"])

func _get_reward_quantity() -> int:
	var frag_bonus = Defragging.MINING["bonus efficiency"] if Stats.has_bonus(Mining) else 0.0
	var eff = TYPE["efficiency"] + Mining.process_upgrades["efficiency"]["amount"] + frag_bonus
	
	var quant = 1

	# Guaranteed bonus for each full point of efficiency
	var guaranteed = int(eff)
	quant += guaranteed
	eff -= guaranteed  # leftover fractional part, e.g. 0.5

	# Probabilistic roll for the remaining fraction
	if eff > 0.0:
		if randf() <= eff:
			quant += 1
	
	return quant

func _reset_info():
	blink_on = false
	session_yield = 0
	session_rate = 0.0
	session_cycle = 0
	session_time = 0.0
	#_update_rate_label()
	var frag_bonus = Defragging.MINING["bonus efficiency"] if Stats.has_bonus(Mining) else 0.0

	efficiency_label.text = str((TYPE["efficiency"] + Mining.process_upgrades["efficiency"]["amount"] + frag_bonus)  * 100.0) + "%"

	level_label.text = str(Mining.SKILL["level"])

func _on_blinking_timer_timeout():
	if blink_on:
		running_label.add_theme_color_override("font_color", COLOR_TEXT_NAME)
		blink_on = false
	else:
		running_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		blink_on = true

func _create_progress_row():
	styleEmpty  = _make_style(COLOR_SEG_EMPTY,  COLOR_SEG_EMPTY_BDR)
	styleFilled = _make_style(COLOR_SEG_FILLED, COLOR_SEG_FILLED_BDR)
	styleHead   = _make_style(COLOR_SEG_HEAD,   COLOR_SEG_HEAD_BDR)
	for n in progress_row.get_children():
		n.queue_free()
	for i in range(SEGMENTS):
		var p = Panel.new()
		p.custom_minimum_size = Vector2(0, 22)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", styleEmpty.duplicate())
		progress_row.add_child(p)
		panel_segments.append(p)

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	return s

func _set_progress(filled: int):
	_update_label(filled)
	for i in SEGMENTS:
		if i < filled:
			panel_segments[i].add_theme_stylebox_override("panel", styleFilled)
		elif i == filled:
			panel_segments[i].add_theme_stylebox_override("panel", styleHead)
		else:
			panel_segments[i].add_theme_stylebox_override("panel", styleEmpty)
			
	
	if filled >= SEGMENTS:
		_reset_progress_row()

func _reset_progress_row():
	for n in progress_row.get_children():
		n.add_theme_stylebox_override("panel", styleEmpty)

func _update_label(num: int):
	var nn = float(num) / float(SEGMENTS) * 100.0
	percent_label.text = str(int(nn)) + "%"

func _format_time(total_seconds: float) -> String:
	var seconds: int = int(total_seconds) % 60
	var minutes: int = int(total_seconds / 60) % 60
	var hours: int = int(total_seconds / 3600)
	
	# %02d pads the number with a leading zero if it's a single digit
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
