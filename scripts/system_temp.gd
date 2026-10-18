class_name SystemTemp
extends VBoxContainer
## SYSTEM section of the side dock: temperature readout, heat bar, cooling rate and state.
## Thresholds mirror Stats.update_tempature(): overheat at 95, recovers at 80, overclock needs < 80.

const TEMP_MIN = 30.0
const TEMP_MAX = 100.0
## overheat clears / overclock allowed below this (80, raised by System's Thermal Paste)
static func overclock_limit() -> float:
	return Upgrades.get_overheat_clear_temp()
const CRITICAL = 95.0
const SEGMENTS = 35

const C_COOL = Color("#2d9e75")
const C_WARM = Color("#c6a700")
const C_HOT = Color("#d85a30")
const C_CRIT = Color("#e24b4a")
const C_OC = Color("#29b6f6")
const C_DIM = Color(0.36, 0.42, 0.48, 1)
const C_EMPTY = Color(1, 1, 1, 0.05)

@onready var status_pill: PanelContainer = %StatusPill
@onready var status_label: Label = %StatusLabel
@onready var temp_label: Label = %TempLabel
@onready var rate_label: Label = %RateLabel
@onready var heat_label: Label = %HeatLabel
@onready var bar: Control = %HeatBar
@onready var hint_label: Label = %HintLabel

var temperature: float = 30.0
var _recent_heat: float = 0.0
var _heat_tween: Tween
var _pulse_time: float = 0.0

func _ready() -> void:
	Signals.system_temp_updated_signal.connect(_on_temp_updated)
	Signals.system_temp_updated_signal.connect(func(_t): _update_rate()) # picks up Defragging: Cooling turning on/off
	Signals.heat_added_signal.connect(_on_heat_added)
	Signals.cooling_updated_signal.connect(_update_rate)
	bar.draw.connect(_draw_bar)
	heat_label.modulate.a = 0.0
	_on_temp_updated(Stats.system_tempature)
	_update_rate()
	_update_version()
	Upgrades.installed.connect(func(_p, _l): _update_version())
	SaveManager.save_loaded.connect(_update_version) # the panel is built before the save loads

## "SYSTEM  v1.4": System's apt version on the panel title
func _update_version() -> void:
	var title = get_node_or_null("Header/Title")
	if title:
		title.text = "SYSTEM  " + Upgrades.version_text("System")

func _process(delta: float) -> void:
	# overclock has no signal, so state is polled; also drives the overheat pulse
	_update_state()
	if Stats.overheated:
		_pulse_time += delta
		temp_label.modulate.a = 0.65 + 0.35 * sin(_pulse_time * 6.0)
	else:
		temp_label.modulate.a = 1.0

static func zone_color(t: float) -> Color:
	if t >= CRITICAL:
		return C_CRIT
	if t >= overclock_limit():
		return C_HOT
	if t >= 60.0:
		return C_WARM
	return C_COOL

func _on_temp_updated(t: float) -> void:
	temperature = t
	temp_label.text = "%.1f°C" % t
	temp_label.add_theme_color_override("font_color", zone_color(t))
	bar.queue_redraw()
	_update_state()

func _on_heat_added(amount: float) -> void:
	# collapse rapid heat ticks into one fading "+x.x°C"
	_recent_heat += amount
	heat_label.text = "+%.1f°C" % _recent_heat
	heat_label.modulate.a = 1.0
	if _heat_tween:
		_heat_tween.kill()
	_heat_tween = create_tween()
	_heat_tween.tween_interval(1.2)
	_heat_tween.tween_property(heat_label, "modulate:a", 0.0, 0.6)
	_heat_tween.tween_callback(func(): _recent_heat = 0.0)

func _update_rate() -> void:
	var per_second = min(0.0, Stats.get_cooling_amount() / Stats.cooling_frequency)
	rate_label.text = "%.1f°C/s" % per_second

func _update_state() -> void:
	var text: String
	var color: Color
	var hint: String
	if Stats.overheated:
		text = "OVERHEATED"; color = C_CRIT
		hint = "processes slowed · cool to %d°C" % int(overclock_limit())
	elif Stats.overclocked:
		text = "OVERCLOCKED"; color = C_OC
		hint = "increased speed · extra heat per cycle"
	elif temperature >= overclock_limit():
		text = "HOT"; color = C_HOT
		hint = "overclock locked until < %d°C" % int(overclock_limit())
	else:
		text = "NOMINAL"; color = C_COOL
		hint = "overclock available" if _any_overclock_unlocked() else "stable"
	if status_label.text != text:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
		var box: StyleBoxFlat = status_pill.get_theme_stylebox("panel").duplicate()
		box.border_color = color.darkened(0.25)
		box.bg_color = Color(color, 0.12)
		status_pill.add_theme_stylebox_override("panel", box)
	hint_label.text = hint

func _any_overclock_unlocked() -> bool:
	return Upgrades.any_overclock_unlocked()

func _pct(t: float) -> float:
	return clamp((t - TEMP_MIN) / (TEMP_MAX - TEMP_MIN), 0.0, 1.0)

func _draw_bar() -> void:
	var w = bar.size.x
	var h = 10.0
	var gap = 2.0
	var seg_w = (w - gap * (SEGMENTS - 1)) / SEGMENTS
	var filled = int(round(_pct(temperature) * SEGMENTS))
	for i in SEGMENTS:
		var seg_temp = TEMP_MIN + (i + 0.5) / SEGMENTS * (TEMP_MAX - TEMP_MIN)
		var col = zone_color(seg_temp) if i < filled else C_EMPTY
		if i == filled - 1:
			col = col.lightened(0.25) # leading segment
		bar.draw_rect(Rect2(i * (seg_w + gap), 0, seg_w, h), col)
	# threshold markers + labels under the bar
	var font = get_theme_default_font()
	for mark in [[overclock_limit(), "OC %d" % int(overclock_limit())], [CRITICAL, "CRIT"]]:
		var x = _pct(mark[0]) * w
		bar.draw_line(Vector2(x, -3), Vector2(x, h + 3), C_DIM, 1.0)
		bar.draw_string(font, Vector2(x - 14, h + 14), mark[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_DIM)
	bar.draw_string(font, Vector2(0, h + 14), "%d" % int(TEMP_MIN), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_DIM)
