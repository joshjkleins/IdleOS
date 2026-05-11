extends PanelContainer

enum MATCH_STATE {
	FAIL,
	PARTIAL,
	LOCKED,
	WAITING,
	ATTEMPTING,
	SUCCESS
}

var current_state = MATCH_STATE.WAITING
var highest_chance: int = 0

func update_label_chances(index: int, chance: int):
	if chance > highest_chance:
		highest_chance = chance
	match index:
		0: #levenshtein
			$MarginContainer/HBoxContainer/LSHLabel.text = str(chance) + "%"
		1: #levenshtein
			$MarginContainer/HBoxContainer/HMLabel.text = str(chance) + "%"
		2: #levenshtein
			$MarginContainer/HBoxContainer/EntLabel.text = str(chance) + "%"
		3: #levenshtein
			$MarginContainer/HBoxContainer/TSLabel.text = str(chance) + "%"

func update(candidate_username: String):
	$MarginContainer/HBoxContainer/MarginContainer/ProgressBar.value = 0
	$MarginContainer/HBoxContainer/CandidateLabel.text = candidate_username
	$MarginContainer/HBoxContainer/LSHLabel.text = "0%"
	$MarginContainer/HBoxContainer/HMLabel.text = "0%"
	$MarginContainer/HBoxContainer/EntLabel.text = "0%"
	$MarginContainer/HBoxContainer/TSLabel.text = "0%"
	update_state(current_state)

func update_state(state: MATCH_STATE):
	match state:
		MATCH_STATE.FAIL:
			current_state = state
			remove_highlight()
			#$MarginContainer/HBoxContainer/StateLabel.text = "fail"
			#$MarginContainer/HBoxContainer/StateLabel.add_theme_color_override("font_color", Color.RED)
		MATCH_STATE.PARTIAL:
			current_state = state
			remove_highlight()
			#$MarginContainer/HBoxContainer/StateLabel.text = "partial"
			#$MarginContainer/HBoxContainer/StateLabel.add_theme_color_override("font_color", Color.YELLOW)
		MATCH_STATE.LOCKED:
			current_state = state
			remove_highlight()
			#$MarginContainer/HBoxContainer/StateLabel.text = "locked"
			#$MarginContainer/HBoxContainer/StateLabel.add_theme_color_override("font_color", Color.CADET_BLUE)
		MATCH_STATE.WAITING:
			current_state = state
			#$MarginContainer/HBoxContainer/StateLabel.text = "waiting"
			#$MarginContainer/HBoxContainer/StateLabel.add_theme_color_override("font_color", Color.DIM_GRAY)
		MATCH_STATE.ATTEMPTING:
			current_state = state
			highlight()
			#$MarginContainer/HBoxContainer/StateLabel.text = "attempting"
			#$MarginContainer/HBoxContainer/StateLabel.add_theme_color_override("font_color", Color.GREEN)
		MATCH_STATE.SUCCESS:
			current_state = state
			remove_highlight()
			#$MarginContainer/HBoxContainer/StateLabel.text = "success"
			#$MarginContainer/HBoxContainer/StateLabel.add_theme_color_override("font_color", Color.GREEN)

func start_progress(fill, time):
	var tween = create_tween()
	tween.tween_property($MarginContainer/HBoxContainer/MarginContainer/ProgressBar, "value", fill, time).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func remove_highlight():
	remove_theme_stylebox_override("panel")

func highlight():
	var style_box = StyleBoxFlat.new()
	var color = Color("#2e2e2e")
	style_box.bg_color = color
	add_theme_stylebox_override("panel", style_box)

func _on_progress_bar_value_changed(value):
	var sb = StyleBoxFlat.new()
	
	# Map value (0-100) to Hue (0 is Red, 0.33 is Green)
	var ratio = value / 100.0
	sb.bg_color = Color.from_hsv(ratio * 0.33, 0.8, 0.9)
	
	$MarginContainer/HBoxContainer/MarginContainer/ProgressBar.add_theme_stylebox_override("fill", sb)

func _hide():
	self.modulate.a = 0.0

func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

func fade_in():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished
