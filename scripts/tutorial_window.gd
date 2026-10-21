class_name TutorialWindow
extends PanelContainer
## Floating tutorial panel, docked at the top of the terminal next to the side panel (like a VM window).
## One page per tutorial step: < prev / next > flip through finished and upcoming steps, "current" jumps
## back to the step you're on. A finished step flashes OBJECTIVE COMPLETE and moves to the next page.
## '_' folds it to its title bar; 'x' hides it ('tutorial' brings it back). Hidden for good once the
## tutorial is complete.

const WIDTH := 400.0
const MARGIN := 10.0
const TOP := 46.0
const GREEN := Color("#33ff33")
const BG := Color("#0b0f14")
const BORDER := Color("#1f5f1f")
const DIM := Color(0.45, 0.5, 0.55, 1)
const TEXT := Color(0.8, 0.84, 0.88, 1)

var page := 0
var folded := false
var _title: Label
var _body: RichTextLabel
var _banner: Label
var _body_box: VBoxContainer
var _prev: Button
var _next: Button
var _current: Button
var _bar: ProgressBar
var _fold: Button
var _banner_left := 0.0
var top_anchor: Control # the skill header: the window's top sits on its bottom edge
var context_hidden := false # in the Hacking module (it prints the steps in its own console)

func _ready() -> void:
	custom_minimum_size.x = WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_END
	mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := StyleBoxFlat.new()
	frame.bg_color = BG
	frame.border_color = BORDER
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(3)
	add_theme_stylebox_override("panel", frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	add_child(box)
	# title bar
	var bar_panel := PanelContainer.new()
	var tb := StyleBoxFlat.new()
	tb.bg_color = Color(0.2, 1.0, 0.2, 0.06)
	tb.content_margin_left = 8
	tb.content_margin_right = 4
	tb.content_margin_top = 3
	tb.content_margin_bottom = 3
	bar_panel.add_theme_stylebox_override("panel", tb)
	box.add_child(bar_panel)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	bar_panel.add_child(head)
	var dot := ColorRect.new()
	dot.color = GREEN
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(dot)
	_title = _label("", 11, GREEN)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_fold = _button("_", func(): set_folded(!folded))
	head.add_child(_fold)
	head.add_child(_button("x", func(): close()))
	# body
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	box.add_child(margin)
	_body_box = VBoxContainer.new()
	_body_box.add_theme_constant_override("separation", 6)
	margin.add_child(_body_box)
	_banner = _label("OBJECTIVE COMPLETE", 11, GREEN)
	_banner.visible = false
	_body_box.add_child(_banner)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = WIDTH - 22
	_body.add_theme_font_size_override("normal_font_size", 12)
	_body.add_theme_color_override("default_color", TEXT)
	_body.mouse_filter = Control.MOUSE_FILTER_PASS
	_body_box.add_child(_body)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size.y = 3
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.08)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GREEN.darkened(0.3)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	_body_box.add_child(_bar)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	_body_box.add_child(nav)
	_prev = _button("< prev", func(): show_page(page - 1))
	nav.add_child(_prev)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)
	_current = _button("current", func(): show_page(current_page()))
	nav.add_child(_current)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer2)
	_next = _button("next >", func(): show_page(page + 1))
	nav.add_child(_next)
	Tutorial.step_completed.connect(_on_step_completed)
	Tutorial.progress_changed.connect(_refresh)
	Tutorial.tutorial_reset.connect(open)
	SaveManager.save_loaded.connect(_on_save_loaded)
	minimum_size_changed.connect(_dock.call_deferred)
	get_viewport().size_changed.connect(_dock)
	folded = Tutorial.window_folded
	_apply_visible()
	page = current_page()
	_apply_fold()
	_refresh()
	_dock.call_deferred()

func _on_save_loaded() -> void:
	folded = Tutorial.window_folded
	page = current_page()
	_apply_fold()
	_refresh()
	_apply_visible()

## Steps in the order players see them
static func pages() -> Array:
	return Tutorial.steps()

static func current_page() -> int:
	var p = pages()
	for i in p.size():
		if !Tutorial.completed_events.has(p[i]):
			return i
	return max(0, p.size() - 1)

static func step_title(e) -> String:
	return Tutorial.step_title(e)

func show_page(i: int) -> void:
	page = clamp(i, 0, pages().size() - 1)
	_refresh()

func _refresh() -> void:
	if _body == null:
		return
	var p = pages()
	if p.is_empty():
		return
	page = clamp(page, 0, p.size() - 1)
	var e = p[page]
	var cur = current_page()
	var done = Tutorial.completed_events.has(e)
	_title.text = "tutorial  ·  step %d/%d" % [page + 1, p.size()]
	var state = "[color=#4ec994]DONE[/color]" if done else ("[color=yellow]CURRENT OBJECTIVE[/color]" if page == cur else "[color=#666666]UPCOMING[/color]")
	var need = Tutorial.get_event_requirement(e)
	var prog = ""
	if need > 1 and !done:
		prog = "  [color=#888888](%d/%d)[/color]" % [min(int(Tutorial.tutorial_progress.get(e, 0)), need), need]
	var text = "%s  [color=#888888]%s[/color]%s\n\n%s" % [state, step_title(e), prog, Tutorial.tutorial_tasks[e]]
	if page > cur:
		text = "%s  [color=#888888]%s[/color]\n\n[color=#888888]%s[/color]" % [state, step_title(e), Tutorial.tutorial_tasks[e]]
	_body.text = text
	_bar.max_value = p.size()
	_bar.value = Tutorial.completed_events.filter(func(x): return p.has(x)).size()
	_prev.disabled = page <= 0
	_next.disabled = page >= p.size() - 1
	_current.disabled = page == cur

func _on_step_completed(_e) -> void:
	if Tutorial.is_tutorial_complete():
		_apply_visible()
		return
	page = current_page()
	_banner_left = 3.0
	_banner.visible = true
	if folded:
		set_folded(false)
	_refresh()

func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false

func set_folded(value: bool) -> void:
	folded = value
	Tutorial.window_folded = value
	SaveManager.mark_dirty()
	_apply_fold()

func _apply_fold() -> void:
	_body_box.get_parent().visible = !folded
	_fold.text = "+" if folded else "_"
	_dock.call_deferred()

## Shown unless closed, finished, or the Hacking module is up
func _apply_visible() -> void:
	visible = !Tutorial.window_closed and !Tutorial.is_tutorial_complete() and !context_hidden
	if visible:
		_dock.call_deferred()

func set_context_hidden(value: bool) -> void:
	context_hidden = value
	_apply_visible()

## true when the window is up (the terminal then keeps tutorial messages short)
func is_showing() -> bool:
	return !Tutorial.window_closed and !Tutorial.is_tutorial_complete()

func close() -> void:
	Tutorial.window_closed = true
	_apply_visible()
	SaveManager.mark_dirty()

func open() -> void:
	if Tutorial.is_tutorial_complete():
		return
	Tutorial.window_closed = false
	page = current_page()
	_refresh()
	_apply_visible()
	SaveManager.mark_dirty()

## Top right of the terminal area, left of the side panel
func _dock() -> void:
	if !is_inside_tree():
		return
	reset_size()
	var host := get_parent() as Control
	var right = host.size.x if host else get_viewport_rect().size.x
	var dock = get_tree().get_first_node_in_group("system_dock") as Control
	if dock and dock.is_visible_in_tree() and host:
		right = dock.global_position.x - host.global_position.x
	var top = TOP
	if top_anchor and host and top_anchor.is_visible_in_tree():
		top = top_anchor.get_global_rect().end.y - host.global_position.y
	position = Vector2(max(0.0, right - size.x - MARGIN), top)

func _label(text: String, s: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", DIM.lightened(0.2))
	b.add_theme_color_override("font_hover_color", GREEN)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.15))
	b.pressed.connect(func(): cb.call(); Signals.vm_window_focused())
	return b
