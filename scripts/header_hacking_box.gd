extends Control


@export var title_text: String = "Hacking"

@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel

@onready var h_level: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HLevel
@onready var h_exp: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HExp
@onready var h_eff: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HEff

@onready var ip_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/IPLabel
@onready var credentials_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/CredentialsLabel

func _ready():
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
	update_header()


func update_header():
	ip_label.text = "IP addresses: x" + str(Inventory.get_amount("ip address"))
	credentials_label.text = "Credentials: x" + str(Inventory.get_amount("credentials"))
	
	var hacking_stats = Stats.player_stats["Hacking"]
	
	var xp_current = hacking_stats["experience"]
	var xp_needed = Stats.xp_for_level(hacking_stats.level + 1)
	
	h_level.text = "Level " + str(hacking_stats.level)
	h_exp.text = "Exp: " + str(xp_current) + "/" + str(xp_needed)
	
