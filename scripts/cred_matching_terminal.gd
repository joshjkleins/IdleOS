extends PanelContainer

@onready var user_row_container = $MarginContainer/VBoxContainer/BottomRow/VBoxContainer/UserRowContainer
@onready var main_bar = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/MainBar
@onready var status_progress_bar = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusProgressBar

@onready var status_image = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusImage
@onready var status_title = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusTitle
@onready var status_username = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusUsername
@onready var status_pw = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusPw
@onready var status_updater = $MarginContainer/VBoxContainer/BottomRow/StatusUpdater

@export var lock_image: Texture2D
@export var cred_image: Texture2D

var target_row = preload("res://scenes/cred_match_target_row.tscn")
var separator = preload("res://scenes/separator_cred.tscn")

var USER_ROWS: int = 5

var process_running: bool = false
var current_progress: int = 0
var current_iteration: int = 0
var fill = [10, 25, 35, 65, 100]


var green = Color("#3b8f68")
var grey = Color("#6b6b78")

var u_name = "j_kleinstine_1"

var highest_roll: int = 0

##NEXT TIME
# add stop features
# add overclock
# add actual stats stuff
# make it looks a bit nicer with colors and better visual clarity
# add 'focus'
# make remove/add resources
# add heat
# add more randomly generated usernames and variations of said usernames
# refactor code??

#func _ready():
	#start()

func start():
	process_running = true
	_reset_rows()
	_build_rows()
	_begin_matching()

func _begin_matching():
	#get current_row
	var current_row = _get_current_row()

	if current_row != null:
		#highlight tag
		status_updater.text = "FINDING CLOSES MATCHING ALGORITHM"
		var current_tag = 0
		current_row.fade_in()
		current_row.update_state(current_row.MATCH_STATE.ATTEMPTING)
		var tags = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/TagContainer.get_children()
		var rolls = []
		for i in range(4):
			rolls.append(randi_range(1, 80))
		#rolls.sort()
		for n in tags:
			tags[0].remove_theme_stylebox_override("panel")
			tags[1].remove_theme_stylebox_override("panel")
			tags[2].remove_theme_stylebox_override("panel")
			tags[3].remove_theme_stylebox_override("panel")
			
			var sb = n.get_theme_stylebox("panel").duplicate()
			sb.bg_color = Color("#2e2e2e")
			tags[current_tag].add_theme_stylebox_override("panel", sb)
			
			var roll = rolls[current_tag]
			await current_row.start_progress(roll, 0.65)
			if roll > highest_roll:
				highest_roll = roll
				status_progress_bar.text = "success chance: " + str(highest_roll) + "%"
			current_row.update_label_chances(current_tag, roll)
			current_tag += 1
		#await current_row.start_progress(highest_roll, 0.65)
		current_row.update_state(current_row.MATCH_STATE.LOCKED)
		_begin_matching()
	else: #finished looping through 5 rows
		#loop through rows to find highest chance and highlight
		var highest_chance = 0
		var t_row = null
		for n in user_row_container.get_children():
			if n is PanelContainer:
				if n.highest_chance > highest_chance:
					highest_chance = n.highest_chance
					t_row = n
					
		t_row.highlight()
		await prepare_cred_roll(t_row.highest_chance)
		await get_tree().create_timer(1.0).timeout
		start()

func prepare_cred_roll(chance: int):
	status_updater.text = "USING HIGHEST CHANCE"
	status_title.text = "ATTEMPING MATCH"
	status_username.text = u_name
	status_pw.text = "****"
	#status_progress_bar.text = "success chance: " + str(chance) + "%"
	
	var tween = create_tween()
	tween.tween_property(main_bar, "value", 100, 2.0)
	await tween.finished
	
	var roll = randi_range(1, 99)
	if roll > chance:
		#fail
		status_title.text = "FAILED"
	else:
		status_title.text = "CREDENTIAL ASSEMBLED"
		status_image.texture = cred_image
		
	

func _reset_rows():
	highest_roll = 0
	current_iteration = 0
	main_bar.value = 0
	status_image.texture = lock_image
	status_title.text = "AWAITING MATCH"
	status_username.text = "-"
	status_pw.text = "-"
	status_progress_bar.text = "success chance: -"
	if user_row_container.get_children().size() > 0:
		for n in user_row_container.get_children():
			n.queue_free()

func _build_rows():
	for i in range(USER_ROWS):
		var r = target_row.instantiate()
		var s = separator.instantiate()
		r.update("j_kleinstine_1")
		r._hide()
		user_row_container.add_child(r)
		
		if i != USER_ROWS - 1:
			user_row_container.add_child(s)

func _get_current_row():
	for n in user_row_container.get_children():
		if n is PanelContainer:
			if n.current_state == n.MATCH_STATE.WAITING:
				return n
	return null
