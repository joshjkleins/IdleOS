extends BaseTerminal
## Mining terminal: fills a 20-segment bar, each segment one speed step; a full bar = one cycle.


@onready var blinking_timer = $BlinkingTimer
@onready var title = $MarginContainer/VBoxContainer/SecondRow/Title
@onready var tier = $MarginContainer/VBoxContainer/SecondRow/HBoxContainer/Tier
@onready var progress_row = $MarginContainer/VBoxContainer/ProgressRow
@onready var percent_label = $MarginContainer/VBoxContainer/FourthRow/HBoxContainer/PercentLabel
@onready var data_yield_label = $MarginContainer/VBoxContainer/InfoRow/DataCol/DataYield
@onready var cycles_label = $MarginContainer/VBoxContainer/InfoRow/CyclesCol/Cycles
@onready var time_label = $MarginContainer/VBoxContainer/InfoRow/TimeCol/Time
@onready var efficiency_label = $MarginContainer/VBoxContainer/InfoRow/EffeciencyCol/EfficiencyLabel
@onready var level_label = $MarginContainer/VBoxContainer/InfoRow/LevelCol/LevelLabel
@onready var yield_title_label = $MarginContainer/VBoxContainer/InfoRow/DataCol/YieldTitleLabel

@onready var total_label_title = $MarginContainer/VBoxContainer/InfoRow/TotalCol/TotalLabelTitle
@onready var total_label_amount = $MarginContainer/VBoxContainer/InfoRow/TotalCol/TotalLabelAmount

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

var RESOURCE_GAIN: ItemData
var EXP_PER_COMPLETION: int = 0

func _process(delta):
	super(delta)
	if running:
		time_label.text = format_time(session_time)

func set_mine_type(type: Dictionary, window: bool = false):
	setup_process(Mining, type, window)
	RESOURCE_GAIN = type["resource gained"]
	EXP_PER_COMPLETION = type["experience per level"]
	tier.text = type["tier name"]
	yield_title_label.text = type["name"].to_upper() + " YIELD"
	title.text = "MINING " + type["name"].to_upper()
	total_label_title.text = "TOTAL " + type["name"].to_upper()
	total_label_amount.text = str(Inventory.get_amount(RESOURCE_GAIN))

func start_data_mining():
	begin_run()
	_reset_info()
	_create_progress_row()
	blinking_timer.start()
	while running:
		if stop_requested:
			finish_safely()
			break
		var cycle_mode := Mode.NORMAL
		for i in range(SEGMENTS):
			_set_progress(i)
			var mode := get_mode()
			cycle_mode = worst_mode(cycle_mode, mode)
			await get_tree().create_timer(get_step_time(mode)).timeout
			if !running:
				break
		if running:
			_cycle_complete(cycle_mode)

func _on_stopped():
	blinking_timer.stop()

func _cycle_complete(cycle_mode: Mode):
	apply_heat(cycle_mode)

	var reward_quantity_gained = _get_reward_quantity()
	Inventory.add_resource(RESOURCE_GAIN, reward_quantity_gained)
	total_label_amount.text = str(Inventory.get_amount(RESOURCE_GAIN))
	Tutorial.track_event(Tutorial.TutorialEvent.MINE_20_LOGS, reward_quantity_gained)
	if randf() <= 0.01:
		Inventory.add_resource(Items.VM_MINING_TOKEN, 1)
	process_data.signal.emit(reward_quantity_gained)
	Exp.add_xp(Mining, process_data, EXP_PER_COMPLETION)
	Signals.update_hud(Mining)
	record_cycle(reward_quantity_gained)
	cycles_label.text = str(session_cycles)
	data_yield_label.text = str(session_yield)

	_update_efficiency_label()
	level_label.text = str(Mining.SKILL["level"])

func _get_mining_efficiency_total():
	var base_efficiency = process_data["efficiency"]
	var defrag_multiplier = Defragging.MINING["bonus efficiency"] if Stats.has_bonus(Mining) else 1.0
	var efficiency_upgrade = Upgrades.get_package_info("mining.efficiency").current
	return (base_efficiency + efficiency_upgrade) * defrag_multiplier

## 1 + one extra per full point of efficiency + a roll for the leftover fraction.
func _get_reward_quantity() -> int:
	var eff = _get_mining_efficiency_total()
	var quant = 1
	var guaranteed = int(eff)
	quant += guaranteed
	eff -= guaranteed
	if eff > 0.0 and randf() <= eff:
		quant += 1
	return quant

func _reset_info():
	_update_efficiency_label()
	level_label.text = str(Mining.SKILL["level"])

func _update_efficiency_label():
	efficiency_label.text = str(_get_mining_efficiency_total() * 100.0) + "%"

func _on_blinking_timer_timeout():
	pass

func _create_progress_row():
	styleEmpty  = _make_style(COLOR_SEG_EMPTY,  COLOR_SEG_EMPTY_BDR)
	styleFilled = _make_style(COLOR_SEG_FILLED, COLOR_SEG_FILLED_BDR)
	styleHead   = _make_style(COLOR_SEG_HEAD,   COLOR_SEG_HEAD_BDR)
	for n in progress_row.get_children():
		n.queue_free()
	panel_segments.clear()
	for i in range(SEGMENTS):
		var p = Panel.new()
		p.custom_minimum_size = Vector2(0, 18)
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
	percent_label.text = str(int(float(num) / float(SEGMENTS) * 100.0)) + "%"
