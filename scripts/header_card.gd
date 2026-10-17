class_name HeaderCard
extends PanelContainer
## One header card: accent line in the skill color, title + level, segmented bar, footer line.
## Used for root skill cards, the skill-view main card and process cards.

const C_BG = Color(0.0352941, 0.0431373, 0.054902, 1)
const C_BORDER = Color(0.12549, 0.160784, 0.196078, 1)
const C_DIM = Color(0.36, 0.42, 0.48, 1)
const C_TEXT = Color(0.85, 0.88, 0.91, 1)
const C_LOCKED = Color(0.3, 0.34, 0.38, 1)
const C_BONUS = Color("#ffc24a") # active defrag bonus: bright so it stands out

var skill: Node           # major skill (or Defragging) this card belongs to
var process: Dictionary   # set for process cards
var accent: Color = Color.WHITE

var title_label: Label
var level_label: Label
var bar: HeaderBar
var left_label: Label
var right_label: Label
var float_label: Label    # "+20" xp popups
var _style: StyleBoxFlat
var _float_tween: Tween
signal level_up_finished # header refills the card with fresh values on this

var celebrating: bool = false # true while the level-up effect plays (xp updates wait)

## big = the main card in skill view (bigger title, xp numbers)
func build(p_accent: Color, big: bool = false, min_width: float = 0.0) -> void:
	accent = p_accent
	custom_minimum_size = Vector2(min_width, 0)
	clip_contents = false
	_style = StyleBoxFlat.new()
	_style.bg_color = C_BG
	_style.border_color = C_BORDER
	_style.set_border_width_all(1)
	_style.border_width_top = 2
	_style.content_margin_left = 10
	_style.content_margin_right = 10
	_style.content_margin_top = 6
	_style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", _style)
	set_accent(accent)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	title_label = _label(14 if big else 12, accent)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	top.add_child(title_label)
	level_label = _label(12 if big else 11, C_TEXT)
	top.add_child(level_label)

	bar = HeaderBar.new()
	bar.custom_minimum_size = Vector2(0, 6 if big else 4)
	bar.segments = 20 if big else 12
	bar.color = accent
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar)

	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bottom)
	left_label = _label(10, C_DIM)
	left_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(left_label)
	float_label = _label(10, Color("#4ec994"))
	float_label.modulate.a = 0.0
	bottom.add_child(float_label)
	right_label = _label(10, C_DIM)
	bottom.add_child(right_label)

	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_accent(c: Color) -> void:
	accent = c
	queue_redraw() # accent line is drawn in _draw()

func _draw() -> void:
	# accent line along the top edge
	draw_rect(Rect2(0, 0, size.x, 2), accent if !is_locked() else C_LOCKED)

var _locked := false
func is_locked() -> bool:
	return _locked

func set_locked(locked: bool, unlock_text: String = "") -> void:
	_locked = locked
	modulate = Color(1, 1, 1, 0.55) if locked else Color.WHITE
	title_label.add_theme_color_override("font_color", C_LOCKED if locked else accent)
	if locked:
		level_label.text = ""
		bar.value = 0.0
		left_label.text = unlock_text
		right_label.text = ""
	queue_redraw()

## Highlight (e.g. the running process).
func set_active(active: bool) -> void:
	_style.border_color = accent.darkened(0.2) if active else C_BORDER
	add_theme_stylebox_override("panel", _style)

func show_gain(amount: int) -> void:
	float_label.text = "+%d xp  " % amount
	if _float_tween:
		_float_tween.kill()
	float_label.modulate.a = 1.0
	_float_tween = create_tween()
	_float_tween.tween_interval(0.8)
	_float_tween.tween_property(float_label, "modulate:a", 0.0, 0.5)

## Level-up flair: flash the card in the accent color, sweep the bar, announce it in the card text.
## Emits level_up_finished when done so the header can refill the card.
func play_level_up(new_level_text: String, new_progress: float, big: bool = true) -> void:
	var flash := StyleBoxFlat.new()
	flash.bg_color = Color(accent, 0.35 if big else 0.25)
	flash.border_color = accent
	flash.set_border_width_all(1)
	flash.border_width_top = 2
	flash.content_margin_left = _style.content_margin_left
	flash.content_margin_right = _style.content_margin_right
	flash.content_margin_top = _style.content_margin_top
	flash.content_margin_bottom = _style.content_margin_bottom
	add_theme_stylebox_override("panel", flash)
	var t := create_tween()
	t.tween_property(flash, "bg_color", C_BG, 1.2 if big else 0.8).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(flash, "border_color", C_BORDER, 1.2 if big else 0.8)
	t.tween_callback(func(): add_theme_stylebox_override("panel", _style))
	bar.sweep_to(new_progress)

	celebrating = true
	# card text announces it; when done, the header writes fresh values (no stale text in between)
	var bright = accent.lightened(0.45)
	level_label.text = "▲ " + new_level_text
	level_label.add_theme_color_override("font_color", bright)
	left_label.text = "LEVEL UP" if big else "LV UP"
	left_label.add_theme_color_override("font_color", bright)
	var r := create_tween()
	r.tween_interval(1.6)
	r.tween_callback(func():
		level_label.add_theme_color_override("font_color", C_TEXT)
		left_label.add_theme_color_override("font_color", C_DIM)
		celebrating = false
		level_up_finished.emit())

## Footer text, gold when it's an active defrag bonus.
func set_footer(label: Label, text: String, bonus: bool = false) -> void:
	label.text = text
	label.add_theme_color_override("font_color", C_BONUS if bonus else C_DIM)

func _label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
