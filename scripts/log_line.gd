extends PanelContainer

# {"level":"INFO","service":"auth.service","message":"Login attempt from 172.16.4.23","tags":[]}
func update(log_line: Dictionary, item: ItemData = null, amount: int = 0) -> void:
	var lvl = log_line["level"]

	var category_label = $MarginContainer/Panel/HBoxContainer/CategoryLabel
	var code_label = $MarginContainer/Panel/HBoxContainer/CodeLabel
	var message_label = $MarginContainer/Panel/HBoxContainer/MessageLabel

	$MarginContainer/Panel/HBoxContainer/TimeLabel.text = Time.get_time_string_from_system()

	category_label.text = log_line["level"]
	code_label.text = log_line["service"]
	message_label.text = log_line["message"]

	apply_log_color(category_label, lvl)
	apply_log_color(code_label, lvl)
	apply_log_color(message_label, lvl)

	if item and amount > 0:
		$MarginContainer/Panel/HBoxContainer/RewardLabel.text = "+" + str(amount) + " " + item.name
	
	flash_green()


func apply_log_color(label: Label, level: String) -> void:
	match level:
		"INFO":
			label.add_theme_color_override("font_color", Color.GRAY)
		"WARN":
			label.add_theme_color_override("font_color", Color.YELLOW)
		"ALERT":
			label.add_theme_color_override("font_color", Color.RED)
		"ERR":
			label.add_theme_color_override("font_color", Color.PURPLE)
		_:
			label.remove_theme_color_override("font_color")


func flash_green(duration := 0.15) -> void:
	var panel = $MarginContainer/Panel
	
	# Duplicate current stylebox so we don't modify the shared resource
	var stylebox := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel.add_theme_stylebox_override("panel", stylebox)

	# Store original color
	var original_color = stylebox.bg_color

	# Flash green
	stylebox.bg_color = Color(0, 1, 0, 0.01)

	# Tween back to original
	var tween = create_tween()
	tween.tween_property(stylebox, "bg_color", original_color, duration)
