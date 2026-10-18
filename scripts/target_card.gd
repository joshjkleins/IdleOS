extends PanelContainer
## A hacking location (School, Lawfirm, ...). Built in code in the header-card style, keeping the ASCII
## art: art | name + TIER pill (+ CURRENT / COMPLETE) | targets + hard mode | payload owned |
## upload goal progress | view commands. hacking_box uses: update_info(location), target, flash_*().

const C_BG = HeaderCard.C_BG
const C_BORDER = HeaderCard.C_BORDER
const C_DIM = HeaderCard.C_DIM
const C_TEXT = HeaderCard.C_TEXT
const C_LOCKED = HeaderCard.C_LOCKED
const C_OK = Color("#4ec994")
const C_HARD = Color("#ee4a3a")
const C_SECTION = Color(0.4, 0.46, 0.52, 1)
const TIER_COLORS = [Color("#3d8a3d"), Color("#2aa198"), Color("#3B82F6"), Color("#c6a700"), Color("#d8743a"), Color("#d83a3a")]
const ROMAN = ["I", "II", "III", "IV", "V", "VI"]

var target  # the location dictionary (name kept for hacking_box)
var tier: int = 1
var _accent := Color.WHITE

func update_info(info) -> void:
	target = info
	for c in get_children():
		c.queue_free()
	tier = Stats.hacking_targets.keys().find(info.name) + 1
	_accent = TIER_COLORS[clamp(tier - 1, 0, TIER_COLORS.size() - 1)]
	_style()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var art := TextureRect.new()
	art.texture = info.get("art")
	art.custom_minimum_size = Vector2(80, 95)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(art)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	var name_label = _label(info.name, 14, C_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	if tier in Uploads.completed_tiers:
		head.add_child(_pill("COMPLETE", C_OK))
	elif tier == Uploads.current_tier():
		head.add_child(_pill("CURRENT", _accent.lightened(0.2)))
	head.add_child(_pill("TIER " + ROMAN[clamp(tier - 1, 0, 5)], _accent))

	if !info.get("unlocked", false):
		box.add_child(_label("LOCKED", 12, C_LOCKED))
		var hint = _label(Stats.get_location_unlock_hint(info.name), 11, C_DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint)
		modulate = Color(1, 1, 1, 0.6)
		return
	modulate = Color.WHITE

	# targets + hard mode
	var targets: Array = info.get("targets", [])
	var hard: Array = info.get("hard mode targets", [])
	var row := HBoxContainer.new()
	box.add_child(row)
	var t = _label("%d targets" % targets.size(), 11, C_DIM)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if hard.is_empty():
		row.add_child(_label("hard mode: none yet", 11, C_LOCKED))
	elif info.get("hard mode unlocked", false):
		var open_hard = hard.filter(func(h): return h.get("unlocked", false)).size()
		row.add_child(_label("hard mode: %d/%d open" % [open_hard, hard.size()], 11, C_HARD if open_hard > 0 else C_DIM))
	else:
		row.add_child(_label("hard mode: locked", 11, C_LOCKED))

	# payload owned
	var payload: ItemData = info.get("required payload")
	if payload:
		var prow := HBoxContainer.new()
		prow.add_theme_constant_override("separation", 6)
		box.add_child(prow)
		prow.add_child(_label("Payloads:", 11, C_DIM))
		var have = Inventory.get_amount(payload)
		prow.add_child(_label(str(have), 11, C_TEXT if have > 0 else C_LOCKED))
		prow.add_child(_label(payload.name, 11, C_DIM))

	# upload goal for this tier
	box.add_child(_label("UPLOAD GOAL", 9, C_SECTION))
	var goals = Uploads.get_goals(tier)
	var done = 0
	var got = 0
	var need = 0
	for g in goals:
		var up = min(Uploads.get_uploaded(g.item), g.amount)
		got += up
		need += g.amount
		if up >= g.amount:
			done += 1
	var bar := HeaderBar.new()
	bar.custom_minimum_size = Vector2(0, 4)
	bar.segments = 12
	bar.color = _accent
	bar.value = float(got) / max(1, need)
	box.add_child(bar)
	var grow := HBoxContainer.new()
	box.add_child(grow)
	var gl = _label("%d/%d items complete" % [done, goals.size()], 10, C_DIM)
	gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.add_child(gl)
	grow.add_child(_label("%d%%" % int(100.0 * got / max(1, need)), 10, C_OK if done == goals.size() else C_DIM))

	# commands
	var cmd := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.border_color = C_BORDER
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	cmd.add_theme_stylebox_override("panel", sb)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 1)
	cmd.add_child(cv)
	cv.add_child(_label(info.get("command", "view " + info.name.to_lower()), 12, C_TEXT))
	if !hard.is_empty():
		cv.add_child(_label(info.get("hard mode command", ""), 11, C_HARD if info.get("hard mode unlocked", false) else C_LOCKED))
	box.add_child(cmd)

#region helpers
func _style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.border_color = C_BORDER
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, 2), _accent if target and target.get("unlocked", false) else C_LOCKED)

func _pill(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(_label(text, 10, Color(0.05, 0.05, 0.05)))
	return p

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
#endregion

func selected():
	pass

func flash_green():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#3dff95"), 0.15)
	await tween.finished
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished

func flash_red():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#ff5a3d"), 0.15)
	await tween.finished
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished
