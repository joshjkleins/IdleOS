class_name TrapStatus
extends HBoxContainer
## Right panel: one small row for the Phishing trap ("TRAP  [bar]  62% · 17m" / "TRAP  [bar]  READY").
## Hidden until Trap is unlocked. Built in code by system_dock.gd.

const DIM = Color(0.45, 0.5, 0.55, 1)
const TEXT = Color(0.8, 0.84, 0.88, 1)
const READY = Color("#4ec994")
const FONT_SIZE = 11
const BAR_WIDTH = 90.0

var _title: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _status: Label
var _accum := 1.0

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_title = _label("TRAP", DIM)
	_title.custom_minimum_size.x = 34
	add_child(_title)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(1, 1, 1, 0.08)
	_bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, 6)
	_bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Phishing.SKILL.color
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bg.add_child(_bar_fill)
	_status = _label("", TEXT)
	add_child(_status)
	Phishing.trap_changed.connect(refresh)
	refresh()

func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	return l

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 1.0:
		_accum = 0.0
		refresh()

func refresh() -> void:
	visible = Phishing.TRAP.unlocked or Phishing.has_trap()
	if !visible:
		return
	var p = Phishing.trap_progress()
	_bar_fill.size = Vector2(BAR_WIDTH * p, 6)
	if !Phishing.has_trap():
		_status.text = "not set"
		_status.add_theme_color_override("font_color", DIM)
		tooltip_text = "Set one in Phishing with 'phish -trap'."
	elif p >= 1.0:
		_status.text = "READY"
		_status.add_theme_color_override("font_color", READY)
		_bar_fill.color = READY
		tooltip_text = "Trap is full: 'trap collect'"
	else:
		_status.text = "%d%% · %s" % [int(p * 100), Phishing.format_minutes(Phishing.trap_seconds_left())]
		_status.add_theme_color_override("font_color", TEXT)
		_bar_fill.color = Phishing.SKILL.color
		tooltip_text = "Trap filling. 'trap' for status, 'trap collect' to take a partial haul."
