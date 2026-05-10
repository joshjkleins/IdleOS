extends PanelContainer


@onready var blinking_timer = $BlinkingTimer
@onready var breadcrumbs = $MarginContainer/VBoxContainer/FirstRow/Breadcrumbs
@onready var running_label = $MarginContainer/VBoxContainer/FirstRow/HBoxContainer/RunningLabel
@onready var title = $MarginContainer/VBoxContainer/SecondRow/Title
@onready var tier = $MarginContainer/VBoxContainer/SecondRow/HBoxContainer/Tier
@onready var progress_row = $MarginContainer/VBoxContainer/ProgressRow
@onready var percent_label = $MarginContainer/VBoxContainer/FourthRow/HBoxContainer/PercentLabel
@onready var data_yield_label = $MarginContainer/VBoxContainer/InfoRow/DataCol/DataYield
@onready var data_rate_label = $MarginContainer/VBoxContainer/InfoRow/RateCol/DataRate
@onready var cycles_label = $MarginContainer/VBoxContainer/InfoRow/CyclesCol/Cycles
@onready var time_label = $MarginContainer/VBoxContainer/InfoRow/TimeCol/Time
@onready var efficiency_label = $MarginContainer/VBoxContainer/InfoRow/EffeciencyCol/EfficiencyLabel
@onready var level_label = $MarginContainer/VBoxContainer/InfoRow/LevelCol/LevelLabel



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

#to finish
#update color scheme to white / grey

func _process(delta):
	if process_running:
		session_time += delta
		time_label.text = _format_time(session_time)

func start_data_mining():
	process_running = true
	_reset_info()
	_create_progress_row()
	blinking_timer.start()
	end_safely = false
	while process_running:
		if end_safely:
			Signals.end_data_mining_safely()
			stop()
			break
		var overclocked = false
		var overheated = false
		for i in range(SEGMENTS):
			_set_progress(i)
			
			_update_rate_label()
			if Stats.overheated:
				await get_tree().create_timer(Stats.player_stats["Data Mining"]["overheat speed"]).timeout
				overheated = true
			elif Stats.overclocked:
				await get_tree().create_timer(Stats.player_stats["Data Mining"]["overclock speed"]).timeout
				overclocked = true
			else:
				await get_tree().create_timer(Stats.player_stats["Data Mining"]["base speed"]).timeout
			if !process_running:
				break
		if process_running:
			_cycle_complete(overclocked, overheated)

func stop():
	process_running = false
	blinking_timer.stop()

func stop_safely():
	end_safely = true

func _cycle_complete(overclocked: bool, overheated: bool):
	if overheated:
		Stats.update_tempature(Stats.player_stats["Data Mining"]["overheat heat"])
	elif overclocked:
		Stats.update_tempature(Stats.player_stats["Data Mining"]["overclock heat"])
	else:
		Stats.update_tempature(Stats.player_stats["Data Mining"]["heat"])
	
	var data_quantity_gained = _get_data_quantity()
	Inventory.add_resource(Items.DATA, data_quantity_gained)
	
	Stats.add_xp(Stats.player_stats["Data Mining"])
	session_cycle += 1
	session_yield += data_quantity_gained
	cycles_label.text = str(session_cycle)
	data_yield_label.text = str(session_yield)
	efficiency_label.text = str(Stats.player_stats["Data Mining"]["efficiency"]  * 100.0) + "%"
	level_label.text = str(Stats.player_stats["Data Mining"]["level"])

func _get_data_quantity() -> int:
	var eff = Stats.player_stats["Data Mining"]["efficiency"]
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
	_update_rate_label()
	efficiency_label.text = str(Stats.player_stats["Data Mining"]["efficiency"]  * 100.0) + "%"
	level_label.text = str(Stats.player_stats["Data Mining"]["level"])

func _update_rate_label():
	var speed
	if Stats.overheated:
		speed = Stats.player_stats["Data Mining"]["overheat speed"]
	elif Stats.overclocked:
		speed = Stats.player_stats["Data Mining"]["overclock speed"]
	else:
		speed = Stats.player_stats["Data Mining"]["base speed"]
	var yr = 1.0 / (float(SEGMENTS) * float(speed))
	data_rate_label.text = str(yr).pad_decimals(2) + " D/s"

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
