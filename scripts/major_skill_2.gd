extends VBoxContainer
#root view
@onready var skill_label: Label = $MajorSkillContainer/ContentBox/VBoxContainer/SkillLabel
@onready var progress_bar: ProgressBar = $MajorSkillContainer/ContentBox/VBoxContainer/ProgressBar
@onready var level_label: Label = $MajorSkillContainer/ContentBox/VBoxContainer/HBoxContainer/LevelLabel
@onready var level_number_label: Label = $MajorSkillContainer/ContentBox/VBoxContainer/HBoxContainer/LevelNumberLabel
@onready var defragged: RichTextLabel = $MajorSkillContainer/ContentBox/VBoxContainer/Defragged
@onready var content_box: MarginContainer = $MajorSkillContainer/ContentBox
@onready var minor_skill_container: HBoxContainer = $MinorSkillContainer
@onready var major_skill_container: PanelContainer = $MajorSkillContainer
@onready var major_details = $MinorSkillContainer/MajorDetails
@onready var defrag_bonus_timer = $DefragBonusTimer

#details view
@onready var skill_name = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/VBoxContainer/HBoxContainer/SkillName
@onready var skill_level = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/VBoxContainer/HBoxContainer/SkillLevel
@onready var skill_exp_bar = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/VBoxContainer/SkillExpBar
@onready var skill_exp_label = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/VBoxContainer/HBoxContainer2/SkillExpLabel
@onready var exp_added_label = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/VBoxContainer/HBoxContainer2/ExpAddedLabel
@onready var defragged_details = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/DefraggedDetails

@onready var minor_skill = preload("res://scenes/minor_skill.tscn")

enum SkillType {
	MINING,
	PARSING,
	CRACKING,
	MATCHING,
	DECODING,
	HACKING,
	PHISHING,
	DEFRAGGING,
	COMPILING
}

@export var skill_type: SkillType
var skill: Node

func _ready():
	match skill_type:
		SkillType.MINING:
			skill = Mining
		SkillType.PARSING:
			skill = Parsing
		SkillType.CRACKING:
			skill = Cracking
		SkillType.MATCHING:
			skill = Matching
		SkillType.PHISHING:
			skill = Phishing
		SkillType.HACKING:
			skill = Hacking
		SkillType.DECODING:
			skill = Decoding
		SkillType.COMPILING:
			skill = Compiling
			
	skill.xp_gained.connect(xp_gained)
	update_colors()
	build_minor_skills()
	
	minor_skill_container.visible = false
	major_skill_container.visible = true

func build_minor_skills():
	#Update first container with accurate exp/lvl/name/color
	skill_name.text = skill.SKILL.name
	skill_name.add_theme_color_override("font_color", skill.SKILL.color)
	skill_level.text = "lvl " + str(skill.SKILL.level)
	
	#experience bar
	var experience = Exp.get_xp_display(skill.SKILL)
	skill_exp_bar.max_value = experience["needed"]
	skill_exp_bar.value = experience["current"]
	skill_exp_label.text = experience["display"]
	
	#defrag bonus labels
	if Stats.has_bonus(skill):
		defragged_details.text = Stats.get_bonus_time_text(skill)
		defragged_details.visible = true
		defrag_bonus_timer.start()
	else:
		defragged_details.visible = false
	
	skill.SKILL["level up signal"].connect(major_skill_level_up)
	#build container for each minor process in skill Singleton
	for s in skill.minor_processes:
		var new_box = minor_skill.instantiate()
		new_box.update(s)
		new_box.set_locked_state(skill.SKILL.level < s["unlock level"])
		#add signal here that connect major skill level up to new_box function that sets locked/unlocked
		minor_skill_container.add_child(new_box)

func major_skill_level_up():
	if minor_skill_container.get_children().size() > 0:
		for m in minor_skill_container.get_children():
			if m is HBoxContainer:
				m.set_locked_state(skill.SKILL.level < m.current_skill["unlock level"])
			

func update_colors():
	skill_label.add_theme_color_override("font_color", skill.SKILL.color)
	level_label.add_theme_color_override("font_color", skill.SKILL.color)
	level_number_label.add_theme_color_override("font_color", skill.SKILL.color)
	
	var sb = major_skill_container.get_theme_stylebox("panel").duplicate()
	sb.border_color = skill.SKILL.color
	major_skill_container.add_theme_stylebox_override("panel", sb)

	var sb2 = major_details.get_theme_stylebox("panel").duplicate()
	sb2.border_color = skill.SKILL.color
	major_details.add_theme_stylebox_override("panel", sb2)

func update():
	skill_label.text = skill.SKILL.name
	level_number_label.text = str(skill.SKILL.level)
	
	var experience = Exp.get_xp_display(skill.SKILL)
	progress_bar.max_value = experience["needed"]
	progress_bar.value = experience["current"]
	
	if Stats.has_bonus(skill):
		var time_text = Stats.get_bonus_time_text(skill)
		defragged.text = time_text
		defragged.visible = true
		defragged_details.text = time_text
		defragged_details.visible = true
		defrag_bonus_timer.start()
	else:
		defragged.visible = false
		defragged_details.visible = false
	await fade_out_minor()
	fade_in_major()


func _on_defrag_bonus_timer_timeout() -> void:
	if Stats.has_bonus(skill):
		var time_text = Stats.get_bonus_time_text(skill)
		defragged.text = time_text
		defragged_details.text = time_text
	else:
		defragged.visible = false
		defragged_details.visible = false
		defrag_bonus_timer.stop()

func xp_gained():
	var experience = Exp.get_xp_display(skill.SKILL)
	progress_bar.max_value = experience["needed"]
	progress_bar.value = experience["current"]
	level_number_label.text = str(skill.SKILL.level)

	skill_exp_bar.max_value = experience["needed"]
	skill_exp_bar.value = experience["current"]
	skill_level.text = "lvl " + str(skill.SKILL.level)
	skill_exp_label.text = experience["display"]

func fade_out_major():
	var tween = create_tween()
	tween.tween_property(major_skill_container, "modulate:a", 0.0, 0.3)
	await tween.finished
	major_skill_container.visible = false

func fade_out_minor():
	var tween = create_tween()
	tween.tween_property(minor_skill_container, "modulate:a", 0.0, 0.3)
	await tween.finished
	minor_skill_container.visible = false

func fade_in_minor():
	minor_skill_container.visible = true
	var tween = create_tween()
	tween.tween_property(minor_skill_container, "modulate:a", 1.0, 0.3)
	await tween.finished

func fade_in_major():
	major_skill_container.visible = true
	var tween = create_tween()
	tween.tween_property(major_skill_container, "modulate:a", 1.0, 0.3)
	await tween.finished

func show_overview():
	major_skill_container.visible = true
	minor_skill_container.visible = false

func show_details():
	major_skill_container.visible = false
	minor_skill_container.visible = true
