extends PanelContainer
## Top header. Root view: one card per skill (level, segmented xp bar, xp %, best EFF, defrag timer).
## Skill view: a main card for the skill + one card per process (level, bar, EFF, locked/unlock level).
## Views switch in one step (collapse -> rebuild -> open -> text fades in) so there's no flicker.
## API used by idle_os_2: update(), display_skill(skill), display_defragging(), prepare_intro(), intro(skill)

const SKILLS_ORDER = ["Mining", "Parsing", "Cracking", "Matching", "Phishing", "Compiling", "Decoding", "Hacking"] # 2026-10-29 order
const C_DEFRAG = Color("#cf3a3a")
const ROOT_CARD_WIDTH = 150.0
const FADE = 0.12

var row: HBoxContainer
var root_cards := {}        # skill Node -> HeaderCard (root view, kept alive for intro + updates)
var detail_cards: Array[HeaderCard] = [] # process cards in skill view (card.process = its dict)
var main_card: HeaderCard   # skill view main card
var driver_card: HeaderCard # skill view: the small DRIVERS card (skills that have drivers)
const C_DRIVER = Color("#ffc24a")
var current_skill: Node = null  # null = root view
var _switch_tween: Tween
var _view_token := 0

func _skills() -> Array:
	return [Mining, Parsing, Cracking, Matching, Phishing, Compiling, Decoding, Hacking] # root header order (2026-10-29)

func _ready() -> void:
	var sb := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", sb)
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	for skill in _skills():
		skill.xp_gained.connect(_on_xp_gained.bind(skill))
		skill.SKILL["level up signal"].connect(_on_level_up.bind(skill))
	Exp.exp_updated_signal.connect(_on_process_xp)
	SaveManager.save_loaded.connect(func(): _rebuild())
	Upgrades.installed.connect(_on_upgrade_installed)
	Drivers.changed.connect(_on_drivers_changed)
	var tick := Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	tick.timeout.connect(_refresh_footers)
	add_child(tick)
	_build_root()

func _on_drivers_changed() -> void:
	if current_skill == null:
		for skill in root_cards:
			if skill != Defragging:
				_fill_root_card(root_cards[skill])
	else:
		_fill_driver_card()

#region view switching
func update() -> void: # root view
	_switch_to(null)

func display_skill(skill: Node) -> void:
	_switch_to(skill)

func display_defragging() -> void:
	_switch_to(Defragging)

## Switch animation: collapse up (height), then right-to-left (width); rebuild; open left-to-right,
## then top-down; then fade the card text in.
const COLLAPSE_V = 0.12
const COLLAPSE_H = 0.14
const OPEN_H = 0.16
const OPEN_V = 0.14
const TEXT_FADE = 0.18
const MIN_Y = 0.06 # a thin line stays while collapsed sideways

func _switch_to(skill: Node) -> void:
	current_skill = skill
	_view_token += 1
	var token = _view_token
	if _switch_tween:
		_switch_tween.kill()
	row.pivot_offset = Vector2.ZERO # collapse toward the top-left corner
	row.modulate.a = 1.0
	_switch_tween = create_tween()
	# tween_method sets the whole scale every frame: the header (a Container) resets the row's scale
	# whenever it lays the row out again, e.g. right after the rebuild
	var start_y = row.scale.y
	_switch_tween.tween_method(func(y): row.scale = Vector2(1.0, y), start_y, MIN_Y, COLLAPSE_V).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_switch_tween.tween_method(func(x): row.scale = Vector2(x, MIN_Y), 1.0, 0.0, COLLAPSE_H).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_switch_tween.tween_callback(func():
		if token != _view_token: # a newer switch supersedes this one
			return
		_rebuild()
		_set_card_text_alpha(0.0)
		(func(): row.scale = Vector2(0.0, MIN_Y)).call_deferred()) # after the layout pass the rebuild queued
	_switch_tween.tween_method(func(x): row.scale = Vector2(x, MIN_Y), 0.0, 1.0, OPEN_H).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_switch_tween.tween_method(func(y): row.scale = Vector2(1.0, y), MIN_Y, 1.0, OPEN_V).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_switch_tween.tween_method(_set_card_text_alpha, 0.0, 1.0, TEXT_FADE)

## Fades each card's contents (text + bar) without touching the card panels.
func _set_card_text_alpha(a: float) -> void:
	for card in row.get_children():
		if card.get_child_count() > 0 and card.get_child(0) is CanvasItem:
			card.get_child(0).modulate.a = a

func _rebuild() -> void:
	if current_skill == null:
		_build_root()
	elif current_skill == Defragging:
		_build_defrag_detail()
	else:
		_build_skill_detail(current_skill)

func _clear_row() -> void:
	for c in row.get_children():
		row.remove_child(c)
		if !(c in root_cards.values()):
			c.queue_free()
	detail_cards.clear()
	main_card = null
	driver_card = null
#endregion

#region root view
func _build_root() -> void:
	_clear_row()
	if root_cards.is_empty():
		for skill in _skills():
			var card := HeaderCard.new()
			card.skill = skill
			card.build(skill.SKILL.color, false, ROOT_CARD_WIDTH)
			root_cards[skill] = card
		var dcard := HeaderCard.new()
		dcard.skill = Defragging
		dcard.build(C_DEFRAG, false, ROOT_CARD_WIDTH)
		root_cards[Defragging] = dcard
	for skill in root_cards:
		row.add_child(root_cards[skill])
		_fill_root_card(root_cards[skill])

func _fill_root_card(card: HeaderCard) -> void:
	if card.celebrating:
		return
	var skill = card.skill
	if skill == Defragging:
		card.title_label.text = "Defragging"
		card.level_label.text = ""
		_fill_defrag_charge(card)
		return
	var xp = Exp.get_xp_display(skill.SKILL)
	card.title_label.text = skill.SKILL.name
	card.level_label.text = "LV %d" % skill.SKILL.level
	card.bar.value = xp.progress
	card.set_footer(card.left_label, _left_footer(skill, xp), Stats.has_bonus(skill))
	card.right_label.text = Upgrades.get_skill_version(skill) # apt version (efficiency is per process: skill view)
	card.level_label.text = "LV %d" % skill.SKILL.level
	_pip_label(card).text = _driver_pips(skill)
#endregion

#region skill view
func _build_skill_detail(skill: Node) -> void:
	_clear_row()
	main_card = HeaderCard.new()
	main_card.skill = skill
	main_card.build(skill.SKILL.color, true, 250.0)
	row.add_child(main_card)
	_fill_main_card()
	# 2026-10-27: a small DRIVERS card next to the skill (slots, what's equipped)
	driver_card = null
	if Drivers.has_drivers(str(skill.SKILL.name)):
		driver_card = HeaderCard.new()
		driver_card.skill = skill
		driver_card.build(C_DRIVER, false, 120.0)
		driver_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(driver_card)
		_fill_driver_card()
	for p in skill.minor_processes:
		var card := HeaderCard.new()
		card.skill = skill
		card.process = p
		card.build(skill.SKILL.color, false, 140.0)
		row.add_child(card)
		detail_cards.append(card)
		_fill_process_card(card)

func _fill_main_card() -> void:
	if main_card == null or main_card.celebrating:
		return
	var skill = main_card.skill
	var xp = Exp.get_xp_display(skill.SKILL)
	main_card.title_label.text = skill.SKILL.name
	main_card.level_label.text = "LV %d/%d" % [skill.SKILL.level, Exp.MAX_LEVEL]
	main_card.bar.value = xp.progress
	main_card.left_label.text = ("MAX LEVEL" if xp.display == "MAX" else "%s xp" % xp.display.replace("/", " / "))
	main_card.set_footer(main_card.right_label, Upgrades.get_skill_version(skill))

## "▮▯": one per open driver slot (filled = equipped); "" when the skill has no slot open yet
func _driver_pips(skill: Node) -> String:
	var n = str(skill.SKILL.name)
	if !Drivers.has_drivers(n) or Drivers.slots(n) == 0:
		return ""
	var on = Drivers.equipped.get(n, []).size()
	return "▮".repeat(on) + "▯".repeat(Drivers.slots(n) - on)

## a small gold label left of the level on a root card: the skill's driver slots
func _pip_label(card: HeaderCard) -> Label:
	if card.has_meta("pips"):
		return card.get_meta("pips")
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", C_DRIVER)
	var top = card.level_label.get_parent()
	top.add_child(l)
	top.move_child(l, card.level_label.get_index())
	card.set_meta("pips", l)
	return l

func _fill_driver_card() -> void:
	if driver_card == null or driver_card.celebrating:
		return
	var n = str(driver_card.skill.SKILL.name)
	driver_card.title_label.text = "Drivers"
	# one long segment per open slot (2 when none is open yet): empty, equipped and filling toward its next
	# rank, or solid at max rank (HeaderBar.segment_values)
	driver_card.bar.gap = 4.0
	var segs = []
	var eq: Array = Drivers.equipped.get(n, [])
	for i in max(1, Drivers.slots(n)) if Drivers.slots(n) > 0 else Drivers.SLOT_LEVELS.size():
		segs.append(Drivers.rank_progress(eq[i]) if i < eq.size() else -1.0)
	driver_card.bar.set_segment_values(segs)
	if Drivers.slots(n) == 0:
		driver_card.set_locked(true, "LOCKED · LV %d" % Drivers.SLOT_LEVELS[0])
		return
	driver_card.set_locked(false)
	var list: Array = Drivers.equipped.get(n, [])
	driver_card.level_label.text = _driver_pips(driver_card.skill)
	driver_card.level_label.add_theme_color_override("font_color", C_DRIVER)
	driver_card.left_label.text = ", ".join(list.map(func(id): return Drivers.DEFS[id].name)) if !list.is_empty() else ""
	driver_card.right_label.text = ""

func _fill_process_card(card: HeaderCard) -> void:
	if card.celebrating:
		return
	var p = card.process
	var skill = card.skill
	card.title_label.text = str(p.name)
	# 2026-10-26 (skill revamp): no process levels. Locked cards name the location they open with; open ones show
	# the XP a cycle gives the skill and the efficiency (from the skill level)
	if !p.get("unlocked", false):
		card.set_locked(true, "LOCKED · " + Upgrades.tier_name(int(p.get("unlock tier", 1))).to_upper())
		return
	card.set_locked(false)
	card.level_label.text = ""
	card.bar.value = 0.0
	card.left_label.text = "+%s xp" % _fmt_xp(float(p.get("experience per level", 0)))
	card.right_label.text = _eff_text(_process_efficiency(skill, p))
	card.set_active(_is_running(skill, p))

func _build_defrag_detail() -> void:
	_clear_row()
	main_card = HeaderCard.new()
	main_card.skill = Defragging
	main_card.build(C_DEFRAG, true, 250.0)
	row.add_child(main_card)
	main_card.title_label.text = "Defragging"
	for p in Defragging.minor_processes:
		var card := HeaderCard.new()
		card.skill = Defragging
		card.process = p
		var target_color: Color = p.get("color", C_DEFRAG)
		card.build(target_color, false, 140.0)
		row.add_child(card)
		detail_cards.append(card)
	_fill_defrag_detail()

## Updates the defrag view in place (called every second; no rebuild, so no blinking).
func _fill_defrag_detail() -> void:
	if main_card == null:
		return
	_fill_defrag_charge(main_card)
	for card in detail_cards:
		var p = card.process
		card.title_label.text = str(p.name)
		if !p.get("unlocked", false):
			card.set_locked(true, "LOCKED · " + Upgrades.tier_name(int(p.get("unlock tier", 1))).to_upper())
			continue
		card.set_locked(false)
		var active = Defragging.is_active(p)
		card.level_label.text = p.get("bonus label", "")
		card.level_label.add_theme_color_override("font_color", HeaderCard.C_BONUS if active else HeaderCard.C_TEXT)
		card.bar.value = 1.0 if active else 0.0
		card.set_footer(card.left_label, ("ACTIVE " + Stats.get_bonus_time_text(p)) if active else Stats.boost_minutes_text() + " boost", active)
		card.set_footer(card.right_label, "", active)

## Defrag "charging" bar: fills as the cooldown runs down, full + bright when available.
func _fill_defrag_charge(card: HeaderCard) -> void:
	var charge = Defragging.get_cooldown_progress()
	var ready = charge >= 1.0
	card.bar.color = C_DEFRAG.lightened(0.15) if ready else C_DEFRAG.darkened(0.12)
	if abs(card.bar.value - charge) > 0.001:
		card.bar.animate_to(charge, 0.9) # smooth tick between 1s refreshes
	# (a running boost is shown at the top of the side panel: DefragBoostSection)
	if ready:
		card.left_label.text = "available"
		card.left_label.add_theme_color_override("font_color", C_DEFRAG.lightened(0.3))
		card.right_label.text = ""
	else:
		card.set_footer(card.left_label, "charging " + Defragging.get_cd_time_text())
		card.set_footer(card.right_label, "%d%%" % int(charge * 100))

#endregion

#region live updates
func _on_xp_gained(skill: Node) -> void:
	if root_cards.has(skill) and current_skill == null and !root_cards[skill].celebrating:
		var card: HeaderCard = root_cards[skill]
		var xp = Exp.get_xp_display(skill.SKILL)
		card.bar.animate_to(xp.progress)
		card.level_label.text = "LV %d" % skill.SKILL.level
		card.set_footer(card.left_label, _left_footer(skill, xp), Stats.has_bonus(skill))
	if driver_card and driver_card.skill == skill:
		_fill_driver_card() # equipped drivers fill toward their next rank
	if main_card and main_card.skill == skill and !main_card.celebrating:
		var xp2 = Exp.get_xp_display(skill.SKILL)
		main_card.bar.animate_to(xp2.progress)
		main_card.level_label.text = "LV %d/%d" % [skill.SKILL.level, Exp.MAX_LEVEL]
		main_card.left_label.text = ("MAX LEVEL" if xp2.display == "MAX" else "%s xp" % xp2.display.replace("/", " / "))

func _on_level_up(skill: Node) -> void:
	var xp = Exp.get_xp_display(skill.SKILL)
	var lv_text = "LV %d" % skill.SKILL.level
	if current_skill == null and root_cards.has(skill):
		var card: HeaderCard = root_cards[skill]
		_refill_when_done(card, func(): _fill_root_card(card))
		card.play_level_up(lv_text, xp.progress)
	elif main_card and main_card.skill == skill:
		var mc := main_card
		_refill_when_done(mc, func():
			if is_same(mc, main_card):
				_fill_main_card())
		mc.play_level_up("LV %d/%d" % [skill.SKILL.level, Exp.MAX_LEVEL], xp.progress)
		for card in detail_cards: # newly unlocked processes
			_fill_process_card(card)
		_fill_driver_card() # a level can open a driver slot

## Refill a card the moment its level-up effect ends (one-shot).
func _refill_when_done(card: HeaderCard, refill: Callable) -> void:
	if !card.level_up_finished.is_connected(refill):
		card.level_up_finished.connect(refill, CONNECT_ONE_SHOT)

func _on_process_xp(amount: int, process: Dictionary) -> void:
	# the "+N xp" popup goes on the card of the skill that earned it: its main card in that skill's
	# view, its root card in the root view (so several VMs light up their own skills)
	var owner = _skill_of(process)
	if main_card and owner != null and main_card.skill == owner:
		main_card.show_gain(amount)
	elif current_skill == null and owner != null and root_cards.has(owner) and !root_cards[owner].celebrating:
		root_cards[owner].show_gain(amount)
	var card: HeaderCard = _card_for(process)
	if card:
		if !card.celebrating:
			_fill_process_card(card)

## Once a second: defrag timers/cooldowns and the running-process highlight.
func _refresh_footers() -> void:
	if current_skill == null:
		for skill in root_cards:
			if skill == Defragging or Stats.has_bonus(skill) or root_cards[skill].left_label.text.begins_with("DFG"):
				_fill_root_card(root_cards[skill])
	elif current_skill == Defragging:
		_fill_defrag_detail()
	else:
		_fill_main_card()
		for card in detail_cards:
			card.set_active(_is_running(current_skill, card.process))
#endregion

func _skill_of(process: Dictionary) -> Node:
	for skill in _skills():
		for p in skill.minor_processes:
			if is_same(p, process):
				return skill
	return null

## Process dicts change as they gain xp, so match by identity, not as dictionary keys.
func _card_for(process: Dictionary) -> HeaderCard:
	for card in detail_cards:
		if is_same(card.process, process):
			return card
	return null

#region intro (fade cards in one by one)
func prepare_intro() -> void:
	_switch_to(null)
	for skill in root_cards:
		root_cards[skill].modulate.a = 0.0

func intro(skill: Node) -> void:
	if root_cards.has(skill):
		create_tween().tween_property(root_cards[skill], "modulate:a", 1.0, 1.0)
#endregion

#region helpers
## apt install: refresh the skill's version on its header card and pop the new number
func _on_upgrade_installed(p: Dictionary, _level: Dictionary) -> void:
	var skill = Upgrades.skill_for_group(p.group)
	if skill == null:
		return
	var v = Upgrades.version_text(p.group)
	if root_cards.has(skill) and current_skill == null:
		root_cards[skill].right_label.text = v
		root_cards[skill].show_note("▲ " + v)
	if main_card and main_card.skill == skill:
		main_card.set_footer(main_card.right_label, v)
		main_card.show_note("▲ " + v)

func _left_footer(skill: Node, xp: Dictionary) -> String:
	if Stats.has_bonus(skill):
		return "DFG " + Stats.get_bonus_time_text(skill)
	return "MAX" if xp.display == "MAX" else "%d%%" % int(xp.progress * 100)

func _bonus_text(skill: Node) -> String:
	return "DEFRAG " + Stats.get_bonus_time_text(skill) if Stats.has_bonus(skill) else ""

static func _fmt_xp(v: float) -> String:
	return ("%.1fk" % (v / 1000.0)).replace(".0k", "k") if v >= 1000.0 else str(int(round(v)))

func _eff_text(eff: float) -> String:
	if eff < 0.0:
		return ""
	return "EFF %s%%" % _fmt_pct(eff * 100.0)

static func _fmt_pct(v: float) -> String:
	return str(int(round(v))) if v >= 10.0 or is_equal_approx(v, round(v)) else "%.1f" % v

## Same formula the terminals use: (process efficiency + skill efficiency upgrade) x defrag bonus.
func _process_efficiency(skill: Node, p: Dictionary) -> float:
	if !p.has("efficiency"):
		return -1.0
	var package = Upgrades.get_package_info(skill.SKILL.name.to_lower() + ".efficiency")
	var upgrade = package.current if package else 0.0
	return (p.efficiency + upgrade) * _defrag_mult(skill)

func _defrag_mult(skill: Node) -> float:
	if !Stats.has_bonus(skill):
		return 1.0
	var d = Defragging.get(skill.SKILL.name.to_upper())
	return d["bonus efficiency"] if d is Dictionary and d.has("bonus efficiency") else 1.0

func _is_running(skill: Node, p: Dictionary) -> bool:
	var os = get_tree().current_scene
	return os != null and os.get("process_running") == true and is_same(os.get("current_process_info"), p)
#endregion
