extends PanelContainer

@onready var skill_details = $SkillDetails
@onready var major_skills = $MajorSkills

@export var h_color_mining: Color = Color("#1D9E75")
@export var h_color_parsing: Color = Color("#7F77DD")
@export var h_color_cracking: Color = Color("#EF9F27")
@export var h_color_matching: Color = Color("#D4537E")
@export var h_color_decoding: Color = Color("#378ADD")
@export var h_color_hacking: Color = Color("#00CC55")
@export var h_color_phishing: Color = Color("#00CC55")
@export var h_color_defragging: Color = Color("#cf0000")
@export var h_color_grey: Color = Color("#00CC55")

@onready var mining: VBoxContainer = $MajorSkills/Mining
@onready var parsing: VBoxContainer = $MajorSkills/Parsing
@onready var cracking: VBoxContainer = $MajorSkills/Cracking
@onready var matching: VBoxContainer = $MajorSkills/Matching
@onready var phishing: VBoxContainer = $MajorSkills/Phishing
@onready var hacking: VBoxContainer = $MajorSkills/Hacking
@onready var decoding: VBoxContainer = $MajorSkills/Decoding

func update():
	mining.update()
	parsing.update()
	cracking.update()
	matching.update()
	phishing.update()
	hacking.update()
	decoding.update()

func display_skill(skill: Node):
	var tar
	for s in major_skills.get_children():
		s.fade_out_major()
		if skill == s.skill:
			tar = s
	await get_tree().create_timer(0.3).timeout
	tar.show_details()
	tar.fade_in_minor()

#func update_header(skill: Node = null): #pass singleton
	##Root (show all major skills)
	#if skill == null:
		#for s in major_skills.get_children():
			#s.update_exp()
		#skill_details.visible = false
		#major_skills.visible = true
		#return
	#
	#var h_col
	##Specific skills
	#match skill:
		#Mining:
			#h_col = h_color_mining
			#skill_details.update(skill, h_col)
		#Parsing:
			#h_col = h_color_parsing
			#skill_details.update(skill, h_col)
		#Cracking:
			#h_col = h_color_cracking
			#skill_details.update(skill, h_col)
		#Matching:
			#h_col = h_color_matching
			#skill_details.update(skill, h_col)
		#Hacking:
			#h_col = h_color_hacking
			#skill_details.update(skill, h_col)
		#Decoding:
			#h_col = h_color_decoding
			#skill_details.update(skill, h_col)
		#Phishing:
			#h_col = h_color_phishing
			#skill_details.update(skill, h_col)
		#Defragging:
			#h_col = h_color_defragging
			#skill_details.update_defrag_hud(skill, h_col)
	#major_skills.visible = false
	#skill_details.visible = true
