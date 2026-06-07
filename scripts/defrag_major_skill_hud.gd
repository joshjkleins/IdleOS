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
	update_colors()
	update_text(Defragging.SKILL)
	current_skill = Defragging

func update_text(skill: Dictionary):
	$MarginContainer/VBoxContainer/SkillLabel.text = skill.name

func update_colors():
	#stylebox borders
	var sb = get_theme_stylebox("panel").duplicate()
	sb.border_color = h_color
	add_theme_stylebox_override("panel", sb)
	
	#labels
	$MarginContainer/VBoxContainer/SkillLabel.add_theme_color_override("font_color", h_color)

func update_exp(): #this actually updates the cooldown info on defragged HUD item (from root view)
	if Defragging.on_cooldown():
		$MarginContainer/VBoxContainer/Defragged.text = Defragging.get_cd_time_text()
		$MarginContainer/VBoxContainer/Defragged.visible = true
	else:
		$MarginContainer/VBoxContainer/Defragged.visible = false

func _on_defrag_bonus_timer_timeout():
	if current_skill:
		if Stats.has_bonus(current_skill):
			$MarginContainer/VBoxContainer/Defragged.text = Stats.get_bonus_time_text(current_skill)
		else:
			$MarginContainer/VBoxContainer/Defragged.visible = false
			$DefragBonusTimer.stop()
