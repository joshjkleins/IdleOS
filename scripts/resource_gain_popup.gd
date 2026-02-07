extends RichTextLabel

var float_up_distance := 18
var float_down_distance := 10
var duration := 1.2

func show_text(new_text: String):
	text = "[color=#00ff88]" + new_text + "[/color]"
	modulate.a = 0.0
	
	var start_pos = position
	var peak_pos = start_pos - Vector2(0, float_up_distance)
	var end_pos = peak_pos + Vector2(0, float_down_distance)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in + move up
	tween.tween_property(self, "modulate:a", 1.0, duration * 0.3)
	tween.tween_property(self, "position", peak_pos, duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Then fade out + drift down
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.7).set_delay(duration * 0.3)
	tween.tween_property(self, "position", end_pos, duration * 0.7).set_delay(duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(queue_free)
