class_name AvailableSection
extends VBoxContainer
## Side panel AVAILABLE TO RUN section: the current tier's production chain (Mining > Parsing > Cracking >
## Matching > Compiling), lit when the inventory holds what that tier's process needs for one run:
##   Mining always · Parsing 1 of the tier's mined item · Cracking 1 encrypted item · Matching / Compiling both inputs.
## The number on the right is how many runs the inventory covers right now.

const HEADER = Color(0.36, 0.42, 0.48, 1)
const DIM = Color(0.45, 0.5, 0.55, 1)
const OFF = Color(0.3, 0.34, 0.38, 1)
const FONT = 10
const ROW_FONT = 11

var _count: Label
var _rows: VBoxContainer
var _summary: Label
var _accum := 0.0
var _last := ""
var toggle: SectionToggle
var collapsed := false
var view_tier := 0 # 0 = follow the current upload tier; arrows page through unlocked tiers
var _prev: Button
var _next: Button

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	add_child(header)
	toggle = SectionToggle.new()
	toggle.toggled_section.connect(set_collapsed)
	header.add_child(toggle)
	var title = _label("AVAILABLE TO RUN", FONT, HEADER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_prev = _arrow("<", -1)
	header.add_child(_prev)
	_count = _label("", FONT, HEADER)
	header.add_child(_count)
	_next = _arrow(">", 1)
	header.add_child(_next)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	add_child(_rows)
	_summary = _label("", FONT, DIM)
	_summary.visible = false
	add_child(_summary)
	_refresh()

func _process(delta: float) -> void:
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	_refresh()

## [{skill, label, item tooltip, runs (-1 = always)}] for the tier
static func chain(tier: int) -> Array:
	var k = clamp(tier, 1, 6) - 1
	var mine = Mining.minor_processes[k]
	var mined: ItemData = mine["resource gained"]
	var crack = Cracking.minor_processes.filter(func(p): return p != Cracking.VM)[k]
	var match_p = Matching.minor_processes[k]
	var comp = Compiling.get_payload_processes()[k]
	return [
		{"skill": Mining, "what": mined.name, "needs": {}},
		{"skill": Parsing, "what": mined.name, "needs": {mined: 1}},
		{"skill": Cracking, "what": crack.requirements.keys()[0].name, "needs": crack.requirements},
		{"skill": Matching, "what": match_p["resource gained"].name, "needs": match_p.requirements},
		{"skill": Compiling, "what": comp["resource gained"].name, "needs": comp.requirements},
	]

static func runs(needs: Dictionary) -> int:
	if needs.is_empty():
		return -1
	var n = 1 << 30
	for item in needs:
		n = min(n, Inventory.get_amount(item) / max(1, int(needs[item])))
	return n

func _max_tier() -> int:
	var m = 1
	for t in range(1, 7):
		if Upgrades.tier_unlocked(t):
			m = t
	return max(m, Uploads.current_tier())

func _tier() -> int:
	return clamp(view_tier if view_tier > 0 else Uploads.current_tier(), 1, _max_tier())

func _page(d: int) -> void:
	var t = clamp(_tier() + d, 1, _max_tier())
	view_tier = 0 if t == Uploads.current_tier() else t
	_last = ""
	_refresh()

func _refresh() -> void:
	var tier = _tier()
	_prev.disabled = tier <= 1
	_next.disabled = tier >= _max_tier()
	_prev.visible = _max_tier() > 1
	_next.visible = _max_tier() > 1
	var rows = chain(tier)
	var key = str(tier)
	for r in rows:
		r.runs = runs(r.needs)
		key += "|%d" % r.runs
	var hack = _hack_row()
	key += "|" + str(hack)
	if key == _last:
		return
	_last = key
	for c in _rows.get_children():
		c.queue_free()
	var ready = 0
	var names = []
	for r in rows:
		var on = r.runs != 0
		if on:
			ready += 1
			names.append(r.skill.SKILL.name.to_lower())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		var tip = "%s: %s" % [r.skill.SKILL.name, r.what]
		if !r.needs.is_empty():
			tip += "  ·  needs " + ", ".join(r.needs.keys().map(func(i): return "%d %s (have %d)" % [int(r.needs[i]), i.name, Inventory.get_amount(i)]))
		row.tooltip_text = tip
		_rows.add_child(row)
		var color: Color = r.skill.SKILL.color if on else OFF
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = color if on else Color(1, 1, 1, 0.12)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)
		var name_label = _label(r.skill.SKILL.name.to_lower(), ROW_FONT, color.lightened(0.3) if on else color)
		name_label.custom_minimum_size.x = 70
		row.add_child(name_label)
		var what = _label(r.what.to_lower(), FONT, DIM if on else OFF)
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		what.clip_text = true
		row.add_child(what)
		row.add_child(_label("ready" if r.runs < 0 else ("x%d" % r.runs if on else "-"), FONT, DIM if on else OFF))
	if !hack.is_empty():
		_add_hack_row(hack)
	_count.text = "T%d %s %d/%d" % [tier, Uploads.get_location_name(tier).to_lower().split(" ")[0], ready, rows.size()]
	_summary.text = "  ·  ".join(names) if !names.is_empty() else "nothing ready"

## NEXT HACK: the strongest target you can hack and what one hack of it takes (HintEngine.hack_needs:
## payload + recommended SQL Injectors from your past hacks of it, or an estimate)
func _hack_row() -> Dictionary:
	var t = HintEngine.best_target()
	if t.is_empty():
		return {}
	var n = HintEngine.hack_needs(t)
	var u = Stats.get_usage(t)
	n["name"] = t.name
	n["spoof_rec"] = int(ceil(float(u.spoof) * HintEngine.SQL_SAFETY)) if int(u.get("n", 0)) > 0 else -1
	n["spoof_have"] = Inventory.get_amount(Items.PACKET_SPOOF)
	return n

func _add_hack_row(h: Dictionary) -> void:
	var on = h.ready
	var color: Color = Hacking.SKILL.color if on else OFF
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_rows.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.tooltip_text = "Next hack: %s. Recommended SQL comes from your past hacks of this target (+25%%), or an estimate before your first." % h.name
	box.add_child(row)
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.color = color if on else Color(1, 1, 1, 0.12)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	var name_label = _label("hacking", ROW_FONT, color.lightened(0.3) if on else color)
	name_label.custom_minimum_size.x = 70
	row.add_child(name_label)
	var what = _label(str(h.name).to_lower(), FONT, DIM)
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	what.clip_text = true
	row.add_child(what)
	row.add_child(_label("ready" if on else "-", FONT, DIM if on else OFF))
	# what one hack takes: each part dim when covered, red when short
	var need := HBoxContainer.new()
	need.add_theme_constant_override("separation", 0)
	box.add_child(need)
	var parts = [["%s %d/%d" % [h.payload.name.to_lower(), h.payload_have, h.payload_need], h.payload_have >= h.payload_need],
		["sql %d/%d" % [h.sql_have, h.sql_rec], h.sql_have >= h.sql_rec]]
	if h.spoof_rec >= 0:
		parts.append(["spoof %d/%d" % [h.spoof_have, h.spoof_rec], h.spoof_have >= h.spoof_rec])
	need.add_child(_label("   ", FONT - 1, DIM))
	for i in parts.size():
		if i > 0:
			need.add_child(_label("  ·  ", FONT - 1, OFF))
		need.add_child(_label(parts[i][0], FONT - 1, DIM if parts[i][1] else Color("#c07a6a")))

func set_collapsed(value: bool) -> void:
	collapsed = value
	toggle.set_collapsed(value)
	_rows.visible = !value
	_summary.visible = value
	SaveManager.mark_dirty()

func _arrow(text: String, d: int) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", FONT)
	b.add_theme_color_override("font_color", DIM)
	b.add_theme_color_override("font_hover_color", Color("#33ff33"))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.12))
	b.add_theme_constant_override("h_separation", 0)
	var sb := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(func(): _page(d); Signals.vm_window_focused())
	return b

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
