extends HBoxContainer

enum CrackStatus { QUEUED, CRACKING, CRACKED }

@export var icon_queued: Texture2D
@export var icon_cracking: Texture2D
@export var icon_cracked: Texture2D

var current_status = CrackStatus.QUEUED

var green = Color("#30a14e")
var yellow = Color("#D4A017")
var grey = Color("#6b6b78")

var uuid: String = ""

func new_row():
	current_status = CrackStatus.QUEUED
	set_status_icon(current_status)
	uuid = _generate_uuid()
	$HBoxContainer/EncryptedPw.text = uuid
	$CrackedStatus.text = "QUEUED"

func start_crack():
	current_status = CrackStatus.CRACKING
	set_status_icon(current_status)
	$CrackedStatus.text = "CRACKING..."
	$CrackedStatus.add_theme_color_override("font_color", yellow)
	$HBoxContainer/EncryptedPw.add_theme_color_override("font_color", green)

func end_crack(word: String):
	current_status = CrackStatus.CRACKED
	set_status_icon(current_status)
	$CrackedStatus.text = "CRACKED"
	$HBoxContainer/EncryptedPw.text = uuid + "    " + word
	$CrackedStatus.add_theme_color_override("font_color", green)
	$HBoxContainer/EncryptedPw.add_theme_color_override("font_color", grey)

func set_status_icon(status: CrackStatus) -> void:
	var icon_node := $HBoxContainer/StatusIcon
	match status:
		CrackStatus.QUEUED:
			icon_node.texture = icon_queued
		CrackStatus.CRACKING:
			icon_node.texture = icon_cracking
		CrackStatus.CRACKED:
			icon_node.texture = icon_cracked

func _generate_uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var sections := [4, 4, 4]  # byte lengths per section
	var parts: Array[String] = []
	
	for length in sections:
		var section := ""
		for i in length:
			section += "%02x" % rng.randi_range(0, 255)
		parts.append(section)
	
	return ":".join(parts)
