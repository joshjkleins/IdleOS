extends Control

@onready var temp_name = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TempName
@onready var temp_range = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TempRange
@onready var temp_desc = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TempDesc
@onready var temp = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Temp
@onready var temp_bar = $MarginContainer/VBoxContainer/TempBar

func _ready():
	Signals.system_temp_updated_signal.connect(update_heat_info)

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
	temp.text = str(tempature)
	temp_bar.value = tempature
	if tempature < 60:
		if !Stats.overheated:
			temp_bar.indeterminate = false
		temp.add_theme_color_override("font_color", HEAT_INFO[0]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[0]["color"])
		update_progressbar_fill(HEAT_INFO[0]["color"])
		temp_name.text = HEAT_INFO[0]["name"]
		temp_range.text = HEAT_INFO[0]["range"]
		if !Stats.overheated:
			temp_desc.text = HEAT_INFO[0]["description"]
		else:
			temp_desc.text = "OVERHEATED: SYSTEM SLOWED UNTIL 40°C"
	elif tempature >= 60 and tempature < 85:
		temp.add_theme_color_override("font_color", HEAT_INFO[1]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[1]["color"])
		update_progressbar_fill(HEAT_INFO[1]["color"])
		temp_name.text = HEAT_INFO[1]["name"]
		temp_range.text = HEAT_INFO[1]["range"]
		if !Stats.overheated:
			temp_desc.text = HEAT_INFO[1]["description"]
		else:
			temp_desc.text = "OVERHEATED: SYSTEM SLOWED UNTIL 40°C"
	elif tempature >= 85 and tempature < 95:
		temp.add_theme_color_override("font_color", HEAT_INFO[2]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[2]["color"])
		update_progressbar_fill(HEAT_INFO[2]["color"])
		temp_name.text = HEAT_INFO[2]["name"]
		temp_range.text = HEAT_INFO[2]["range"]
		if !Stats.overheated:
			temp_desc.text = HEAT_INFO[2]["description"]
		else:
			temp_desc.text = "OVERHEATED: SYSTEM SLOWED UNTIL 40°C"
	elif tempature >= 95:
		if Stats.overheated:
			temp_bar.indeterminate = true
		temp.add_theme_color_override("font_color", HEAT_INFO[3]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[3]["color"])
		update_progressbar_fill(HEAT_INFO[3]["color"])
		temp_name.text = HEAT_INFO[3]["name"]
		temp_range.text = HEAT_INFO[3]["range"]
		if !Stats.overheated:
			temp_desc.text = HEAT_INFO[3]["description"]
		else:
			temp_desc.text = "OVERHEATED: SYSTEM SLOWED UNTIL 40°C"


func update_progressbar_fill(color: Color) -> void:
	var stylebox := temp_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	stylebox.bg_color = color
	temp_bar.add_theme_stylebox_override("fill", stylebox)
