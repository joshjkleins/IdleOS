class_name SystemDock
extends PanelContainer
## Right-side panel: system temperature, tracked items and running VMs. Click a VM row to minimize/restore it.

@onready var tracked_section: VBoxContainer = %TrackedSection
@onready var hud_monitor = %HUDMonitor
@onready var vm_section: VBoxContainer = %VMSection
@onready var vm_count_label: Label = %VMCountLabel
@onready var vm_list: VBoxContainer = %VMList
@onready var vm_empty_label: Label = %VMEmptyLabel
@onready var separator: HSeparator = %Separator
@onready var system_separator: HSeparator = %SystemSeparator
@onready var system_temp: SystemTemp = %SystemTemp

@onready var full_view: VBoxContainer = $VBox
@onready var compact_view: SystemDockCompact = %Compact
@onready var collapse_button: Button = %CollapseButton
@onready var process_section = %HUDProcessRunning

## Emitted when the panel changes size so idle_os_2 can re-layout the terminal.
signal width_changed(new_width: float)

const EXPANDED_WIDTH = 284.0
const COLLAPSED_WIDTH = 56.0

var collapsed: bool = false

const ROW_FONT_SIZE = 11
const DIM = Color(0.45, 0.5, 0.55, 1)
const TEXT = Color(0.8, 0.84, 0.88, 1)

var _rows := {} # VMWindow -> {button, name, status, bar}
var _refresh_accum := 0.0

func _ready() -> void:
	# line tracked rows up with the section headers
	var monitor_margin: MarginContainer = hud_monitor.get_node("MarginContainer")
	for side in ["left", "top", "right", "bottom"]:
		monitor_margin.add_theme_constant_override("margin_" + side, 0)
	VMManager.vms_changed.connect(_rebuild_rows)
	_rebuild_rows()
	add_to_group("system_dock")
	collapse_button.pressed.connect(func(): set_collapsed(true); Signals.vm_window_focused())
	compact_view.expand_requested.connect(func(): set_collapsed(false); Signals.vm_window_focused())
	_apply_collapsed()

func get_panel_width() -> float:
	return COLLAPSED_WIDTH if collapsed else EXPANDED_WIDTH

func set_collapsed(value: bool) -> void:
	if collapsed == value:
		return
	collapsed = value
	_apply_collapsed()
	SaveManager.mark_dirty()

func toggle() -> void:
	set_collapsed(!collapsed)

func _apply_collapsed() -> void:
	full_view.visible = !collapsed
	compact_view.visible = collapsed
	custom_minimum_size.x = get_panel_width()
	offset_left = -get_panel_width()
	width_changed.emit(get_panel_width())

func save_data() -> Dictionary:
	return {"collapsed": collapsed}

func load_data(data: Dictionary) -> void:
	set_collapsed(bool(data.get("collapsed", false)))

func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum < (0.05 if collapsed else 0.25):
		return
	if collapsed:
		compact_view.refresh(process_section.is_running(), process_section.current_color, _refresh_accum)
		_refresh_accum = 0.0
		return
	_refresh_accum = 0.0
	_refresh_rows()
	_update_visibility()

func _update_visibility() -> void:
	var has_tracked: bool = hud_monitor.tracked_items.size() > 0
	var vms_unlocked: bool = Stats.MAX_ALL_VMS > 0
	tracked_section.visible = has_tracked
	vm_section.visible = vms_unlocked
	separator.visible = has_tracked and vms_unlocked
	system_separator.visible = has_tracked or vms_unlocked
	vm_count_label.text = "%d/%d" % [VMManager.vms.size(), Stats.MAX_ALL_VMS]
	vm_empty_label.visible = VMManager.vms.is_empty()

func _rebuild_rows() -> void:
	for row in vm_list.get_children():
		row.queue_free()
	_rows.clear()
	for vm in VMManager.vms:
		_rows[vm] = _make_row(vm)
	_refresh_rows()
	_update_visibility()

func _make_row(vm: VMWindow) -> Dictionary:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.custom_minimum_size = Vector2(0, 30)
	button.tooltip_text = "Click to minimize / restore"
	button.pressed.connect(func(): VMManager.toggle(vm); Signals.vm_window_focused())
	vm_list.add_child(button)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 3)
	button.add_child(box)

	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 6)
	box.add_child(line)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.color = vm.skill.SKILL.color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(dot)

	var name_label := _label("vm-%02d %s/%s" % [vm.vm_id, vm.skill.SKILL.name.to_lower(), str(vm.minor_process.name).to_lower().replace(" ", "-")])
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	line.add_child(name_label)

	var status_label := _label("")
	line.add_child(status_label)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 3)
	bar.max_value = 1.0
	bar.step = 0.001
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(1, 1, 1, 0.06)
	var fill := StyleBoxFlat.new(); fill.bg_color = vm.skill.SKILL.color
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)

	return {"button": button, "name": name_label, "status": status_label, "bar": bar}

func _refresh_rows() -> void:
	for vm in _rows:
		if !is_instance_valid(vm):
			continue
		var row = _rows[vm]
		var minimized: bool = !vm.visible
		if vm.stopping:
			row.status.text = "stopping"
		else:
			row.status.text = "%ds%s" % [vm.get_seconds_left(), "" if vm.tokens_used <= 1 else " x%d" % vm.tokens_used]
		row.button.tooltip_text = ("Minimized - click to restore" if minimized else "Click to minimize") + "\nTokens used: %d" % vm.tokens_used
		row.name.add_theme_color_override("font_color", DIM if minimized else TEXT)
		row.bar.value = vm.get_progress()
		row.bar.modulate.a = 0.45 if minimized else 1.0

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	l.add_theme_color_override("font_color", DIM)
	return l
