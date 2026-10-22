class_name UploadSection
extends VBoxContainer
## Side panel UPLOADS section: every item in the current tier's upload goal (even at 0) plus anything
## else queued, in a scroll area that takes the panel's free space.
## Uploading rows show a count (uploaded/goal), an overall bar and a thin bar that fills once per item.

const HEADER = Color(0.36, 0.42, 0.48, 1)
const DIM = Color(0.45, 0.5, 0.55, 1)
const TEXT = Color(0.8, 0.84, 0.88, 1)
const EMPTY = Color(0.3, 0.34, 0.38, 1)
const UPLOAD_COLOR = Color("#4ec9b0")
const DONE_COLOR = Color("#4ec994")
const RARE_COLOR = Color("#e0c068")
const FONT = 10
const ROW_FONT = 11

var _title: Label
var _count: Label
var _list: VBoxContainer
var _empty: Label
var _rows := {} # ItemData -> {name, count, bar, tick}
var _accum := 0.0
var _scroll: ScrollContainer
var _summary: VBoxContainer
var _summary_bar: ProgressBar
var _summary_label: Label
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
	_title = _label("UPLOADS", FONT, HEADER)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_count = _label("", FONT, HEADER)
	header.add_child(_count)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_scroll = scroll
	# collapsed view: one bar for the whole tier goal + what's uploading
	_summary = VBoxContainer.new()
	_summary.add_theme_constant_override("separation", 3)
	_summary.visible = false
	add_child(_summary)
	_summary_bar = _bar(4, UPLOAD_COLOR)
	_summary.add_child(_summary_bar)
	_summary_label = _label("", FONT, DIM)
	_summary.add_child(_summary_label)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 5)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_empty = _label("all uploads complete  ·  upload", FONT, EMPTY)
	add_child(_empty)
	Uploads.tier_completed.connect(func(_t): _rebuild())
	_rebuild()

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.1:
		return
	_accum = 0.0
	if _wanted_items() != _rows.keys():
		_rebuild()
	_refresh()

## Rows: every unfinished goal item of the current tier (in goal order), then anything else queued,
## then the finished goals at the bottom (the list re-sorts itself when one completes).
func _wanted_items() -> Array:
	var items := []
	var finished := []
	for g in Uploads.get_goals():
		if Uploads.get_uploaded(g.item) >= g.amount:
			finished.append(g.item)
		else:
			items.append(g.item)
	for item in Uploads.staged:
		if not item in items and not item in finished:
			items.append(item)
	return items + finished

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	for item in _wanted_items():
		_rows[item] = _make_row(item)
	_refresh()

func _make_row(item: ItemData) -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_list.add_child(box)
	var line := HBoxContainer.new()
	box.add_child(line)
	var name_label := _label(item.name.to_lower(), ROW_FONT, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	line.add_child(name_label)
	var count := _label("", ROW_FONT, DIM)
	line.add_child(count)
	var color = RARE_COLOR if Uploads.get_tier_rares(Uploads.current_tier()).has(item) else UPLOAD_COLOR
	var bar := _bar(4, color)
	box.add_child(bar)
	var tick := _bar(2, color.lightened(0.3))
	box.add_child(tick)
	return {"name": name_label, "count": count, "bar": bar, "tick": tick}

func _refresh() -> void:
	var tier = Uploads.current_tier()
	var goals = Uploads.get_goals(tier)
	var done = 0
	for g in goals:
		if Uploads.get_uploaded(g.item) >= g.amount:
			done += 1
	_title.text = "UPLOADS  ·  T%d %s" % [tier, Uploads.get_location_name(tier).to_upper()]
	_count.text = "%d/%d" % [done, goals.size()]
	_empty.visible = _rows.is_empty() and !collapsed
	var got = 0
	var need = 0
	for g in goals:
		got += min(Uploads.get_uploaded(g.item), g.amount)
		need += g.amount
	_summary_bar.value = float(got) / max(1, need)
	var up_names = Uploads.active.keys().map(func(i): return i.name.to_lower())
	_summary_label.text = ("%d%% of goal" % int(100.0 * got / max(1, need))) + ("  ·  uploading " + ", ".join(up_names) if !up_names.is_empty() else "  ·  nothing uploading")
	for item in _rows:
		var row = _rows[item]
		var goal = Uploads.get_goal_amount(item)
		var up = Uploads.get_uploaded(item)
		var uploading = Uploads.is_uploading(item)
		var staged = Uploads.get_staged(item)
		if goal > 0:
			row.count.text = "%d/%d%s" % [up, goal, "  +%d" % staged if staged > 0 else ""]
			row.bar.value = float(up) / goal
		else:
			row.count.text = "%d queued" % staged
			row.bar.value = 0.0
		row.tick.value = Uploads.active.get(item, 0.0)
		row.tick.visible = uploading
		var complete = goal > 0 and up >= goal
		row.name.add_theme_color_override("font_color", DONE_COLOR if complete else (TEXT if uploading else DIM))
		row.count.add_theme_color_override("font_color", DONE_COLOR if complete else (TEXT if uploading else DIM))
		row.bar.modulate.a = 1.0 if uploading or complete else 0.5

func set_collapsed(value: bool) -> void:
	collapsed = value
	toggle.set_collapsed(value)
	_scroll.visible = !value
	_summary.visible = value
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# expanded it fills the panel's free space; collapsed it shrinks to its summary
	size_flags_vertical = Control.SIZE_FILL if value else Control.SIZE_EXPAND_FILL
	var spacer = get_parent().get_node_or_null("Spacer") if get_parent() else null
	if spacer:
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL if value else Control.SIZE_FILL
	SaveManager.mark_dirty()

func _bar(height: int, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.max_value = 1.0
	bar.step = 0.001
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(1, 1, 1, 0.06)
	var fill := StyleBoxFlat.new(); fill.bg_color = color
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
