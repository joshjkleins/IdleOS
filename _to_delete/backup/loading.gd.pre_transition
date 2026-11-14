extends Control


@onready var progress_bar = $CenterContainer/ProgressBar


func show_loading():
	progress_bar.value = 0.0
	
	await show_progress_bar()
	await fill_progress_bar()
	await hide_progress_bar()
	visible = false

func fill_progress_bar():
	var fill_tween = create_tween()
	fill_tween.tween_property(progress_bar, "value", 100.0, 1.5)
	await fill_tween.finished

func show_progress_bar():
	progress_bar.modulate.a = 0.0
	visible = true
	await get_tree().process_frame  # let layout settle

	var base_pos = progress_bar.position

	
	progress_bar.position = base_pos + Vector2(0, 10)

	var tween := create_tween()

	tween.parallel().tween_property(
		progress_bar,
		"position",
		base_pos,
		0.5
	)

	tween.parallel().tween_property(
		progress_bar,
		"modulate:a",
		1.0,
		0.5
	)

	await tween.finished



func hide_progress_bar():
	var t_pos = progress_bar.position + Vector2(0, 10.0)
	var tween = create_tween()
	tween.parallel().tween_property(
		progress_bar,
		"position",
		t_pos,
		0.5
	)

	tween.parallel().tween_property(
		progress_bar,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished
