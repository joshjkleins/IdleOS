extends VBoxContainer

@onready var major_skill_container = $MajorSkillContainer
@onready var minor_skill_container = $MinorSkillContainer
@onready var skill_label = $MajorSkillContainer/ContentBox/VBoxContainer/SkillLabel

@onready var defragging_status = $MajorSkillContainer/ContentBox/VBoxContainer/DefraggingStatus
@onready var defragging_status_details = $MinorSkillContainer/MajorDetails/MarginContainer/MainSkillCol/DefraggingStatusDetails
@onready var defrag_cooldown = $DefragCooldown

@onready var defrag_minor = preload("res://scenes/defrag_minor.tscn")

func _ready():
	build_minor_processes()
	minor_skill_container.visible = false
	major_skill_container.visible = true
	Defragging.on_cooldown_signal.connect(cooldown_text)
	cooldown_text()

func build_minor_processes():
	for p in Defragging.minor_processes:
		var dm = defrag_minor.instantiate()
		dm.update_labels(p)
		minor_skill_container.add_child(dm)

func cooldown_text(): #called when defragging has finished and cooldown has started
	if Defragging.on_cooldown():
		var cooldown_text = Defragging.get_cd_time_text()
		defragging_status.text = cooldown_text
		defragging_status_details.text = cooldown_text
		if defrag_cooldown.is_stopped():
			defrag_cooldown.start()
	else:
		defragging_status.text = "available"
		defragging_status_details.text = "available"

func update(): #called when user goes to root or starts game
	skill_label.text = Defragging.SKILL.name
	#cooldown/available logic
	
	await fade_out_minor()
	fade_in_major()

func update_skills():
	for minor_p in minor_skill_container.get_children():
		if minor_p == $MinorSkillContainer/MajorDetails:
			continue
		minor_p.queue_free()
	build_minor_processes()

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

func _on_defrag_cooldown_timeout():
	if Defragging.on_cooldown():
		var cooldown_text = Defragging.get_cd_time_text()
		defragging_status.text = cooldown_text
		defragging_status_details.text = cooldown_text
		if defrag_cooldown.is_stopped():
			defrag_cooldown.start()
	else:
		defragging_status.text = "available"
		defragging_status_details.text = "available"
		defrag_cooldown.stop()
