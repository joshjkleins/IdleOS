extends VBoxContainer

#@onready var exp_add_label = $Control/ExpAddLabel
@onready var process_name = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/PanelContainer/MarginContainer/Contents/ProcessName
@onready var process_level = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/PanelContainer/MarginContainer/Contents/ProcessLevel
@onready var exp_label = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/PanelContainer3/MarginContainer/Contents/ExpLabel
#@onready var efficiency_label = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/VBoxContainer/HBoxContainer/EfficiencyLabel
#@onready var requirement_label = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/VBoxContainer/HBoxContainer/RequirementLabel
#@onready var efficiency_desc = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/VBoxContainer/EfficiencyDesc
@onready var progress_bar = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/PanelContainer3/MarginContainer/Contents/ProgressBar
@onready var root_process_container: HBoxContainer = $PanelContainer/MarginContainer/RootProcessContainer
@onready var specific_process: VBoxContainer = $PanelContainer/MarginContainer/SpecificProcess
@onready var minor_skills = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/MinorSkills
@onready var exp_add_label_container = $PanelContainer/MarginContainer/SpecificProcess/MajorSkill/PanelContainer/ExpAddLabelContainer

var process_box = preload("res://scenes/hud_process_box.tscn")
var exp_add_label = preload("res://scenes/exp_add_label.tscn")

var current_module
var og_pos = Vector2(0, 0)

func _ready():
	Exp.gained_xp_signal.connect(show_added_exp)
	Signals.update_hud_signal.connect(update_hud_info)
	Signals.update_hud_root_signal.connect(update_hud_info_root)
	#og_pos = exp_add_label.position

func show_added_exp(amount: int):
	var new_label = exp_add_label.instantiate()
	new_label.text = "+" + str(amount)
	exp_add_label_container.add_child(new_label)


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
	#og_pos = label.position
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
	for s in Stats.SKILLS.keys():
		var skill = Stats.SKILLS[s]
		var n = process_box.instantiate()
		n.update(skill)
		root_process_container.add_child(n)

func update_hud_info(skill): #SINGLETON as param
	specific_process.visible = true
	root_process_container.visible = false
	process_name.text = skill.SKILL["name"]
	process_level.text = str(skill.SKILL["level"])
	
	var dumb = {"level": skill.SKILL["level"], "experience": skill.SKILL["experience"] }
	var experience = Exp.get_xp_display(dumb)
	
	progress_bar.value = experience["progress"]
	exp_label.text = experience["display"]
	
	clear_children_nodes(minor_skills)
	
	if skill.minor_processes.size() > 0:
		for s in skill.minor_processes:
			if s.unlocked:
				var n = process_box.instantiate()
				n.update(s, false)
				minor_skills.add_child(n)

func clear_children_nodes(container: Node):
	if container.get_children().size() > 0:
		for n in container.get_children():
			n.queue_free()

func format_number(value: float) -> String:
	if value == int(value):
		return str(int(value)) # No decimals
	else:
		return "%.2f" % value # 2 decimals
