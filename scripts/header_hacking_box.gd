extends Control


@export var title_text: String = "Hacking"
@onready var rtl = $RichTextLabel

@onready var ip_address_amount = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/HBoxContainer/ResourceCol/IPAddressAmount
@onready var cred_amount = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/HBoxContainer/ResourceCol2/CredAmount
@onready var efficiency = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/VBoxContainer/Efficiency

@onready var skill_level = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer/SkillLevel
@onready var skill_exp_bar = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/SkillExpBar
@onready var skill_exp_label = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer2/SkillExpLabel
@onready var exp_added_label = $PanelContainer/MarginContainer/HBoxContainer/MainSkill/HBoxContainer/MainSkillCol/VBoxContainer/HBoxContainer2/ExpAddedLabel
@onready var exp_label_timer = $ExpLabelTimer

var fade_in_tween: Tween
var fade_out_tween: Tween

func _ready():
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
	Exp.gained_xp_signal.connect(update_header_exp)
	Signals.update_hacking_header_signal.connect(update_header_resources)

func update_hacking_header():
	update_header_exp()
	update_header_resources()

func update_header_resources():
	ip_address_amount.text = str(Inventory.get_amount(Items.IP_ADDRESS))
	cred_amount.text = str(Inventory.get_amount(Items.CREDENTIALS))

func update_header_exp(amount: int = 0):
	var experience = Exp.get_xp_display(Hacking.SKILL)
	skill_level.text = "LVL " + str(Hacking.SKILL.level)
	efficiency.text = "%.2f%%" % (Hacking.SKILL.efficiency * 100.0)
	skill_exp_bar.max_value = experience["needed"]
	skill_exp_bar.value = experience["current"]
	skill_exp_label.text = experience["display"]
	
	if amount > 0:
		_cancel_tweens()
		exp_added_label.modulate.a = 0.0
		exp_added_label.visible = true
		exp_added_label.text = "+" + str(amount)
		await _fade_in(exp_added_label)
		exp_label_timer.start()

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
