extends Control

const TEMP_MIN = 30.0
const TEMP_MAX = 100.0

const THRESHOLDS = [
	{ "temp": 60.0, "color": Color("#888888") },
	{ "temp": 85.0, "color": Color("#c6a700") },
	{ "temp": 95.0, "color": Color("#d85a30") },
]
const TICK_WIDTH = 1.0

func temp_to_pct(temp: float) -> float:
	return (temp - TEMP_MIN) / (TEMP_MAX - TEMP_MIN)

func _draw() -> void:
	for tick in THRESHOLDS:
		var x = size.x * temp_to_pct(tick["temp"])
		draw_line(
			Vector2(x, 1.0),
			Vector2(x, size.y),
			tick["color"],
			TICK_WIDTH
		)
