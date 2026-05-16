extends VBoxContainer

#@onready var exp_add_label = $Control/ExpAddLabel
@onready var process_name = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/PanelContainer/MarginContainer/Contents/ProcessName
@onready var process_level = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/PanelContainer/MarginContainer/Contents/ProcessLevel
@onready var exp_label = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/PanelContainer3/MarginContainer/Contents/ExpLabel
@onready var efficiency_label = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/VBoxContainer/HBoxContainer/EfficiencyLabel
@onready var requirement_label = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/VBoxContainer/HBoxContainer/RequirementLabel
@onready var efficiency_desc = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/VBoxContainer/EfficiencyDesc
@onready var progress_bar = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/PanelContainer3/MarginContainer/Contents/ProgressBar
@onready var root_process_container: HBoxContainer = $PanelContainer/MarginContainer/RootProcessContainer
@onready var specific_process: VBoxContainer = $PanelContainer/MarginContainer/SpecificProcess
@onready var exp_add_label: Label = $PanelContainer/MarginContainer/SpecificProcess/HBoxContainer/PanelContainer3/MarginContainer/Control/ExpAddLabel

var process_box = preload("res://scenes/hud_process_box.tscn")

var current_module
var og_pos

func _ready():
	Stats.gained_xp_signal.connect(show_added_exp)
	Signals.update_hud_signal.connect(update_hud_info)
	Signals.update_hud_root_signal.connect(update_hud_info_root)
	og_pos = exp_add_label.position

func show_added_exp(amount: int):
	exp_add_label.text = "+" + str(amount)
	await _fade_up_in(exp_add_label)
	await get_tree().create_timer(1.0).timeout
	await _fade_up_out(exp_add_label)

func _fade_up_in(label: Label):
	label.modulate.a = 0.0
	label.position.y = 10.0
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(label, "position", og_pos, 0.3)
	await tween.finished
	label.position = og_pos

func _fade_up_out(label: Label):
	label.modulate.a = 1.0
	og_pos = label.position
	var tar_pos = og_pos - Vector2(-10.0, 0.0)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(label, "position", tar_pos, 0.3)
	await tween.finished
	label.position = og_pos

func update_hud_info_root():
	specific_process.visible = false
	root_process_container.visible = true
	if root_process_container.get_children().size() > 0:
		for n in root_process_container.get_children():
			n.queue_free()
	for s in Stats.player_stats.keys():
		var skill = Stats.player_stats[s]
		if skill.unlocked:
			var n = process_box.instantiate()
			n.update(skill)
			root_process_container.add_child(n)

func update_hud_info(process_info: Dictionary):
	specific_process.visible = true
	root_process_container.visible = false
	process_name.text = process_info.name
	process_level.text = str(process_info["level"])
	
	var experience = Stats.get_xp_display(process_info)
	progress_bar.value = experience["progress"]
	exp_label.text = experience["display"]
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
