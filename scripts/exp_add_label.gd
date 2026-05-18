extends Label

@export var rise_distance: float = 10.0
@export var fade_in_time: float = 0.2
@export var hold_time: float = 1.0
@export var fade_out_time: float = 0.25

func _ready() -> void:
	# Start slightly lower and invisible
	var start_pos := position
	position.y += rise_distance
	modulate.a = 0.0

	var tween = create_tween()

	# Fade in + move up
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start_pos.y, fade_in_time)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_time)

	# Hold
	tween.set_parallel(false)
	tween.tween_interval(hold_time)

	# Fade out + move up again
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start_pos.y - rise_distance, fade_out_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_time)

	tween.finished.connect(queue_free)
