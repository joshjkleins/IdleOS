extends Control

@onready var temp = $MarginContainer/VBoxContainer/HBoxContainer3/Temp
@onready var temp_bar = $MarginContainer/VBoxContainer/HBoxContainer2/TempBar
@onready var added_heat_labels = $MarginContainer/VBoxContainer/HBoxContainer3/ScrollContainer/MarginContainer/AddedHeatLabels
@onready var status_label = $MarginContainer/VBoxContainer/MarginContainer/StatusLabel

func _ready():
	Signals.system_temp_updated_signal.connect(update_heat_info)
	Signals.heat_added_signal.connect(heat_added_label)

const ZONE_COLORS = [
	Color("#2d9e75"),  # cool
	Color("#c6a700"),  # warm
	Color("#d85a30"),  # hot
	Color("#e24b4a"),  # critical
]

const HEAT_INFO = {
	0: {
		"name": "COOL",
		"range": "< 60°C",
		"description": "Overclock available.",
		"color": Color("#2d9e75")
	},
	1: {
		"name": "WARM",
		"range": "60-85°C",
		"description": "Requires fans for cooling faster.",
		"color": Color("#c6a700")
	},
	2: {
		"name": "HOT",
		"range": "85-95°C",
		"description": "Cooling required, overclock stopped.",
		"color": Color("#d85a30")
	},
	3: {
		"name": "CRITICAL",
		"range": "> 95°C",
		"description": "Critical tempature, processes slowed.",
		"color": Color("#e24b4a")
	}
}

func update_heat_info(tempature: int) -> void:
	if Stats.overheated:
		status_label.text = "Overheated"
		status_label.visible = true
	elif Stats.overclocked:
		status_label.text = "Overclocked"
		status_label.visible = true
	else:
		status_label.visible = false
	temp.text = str(tempature)
	temp_bar.value = tempature
	if tempature < 60:
		if !Stats.overheated:
			temp_bar.indeterminate = false
		temp.add_theme_color_override("font_color", HEAT_INFO[0]["color"])
		update_progressbar_fill(HEAT_INFO[0]["color"])
	elif tempature >= 60 and tempature < 85:
		temp.add_theme_color_override("font_color", HEAT_INFO[1]["color"])
		update_progressbar_fill(HEAT_INFO[1]["color"])
	elif tempature >= 85 and tempature < 95:
		temp.add_theme_color_override("font_color", HEAT_INFO[2]["color"])
		update_progressbar_fill(HEAT_INFO[2]["color"])
	elif tempature >= 95:
		if Stats.overheated:
			temp_bar.indeterminate = true
		temp.add_theme_color_override("font_color", HEAT_INFO[3]["color"])
		update_progressbar_fill(HEAT_INFO[3]["color"])

func update_progressbar_fill(color: Color) -> void:
	var stylebox := temp_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	stylebox.bg_color = color
	temp_bar.add_theme_stylebox_override("fill", stylebox)

func heat_added_label(temp_n: int):
	var lab = Label.new()
	lab.add_theme_font_size_override("font_size", 10)
	lab.add_theme_color_override("font_color", Color.DARK_RED)
	lab.text = "+" + str(temp_n) + "°C"
	added_heat_labels.add_child(lab)
	await _fade_in(lab)
	await get_tree().create_timer(2.0).timeout
	await _fade_out(lab)

func _fade_in(label: Label):
	label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	await tween.finished

func _fade_out(label: Label):
	label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	await tween.finished
	label.queue_free()
