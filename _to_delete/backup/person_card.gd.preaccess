extends PanelContainer
## One hacking target at a location. Built in code, in the header-card style. Shows, top to bottom:
##   name + difficulty | how to hack it (command + payload needed vs owned) | integrity, firewall,
##   counter damage, counter rate | reward (cache + its rare item) | SPECIAL notes ("special" in the
##   target data, hidden when empty) | INTEL from Decoding (stat after intel, hacks left).
## hacking_box uses: update_info(target), target, flash_green(), flash_red().

const C_BG = HeaderCard.C_BG
const C_BORDER = HeaderCard.C_BORDER
const C_DIM = HeaderCard.C_DIM
const C_TEXT = HeaderCard.C_TEXT
const C_LOCKED = HeaderCard.C_LOCKED
const C_OK = Color("#4ec994")
const C_BAD = Color("#e26d5a")
const C_RARE = Color("#e0c068")
const C_INTEL = Color("#4ec9b0")
const C_SPECIAL = Color("#d29922")
const C_SECTION = Color(0.4, 0.46, 0.52, 1)

const ICONS = {
	"integrity": "res://art/icons/heart(1).png",
	"firewall": "res://art/icons/shield(2).png",
	"counter": "res://art/icons/swords(1).png",
	"counter speed": "res://art/icons/zap(2).png",
	"reward": "res://art/icons/database(1).png",
	"command": "res://art/icons/square-terminal(1).png",
}
const COUNTER_BAR_MAX = 100.0 # hacking_game's counter bar fills at "counter speed" per second

var target
var _accent := Color.WHITE

func update_info(info) -> void:
	target = info
	for c in get_children():
		c.queue_free()
	_accent = _difficulty_color(info.get("difficulty", "Easy"))
	_style()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	# name + difficulty
	var head := HBoxContainer.new()
	box.add_child(head)
	var name_label = _label(info.name, 14, C_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	head.add_child(_pill(info.get("difficulty", "Easy"), _accent))

	if !info.get("unlocked", false):
		_add_locked(box, info)
		return
	modulate = Color.WHITE

	_add_hack_section(box, info)
	_add_stats(box, info)
	_add_reward(box, info)
	_add_special(box, info)
	_add_intel(box, info)

#region sections
## Locked: how to unlock it (access recipe with what you have, or hard-mode wins), then the stats dimmed.
func _add_locked(box: VBoxContainer, info) -> void:
	box.add_child(_section("LOCKED", C_BAD))
	var recipe = Stats.get_access_recipe(info)
	if !recipe.is_empty() and recipe.rare != null and Stats.hacking_targets[Stats.target_place(info).location].get("unlocked", false):
		var cmd = _label(Stats.get_unlock_hint(info), 12, C_TEXT)
		box.add_child(cmd)
		for pair in [[recipe.rare, recipe.rare_amount], [recipe.payload, recipe.payload_amount]]:
			var have = Inventory.get_amount(pair[0])
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			row.add_child(_label("%d/%d" % [have, pair[1]], 11, C_OK if have >= pair[1] else C_BAD))
			row.add_child(_label(pair[0].name, 11, C_DIM))
			box.add_child(row)
	else:
		var hint = _label(Stats.get_unlock_hint(info), 11, C_TEXT)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(hint)
	var stats_box := VBoxContainer.new()
	stats_box.modulate = Color(1, 1, 1, 0.45)
	box.add_child(stats_box)
	_add_stats(stats_box, info)
	_add_reward(stats_box, info)
	_add_special(stats_box, info)

func _add_hack_section(box: VBoxContainer, info) -> void:
	box.add_child(_section("TO HACK"))
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
	var cmd_row := HBoxContainer.new()
	cmd_row.add_theme_constant_override("separation", 6)
	cmd.add_child(cmd_row)
	cmd_row.add_child(_icon("command"))
	cmd_row.add_child(_label(info.command, 12, C_TEXT))
	box.add_child(cmd)

	var req = info.requirements
	var have = Inventory.get_amount(req.item)
	var need_row := HBoxContainer.new()
	box.add_child(need_row)
	need_row.add_theme_constant_override("separation", 6)
	need_row.add_child(_label("Requirement:", 11, C_DIM))
	need_row.add_child(_label("%d/%d" % [have, req.amount], 11, C_OK if have >= req.amount else C_BAD))
	need_row.add_child(_label(req.item.name, 11, C_TEXT))

func _add_stats(box: VBoxContainer, info) -> void:
	var intel = Decoding.get_intel(info)
	var intel_stat = Decoding.intel_stat(info) if intel.hacks > 0 else ""
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var stats = [
		["integrity", "Integrity", str(info.integrity), "health to break through"],
		["firewall", "Firewall", str(info.firewall), "absorbs attack damage"],
		["counter", "Counter", "%s dmg" % str(info.counter), "damage per counterattack"],
		["counter speed", "Counter rate", "every %ss" % _fmt(COUNTER_BAR_MAX / max(0.01, float(info["counter speed"]))), "time between counterattacks"],
	]
	for s in stats:
		var value = s[2]
		var color = C_TEXT
		if s[0] == intel_stat: # show what intel brings it down to for the next hack
			value = _intel_value(s[0], info, intel.amount)
			color = C_INTEL
		grid.add_child(_stat_box(s[0], s[1], value, color, s[3]))

func _add_reward(box: VBoxContainer, info) -> void:
	box.add_child(_section("REWARD"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	row.add_child(_icon("reward"))
	var qty = info.get("loot quantity", 1)
	row.add_child(_label("%s x%d" % [info.loot.name, qty], 12, C_TEXT))
	if info.loot is CacheData and !info.loot.rare_pool.is_empty():
		var rares = []
		for e in info.loot.rare_pool:
			rares.append(e.item.name)
		var r = _label("rare: " + ", ".join(rares), 10, C_RARE)
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(r)

func _add_special(box: VBoxContainer, info) -> void:
	var special = info.get("special", "")
	if special is Array:
		special = "\n".join(special)
	if special == "":
		return
	box.add_child(_section("SPECIAL", C_SPECIAL))
	var l = _label(special, 11, C_TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)

func _add_intel(box: VBoxContainer, info) -> void:
	box.add_child(_section("INTEL", C_INTEL))
	var intel = Decoding.get_intel(info)
	var stat = Decoding.intel_stat(info)
	if intel.hacks > 0:
		box.add_child(_label("-%d %s for %d hack%s" % [intel.amount, stat, intel.hacks, "" if intel.hacks == 1 else "s"], 11, C_INTEL))
		box.add_child(_label("max -%d %s / %d hacks" % [Decoding.intel_cap(info), stat, Decoding.intel_max_hacks()], 10, C_DIM))
	else:
		box.add_child(_label("none  ·  gather intel with the Decoding skill (weakens %s)" % stat, 10, C_DIM))
#endregion

#region helpers
func _intel_value(stat: String, info, amount: int) -> String:
	var base = float(info[stat])
	match stat:
		"counter":
			return "%d → %d dmg" % [int(base), int(max(0, base - amount))]
		"counter speed":
			var after = max(0.1, base - amount)
			return "%ss → %ss" % [_fmt(COUNTER_BAR_MAX / base), _fmt(COUNTER_BAR_MAX / after)]
		"integrity":
			return "%d → %d" % [int(base), int(max(1, base - amount))]
	return "%d → %d" % [int(base), int(max(0, base - amount))]

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
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, 2), _accent if target and target.get("unlocked", false) else C_LOCKED)

func _stat_box(icon: String, title: String, value: String, color: Color, tip: String) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.03)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.tooltip_text = tip
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	v.add_child(h)
	h.add_child(_icon(icon))
	h.add_child(_label(title, 10, C_DIM))
	v.add_child(_label(value, 13, color))
	return p

func _section(text: String, color: Color = C_SECTION) -> Label:
	return _label(text, 9, color)

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

func _icon(key: String) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(ICONS[key]):
		t.texture = load(ICONS[key])
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(11, 11)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.modulate = Color(1, 1, 1, 0.6)
	return t

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func _fmt(v: float) -> String:
	return str(int(round(v))) if is_equal_approx(v, round(v)) else "%.1f" % v

func _difficulty_color(difficulty: String) -> Color:
	match difficulty.to_lower():
		"medium":
			return Color("#b89324")
		"hard":
			return Color("#ee0e00")
	return Color("#3d8a3d")
#endregion

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
