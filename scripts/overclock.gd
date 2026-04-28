extends Control

@onready var temp_name = $MarginContainer/HBoxContainer/VBoxContainer/TempName
@onready var temp_range = $MarginContainer/HBoxContainer/VBoxContainer/TempRange
@onready var temp_desc = $MarginContainer/HBoxContainer/VBoxContainer/TempDesc
@onready var temp = $MarginContainer/HBoxContainer/HBoxContainer/Temp
@onready var cooling = $Cooling

func _ready():
	Signals.system_temp_updated_signal.connect(update_heat_info)
	cooling.wait_time = Stats.cooling_frequency
	cooling.start()

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
	if tempature < 60:
		temp.add_theme_color_override("font_color", HEAT_INFO[0]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[0]["color"])
		temp_name.text = HEAT_INFO[0]["name"]
		temp_range.text = HEAT_INFO[0]["range"]
		temp_desc.text = HEAT_INFO[0]["description"]
	elif tempature >= 60 and tempature < 85:
		temp.add_theme_color_override("font_color", HEAT_INFO[1]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[1]["color"])
		temp_name.text = HEAT_INFO[1]["name"]
		temp_range.text = HEAT_INFO[1]["range"]
		temp_desc.text = HEAT_INFO[1]["description"]
	elif tempature >= 85 and tempature < 95:
		temp.add_theme_color_override("font_color", HEAT_INFO[2]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[2]["color"])
		temp_name.text = HEAT_INFO[2]["name"]
		temp_range.text = HEAT_INFO[2]["range"]
		temp_desc.text = HEAT_INFO[2]["description"]
	elif tempature >= 95:
		temp.add_theme_color_override("font_color", HEAT_INFO[3]["color"])
		temp_name.add_theme_color_override("font_color", HEAT_INFO[3]["color"])
		temp_name.text = HEAT_INFO[3]["name"]
		temp_range.text = HEAT_INFO[3]["range"]
		temp_desc.text = HEAT_INFO[3]["description"]


func _on_cooling_timeout():
	Stats.update_tempature(Stats.cooling_amount)
