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
const C_DRV = Color("#ffc24a") # compromise step pills
const C_SECTION = Color(0.4, 0.46, 0.52, 1)

const ICONS = {
	"integrity": "res://art/icons/heart(1).png",
	"firewall": "res://art/icons/shield(2).png",
	"counter": "res://art/icons/swords(1).png",
	"counter speed": "res://art/icons/zap(2).png",
	"firewall reboot": "res://art/icons/loader(2).png",
	"reward": "res://art/icons/database(1).png",
	"command": "res://art/icons/square-terminal(1).png",
}
const COUNTER_BAR_MAX = 100.0 # hacking_game's counter bar fills at "counter speed" per second

var target
var _accent := Color.WHITE
## 2026-10-27 layout: the 4 stats as a list (left) next to the traits (right), intel on one line, loot in 2 columns

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
	var step = int(info.get("_step", 0)) # a Compromise fight (recon view): numbered, no hack / reward sections
	if step > 0:
		head.add_theme_constant_override("separation", 8)
		head.add_child(_pill("%d" % step, C_DRV))
	var name_label = _label(info.name, 14, C_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	if step > 0:
		head.add_child(_label(("then %d →" % (step + 1)) if step < int(info._steps) else "final", 10, C_DIM))
	else:
		head.add_child(_pill(info.get("difficulty", "Easy"), _accent))

	if !info.get("unlocked", false):
		_add_locked(box, info)
		return
	modulate = Color.WHITE

	if step == 0:
		_add_hack_section(box, info)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 8)
	box.add_child(split)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	split.add_child(left)
	_add_stats_rows(left, info)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	_add_traits(right, info, true)
	if step == 0:
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
	var anon_gain = Stats.anon_for_unlock(info) # 2026-10-30: max anonymity grows with target unlocks
	if anon_gain > 0:
		box.add_child(_label("+%d max anonymity when unlocked" % anon_gain, 11, C_OK))
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
	var with_intel = int(intel.hacks) > 0 # next hack uses intel: every stat shows its weakened value
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var ts = Stats.trait_stats(info) # after traits (Fortress, Swarm ...)
	var stats = [
		["integrity", "Integrity", str(int(ts.integrity)), "health to break through"],
		["firewall", "Firewall", str(int(ts.firewall)), "absorbs attack damage"],
		["counter", "Counter", "%s dmg" % str(int(ts.counter)), "damage per counterattack"],
		["counter speed", "Counter rate", "every %ss" % _fmt(COUNTER_BAR_MAX / max(0.01, float(ts["counter speed"]))), "time between counterattacks"],
		["firewall reboot", "Reboot", "%ss" % _fmt(float(ts["firewall reboot"])), "how long the firewall stays down after it breaks"],
	]
	for s in stats:
		var value = s[2]
		var color = C_TEXT
		var ip = Decoding.intel_pcts(info)
		if with_intel and ip[s[0]] > 0.0: # show what intel brings it down to for the next hack
			value = _intel_value(s[0], info, ip[s[0]])
			color = C_INTEL
		grid.add_child(_stat_box(s[0], s[1], value, color, s[3]))

## the 5 stats as [key, title, value text, color] (after traits; intel shown as old -> new)
func _stat_values(info) -> Array:
	var ts = Stats.trait_stats(info)
	var intel = Decoding.get_intel(info)
	var ip = Decoding.intel_pcts(info)
	var out = []
	for s in [["integrity", "Integrity", str(int(ts.integrity))], ["firewall", "Firewall", str(int(ts.firewall))],
			["counter", "Counter", "%d dmg" % int(ts.counter)], ["counter speed", "Rate", "every %ss" % _fmt(COUNTER_BAR_MAX / max(0.01, float(ts["counter speed"])))],
			["firewall reboot", "Reboot", "%ss" % _fmt(float(ts["firewall reboot"]))]]:
		if int(intel.hacks) > 0 and ip[s[0]] > 0.0:
			out.append([s[0], s[1], _intel_value(s[0], info, ip[s[0]]), C_INTEL])
		else:
			out.append([s[0], s[1], s[2], C_TEXT])
	return out

## one stat per row (icon, name, value)
func _add_stats_rows(box: VBoxContainer, info) -> void:
	for s in _stat_values(info):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.add_child(_icon(s[0]))
		var n = _label(s[1], 10, C_DIM)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(n)
		row.add_child(_label(s[2], 11, s[3]))
		box.add_child(row)

func _add_reward(box: VBoxContainer, info) -> void:
	box.add_child(_section("REWARD"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	row.add_child(_icon("reward"))
	var qty = info.get("loot quantity", 1)
	row.add_child(_label("%s x%d" % [info.loot.name, qty], 12, C_TEXT))
	# 2026-10-30: the win streak reward (hacking_game._streak_rare)
	if info.loot is CacheData and !info.loot.rare_pool.is_empty() and Upgrades.win_streak_unlocked():
		var st = _label("streak: %d wins in one run ('hack %s=%d' or '-r') = +1 %s" % [5, str(info.name).to_lower(), 5, info.loot.rare_pool[0].item.name.to_lower()], 10, C_RARE)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st.custom_minimum_size.x = 60
		box.add_child(st)
	if info.loot is CacheData:
		_add_loot_pool(box, info.loot)

## What one decoded cache of this target holds (Decoding's drop table for the Cache process): name, amount, chance
func _add_loot_pool(box: VBoxContainer, cache: CacheData) -> void:
	box.add_child(_section("CACHE LOOT"))
	var grid := GridContainer.new()
	grid.columns = 6 # 2026-10-27: two items per row
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 1)
	box.add_child(grid)
	for r in Decoding.get_drop_table(cache, Decoding.CACHE):
		if r.get("sweep", false): # Salvage Sweep: only in 'ls' and the decode screen
			continue
		var col = C_RARE if r.rare else C_DIM
		var n = _label(r.name.to_lower(), 10, C_RARE if r.rare else C_TEXT)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # long names break between words (2 lines)
		n.custom_minimum_size.x = 60
		n.tooltip_text = r.name
		grid.add_child(n)
		grid.add_child(_label(str(r.min) if r.min == r.max else "%d-%d" % [r.min, r.max], 10, col))
		var pc = _label(("%.1f%%" % (r.chance * 100.0)).replace(".0%", "%"), 10, col)
		pc.custom_minimum_size.x = 34
		grid.add_child(pc)

## 2026-10-27: target traits (Stats.TRAITS): a tag + what it does, no solution hints
func _add_traits(box: VBoxContainer, info, stacked: bool = false) -> void:
	var traits = Stats.target_traits(info)
	if traits.is_empty():
		return
	if stacked: # layout b: tag over its text
		for tr in traits:
			var tp = _pill(Stats.TRAITS[tr].name, C_SPECIAL)
			tp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			box.add_child(tp)
			var tl = _label(Stats.TRAITS[tr].text, 10, C_TEXT)
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(tl)
		return
	box.add_child(_section("TRAITS", C_SPECIAL))
	for tr in traits:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_pill(Stats.TRAITS[tr].name, C_SPECIAL))
		var l = _label(Stats.TRAITS[tr].text, 10, C_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		box.add_child(row)

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

## 2026-10-27: one line. "INTEL  -" or "INTEL [5 hacks]  -4% all stats" / "-4% int · -2% fw · -2% ctr · -2% speed"
func _add_intel(box: VBoxContainer, info) -> void:
	var intel = Decoding.get_intel(info)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	if int(intel.hacks) <= 0:
		row.add_child(_section("INTEL", C_INTEL))
		row.add_child(_label("-", 10, C_DIM))
		return
	row.add_child(_section("INTEL [%d hack%s]" % [intel.hacks, "" if int(intel.hacks) == 1 else "s"], C_INTEL))
	var p = Decoding.intel_pcts(info)
	var v = [roundi(p.integrity * 100), roundi(p.firewall * 100), roundi(p.counter * 100), roundi(p["counter speed"] * 100), roundi(p["firewall reboot"] * 100)]
	var t = ("%d%% weaker, all stats" % v[0]) if v.min() == v.max() else "-%d%% int · -%d%% fw · -%d%% ctr · -%d%% speed · +%d%% reboot" % v
	row.add_child(_label(t, 10, C_INTEL))
#endregion

#region helpers
func _intel_value(stat: String, info, pct: float) -> String:
	var base = float(Stats.trait_stats(info)[stat])
	var k = 1.0 - pct
	match stat:
		"counter":
			return "%d → %d dmg" % [int(base), int(max(0, round(base * k)))]
		"counter speed":
			var after = max(0.1, base * k)
			return "%ss → %ss" % [_fmt(COUNTER_BAR_MAX / base), _fmt(COUNTER_BAR_MAX / after)]
		"integrity":
			return "%d → %d" % [int(base), int(max(1, round(base * k)))]
		"firewall reboot": # intel keeps the firewall down longer
			return "%ss → %ss" % [_fmt(base), _fmt(base * (1.0 + pct))]
	return "%d → %d" % [int(base), int(max(0, round(base * k)))]

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
