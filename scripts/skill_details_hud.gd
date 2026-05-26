extends PanelContainer

@onready var skill_name = $HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer/SkillName
@onready var skill_level = $HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer/SkillLevel
@onready var skill_exp_bar = $HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/SkillExpBar
@onready var minor_container = $HBoxContainer/MinorContainer
@onready var exp_added_label = $HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer2/ExpAddedLabel
@onready var skill_exp_label = $HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer2/SkillExpLabel
@onready var exp_label_timer = $ExpLabelTimer

var m_skill_scene = preload("res://scenes/minor_skill.tscn")
var current_skill

var fade_in_tween: Tween
var fade_out_tween: Tween

func _ready():
	Exp.exp_updated_signal.connect(exp_updated)

func update(skill: Node, color: Color): #pass singleton ie Mining, Parsing, Decoding, Matching, Cracking, Hacking
	current_skill = skill
	_update_border(color)
	#main skill
	skill_name.text = skill.SKILL.name
	skill_name.add_theme_color_override("font_color", color)
	var experience = Exp.get_xp_display(skill.SKILL)
	skill_level.text = "LVL " + str(skill.SKILL.level)
	skill_exp_bar.max_value = experience["needed"]
	skill_exp_bar.value = experience["current"]
	skill_exp_label.text = str(experience["display"])
	
	#cleanup
	if minor_container.get_children().size() > 0:
		for n in minor_container.get_children():
			n.queue_free()
	
	for s in skill.minor_processes:
		var skill_scene = m_skill_scene.instantiate()
		skill_scene.update(s)
		minor_container.add_child(skill_scene)

func exp_updated(amount: int, _minor: Dictionary):
	var experience = Exp.get_xp_display(current_skill.SKILL)
	skill_level.text = "LVL " + str(current_skill.SKILL.level)
	skill_exp_bar.max_value = experience["needed"]
	skill_exp_bar.value = experience["current"]
	skill_exp_label.text = str(experience["display"])
	
	if minor_container.get_children().size() > 0:
		for n in minor_container.get_children():
			n.update_exp(amount)
	
	_cancel_tweens()
	exp_added_label.modulate.a = 0.0
	exp_added_label.visible = true
	exp_added_label.text = "+" + str(amount)
	await _fade_in(exp_added_label)
	exp_label_timer.start()


func _update_border(color:Color):
	var sb = get_theme_stylebox("panel").duplicate()
	sb.border_color = color
	add_theme_stylebox_override("panel", sb)

func _fade_in(label: Label):
	label.modulate.a = 0.0
	
	fade_in_tween = create_tween()
	fade_in_tween.tween_property(label, "modulate:a", 1.0, 0.3)
	await fade_in_tween.finished

func _fade_out(label: Label):
	label.modulate.a = 1.0
	
	fade_out_tween = create_tween()
	fade_out_tween.tween_property(label, "modulate:a", 0.0, 0.3)
	await fade_out_tween.finished

func _cancel_tweens():
	if !exp_label_timer.is_stopped():
		exp_label_timer.stop()
	if fade_in_tween:
		if fade_in_tween.is_running():
			fade_in_tween.stop()
	if fade_out_tween:
		if fade_out_tween.is_running():
			fade_out_tween.stop()

func _on_exp_label_timer_timeout():
	await _fade_out(exp_added_label)
