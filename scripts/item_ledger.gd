class_name ItemLedger
extends VBoxContainer
## LEDGER section at the bottom of the side panel: a small read-only rx/tx log of recent item changes.
## Gains "download" (↓) and resolve to:   +amount  Name ...... total
## Items used up "upload" (↑) and resolve to: -amount  Name ...... total
## Repeated changes of the same item in the same direction within MERGE_WINDOW merge into the newest row.

const MAX_ROWS = 7
const ROW_WIDTH = 36          # characters (monospace)
const DOWNLOAD_TIME = 0.35
const UPLOAD_TIME = 0.25
const MERGE_WINDOW = 2.0      # seconds
const MERGE_DEPTH = 3         # how many recent rows can absorb a repeat
const BAR_CELLS = 10
const FONT_SIZE = 11
const C_AMOUNT = Color("#4ec994")
const C_REMOVED = Color("#d98a4a")
const C_DIM = Color(0.36, 0.42, 0.48, 1)
const C_DOWNLOAD = Color(0.45, 0.62, 0.72, 1)
const C_UPLOAD = Color(0.72, 0.58, 0.45, 1)

@onready var rows_box: VBoxContainer = %LedgerRows
@onready var cursor_label: Label = %LedgerCursor

var _rows: Array[Dictionary] = [] # newest first: {item, amount, dir, label, time, settled}
var _blink := 0.0

func _ready() -> void:
	Signals.item_added_signal.connect(func(item, amount): _on_item_changed(item, amount, 1))
	Signals.item_removed_signal.connect(func(item, amount): _on_item_changed(item, amount, -1))

func _process(delta: float) -> void:
	_blink += delta
	cursor_label.text = "> _" if fmod(_blink, 1.0) < 0.5 else ">"

## dir: 1 = received (download), -1 = used up (upload)
func _on_item_changed(item: ItemData, amount: int, dir: int) -> void:
	if amount <= 0:
		return
	var now = Time.get_ticks_msec() / 1000.0
	# merge into a recent matching row (checks a few rows so alternating -logs / +ip still merge)
	for i in min(MERGE_DEPTH, _rows.size()):
		var row = _rows[i]
		if row.item == item and row.dir == dir and now - row.time <= MERGE_WINDOW:
			row.amount += amount
			row.time = now
			if row.settled:
				_render_settled(row)
				_flash(row.label)
			return
	_add_row(item, amount, dir, now)

func _add_row(item: ItemData, amount: int, dir: int, now: float) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	rows_box.add_child(label)
	rows_box.move_child(label, 0)
	var row = {"item": item, "amount": amount, "dir": dir, "label": label, "time": now, "settled": false}
	_rows.push_front(row)
	while _rows.size() > MAX_ROWS:
		var old = _rows.pop_back()
		if old.has("tween") and old.tween.is_valid():
			old.tween.kill() # its callbacks reference the label we're about to free
		old.label.queue_free()
	_restyle_ages()
	var tween = create_tween()
	row["tween"] = tween
	tween.tween_method(func(p): _render_transfer(row, p), 0.0, 1.0, DOWNLOAD_TIME if dir > 0 else UPLOAD_TIME)
	tween.tween_callback(func():
		row.settled = true
		_render_settled(row)
		_flash(row.label))

func _file_name(item: ItemData) -> String:
	return item.name.to_lower().replace(" ", "_") + ".dat"

func _render_transfer(row: Dictionary, progress: float) -> void:
	if !is_instance_valid(row.label):
		return
	var filled = int(round(progress * BAR_CELLS))
	var bar = "█".repeat(filled) + "░".repeat(BAR_CELLS - filled)
	var name = _file_name(row.item)
	var max_name = ROW_WIDTH - BAR_CELLS - 9
	if name.length() > max_name:
		name = name.substr(0, max_name - 1) + "~"
	var arrow = "↓" if row.dir > 0 else "↑"
	var col = C_DOWNLOAD if row.dir > 0 else C_UPLOAD
	row.label.text = "[color=#%s]%s %s %s %3d%%[/color]" % [col.to_html(false), arrow, name.rpad(max_name), bar, int(progress * 100)]

func _render_settled(row: Dictionary) -> void:
	if !is_instance_valid(row.label):
		return
	var amount_text = ("+%d" if row.dir > 0 else "-%d") % row.amount
	var total_text = _format_number(Inventory.get_amount(row.item))
	var name = row.item.name
	var max_name = ROW_WIDTH - 6 - total_text.length() - 2
	if name.length() > max_name:
		name = name.substr(0, max_name - 1) + "~"
	var dots = ROW_WIDTH - 6 - name.length() - total_text.length() - 2
	var item_color: Color = Palette.get_color(row.item.color_type)
	row.label.text = "[color=#%s]%s[/color][color=#%s]%s[/color] [color=#%s]%s[/color] %s" % [
		(C_AMOUNT if row.dir > 0 else C_REMOVED).to_html(false), amount_text.rpad(6),
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
