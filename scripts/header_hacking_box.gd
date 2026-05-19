extends Control


@export var title_text: String = "Hacking"

@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel

@onready var hud = $PanelContainer/MarginContainer/HBoxContainer/HUD

func _ready():
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
	Signals.update_hacking_header_signal.connect(update_header)

func update_header():
	#var hacking_stats = Stats.player_stats["Hacking"]
	hud.update_hud_info(Hacking)
