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
var highest_color: Color
var tween: Tween
var u_name: String
var current_active_label

func update_label_chances(index: int, chance: int, color: Color):
	if chance > highest_chance:
		highest_chance = chance
		highest_color = color
		
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	$MarginContainer/HBoxContainer/MarginContainer/ProgressBar.add_theme_stylebox_override("fill", sb)
	
	match index:
		0: #levenshtein
			current_active_label = $MarginContainer/HBoxContainer/LSHLabel
			$MarginContainer/HBoxContainer/LSHLabel.text = str(chance) + "%"
			$MarginContainer/HBoxContainer/LSHLabel.add_theme_color_override("font_color", color)
		1: #levenshtein
			current_active_label = $MarginContainer/HBoxContainer/HMLabel
			$MarginContainer/HBoxContainer/HMLabel.text = str(chance) + "%"
			$MarginContainer/HBoxContainer/HMLabel.add_theme_color_override("font_color", color)
		2: #levenshtein
			current_active_label = $MarginContainer/HBoxContainer/EntLabel
			$MarginContainer/HBoxContainer/EntLabel.text = str(chance) + "%"
			$MarginContainer/HBoxContainer/EntLabel.add_theme_color_override("font_color", color)
		3: #levenshtein
			current_active_label = $MarginContainer/HBoxContainer/TSLabel
			$MarginContainer/HBoxContainer/TSLabel.text = str(chance) + "%"
			$MarginContainer/HBoxContainer/TSLabel.add_theme_color_override("font_color", color)

func set_highest_color():
	var sb = StyleBoxFlat.new()
	sb.bg_color = highest_color
	$MarginContainer/HBoxContainer/MarginContainer/ProgressBar.add_theme_stylebox_override("fill", sb)
	$MarginContainer/HBoxContainer/MarginContainer/ProgressBar.value = highest_chance

func update(candidate_username: String):
	u_name = candidate_username
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
	tween = create_tween()
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
	if current_active_label:
		current_active_label.text = str(int(value)) + "%"

func _hide():
	self.modulate.a = 0.0

func _fade_out():
	var n_tween = create_tween()
	n_tween.tween_property(self, "modulate:a", 0.0, 0.5)

func fade_in():
	var n_tween = create_tween()
	n_tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await n_tween.finished


func cancel():
	if tween:
		tween.kill()
