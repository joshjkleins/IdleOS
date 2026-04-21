extends VBoxContainer

@onready var stage_one_progress_bar = $BattleInfo/StageOne/VBoxContainer/ProgressBar
@onready var stage_two_progress_bar = $BattleInfo/StageTwo/VBoxContainer/ProgressBar
@onready var stage_three_progress_bar = $BattleInfo/StageThree/VBoxContainer/ProgressBar
@onready var stage_one_success_label = $BattleInfo/StageOne/VBoxContainer/SuccessLabel
@onready var stage_two_success_label = $BattleInfo/StageTwo/VBoxContainer/SuccessLabel
@onready var stage_three_success_label = $BattleInfo/StageThree/VBoxContainer/SuccessLabel

@onready var stage_one_node = $BattleInfo/StageOne
@onready var stage_one_left_label = $BattleInfo/StageOne/LeftLabel
@onready var stage_one_right_label = $BattleInfo/StageOne/RightLabel
@onready var stage_two_node = $BattleInfo/StageTwo
@onready var stage_two_left_label = $BattleInfo/StageTwo/LeftLabel
@onready var stage_two_right_label = $BattleInfo/StageTwo/RightLabel
@onready var stage_three_node = $BattleInfo/StageThree
@onready var stage_three_left_label = $BattleInfo/StageThree/LeftLabel
@onready var stage_three_right_label = $BattleInfo/StageThree/RightLabel

@onready var stage_labels = $StageLabels
@onready var stage_number = $StageLabels/StageNumber
@onready var stage_name = $StageLabels/StageName
@onready var battle_info = $BattleInfo

var target

func setup_hack():
	#reset to stage 1
	stage_one_node.visible = true
	stage_two_node.visible = true
	stage_three_node.visible = true
	stage_one_node.modulate.a = 0.0
	stage_two_node.modulate.a = 0.0
	stage_three_node.modulate.a = 0.0
	stage_one_right_label.text = "Searching for target"
	stage_two_right_label.text = "Attempting hack"
	stage_three_left_label.text = ""
	stage_three_right_label.text = "Extracting valuables"

	stage_one_progress_bar.value = 0.0
	stage_two_progress_bar.value = 0.0
	stage_three_progress_bar.value = 100.0

	_remove_progress_bar_color(stage_one_progress_bar)
	_remove_progress_bar_color(stage_two_progress_bar)
	_remove_progress_bar_color(stage_three_progress_bar)

	stage_labels.modulate.a = 0.0
	stage_labels.visible = true
	_update_stage_labels("Stage 1", Ascii.recon)
	battle_info.modulate.a = 1.0


func begin_hack():
	#fade in stage_one
	_fade_node_up_in(stage_labels)
	await _fade_node_up_in(stage_one_node)
	# await _fade_node_up_in(battle_info)
	phase_one()

func phase_one():
	var tween = create_tween()
	tween.tween_property(stage_one_progress_bar, "value", 100.0, 2.0)
	await tween.finished
	
	if randf() < 0.1: #fail
		_progress_bar_fail(stage_one_progress_bar, stage_one_success_label)
		Inventory.remove_resource(Items.IP_ADDRESS, 1)
		await get_tree().create_timer(1.0).timeout
		if Inventory.get_amount(Items.IP_ADDRESS) > 0:
			_reset_progress_bar(stage_one_progress_bar)
			phase_one()
		else:
			stop_hacking()
	else: #success
		_progress_bar_success(stage_one_progress_bar, stage_one_success_label, stage_one_right_label)
		Inventory.remove_resource(Items.IP_ADDRESS, 1)
		await get_tree().create_timer(1.0).timeout
		await end_phase_one()
		await phase_two_setup()

func end_phase_one():
	await _fade_node_down_out(stage_labels)
	

func phase_two_setup():
	#update stage labels
	_update_stage_labels("Stage 2", Ascii.breach)
	_fade_node_up_in(stage_labels)
	await _fade_node_up_in(stage_two_node)

	phase_two()


func phase_two():
	#start progress bar
	var tween = create_tween()
	tween.tween_property(stage_two_progress_bar, "value", 100.0, 2.0)
	await tween.finished

	if randf() < 0.1: #fail
		stage_two_success_label.text = "Failed"
		var style = StyleBoxFlat.new()
		style.bg_color = Color.RED
		stage_two_progress_bar.add_theme_stylebox_override("fill", style)
		Inventory.remove_resource(Items.CREDENTIALS, 1)
		await get_tree().create_timer(1.0).timeout
		if Inventory.get_amount(Items.CREDENTIALS) > 0:
			_reset_progress_bar(stage_two_progress_bar)
			phase_two()
		else:
			stop_hacking()
	else: #success
		stage_two_success_label.text = "Success"
		stage_two_right_label.text = "I'm in"
		_update_progress_bar_color(Color.LIME_GREEN, stage_two_progress_bar)
		Inventory.remove_resource(Items.CREDENTIALS, 1)
		await get_tree().create_timer(1.0).timeout
		await end_phase_two()
		phase_three_setup()

func end_phase_two():
	await _fade_node_down_out(stage_labels)

func phase_three_setup():
	_update_stage_labels("Stage 3", Ascii.extract)
	stage_three_progress_bar.value = 100.0
	_fade_node_up_in(stage_labels)
	stage_three_success_label.text = "downloading"
	await _fade_node_up_in(stage_three_node)
	
	phase_three() 

func phase_three():
	var amount_of_items = randi_range(5, 15)
	var loot = target["loot"]
	
	# Precompute total weight ONCE
	var total_weight = 0.0
	for item in loot.values():
		total_weight += item.weight
	
	var percentage_of_bar_per_item = 100.0 / amount_of_items
	var current_value = stage_three_progress_bar.value
	
	stage_three_left_label.text = ""  # reset text
	
	for i in range(amount_of_items):
		# ---- WEIGHTED ROLL ----
		var roll = randf() * total_weight
		var cumulative = 0.0
		var chosen_key = ""
		var entry
		
		for key in loot.keys():
			entry = loot[key]
			cumulative += entry.weight
			
			if roll <= cumulative:
				chosen_key = key
				break
		
		var amount = randi_range(entry.min, entry.max)
		
		# ---- PROGRESS BAR ANIMATION ----
		var target_percent = current_value - percentage_of_bar_per_item
		var tween = create_tween()
		tween.tween_property(stage_three_progress_bar, "value", target_percent, 0.5)
		await tween.finished
		
		current_value = stage_three_progress_bar.value
		
		# ---- DISPLAY (NO STACKING) ----
		stage_three_left_label.text += chosen_key + " x" + str(amount) + "\n"
		Inventory.add_resource(chosen_key, amount)
		await get_tree().create_timer(0.2).timeout
	
	_update_progress_bar_color(Color.LIME_GREEN, stage_three_progress_bar)
	stage_three_success_label.text = "Success"
	stage_three_right_label.text = "Valuables Extracted"
	
	#check if player has ip addresses and credentials
	await get_tree().create_timer(1.5).timeout

	_fade_node_down_out(stage_labels)
	await _fade_node_down_out(battle_info)

	if Inventory.get_amount(Items.CREDENTIALS) > 0 and Inventory.get_amount(Items.IP_ADDRESS) > 0:
		setup_hack()
		begin_hack()
	else:
		stop_hacking()

func stop_hacking():
	Signals.end_hacking()

##FILE PRIVATE FUNCTIONS##

func _progress_bar_fail(progress_bar, success_label):
	success_label.text = "Failed"
	_update_progress_bar_color(Color.RED, progress_bar)

func _progress_bar_success(progress_bar, success_label, right_label):
	success_label.text = "Success"
	right_label.text = "Target aquired"
	_update_progress_bar_color(Color.LIME_GREEN, progress_bar)

func _update_progress_bar_color(color: Color, progress_bar):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	progress_bar.add_theme_stylebox_override("fill", style)

func _remove_progress_bar_color(progress_bar):
	progress_bar.remove_theme_stylebox_override("fill")

func _reset_progress_bar(progress_bar):
	progress_bar.value = 0.0
	_remove_progress_bar_color(progress_bar)

func _fade_node_down_out(n):
	var og_pos = n.position
	var t_pos = n.position + Vector2(0, 10.0)
	var tween = create_tween()
	tween.parallel().tween_property(
		n,
		"position",
		t_pos,
		0.5
	)

	tween.parallel().tween_property(
		n,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished
	n.position = og_pos

#assumes node is visible with opacity set to 0.0
func _fade_node_up_in(n):
	var base_pos = n.position
	n.position = base_pos + Vector2(0, 10)
	var tween := create_tween()

	tween.parallel().tween_property(
		n,
		"position",
		base_pos,
		0.5
	)

	tween.parallel().tween_property(
		n,
		"modulate:a",
		1.0,
		0.5
	)

	await tween.finished


func _update_stage_labels(new_stage_number: String, new_stage_name: String):
	stage_number.text = new_stage_number
	stage_name.text = new_stage_name
