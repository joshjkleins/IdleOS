extends PanelContainer

@onready var major_skills = $HBoxContainer/MajorSkills

@export var h_color_mining: Color = Color("#1D9E75")
@export var h_color_parsing: Color = Color("#7F77DD")
@export var h_color_cracking: Color = Color("#EF9F27")
@export var h_color_matching: Color = Color("#D4537E")
@export var h_color_decoding: Color = Color("#378ADD")
@export var h_color_hacking: Color = Color("#00CC55")
@export var h_color_phishing: Color = Color("#00CC55")
@export var h_color_defragging: Color = Color("#cf0000")
@export var h_color_grey: Color = Color("#00CC55")

@onready var mining: VBoxContainer = $HBoxContainer/MajorSkills/Mining
@onready var parsing: VBoxContainer = $HBoxContainer/MajorSkills/Parsing
@onready var cracking: VBoxContainer = $HBoxContainer/MajorSkills/Cracking
@onready var matching: VBoxContainer = $HBoxContainer/MajorSkills/Matching
@onready var phishing: VBoxContainer = $HBoxContainer/MajorSkills/Phishing
@onready var hacking: VBoxContainer = $HBoxContainer/MajorSkills/Hacking
@onready var decoding: VBoxContainer = $HBoxContainer/MajorSkills/Decoding
@onready var defragging = $HBoxContainer/Defragging

func _ready():
	major_skills.visible = true
	defragging.visible = true

func update(): #called when player enters root directory (start of game and exiting processes)
	mining.update()
	parsing.update()
	cracking.update()
	matching.update()
	phishing.update()
	hacking.update()
	decoding.update()
	defragging.update()

func display_skill(skill: Node): #called when player enters specific process
	var tar
	for s in major_skills.get_children():
		s.fade_out_major()
		if skill == s.skill:
			tar = s
	defragging.fade_out_major()
	await get_tree().create_timer(0.3).timeout
	tar.show_details()
	tar.fade_in_minor()

func display_defragging(): #special for defragging since it isn't like other skills
	defragging.update_skills() #check to see if player unlocked any defrag processes
	for s in major_skills.get_children():
		s.fade_out_major()
	defragging.fade_out_major()
	await get_tree().create_timer(0.3).timeout
	defragging.fade_in_minor()


func _on_defrag_cooldown_timeout():
	pass # Replace with function body.
