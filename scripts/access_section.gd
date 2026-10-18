class_name AccessSection
extends VBoxContainer
## Side panel ACCESS section: one row per location, one square per target.
##   empty outline = locked · filled (tier color) = unlocked · gold = its hard mode has been beaten
## Hover a square for the target and how to unlock it.

const HEADER = Color(0.36, 0.42, 0.48, 1)
const DIM = Color(0.45, 0.5, 0.55, 1)
const LOCKED_TEXT = Color(0.3, 0.34, 0.38, 1)
const GOLD = Color("#ffc24a")
const EMPTY = Color(1, 1, 1, 0.12)
const TIER_COLORS = [Color("#3d8a3d"), Color("#2aa198"), Color("#3B82F6"), Color("#c6a700"), Color("#d8743a"), Color("#d83a3a")]
const SQUARE = 9

var _count: Label
var _rows: VBoxContainer
var _summary: Label
var toggle: SectionToggle
var collapsed := false

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	add_child(header)
	toggle = SectionToggle.new()
	toggle.toggled_section.connect(set_collapsed)
	header.add_child(toggle)
	var title = _label("ACCESS", 10, HEADER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count = _label("", 10, HEADER)
	header.add_child(_count)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	add_child(_rows)
	_summary = _label("", 10, DIM)
	_summary.visible = false
	add_child(_summary)
	Stats.unlocks_changed.connect(_rebuild)
	SaveManager.save_loaded.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in _rows.get_children():
		c.queue_free()
	var unlocked = 0
	var total = 0
	var i = 0
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		var color = TIER_COLORS[clamp(i, 0, TIER_COLORS.size() - 1)]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		_rows.add_child(row)
		var name_label = _label(loc.to_lower(), 11, DIM if l.get("unlocked", false) else LOCKED_TEXT)
		name_label.custom_minimum_size.x = 104
		name_label.clip_text = true
		row.add_child(name_label)
		var targets: Array = l.get("targets", [])
		var hard: Array = l.get("hard mode targets", [])
		for k in targets.size():
			var t = targets[k]
			total += 1
			var state = "locked"
			if t.get("unlocked", false):
				unlocked += 1
				state = "unlocked"
				if k < hard.size() and Stats.get_wins(hard[k]) > 0:
					state = "hard"
			row.add_child(_square(state, color, t, hard[k] if k < hard.size() else {}))
		i += 1
	_count.text = "%d/%d" % [unlocked, total]
	# collapsed: one line, unlocked count per open location (+ hard modes beaten)
	var parts = []
	var gold = 0
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		for h in l.get("hard mode targets", []):
			if Stats.get_wins(h) > 0:
				gold += 1
		if l.get("unlocked", false):
			parts.append("%s %d/%d" % [loc.to_lower().split(" ")[0], l.targets.filter(func(t): return t.get("unlocked", false)).size(), l.targets.size()])
	_summary.text = "  ·  ".join(parts) + ("  ·  %d hard" % gold if gold > 0 else "")

func set_collapsed(value: bool) -> void:
	collapsed = value
	toggle.set_collapsed(value)
	_rows.visible = !value
	_summary.visible = value
	SaveManager.mark_dirty()

func _square(state: String, color: Color, target: Dictionary, hard: Dictionary) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(SQUARE + 2, SQUARE)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip = target.name
	match state:
		"locked":
			tip += "  ·  locked: " + Stats.get_unlock_hint(target)
		"unlocked":
			tip += "  ·  beaten %d times" % Stats.get_wins(target)
			if !hard.is_empty():
				tip += ("  ·  hard: " + ("unlocked" if hard.get("unlocked", false) else Stats.get_unlock_hint(hard)))
		"hard":
			tip += "  ·  hard mode beaten"
	c.tooltip_text = tip
	c.draw.connect(_draw_square.bind(c, state, color))
	return c

func _draw_square(c: Control, state: String, color: Color) -> void:
	var r = Rect2(Vector2.ZERO, Vector2(SQUARE, SQUARE))
	if state == "locked":
		c.draw_rect(r, EMPTY)
	elif state == "hard":
		c.draw_rect(r, GOLD)
	else:
		c.draw_rect(r, color)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
