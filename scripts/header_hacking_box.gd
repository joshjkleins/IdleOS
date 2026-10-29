extends MarginContainer
## Hacking view header, in the same card style as the main terminal's header and side panel:
##   [ Hacking skill card ] [ ARSENAL ] [ PAYLOADS ] [ MODIFIERS ] [ SYSTEM temperature ]
## ARSENAL shows the two permanent combat items (SQL Injectors, Packet Spoofs) and the equipped drivers (name in
## its skill's color + what it does; 2026-10-28, moved from the hack's YOU card). PAYLOADS shows one count
## per unlocked location.
## API used by hacking.gd: update_hacking_header(), update_modifiers_ui().

@export var title_text: String = "Hacking" # (kept for the scene instance; not shown)

const C_BG = HeaderCard.C_BG
const C_BORDER = HeaderCard.C_BORDER
const C_DIM = HeaderCard.C_DIM
const C_TEXT = HeaderCard.C_TEXT
const C_ZERO = Color(0.3, 0.34, 0.38, 1)
var C_PAYLOAD: Color = Compiling.SKILL.color  # payloads come from Compiling
var C_ARSENAL: Color = Phishing.SKILL.color   # combat items come from Phishing
const C_MODS = Color("#e0c068")
const C_SYSTEM = Color("#4ec9b0")
const PAYLOAD_NAMES = ["School", "Lawfirm", "Hospital", "Bank", "Police", "Government"]
## short names for the compact (3+ mods) layout
var SHORT_MOD_NAMES = {
	HackingMods.MOD_TYPE.DAMAGE: "SQL Dmg", HackingMods.MOD_TYPE.EFFICIENCY: "Crit",
	HackingMods.MOD_TYPE.FIREWALL_REDUCTION: "FW Cut", HackingMods.MOD_TYPE.FIREWALL_DAMAGE: "FW Dmg",
	HackingMods.MOD_TYPE.RESTORE: "Spoof", HackingMods.MOD_TYPE.BAND_RATE: "BW Regen",
	HackingMods.MOD_TYPE.ATTACK_SPEED: "SQL Speed", HackingMods.MOD_TYPE.DAMAGE_REDUCTION: "Ctr Dmg",
	HackingMods.MOD_TYPE.COUNTER_SLOW: "Ctr Slow",
}

## 7 slot squares next to the MODIFIERS title: gold = in use, outlined = open, dim = locked (upgrade per tier)
class _SlotPips extends Control:
	var used := 0
	var unlocked := 1
	const SIZE := 7.0
	const GAP := 3.0
	func _init() -> void:
		custom_minimum_size = Vector2(HackingMods.MAX_MOD_SLOTS * (SIZE + GAP), SIZE)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for i in HackingMods.MAX_MOD_SLOTS:
			var r = Rect2(i * (SIZE + GAP), 0, SIZE, SIZE)
			if i < used:
				draw_rect(r, Color("#e0c068"))
			elif i < unlocked:
				draw_rect(r.grow(-0.5), Color("#e0c068"), false, 1.0) # inset so the 1px outline isn't clipped
			else:
				draw_rect(r, Color(0.3, 0.34, 0.38, 0.45))

var skill_card: HeaderCard
var arsenal_grid: GridContainer
var drivers_box: VBoxContainer
var payload_grid: GridContainer
var mods_title: Label
var mods_list: VBoxContainer
var mods_pips: Control
var _arsenal_labels := {} # ItemData -> count Label
var _payload_labels := {} # ItemData -> [code Label, count Label]

func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	skill_card = HeaderCard.new()
	skill_card.skill = Hacking
	skill_card.build(Hacking.SKILL.color, true, 240.0)
	skill_card.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(skill_card)

	# ARSENAL (2026-10-28 layout): SQL Injectors / Packet Spoofs on the title row, the equipped drivers (up to 14)
	# below in as many columns as fit (~190px each: 5 at 1920 wide, so 14 drivers take 3 rows)
	var arsenal = _panel(row, "ARSENAL", C_ARSENAL, 340.0, true)
	arsenal.panel.size_flags_stretch_ratio = 3.0 # the widest card: it holds the drivers
	var head: HBoxContainer = arsenal.title.get_parent()
	head.add_theme_constant_override("separation", 14)
	arsenal_grid = GridContainer.new()
	arsenal_grid.columns = 2
	arsenal_grid.add_theme_constant_override("h_separation", 14)
	head.add_child(arsenal_grid)
	drivers_box = VBoxContainer.new()
	drivers_box.add_theme_constant_override("separation", 0)
	drivers_box.resized.connect(_fit_driver_columns)
	arsenal.body.add_child(drivers_box)
	var payloads = _panel(row, "PAYLOADS", C_PAYLOAD, 170.0) # 2 columns, more rows as locations open
	payload_grid = _grid(payloads.body, 2)
	payload_grid.add_theme_constant_override("h_separation", 10)
	var mods = _panel(row, "MODIFIERS", C_MODS, 240.0, true)
	mods_title = mods.title
	mods_pips = _SlotPips.new()
	mods.title.get_parent().add_child(mods_pips)
	mods_list = VBoxContainer.new()
	mods_list.add_theme_constant_override("separation", 2)
	mods.body.add_child(mods_list)

	var system = _panel(row, "", C_SYSTEM, 250.0)
	var temp: SystemTemp = load("res://scenes/system_temp.tscn").instantiate()
	system.body.add_child(temp)
	temp.get_node("%HintLabel").visible = false # keep the header short
	system.title.get_parent().visible = false   # SystemTemp has its own "SYSTEM" title

	_build_arsenal()
	_build_payloads()
	_build_drivers()
	Drivers.changed.connect(_build_drivers)
	Drivers.ranked_up.connect(func(_id, _r): _build_drivers())

	Exp.gained_xp_signal.connect(func(_a): _fill_skill())
	Hacking.xp_gained.connect(_on_hacking_xp)
	Hacking.SKILL["level up signal"].connect(_on_level_up)
	Signals.update_hacking_header_signal.connect(update_hacking_header)
	Signals.item_added_signal.connect(func(_i, _a): _refresh_counts())
	Signals.item_removed_signal.connect(func(_i, _a): _refresh_counts())
	update_hacking_header()

#region API
func update_hacking_header() -> void:
	_fill_skill()
	_build_payloads()
	_refresh_counts()
	update_modifiers_ui()

func update_modifiers_ui() -> void:
	for c in mods_list.get_children():
		c.queue_free()
	mods_title.text = "MODIFIERS  %d/%d" % [HackingMods.current_mods.size(), HackingMods.max_mods]
	mods_pips.used = HackingMods.current_mods.size()
	mods_pips.unlocked = HackingMods.max_mods
	mods_pips.queue_redraw()
	if HackingMods.current_mods.is_empty():
		mods_list.add_child(_label("none active  ·  find mods with phish -mod or parse -corruption", 10, C_ZERO))
		return
	if HackingMods.current_mods.size() > 2:
		# 3-7 mods: two compact columns so the header keeps its height
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 12)
		g.add_theme_constant_override("v_separation", 0)
		mods_list.add_child(g)
		for m in HackingMods.current_mods.keys():
			var d = int(HackingMods.current_mods[m].duration)
			var l = _label("%s %s · %d" % [SHORT_MOD_NAMES.get(m, HackingMods.get_mod_name(m)), HackingMods.get_mod_value_text(m, HackingMods.current_mods[m].value), d], 10, C_TEXT)
			l.tooltip_text = "%s · %d hacks left" % [HackingMods.get_mod_name(m), d]
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			g.add_child(l)
		return
	for m in HackingMods.current_mods.keys():
		var line := HBoxContainer.new()
		mods_list.add_child(line)
		line.add_theme_constant_override("separation", 10)
		var d = int(HackingMods.current_mods[m].duration)
		var dur = _label("%d hack%s" % [d, "" if d == 1 else "s"], 11, C_MODS)
		dur.custom_minimum_size.x = 58
		line.add_child(dur)
		var name_label = _label("%s %s" % [HackingMods.get_mod_name(m), HackingMods.get_mod_value_text(m, HackingMods.current_mods[m].value)], 11, C_TEXT)
		name_label.clip_text = true
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
#endregion

#region skill card
func _fill_skill() -> void:
	if skill_card.celebrating:
		return
	var xp = Exp.get_xp_display(Hacking.SKILL)
	skill_card.title_label.text = "Hacking"
	skill_card.level_label.text = "LV %d/%d" % [Hacking.SKILL.level, Exp.MAX_LEVEL]
	skill_card.bar.value = xp.progress
	skill_card.left_label.text = "MAX LEVEL" if xp.display == "MAX" else "%s xp" % xp.display.replace("/", " / ")
	skill_card.right_label.text = "EFF %s%%" % _fmt(_get_total_efficiency() * 100.0)

func _on_hacking_xp() -> void:
	_fill_skill()

func _on_level_up() -> void:
	skill_card.play_level_up("LV %d/%d" % [Hacking.SKILL.level, Exp.MAX_LEVEL], Exp.get_xp_display(Hacking.SKILL).progress)
	if !skill_card.level_up_finished.is_connected(_fill_skill):
		skill_card.level_up_finished.connect(_fill_skill, CONNECT_ONE_SHOT)

func _get_total_efficiency() -> float:
	var base = Hacking.SKILL.get("efficiency", 0.0)
	var mod_eff = HackingMods.get_mod_value(HackingMods.MOD_TYPE.EFFICIENCY) if HackingMods.has_mod(HackingMods.MOD_TYPE.EFFICIENCY) else 0.0
	return base + mod_eff
#endregion

#region arsenal + payloads
func _combat_items() -> Array:
	return [Items.SQL_INJECTOR, Items.PACKET_SPOOF]

func _build_arsenal() -> void:
	for it in _combat_items():
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)
		var n = _label(it.name, 10, C_DIM)
		cell.add_child(n)
		var c = _label("0", 12, C_TEXT)
		cell.add_child(c)
		arsenal_grid.add_child(cell)
		_arsenal_labels[it] = c

## Equipped drivers under the title row: name in its skill's color + its short effect (full text on hover).
var _driver_grid: GridContainer = null
func _build_drivers() -> void:
	for c in drivers_box.get_children():
		c.queue_free()
	_driver_grid = null
	var ids = Drivers.all_equipped()
	if ids.is_empty():
		drivers_box.add_child(_label("no drivers equipped  ·  'driver' inside a skill", 10, C_ZERO))
		return
	_driver_grid = GridContainer.new()
	_driver_grid.add_theme_constant_override("h_separation", 14)
	_driver_grid.add_theme_constant_override("v_separation", 0)
	drivers_box.add_child(_driver_grid)
	for id in ids:
		var d = Drivers.DEFS[id]
		var rtl := RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		rtl.clip_contents = true
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rtl.custom_minimum_size.x = DRIVER_CELL - 14
		rtl.add_theme_font_size_override("normal_font_size", 10)
		var col: Color = _skill_color(d.skill)
		rtl.text = "[color=#%s]%s[/color]%s [color=#8b96a1]%s[/color]" % [col.lightened(0.2).to_html(false), d.name,
			"" if Drivers.rank(id) <= 1 else "[color=#5c6b7a] r%d[/color]" % Drivers.rank(id), Drivers.short_text(id)]
		rtl.tooltip_text = "%s (%s driver, rank %d): %s" % [d.name, d.skill, Drivers.rank(id), Drivers.value_text(id)]
		rtl.mouse_filter = Control.MOUSE_FILTER_PASS
		_driver_grid.add_child(rtl)
	_fit_driver_columns()

const DRIVER_CELL := 200.0
func _fit_driver_columns() -> void:
	if _driver_grid == null or !is_instance_valid(_driver_grid):
		return
	var w = drivers_box.size.x
	_driver_grid.columns = clampi(int(w / DRIVER_CELL), 1, 7) if w > 0 else 2

func _skill_color(skill_name: String) -> Color:
	for m in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Hacking]:
		if m.SKILL.name == skill_name:
			return m.SKILL.color
	return C_TEXT

## One cell per unlocked location (rebuilt when the header updates, so new unlocks appear).
func _build_payloads() -> void:
	for c in payload_grid.get_children():
		c.queue_free()
	_payload_labels.clear()
	var payloads = Compiling.get_payload_processes().map(func(p): return p["resource gained"])
	var locations = Stats.hacking_targets.values()
	for i in payloads.size():
		if i < locations.size() and !locations[i].get("unlocked", false):
			continue
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 5)
		var code = _label(PAYLOAD_NAMES[i] if i < PAYLOAD_NAMES.size() else "Tier %d" % (i + 1), 10, C_DIM)
		code.custom_minimum_size.x = 52
		cell.add_child(code)
		var c = _label("0", 11, C_TEXT)
		c.custom_minimum_size.x = 26
		cell.add_child(c)
		payload_grid.add_child(cell)
		_payload_labels[payloads[i]] = [code, c]

func _refresh_counts() -> void:
	for it in _arsenal_labels:
		var n = Inventory.get_amount(it)
		_arsenal_labels[it].text = _short(n)
		_arsenal_labels[it].add_theme_color_override("font_color", C_TEXT if n > 0 else C_ZERO)
	for it in _payload_labels:
		var n = Inventory.get_amount(it)
		_payload_labels[it][1].text = _short(n)
		_payload_labels[it][1].add_theme_color_override("font_color", C_PAYLOAD.lightened(0.35) if n > 0 else C_ZERO)
		_payload_labels[it][0].add_theme_color_override("font_color", C_DIM if n > 0 else C_ZERO)
#endregion

#region helpers
## A panel styled like the header cards: dark box, border, accent line on top, small title.
func _panel(parent: Control, title: String, accent: Color, min_width: float, expand: bool = false) -> Dictionary:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.border_color = C_BORDER
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.x = min_width
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_FILL
	p.draw.connect(func(): p.draw_rect(Rect2(0, 0, p.size.x, 2), accent))
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var t = _label(title, 10, accent)
	head.add_child(t)
	return {"panel": p, "body": box, "title": t}

func _grid(parent: Control, columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 2)
	parent.add_child(g)
	return g

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func _fmt(v: float) -> String:
	return str(int(round(v))) if v >= 10.0 or is_equal_approx(v, round(v)) else "%.1f" % v

## 1234 -> 1.2k so big stacks don't push the layout around
static func _short(n: int) -> String:
	if n >= 1000000:
		return "%.1fm" % (n / 1000000.0)
	if n >= 10000:
		return "%dk" % (n / 1000)
	return str(n)
#endregion
