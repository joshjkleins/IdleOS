class_name SystemDockCompact
extends VBoxContainer
## Collapsed view of the side panel: just the essentials as small lights.
##   « (expand) / process light / temperature + mini heat bar / one light per VM slot

const LIGHT = Vector2(12, 12)
const C_EMPTY = Color(1, 1, 1, 0.08)
const C_IDLE = Color(0.25, 0.29, 0.33, 1)
const C_DIM = Color(0.36, 0.42, 0.48, 1)

signal expand_requested

var process_light: Panel
var temp_label: Label
var heat_bar: Control
var vm_box: VBoxContainer
var _pulse := 0.0

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	alignment = BoxContainer.ALIGNMENT_BEGIN

	var expand := Button.new()
	expand.text = "«"
	expand.flat = true
	expand.focus_mode = Control.FOCUS_NONE
	expand.tooltip_text = "Expand panel  (or type 'panel')"
	expand.add_theme_color_override("font_color", C_DIM)
	expand.add_theme_font_size_override("font_size", 16)
	expand.pressed.connect(func(): expand_requested.emit())
	add_child(expand)

	add_child(_caption("PROC"))
	process_light = _light()
	process_light.tooltip_text = "Main terminal process"
	add_child(_centered(process_light))

	add_child(_caption("TEMP"))
	temp_label = Label.new()
	temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_label.add_theme_font_size_override("font_size", 12)
	add_child(temp_label)
	heat_bar = Control.new()
	heat_bar.custom_minimum_size = Vector2(8, 90)
	heat_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	heat_bar.draw.connect(_draw_heat_bar)
	add_child(heat_bar)

	add_child(_caption("VM"))
	vm_box = VBoxContainer.new()
	vm_box.add_theme_constant_override("separation", 5)
	add_child(vm_box)

## Called by SystemDock a few times a second while collapsed.
func refresh(process_running: bool, process_color: Color, delta: float) -> void:
	_pulse += delta
	var light_col = process_color.lightened(0.2) if process_running else C_IDLE
	if process_running:
		light_col.a = 0.75 + 0.25 * sin(_pulse * 3.0)
	_set_light(process_light, light_col)

	var t = Stats.system_tempature
	temp_label.text = "%d°" % int(round(t))
	temp_label.add_theme_color_override("font_color", SystemTemp.zone_color(t))
	heat_bar.queue_redraw()

	# one light per VM slot
	var slots = max(Stats.MAX_ALL_VMS, VMManager.vms.size())
	while vm_box.get_child_count() < slots:
		vm_box.add_child(_centered(_light()))
	while vm_box.get_child_count() > slots:
		var extra = vm_box.get_child(vm_box.get_child_count() - 1)
		vm_box.remove_child(extra)
		extra.queue_free()
	for i in slots:
		var light: Panel = vm_box.get_child(i).get_child(0)
		if i < VMManager.vms.size():
			var vm: VMWindow = VMManager.vms[i]
			var c: Color = vm.skill.SKILL.color.lightened(0.15)
			if vm.visible:
				_set_light(light, c)
			else: # minimized: hollow square in the skill color
				_set_light(light, Color(c, 0.15), true, c)
			light.tooltip_text = "vm-%02d %s/%s  %ds%s" % [vm.vm_id, vm.skill.SKILL.name.to_lower(), str(vm.minor_process.name).to_lower(), vm.get_seconds_left(), "  (minimized)" if !vm.visible else ""]
		else:
			_set_light(light, Color(0, 0, 0, 0), true)
			light.tooltip_text = "empty VM slot"

func _draw_heat_bar() -> void:
	var segs = 15
	var h = heat_bar.size.y
	var seg_h = (h - (segs - 1) * 2.0) / segs
	var pct = clamp((Stats.system_tempature - SystemTemp.TEMP_MIN) / (SystemTemp.TEMP_MAX - SystemTemp.TEMP_MIN), 0.0, 1.0)
	var filled = int(round(pct * segs))
	for i in segs: # bottom to top
		var y = h - (i + 1) * seg_h - i * 2.0
		var seg_temp = SystemTemp.TEMP_MIN + (i + 0.5) / segs * (SystemTemp.TEMP_MAX - SystemTemp.TEMP_MIN)
		var col = SystemTemp.zone_color(seg_temp) if i < filled else C_EMPTY
		heat_bar.draw_rect(Rect2(0, y, heat_bar.size.x, seg_h), col)

func _light() -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = LIGHT
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_light(p, C_IDLE)
	return p

func _set_light(p: Panel, color: Color, outline: bool = false, outline_color: Color = Color(1, 1, 1, 0.18)) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	if outline:
		sb.set_border_width_all(1)
		sb.border_color = outline_color
	p.add_theme_stylebox_override("panel", sb)

func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", C_DIM)
	return l
