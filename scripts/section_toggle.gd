class_name SectionToggle
extends Button
## Small - / + button for a side-panel section header. Emits toggled_section(collapsed).

signal toggled_section(collapsed: bool)

const C = Color(0.36, 0.42, 0.48, 1)
var collapsed := false

func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(14, 0)
	add_theme_font_size_override("font_size", 12)
	add_theme_color_override("font_color", C)
	add_theme_color_override("font_hover_color", C.lightened(0.4))
	add_theme_constant_override("h_separation", 0)
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	tooltip_text = "Collapse / expand"
	pressed.connect(func(): set_collapsed(!collapsed); toggled_section.emit(collapsed))
	_update()

func set_collapsed(value: bool) -> void:
	collapsed = value
	_update()

func _update() -> void:
	text = "+" if collapsed else "-"
