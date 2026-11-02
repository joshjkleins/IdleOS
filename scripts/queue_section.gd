class_name QueueSection
extends VBoxContainer
## 2026-11-02: side panel QUEUE (above the VMs): the command queue's steps. The step it's on is highlighted (a lit
## row: green while running, amber while it waits paused). Collapsible: one line with that step. Hidden until the
## queue opens (Lawfirm). Built in code by system_dock.gd.

const HEADER = Color(0.36, 0.42, 0.48, 1)
const DIM = Color(0.45, 0.5, 0.55, 1)
const TEXT = Color(0.8, 0.84, 0.88, 1)
const RUN = Color("#4ec994")
const WAIT = Color("#e3b341")
const FONT = 10
const ROW_FONT = 11

var _status: Label
var _rows: VBoxContainer
var _empty: Label
var _summary: Label
var toggle: SectionToggle
var collapsed := false
var sep: HSeparator # the line under it (hidden with it)
var _sig := ""
var _accum := 0.0
var _pulse := 0.0
var _lit: PanelContainer # the highlighted row

func _ready() -> void:
	add_theme_constant_override("separation", 3)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 2)
	add_child(head)
	toggle = SectionToggle.new()
	toggle.toggled_section.connect(set_collapsed)
	head.add_child(toggle)
	var title = _label("QUEUE", FONT, HEADER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_status = _label("", FONT, HEADER)
	head.add_child(_status)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 1)
	add_child(_rows)
	_summary = _label("", ROW_FONT, TEXT)
	_summary.clip_text = true
	_summary.visible = false
	add_child(_summary)
	_empty = _label("empty  ·  'queue -add <command>'", FONT, Color(0.3, 0.34, 0.38, 1))
	add_child(_empty)
	Queue.changed.connect(_refresh)
	_refresh()

func set_collapsed(value: bool) -> void:
	collapsed = value
	toggle.set_collapsed(value)
	_sig = ""
	_refresh()
	SaveManager.mark_dirty()

func _process(delta: float) -> void:
	_pulse += delta
	if _lit and is_instance_valid(_lit) and Queue.running: # the running step breathes
		_lit.self_modulate.a = 0.75 + 0.25 * sin(_pulse * 3.0)
	_accum += delta
	if _accum >= 1.0:
		_accum = 0.0
		_refresh()

func _refresh() -> void:
	visible = Queue.unlocked()
	if sep:
		sep.visible = visible
	if !visible:
		return
	var has = !Queue.steps.is_empty()
	_status.text = "%d/%d · %s" % [Queue.steps.size(), Queue.slots(), ("RUNNING" if Queue.running else "paused") if has else "empty"]
	_status.add_theme_color_override("font_color", RUN if Queue.running else HEADER)
	_empty.visible = !has and !collapsed
	_rows.visible = !collapsed
	_summary.visible = collapsed and has
	if collapsed and has:
		var i = clampi(Queue.index, 0, Queue.steps.size() - 1)
		_summary.text = "%s %d  %s" % [">" if Queue.running else "||", i, Queue.steps[i]]
		_summary.add_theme_color_override("font_color", RUN if Queue.running else WAIT)
	var sig = "%s|%s|%d|%s" % [str(Queue.steps), str(Queue.running), Queue.index, str(collapsed)]
	if sig == _sig:
		return
	_sig = sig
	for c in _rows.get_children():
		c.queue_free()
	_lit = null
	for i in Queue.steps.size():
		var cur = i == Queue.index
		var col = (RUN if Queue.running else WAIT) if cur else DIM
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col, 0.16) if cur else Color(0, 0, 0, 0)
		sb.border_color = col
		sb.border_width_left = 2 if cur else 0
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 1
		sb.content_margin_bottom = 1
		row.add_theme_stylebox_override("panel", sb)
		_rows.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		row.add_child(line)
		line.add_child(_label((">" if Queue.running else "||") if cur else str(i), ROW_FONT, col))
		var cmd = _label(Queue.steps[i], ROW_FONT, col if cur else (TEXT if Queue.running else DIM))
		cmd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cmd.clip_text = true
		line.add_child(cmd)
		if cur:
			_lit = row

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
