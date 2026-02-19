extends VBoxContainer


@onready var progress_bar = $BattleInfo/VBoxContainer/ProgressBar
@onready var success_label = $BattleInfo/VBoxContainer/SuccessLabel

@onready var stage_labels = $StageLabels
@onready var stage_number = $StageLabels/StageNumber
@onready var stage_name = $StageLabels/StageName
@onready var battle_info = $BattleInfo

func setup_hack():
	#reset to stage 1
	stage_number.text = "Stage 1"
	stage_name.text = Ascii.recon

func begin_hack():
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, 8.0)
	await tween.finished
	
	if randf() < 0.5: #fail
		progress_bar_fail()
		await get_tree().create_timer(1.0).timeout
		reset_progress_bar()
		begin_hack()
	else: #success
		progress_bar_success()
		await get_tree().create_timer(1.0).timeout
		begin_second_phase()

func begin_second_phase():
	fade_node_down_out(battle_info)
	await fade_node_down_out(stage_labels)
	stage_number.text = "Stage 2"
	stage_name.text = Ascii.breach
	await fade_node_up_in(stage_labels)
	

func progress_bar_fail():
	success_label.text = "Failed"
	update_progress_bar_color(Color.RED)

func progress_bar_success():
	success_label.text = "Success"
	update_progress_bar_color(Color.LIME_GREEN)

func update_progress_bar_color(color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	progress_bar.add_theme_stylebox_override("fill", style)

func remove_progress_bar_color():
	progress_bar.remove_theme_stylebox_override("fill")

func reset_progress_bar():
	progress_bar.value = 0.0
	remove_progress_bar_color()
	success_label.text = "Success Chance: 50%"

func fade_node_down_out(n):
	var og_pos = n.position
	var t_pos = n.position + Vector2(0, 10.0)
	var tween = create_tween()
	tween.parallel().tween_property(
		n,
		"position",
		t_pos,
		0.5
	)

	tween.parallel().tween_property(
		n,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished
	n.position = og_pos

func fade_node_up_in(n):
	var base_pos = n.position
	n.position = base_pos + Vector2(0, 10)
	var tween := create_tween()

	tween.parallel().tween_property(
		n,
		"position",
		base_pos,
		0.5
	)

	tween.parallel().tween_property(
		n,
		"modulate:a",
		1.0,
		0.5
	)

	await tween.finished
