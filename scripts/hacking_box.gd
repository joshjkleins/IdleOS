extends Control


@export var title_text: String = "Hacking"
@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel

func _ready():
	rtl.text = "[bgcolor=#000000]" + title_text + "[/bgcolor]"
