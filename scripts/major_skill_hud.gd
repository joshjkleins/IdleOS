extends PanelContainer

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
@export var h_color: Color

var current_skill

func _ready():
	update()

func update():
	match skill_type:
		SkillType.MINING:
			update_colors()
			update_text(Mining.SKILL)
			current_skill = Mining
		SkillType.PARSING:
			update_colors()
			update_text(Parsing.SKILL)
			current_skill = Parsing
		SkillType.CRACKING:
			update_colors()
			update_text(Cracking.SKILL)
			current_skill = Cracking
		SkillType.MATCHING:
			update_colors()
			update_text(Matching.SKILL)
			current_skill = Matching
		SkillType.DECODING:
			update_colors()
			update_text(Decoding.SKILL)
			current_skill = Decoding
		SkillType.HACKING:
			update_colors()
			update_text(Hacking.SKILL)
			current_skill = Hacking
		SkillType.PHISHING:
			update_colors()
			update_text(Phishing.SKILL)
			current_skill = Phishing
		SkillType.DEFRAGGING:
			update_colors()
			update_text(Defragging.SKILL)
			current_skill = Defragging
	


func update_text(skill: Dictionary):
	$MarginContainer/VBoxContainer/SkillLabel.text = skill.name
	$MarginContainer/VBoxContainer/HBoxContainer/LevelNumberLabel.text = str(skill.level)
	#progress bar
	var experience = Exp.get_xp_display(skill)
	$MarginContainer/VBoxContainer/ProgressBar.max_value = experience["needed"]
	$MarginContainer/VBoxContainer/ProgressBar.value = experience["current"]

func update_colors():
	#stylebox borders
	var sb = get_theme_stylebox("panel").duplicate()
	sb.border_color = h_color
	add_theme_stylebox_override("panel", sb)
	
	#labels
	$MarginContainer/VBoxContainer/SkillLabel.add_theme_color_override("font_color", h_color)
	$MarginContainer/VBoxContainer/HBoxContainer/LevelNumberLabel.add_theme_color_override("font_color", h_color)
	$MarginContainer/VBoxContainer/HBoxContainer/LevelLabel.add_theme_color_override("font_color", h_color)
	
	#progress bar
	var fill = $MarginContainer/VBoxContainer/ProgressBar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = h_color
	$MarginContainer/VBoxContainer/ProgressBar.add_theme_stylebox_override("fill", fill)

func update_exp():
	if current_skill:
		if current_skill.has_bonus():
			$MarginContainer/VBoxContainer/Defragged.text = Mining.get_bonus_time_text()
			$MarginContainer/VBoxContainer/Defragged.visible = true
		else:
			$MarginContainer/VBoxContainer/Defragged.visible = false
		$MarginContainer/VBoxContainer/HBoxContainer/LevelNumberLabel.text = str(current_skill.SKILL.level)
		#progress bar
		var experience = Exp.get_xp_display(current_skill.SKILL)
		$MarginContainer/VBoxContainer/ProgressBar.max_value = experience["needed"]
		$MarginContainer/VBoxContainer/ProgressBar.value = experience["current"]
