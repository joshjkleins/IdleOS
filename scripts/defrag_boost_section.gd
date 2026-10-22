class_name DefragBoostSection
extends VBoxContainer
## Side panel, top: the running Defragging boost (name, effect, time left, draining bar).
## Hidden while no boost is active. The header's Defragging card only shows the cooldown.

const HEADER = Color(0.36, 0.42, 0.48, 1)
const TEXT = Color(0.8, 0.84, 0.88, 1)
const FONT = 10
const ROW_FONT = 11

var _name: Label
var _time: Label
var _effect: Label
var _bar: ProgressBar
var _fill: StyleBoxFlat
var _sep: HSeparator # the line under it (hidden with it)
var _accum := 0.0

func _ready() -> void:
	add_theme_constant_override("separation", 3)
	add_child(_label("DEFRAG BOOST", FONT, HEADER))
	var line := HBoxContainer.new()
	add_child(line)
	_name = _label("", ROW_FONT, TEXT)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	line.add_child(_name)
	_time = _label("", ROW_FONT, TEXT)
	line.add_child(_time)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 4)
	_bar.max_value = 1.0
	_bar.step = 0.001
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(1, 1, 1, 0.06)
	_fill = StyleBoxFlat.new(); _fill.bg_color = Defragging.SKILL.color
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", _fill)
	add_child(_bar)
	_effect = _label("", FONT, HEADER)
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_effect)
	_refresh()

func set_separator(sep: HSeparator) -> void:
	_sep = sep
	_refresh()

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	_refresh()

func _refresh() -> void:
	var boosts = Defragging.get_active()
	visible = !boosts.is_empty()
	if _sep:
		_sep.visible = visible
	if !visible:
		return
	var p: Dictionary = boosts[0]
	var total = max(1.0, Upgrades.get_defrag_minutes() * 60.0)
	var left = Stats.get_bonus_time_remaining(p.get("expires_at", 0))
	_name.text = "%s  %s" % [str(p.name).to_lower(), p.get("bonus label", "")]
	_name.add_theme_color_override("font_color", p.get("color", TEXT))
	_fill.bg_color = p.get("color", Defragging.SKILL.color)
	_time.text = Stats.get_bonus_time_text(p)
	_bar.value = clamp(left / total, 0.0, 1.0)
	_effect.text = p.get("description", "")

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
