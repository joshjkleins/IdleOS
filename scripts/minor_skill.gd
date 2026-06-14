extends HBoxContainer

var current_skill
@onready var fade_in_tween: Tween
@onready var fade_out_tween: Tween

func update(skill: Dictionary): #minor
	current_skill = skill
	$Unlocked/VBoxContainer/HBoxContainer/SkillName.text = skill.name
	$Unlocked/VBoxContainer/HBoxContainer/SkillLevel.text = str(skill.level) + "/99"
	
	$Locked/VBoxContainer/SkillName.text = skill.name
	$Locked/VBoxContainer/UnlockLevel.text = "(lvl " + str(skill["unlock level"]) + ")"
	
	var experience = Exp.get_xp_display(skill)
	$Unlocked/VBoxContainer/SkillExpBar.max_value = experience["needed"]
	$Unlocked/VBoxContainer/SkillExpBar.value = experience["current"]
	$Unlocked/VBoxContainer/HBoxContainer2/SkillExpLabel.text = experience["display"]
	
	$ExpLabelTimer.timeout.connect(exp_timeout)
	
	Exp.exp_updated_signal.connect(exp_updated)

func set_locked_state(locked: bool):
	if locked:
		$Locked.visible = true
		$Unlocked.visible = false
	else:
		$Locked.visible = false
		$Unlocked.visible = true
		current_skill.unlocked = true

#updates progress bar and 10/100 label and level label
func update_exp(_amount: int):
	if current_skill:
		$Unlocked/VBoxContainer/HBoxContainer/SkillLevel.text = str(current_skill.level) + "/99"
		
		var experience = Exp.get_xp_display(current_skill)
		$Unlocked/VBoxContainer/SkillExpBar.max_value = experience["needed"]
		$Unlocked/VBoxContainer/SkillExpBar.value = experience["current"]
		$Unlocked/VBoxContainer/HBoxContainer2/SkillExpLabel.text = experience["display"]

#shows +100 exp label
func exp_updated(amount, minor):
	update_exp(amount)
	if current_skill == minor:
		_cancel_tweens()
		$Unlocked/VBoxContainer/HBoxContainer2/ExpAddedLabel.modulate.a = 0.0
		$Unlocked/VBoxContainer/HBoxContainer2/ExpAddedLabel.visible = true
		$Unlocked/VBoxContainer/HBoxContainer2/ExpAddedLabel.text = "+" + str(amount)
		await _fade_in($Unlocked/VBoxContainer/HBoxContainer2/ExpAddedLabel)
		$ExpLabelTimer.start()

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
	if !$ExpLabelTimer.is_stopped():
		$ExpLabelTimer.stop()
	if fade_in_tween:
		if fade_in_tween.is_running():
			fade_in_tween.stop()
	if fade_out_tween:
		if fade_out_tween.is_running():
			fade_out_tween.stop()

func exp_timeout():
	await _fade_out($Unlocked/VBoxContainer/HBoxContainer2/ExpAddedLabel)
	
