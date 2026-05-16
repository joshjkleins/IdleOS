extends Label

func update(n_text: String, amount: int):
	text = "+" + str(amount) + " " + n_text

func display():
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	await get_tree().create_timer(1.0).timeout
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween2.finished
	
	await get_tree().create_timer(1.0).timeout
	
	queue_free()
