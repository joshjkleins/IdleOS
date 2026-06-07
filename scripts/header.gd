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


func update_header(skill: Node = null): #pass singleton
	#Root (show all major skills)
	if skill == null:
		for s in major_skills.get_children():
			s.update_exp()
		skill_details.visible = false
		major_skills.visible = true
		return
	
	var h_col
	#Specific skills
	match skill:
		Mining:
			h_col = h_color_mining
			skill_details.update(skill, h_col)
		Parsing:
			h_col = h_color_parsing
			skill_details.update(skill, h_col)
		Cracking:
			h_col = h_color_cracking
			skill_details.update(skill, h_col)
		Matching:
			h_col = h_color_matching
			skill_details.update(skill, h_col)
		Hacking:
			h_col = h_color_hacking
			skill_details.update(skill, h_col)
		Decoding:
			h_col = h_color_decoding
			skill_details.update(skill, h_col)
		Phishing:
			h_col = h_color_phishing
			skill_details.update(skill, h_col)
		Defragging:
			h_col = h_color_defragging
			skill_details.update_defrag_hud(skill, h_col)
	major_skills.visible = false
	skill_details.visible = true
