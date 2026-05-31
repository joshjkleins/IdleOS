extends PanelContainer

func setup():
	$Method.text = "Method"
	$Status.text = "sending..."
	$ProgressBar.value = 0
	$ProgressBar.max_value = 100
	$TimeRemaining.text = "00:00:00"

func start():
	var tween = create_tween
	tween.tween_property($ProgressBar, "value", 100, 0.4)
	await tween.finished

func update():
	pass
