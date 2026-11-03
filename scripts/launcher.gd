extends Control
## 2026-11-02 (Josh): launch screen. Three save slots as terminal cards, clickable or driven by typed commands
## ('boot 1', 'ls', 'help', 'quit'). Booting a slot sets SaveManager.slot, then loads the game scene as before
## (boot text, offline welcome back). Cards read only the save's "meta" block (SaveManager.read_meta).

const GAME_SCENE := "res://scenes/idle_os_2.tscn"
const BG := Color("#0b0e11")
const CARD := Color("#10151a")
const CARD_HI := Color("#141c22")
const LINE := Color("#2a333c")
const GREEN := "#4ec994"
const BRIGHT := "#33ff33"
const DIM := "#888888"
const FAINT := "#555f69"
const TEXT := "#cccccc"
const YELLOW := "#e3b341"

var _cards: Array = []     # PanelContainer per slot
var _metas: Array = []     # meta per slot ({} empty)
var _selected := 0
var _busy := false
var _log: RichTextLabel
var _input: LineEdit
var _out: RichTextLabel
var _modal: Control = null   # the open popup (new / rename / delete), or null

func _ready() -> void:
	theme = load("res://theme/TerminalTheme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg = ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)
	_log = _rich(16)
	_log.fit_content = true
	col.add_child(_log)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_vspace())
	col.add_child(row)
	col.add_child(_vspace())
	for n in SaveManager.SLOTS:
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(360, 420)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(_on_card_input.bind(n))
		card.mouse_entered.connect(func(): _select(n))
		row.add_child(card)
		_cards.append(card)
	_out = _rich(15)
	_out.fit_content = true
	col.add_child(_out)
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	col.add_child(bar)
	var lead = Label.new()
	lead.text = "boot>"
	lead.add_theme_color_override("font_color", Color(BRIGHT))
	lead.add_theme_font_size_override("font_size", 16)
	lead.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lead.size_flags_vertical = Control.SIZE_FILL
	bar.add_child(lead)
	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.flat = true
	_input.caret_blink = true
	_input.placeholder_text = "type a command, e.g. 'boot 1'"
	_input.add_theme_font_size_override("font_size", 16)
	_style_field(_input)
	if "keep_editing_on_text_submit" in _input:
		_input.keep_editing_on_text_submit = true # (Godot 4.4) Enter doesn't drop focus
	_input.text_submitted.connect(_on_submit)
	bar.add_child(_input)
	bar.add_child(_button("Settings", func(): _open_settings()))
	bar.add_child(_button("Quit", func(): _quit()))
	_refresh()
	_intro()

## Line edit look: thin border, a little room left of the caret
func _style_field(le: LineEdit) -> void:
	for st in ["normal", "focus", "read_only"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(GREEN) if st == "focus" else LINE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		le.add_theme_stylebox_override(st, sb)

func _refocus() -> void:
	if _modal == null and is_instance_valid(_input):
		_input.grab_focus()

func _vspace() -> Control:
	var c = Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _rich(size: int) -> RichTextLabel:
	var r = RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	return r

func _button(label: String, cb: Callable, color: String = DIM, hover: String = GREEN) -> Button:
	var b = Button.new()
	b.text = "[ %s ]" % label
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_color_override("font_color", Color(color))
	b.add_theme_color_override("font_hover_color", Color(hover))
	b.add_theme_color_override("font_pressed_color", Color(hover))
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b

func _intro() -> void:
	var lines = ["[color=%s]IdleOS bootloader[/color]  [color=%s]v1.0[/color]" % [BRIGHT, FAINT], "",
		"[color=%s][  OK  ][/color] Mounting /home" % GREEN,
		"[color=%s][  OK  ][/color] Found %d user profile%s" % [GREEN, _filled(), "" if _filled() == 1 else "s"], "",
		"Select a user profile."]
	_log.text = ""
	for l in lines:
		_log.text += ("\n" if _log.text != "" else "") + l
		await get_tree().create_timer(0.08).timeout
	if _out.text == "":
		_say(_help_text()) # 2026-11-02 (Josh): the commands show from the start
	_input.grab_focus()

func _filled() -> int:
	var c = 0
	for n in SaveManager.SLOTS:
		if SaveManager.slot_exists(n + 1):
			c += 1
	return c

#region cards
func _refresh() -> void:
	_metas.clear()
	for n in SaveManager.SLOTS:
		_metas.append(SaveManager.read_meta(n + 1))
		_build_card(n)
	_select(_selected)

func _style(hi: bool) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = CARD_HI if hi else CARD
	s.border_color = Color(GREEN) if hi else LINE
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(20)
	return s

func _select(n: int) -> void:
	_selected = clampi(n, 0, SaveManager.SLOTS - 1)
	for i in _cards.size():
		_cards[i].add_theme_stylebox_override("panel", _style(i == _selected))

func _build_card(n: int) -> void:
	var card: PanelContainer = _cards[n]
	for c in card.get_children():
		c.queue_free()
	var meta: Dictionary = _metas[n]
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var top = HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var title = _rich(22)
	title.fit_content = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	if meta.is_empty():
		title.text = "[color=%s]%d[/color]  [color=%s]empty slot[/color]" % [FAINT, n + 1, FAINT]
		var body = _rich(16)
		body.fit_content = true
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.text = "\n\n\n\n\n[center][color=%s][ + new profile ][/color]\n\n[color=%s]starts a fresh IdleOS install[/color][/center]" % [GREEN, FAINT]
		v.add_child(body)
		return
	title.text = "[color=%s]%d[/color]  [color=%s]%s[/color]" % [FAINT, n + 1, TEXT, SaveManager.display_name(n + 1, meta)]
	if str(meta.get("hat", "")) != "":
		var hat = HatIcon.new()
		hat.fixed = str(meta.hat)
		top.add_child(hat)
		hat.custom_minimum_size = Vector2(30, 24)
	var body = _rich(15)
	body.fit_content = true
	v.add_child(body)
	if meta.get("corrupt", false) or meta.get("legacy", false):
		body.text = "[color=#e26d5a]This save can't be read.[/color]" if meta.get("corrupt", false) else "[color=%s]Older save: boot it once to fill in this card.[/color]" % DIM
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_card_footer(v, n, !meta.get("corrupt", false))
		return
	var t = ""
	var tiers_done = int(meta.get("tiers_done", 0))
	if meta.get("all_done", false):
		t += "[color=%s]All 6 locations complete[/color]\n" % GREEN
	else:
		t += "[color=%s]%s[/color]  [color=%s]location %d/6[/color]\n" % [TEXT, str(meta.get("location", "?")), DIM, int(meta.get("tier", 1))]
		var goal = max(1, int(meta.get("upload_goal", 1)))
		var frac = clampf(float(meta.get("upload_done", 0)) / goal, 0.0, 1.0)
		t += "[color=%s]uploads[/color]  %s  [color=%s]%d%%[/color]\n" % [DIM, _bar(frac, 18), DIM, int(frac * 100)]
	t += "[color=%s]last played %s  ·  played %s[/color]\n" % [FAINT, _ago(int(meta.get("saved_at", 0))), _dur(int(meta.get("play_seconds", 0)))]
	body.text = t
	# skills: two columns
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 2)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	for sk in meta.get("skills", []):
		var l = _rich(14)
		l.fit_content = true
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.text = "[color=#%s]%s[/color] [color=%s]lv %d[/color]%s" % [str(sk.color), str(sk.name).rpad(10), TEXT, int(sk.level),
			"  [color=%s]FW[/color]" % YELLOW if sk.get("firmware", false) else ""]
		grid.add_child(l)
	# what runs while away
	var off = _rich(14)
	off.fit_content = true
	v.add_child(off)
	var q: Dictionary = meta.get("queue", {})
	var o = ""
	if q.get("running", false):
		var cur = str(q.get("current", ""))
		o = "[color=%s]▶ queue[/color] [color=%s]step %d%s[/color]\n  [color=%s]%d steps · half speed offline[/color]" % [GREEN, GREEN, int(q.get("index", 0)), (": " + cur) if cur != "" else "", DIM, int(q.get("steps", 0))]
	elif str(meta.get("offline", "")) != "":
		o = "[color=%s]▶ %s[/color] [color=%s]· running offline[/color]" % [GREEN, str(meta.offline), DIM]
	else:
		o = "[color=%s]no process running[/color]" % FAINT
	off.text = "\n" + o
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	_card_footer(v, n, true)

## rename / delete (and boot) along the bottom of a filled card
func _card_footer(v: VBoxContainer, n: int, can_boot: bool) -> void:
	var foot = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 6)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(foot)
	foot.add_child(_button("rename", func(): _open_rename(n + 1)))
	foot.add_child(_button("delete", func(): _open_delete(n + 1), DIM, "#e26d5a"))
	var gap = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(gap)
	if can_boot:
		foot.add_child(_button("boot", func(): _boot(n + 1), GREEN, BRIGHT))

func _bar(frac: float, width: int) -> String:
	var full = int(round(frac * width))
	return "[color=%s]%s[/color][color=%s]%s[/color]" % [GREEN, "█".repeat(full), "#2a333c", "█".repeat(width - full)]

func _ago(unix: int) -> String:
	if unix <= 0:
		return "?"
	var s = int(Time.get_unix_time_from_system()) - unix
	if s < 60:
		return "just now"
	if s < 3600:
		return "%dm ago" % (s / 60)
	if s < 86400:
		return "%dh %dm ago" % [s / 3600, (s % 3600) / 60]
	return "%dd ago" % (s / 86400)

func _dur(s: int) -> String:
	if s < 3600:
		return "%dm" % (s / 60)
	return "%dh %dm" % [s / 3600, (s % 3600) / 60]

func _on_card_input(ev: InputEvent, n: int) -> void:
	if _modal == null and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_boot(n + 1)
#endregion

#region commands
func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE and _modal != null:
		_close_modal()
		return
	if _busy or _modal != null or !(ev is InputEventKey) or !ev.pressed or _input.text != "":
		return
	if ev.keycode == KEY_LEFT:
		_select(_selected - 1)
	elif ev.keycode == KEY_RIGHT:
		_select(_selected + 1)

func _on_submit(text: String) -> void:
	var raw = text.strip_edges()
	var t = raw.to_lower()
	_input.clear()
	_refocus.call_deferred()
	if _busy or _modal != null:
		return
	if t == "":
		_boot(_selected + 1) # Enter on an empty line boots the highlighted profile
		return
	var w = t.split(" ", false)
	match w[0]:
		"boot", "load", "new", "rename", "rm", "delete":
			if w.size() < 2 or !w[1].is_valid_int() or int(w[1]) < 1 or int(w[1]) > SaveManager.SLOTS:
				_say("usage: %s <1-%d>%s" % [w[0], SaveManager.SLOTS, " <name>" if w[0] == "rename" else ""])
				return
			var n = int(w[1])
			var arg = raw.split(" ", false, 2)[2].strip_edges() if raw.split(" ", false, 2).size() > 2 else ""
			match w[0]:
				"boot", "load":
					_boot(n)
				"new":
					if !_metas[n - 1].is_empty():
						_say("Slot %d is in use. 'rm %d' first, or pick an empty slot." % [n, n])
					else:
						_boot(n)
				"rename":
					if _metas[n - 1].is_empty():
						_say("Slot %d is empty." % n)
					elif arg != "":
						_do_rename(n, arg)
					else:
						_open_rename(n)
				_:
					if _metas[n - 1].is_empty():
						_say("Slot %d is empty." % n)
					else:
						_open_delete(n)
		"ls", "list":
			_refresh()
			_say(_ls_text())
		"help", "-h":
			_say(_help_text())
		"settings":
			_open_settings()
		"quit", "exit":
			_quit()
		_:
			if t.is_valid_int():
				_boot(int(t))
			else:
				_say("'%s' isn't a command. Type 'help'." % w[0])

func _help_text() -> String:
	var rows = [["boot <n>", "load profile n (1-3)"], ["new <n>", "new profile in empty slot n"],
		["rename <n> <name>", "rename profile n"], ["rm <n>", "delete profile n"], ["ls", "list profiles"], ["settings", "volume, music, window"], ["quit", "exit"]]
	var h = ""
	for r in rows:
		h += "[color=%s]%s[/color] %s\n" % [GREEN, r[0].rpad(18), r[1]]
	return h + "[color=%s]Or click a profile card.[/color]" % FAINT

func _ls_text() -> String:
	var out = ""
	for n in SaveManager.SLOTS:
		var m: Dictionary = _metas[n]
		out += "%d  %s\n" % [n + 1, ("[color=%s]empty[/color]" % FAINT) if m.is_empty() else "%s  [color=%s]%s[/color]" % [SaveManager.display_name(n + 1, m), DIM, str(m.get("location", ""))]]
	return out.strip_edges()

func _say(text: String) -> void:
	_out.text = text
#endregion

func _boot(n: int, new_name: String = "") -> void:
	if _busy or _modal != null or n < 1 or n > SaveManager.SLOTS:
		return
	var empty = _metas[n - 1].is_empty()
	if empty and new_name == "":
		_open_new(n)
		return
	if _metas[n - 1].get("corrupt", false):
		_say("[color=#e26d5a]Slot %d can't be read. 'rm %d' clears it.[/color]" % [n, n])
		return
	_busy = true
	_select(n - 1)
	if empty:
		SaveManager.profile_name = new_name
	SaveManager.slot = n
	var name = new_name if empty else SaveManager.display_name(n, _metas[n - 1])
	_say("[color=%s][  ..  ][/color] %s %s" % [DIM, "Creating profile" if empty else "Mounting", name])
	await get_tree().create_timer(0.35).timeout
	_say("[color=%s][  OK  ][/color] %s %s" % [GREEN, "Creating profile" if empty else "Mounting", name])
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file(GAME_SCENE)

#region popups
## A small modal box: title, text, an optional name field, and confirm / cancel. <on_ok> gets the field text and
## returns "" when done (the box closes) or an error to show.
func _popup(title: String, text: String, field: String, ok_label: String, ok_color: String, on_ok: Callable, need_match: String = "") -> void:
	_close_modal()
	var shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	_modal = shade
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var box = PanelContainer.new()
	var st = _style(true)
	st.border_color = Color(ok_color)
	st.bg_color = CARD
	st.set_content_margin_all(24)
	box.add_theme_stylebox_override("panel", st)
	box.custom_minimum_size = Vector2(520, 0)
	center.add_child(box)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	box.add_child(v)
	var head = _rich(20)
	head.fit_content = true
	head.text = "[color=%s]%s[/color]" % [ok_color, title]
	v.add_child(head)
	var body = _rich(15)
	body.fit_content = true
	body.text = text
	v.add_child(body)
	var le: LineEdit = null
	if field != "-":
		le = LineEdit.new()
		le.text = field
		le.select_all_on_focus = true
		le.add_theme_font_size_override("font_size", 16)
		le.max_length = 16 if need_match == "" else 64
		_style_field(le)
		v.add_child(le)
	var err = _rich(14)
	err.fit_content = true
	v.add_child(err)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	row.add_child(_button("cancel", func(): _close_modal()))
	var ok_btn = _button(ok_label, func(): pass, ok_color, ok_color)
	row.add_child(ok_btn)
	var submit = func(_t = ""):
		var why = on_ok.call(le.text.strip_edges() if le else "")
		if why == "":
			_close_modal()
		else:
			err.text = "[color=#e26d5a]%s[/color]" % why
	ok_btn.pressed.connect(submit)
	if le:
		le.text_submitted.connect(submit)
		if need_match != "": # delete: the button only works once the command is typed
			var fs: StyleBoxFlat = le.get_theme_stylebox("focus").duplicate()
			fs.border_color = Color(ok_color)
			le.add_theme_stylebox_override("focus", fs)
			ok_btn.disabled = true
			ok_btn.add_theme_color_override("font_disabled_color", Color(FAINT))
			le.text_changed.connect(func(t): ok_btn.disabled = t.strip_edges() != need_match)
		le.grab_focus.call_deferred()
		if need_match == "":
			le.select_all.call_deferred()

func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null
	_refocus.call_deferred()

func _open_settings() -> void:
	if _modal != null or _busy:
		return
	var p = SettingsPopup.open(self)
	_modal = p
	p.closed.connect(func():
		_modal = null
		_refocus.call_deferred())

func _open_new(n: int) -> void:
	_select(n - 1)
	_popup("New profile", "Slot %d. Name it (letters, numbers, '_' and '-').\n[color=%s]It starts a fresh IdleOS install.[/color]" % [n, FAINT],
		"user_%d" % n, "create", GREEN, func(nm):
			var why = SaveManager.name_problem(nm)
			if why != "":
				return why
			_boot.call_deferred(n, nm)
			return "")

func _open_rename(n: int) -> void:
	_select(n - 1)
	_popup("Rename profile", "Slot %d." % n, SaveManager.display_name(n, _metas[n - 1]), "save", GREEN, func(nm): return _do_rename(n, nm))

func _do_rename(n: int, nm: String) -> String:
	var why = SaveManager.name_problem(nm)
	if why != "":
		_say("[color=#e26d5a]%s[/color]" % why)
		return why
	if !SaveManager.rename_slot(n, nm):
		return "Couldn't write slot %d." % n
	_refresh()
	_say("Slot %d is now [color=%s]%s[/color]." % [n, GREEN, nm])
	return ""

func _open_delete(n: int) -> void:
	_select(n - 1)
	var nm = SaveManager.display_name(n, _metas[n - 1])
	var cmd = "sudo rm -rf " + nm # 2026-11-02 (Josh): confirm by typing the command
	_popup("Delete profile", "Delete [color=%s]%s[/color] (slot %d)? All of its progress goes.\nTo confirm, type:  [color=#e26d5a]%s[/color]" % [TEXT, nm, n, cmd],
		"", "delete", "#e26d5a", func(_t):
			if !SaveManager.delete_slot(n):
				return "Couldn't delete slot %d." % n
			_refresh()
			_say("Deleted %s. Slot %d is empty." % [nm, n])
			return "", cmd)
#endregion

func _quit() -> void:
	get_tree().quit()
