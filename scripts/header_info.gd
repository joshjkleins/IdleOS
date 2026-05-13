extends VBoxContainer

@onready var exp_add_label = $Control/ExpAddLabel
@onready var process_name = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/Contents/ProcessName
@onready var process_level = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/Contents/ProcessLevel
@onready var exp_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer3/MarginContainer/Contents/ExpLabel
@onready var efficiency_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/EfficiencyLabel
@onready var requirement_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/RequirementLabel
@onready var efficiency_desc = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/EfficiencyDesc
@onready var progress_bar = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer3/MarginContainer/Contents/ProgressBar

var current_module

func _ready():
	Stats.gained_xp_signal.connect(show_added_exp)
	Signals.update_hud_signal.connect(update_hud_info)

func show_added_exp(amount: int):
	exp_add_label.text = "+" + str(amount)
	await _fade_up_in(exp_add_label)
	await get_tree().create_timer(0.5).timeout
	await _fade_up_out(exp_add_label)

func _fade_up_in(label: Label):
	label.modulate.a = 0.0
	var og_pos = label.position
	label.position.y = 10.0
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(label, "position", og_pos, 0.3)
	await tween.finished
	label.position = og_pos

func _fade_up_out(label: Label):
	label.modulate.a = 1.0
	var og_pos = label.position
	var tar_pos = og_pos - Vector2(-10.0, 0.0)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(label, "position", tar_pos, 0.3)
	await tween.finished
	label.position = og_pos

func update_hud_info(process_info: Dictionary):
	process_name.text = process_info.name
	process_level.text = str(process_info["level"])
	
	var exp = Stats.get_xp_display(process_info)
	progress_bar.value = exp["progress"]
	exp_label.text = exp["display"]
	efficiency_label.text = "EFFICIENCY: " + str(format_number(process_info["efficiency"] * 100)) + "%"
	
	if process_info["requirements"].size() > 0:
		var require = "REQUIREMENTS: "
		for item in process_info["requirements"]:
			if item is ItemData:
				require += item.name + "   "
			else:
				require += item
		requirement_label.text = require
	else:
		requirement_label.text = "REQUIREMENTS: none"
	
	efficiency_desc.text = process_info["efficiency description"]


func format_number(value: float) -> String:
	if value == int(value):
		return str(int(value)) # No decimals
	else:
		return "%.2f" % value # 2 decimals
