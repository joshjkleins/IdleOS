class_name SettingsPopup
extends ColorRect
## 2026-11-02 (Josh): clickable settings box (launcher + in-game 'settings'). Built from Settings.DEFS: sliders for
## the 0-100 ranges, toggle buttons for the choices. Every change goes through Settings.set_value (applied + saved).
## Esc or [ close ] closes it. 'settings key=value' still works in the terminal.

signal closed

const GREEN := "#4ec994"
const DIM := "#888888"
const FAINT := "#555f69"
const TEXT := "#cccccc"
const LINE := Color("#2a333c")
const NAMES := {"volume": "Master", "sfx": "Sound effects", "music": "Music", "music_player": "Music player", "music_builtin": "Built-in tracks", "window_mode": "Window", "hack_transition": "Hacking load"}

var _rows := {} # key -> {"slider", "label"} or {"buttons": {value: Button}}

## Opens the box over everything (its own CanvasLayer) and returns it
static func open(parent: Node) -> SettingsPopup:
	var layer = CanvasLayer.new()
	layer.layer = 120
	parent.add_child(layer)
	var p = SettingsPopup.new()
	layer.add_child(p)
	return p

func _ready() -> void:
	theme = load("res://theme/TerminalTheme.tres")
	color = Color(0, 0, 0, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color("#10151a")
	st.border_color = Color(GREEN)
	st.set_border_width_all(1)
	st.set_corner_radius_all(3)
	st.set_content_margin_all(26)
	box.add_theme_stylebox_override("panel", st)
	box.custom_minimum_size = Vector2(600, 0)
	center.add_child(box)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	box.add_child(v)
	v.add_child(_label("Settings", 20, GREEN))
	var section = ""
	for key in Settings.DEFS:
		var def: Dictionary = Settings.DEFS[key]
		if def.section != section:
			section = def.section
			var sl = _label(section.to_upper(), 13, FAINT)
			sl.custom_minimum_size.y = 26
			sl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			v.add_child(sl)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		v.add_child(row)
		var name_l = _label(NAMES.get(key, key), 15, TEXT)
		name_l.custom_minimum_size.x = 170
		row.add_child(name_l)
		if def.type == "range":
			var s = HSlider.new()
			s.min_value = 0
			s.max_value = 100
			s.step = 1
			s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			s.focus_mode = Control.FOCUS_NONE
			s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			_style_slider(s)
			row.add_child(s)
			var val = _label("", 15, DIM)
			val.custom_minimum_size.x = 56
			val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(val)
			s.value_changed.connect(func(x): val.text = "%d%%" % int(x); Settings.set_value(key, str(int(x))))
			_rows[key] = {"slider": s, "label": val}
		else:
			var btns := {}
			for opt in def.values:
				var b = _button(str(opt).replace("_", " "), func(): Settings.set_value(key, opt); _refresh())
				row.add_child(b)
				btns[opt] = b
			_rows[key] = {"buttons": btns}
	var gap = Control.new()
	gap.custom_minimum_size.y = 8
	v.add_child(gap)
	var foot = HBoxContainer.new()
	v.add_child(foot)
	foot.add_child(_button("reset defaults", func(): Settings.reset_defaults(); _refresh()))
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	var hint = _label("esc", 13, FAINT)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(hint)
	foot.add_child(_button("close", close))
	_refresh()
	grab_focus.call_deferred() # keys stop going to the terminal's input while the box is up

func _refresh() -> void:
	for key in _rows:
		var r: Dictionary = _rows[key]
		var cur = Settings.get_value(key)
		if r.has("slider"):
			r.slider.set_value_no_signal(int(cur))
			r.label.text = "%d%%" % int(cur)
		else:
			for opt in r.buttons:
				var on = str(opt) == str(cur)
				r.buttons[opt].add_theme_color_override("font_color", Color(GREEN if on else FAINT))
				r.buttons[opt].add_theme_color_override("font_hover_color", Color(GREEN if on else TEXT))

func close() -> void:
	closed.emit()
	var layer = get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and !ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

func _label(t: String, size: int, col: String) -> Label:
	var l = Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(col))
	return l

func _button(label: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = "[ %s ]" % label
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_color_override("font_color", Color(DIM))
	b.add_theme_color_override("font_hover_color", Color(GREEN))
	b.add_theme_color_override("font_pressed_color", Color(GREEN))
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b

func _style_slider(s: HSlider) -> void:
	var track = StyleBoxFlat.new()
	track.bg_color = LINE
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	track.set_corner_radius_all(2)
	var fill = track.duplicate()
	fill.bg_color = Color(GREEN)
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
