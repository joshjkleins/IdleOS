extends Control


@export var title_text: String = "Hacking"
@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel

func _ready():
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
