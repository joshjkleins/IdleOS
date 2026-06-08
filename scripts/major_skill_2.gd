extends VBoxContainer

@onready var skill_label: Label = $MajorSkillContainer/ContentBox/VBoxContainer/SkillLabel
@onready var progress_bar: ProgressBar = $MajorSkillContainer/ContentBox/VBoxContainer/ProgressBar
@onready var level_label: Label = $MajorSkillContainer/ContentBox/VBoxContainer/HBoxContainer/LevelLabel
@onready var level_number_label: Label = $MajorSkillContainer/ContentBox/VBoxContainer/HBoxContainer/LevelNumberLabel
@onready var defragged: RichTextLabel = $MajorSkillContainer/ContentBox/VBoxContainer/Defragged
@onready var defrag_bonus_timer: Timer = $MajorSkillContainer/DefragBonusTimer
@onready var content_box: MarginContainer = $MajorSkillContainer/ContentBox
@onready var minor_skill_container: HBoxContainer = $MinorSkillContainer
@onready var major_skill_container: PanelContainer = $MajorSkillContainer

@onready var minor_skill = preload("res://scenes/minor_skill.tscn")

enum SkillType {
	MINING,
	PARSING,
	CRACKING,
	MATCHING,
	DECODING,
	HACKING,
	PHISHING,
	DEFRAGGING
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
			
	skill.xp_gained.connect(xp_gained)
	update_colors()
	build_minor_skills()
	
	minor_skill_container.visible = false
	major_skill_container.visible = true

func defrag_start():
	pass

func build_minor_skills():
	for s in skill.minor_processes:
		var new_box = minor_skill.instantiate()
		new_box.update(s)
		minor_skill_container.add_child(new_box)

func update_colors():
	skill_label.add_theme_color_override("font_color", skill.SKILL.color)
	level_label.add_theme_color_override("font_color", skill.SKILL.color)
	level_number_label.add_theme_color_override("font_color", skill.SKILL.color)
	
	var sb = major_skill_container.get_theme_stylebox("panel").duplicate()
	sb.border_color = skill.SKILL.color
	major_skill_container.add_theme_stylebox_override("panel", sb)

func update():
	skill_label.text = skill.SKILL.name
	level_number_label.text = str(skill.SKILL.level)
	
	var experience = Exp.get_xp_display(skill.SKILL)
	progress_bar.max_value = experience["needed"]
	progress_bar.value = experience["current"]
	
	if Stats.has_bonus(skill):
		defragged.text = Stats.get_bonus_time_text(skill)
		defragged.visible = true
		defrag_bonus_timer.start()
	else:
		defragged.visible = false
	fade_out_minor()
	fade_in_major()

func _on_defrag_bonus_timer_timeout() -> void:
	if Stats.has_bonus(skill):
		defragged.text = Stats.get_bonus_time_text(skill)
	else:
		defragged.visible = false
		defrag_bonus_timer.stop()

func xp_gained():
	var experience = Exp.get_xp_display(skill.SKILL)
	progress_bar.max_value = experience["needed"]
	progress_bar.value = experience["current"]
	level_number_label.text = str(skill.SKILL.level)

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
