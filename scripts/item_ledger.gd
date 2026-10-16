class_name ItemLedger
extends VBoxContainer
## LEDGER section at the bottom of the side panel: a small read-only terminal of recent item gains.
## Each new entry "downloads" (quick progress line) before resolving to: +amount  Name ...... total
## Repeated gains of the same item within MERGE_WINDOW merge into the newest row.

const MAX_ROWS = 7
const ROW_WIDTH = 36          # characters (monospace)
const DOWNLOAD_TIME = 0.35
const MERGE_WINDOW = 2.0      # seconds
const BAR_CELLS = 10
const FONT_SIZE = 11
const C_AMOUNT = Color("#4ec994")
const C_DIM = Color(0.36, 0.42, 0.48, 1)
const C_DOWNLOAD = Color(0.45, 0.62, 0.72, 1)

@onready var rows_box: VBoxContainer = %LedgerRows
@onready var cursor_label: Label = %LedgerCursor

var _rows: Array[Dictionary] = [] # newest first: {item, amount, label, time, settled}
var _blink := 0.0

func _ready() -> void:
	Signals.item_added_signal.connect(_on_item_added)

func _process(delta: float) -> void:
	_blink += delta
	cursor_label.text = "> _" if fmod(_blink, 1.0) < 0.5 else ">"

func _on_item_added(item: ItemData, amount: int) -> void:
	if amount <= 0:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if !_rows.is_empty():
		var top = _rows[0]
		if top.item == item and now - top.time <= MERGE_WINDOW:
			top.amount += amount
			top.time = now
			if top.settled:
				_render_settled(top)
				_flash(top.label)
			return
	_add_row(item, amount, now)

func _add_row(item: ItemData, amount: int, now: float) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	rows_box.add_child(label)
	rows_box.move_child(label, 0)
	var row = {"item": item, "amount": amount, "label": label, "time": now, "settled": false}
	_rows.push_front(row)
	while _rows.size() > MAX_ROWS:
		var old = _rows.pop_back()
		old.label.queue_free()
	_restyle_ages()
	var tween = create_tween()
	tween.tween_method(func(p): _render_download(row, p), 0.0, 1.0, DOWNLOAD_TIME)
	tween.tween_callback(func():
		row.settled = true
		_render_settled(row)
		_flash(label))

func _file_name(item: ItemData) -> String:
	return item.name.to_lower().replace(" ", "_") + ".dat"

func _render_download(row: Dictionary, progress: float) -> void:
	if !is_instance_valid(row.label):
		return
	var filled = int(round(progress * BAR_CELLS))
	var bar = "█".repeat(filled) + "░".repeat(BAR_CELLS - filled)
	var name = _file_name(row.item)
	var max_name = ROW_WIDTH - BAR_CELLS - 9
	if name.length() > max_name:
		name = name.substr(0, max_name - 1) + "~"
	row.label.text = "[color=#%s]↓ %s %s %3d%%[/color]" % [C_DOWNLOAD.to_html(false), name.rpad(max_name), bar, int(progress * 100)]

func _render_settled(row: Dictionary) -> void:
	if !is_instance_valid(row.label):
		return
	var amount_text = "+%d" % row.amount
	var total_text = _format_number(Inventory.get_amount(row.item))
	var name = row.item.name
	var max_name = ROW_WIDTH - 6 - total_text.length() - 2
	if name.length() > max_name:
		name = name.substr(0, max_name - 1) + "~"
	var dots = ROW_WIDTH - 6 - name.length() - total_text.length() - 2
	var item_color: Color = Palette.get_color(row.item.color_type)
	row.label.text = "[color=#%s]%s[/color][color=#%s]%s[/color] [color=#%s]%s[/color] %s" % [
		C_AMOUNT.to_html(false), amount_text.rpad(6),
		item_color.lightened(0.25).to_html(false), name,
		C_DIM.to_html(false), ".".repeat(max(1, dots)),
		total_text]

func _restyle_ages() -> void:
	for i in _rows.size():
		_rows[i].label.modulate.a = clamp(1.0 - i * 0.14, 0.25, 1.0)

func _flash(label: RichTextLabel) -> void:
	if !is_instance_valid(label):
		return
	label.modulate = Color(1.6, 1.6, 1.6, label.modulate.a)
	create_tween().tween_property(label, "modulate:r", 1.0, 0.25)
	create_tween().tween_property(label, "modulate:g", 1.0, 0.25)
	create_tween().tween_property(label, "modulate:b", 1.0, 0.25)

static func _format_number(n: int) -> String:
	var s = str(abs(n))
	var out = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
