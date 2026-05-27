extends PanelContainer

var current_contract = null
var opened: bool = false

func _ready():
	$MarginContainer/ProgressBox.visible = true
	$MarginContainer/FinishedBox.visible = false
	$MarginContainer.visible = false

func update_info(contract: Contract):
	var sb = get_theme_stylebox("panel").duplicate()
	sb.bg_color = contract.major_skill.SKILL.color
	add_theme_stylebox_override("panel", sb)
	current_contract = contract
	$MarginContainer/ProgressBox/Major.text = contract.major_skill.SKILL.name
	$MarginContainer/ProgressBox/HBoxContainer/Desc.text = contract.description
	$MarginContainer/ProgressBox/HBoxContainer/Progress.text = str(contract.progress) + "/" + str(contract.goal_amount)
	$MarginContainer/ProgressBox/Reward.text = "+" + str(contract.reward_exp) + ", +" + str(contract.reward_item_amount) + " " + contract.reward_item.name
	
	$MarginContainer/FinishedBox/HBoxContainer/Progress.text = str(contract.progress) + "/" + str(contract.goal_amount)
	$MarginContainer/FinishedBox/HBoxContainer/Reward.text = "+" + str(contract.reward_exp) + ", +" + str(contract.reward_item_amount) + " " + contract.reward_item.name
	$MarginContainer/FinishedBox/CompleteTitle.text = contract.major_skill.SKILL.name.to_upper() + " CONTRACT COMPLETE"

func connect_contract(contract: Contract):
	current_contract = contract
	contract.progress_updated_signal.connect(update_info)
	contract.progress_complete_signal.connect(progress_ready)
	contract.contract_finished_signal.connect(contract_finished)

func progress_ready():
	if opened:
		await _fade_out($MarginContainer/ProgressBox)
		await _fade_in($MarginContainer/FinishedBox)
	else:
		$MarginContainer/ProgressBox.visible = false
		$MarginContainer/FinishedBox.visible = true

func minimize():
	if !opened:
		return
	var tween3 = create_tween()

	$MarginContainer.modulate.a = 1.0
	$MarginContainer.visible = true
	tween3.tween_property($MarginContainer,"modulate:a",0.0,0.2)
	await tween3.finished
	
	var tween2 = create_tween()

	$MarginContainer.visible = false
	tween2.tween_property(self,"custom_minimum_size:y",15.0,0.2)
	await tween2.finished
	
	var tween = create_tween()
	$MarginContainer.visible = false
	tween.tween_property(self,"custom_minimum_size:x",3.0,0.1)
	await tween.finished
	opened = false

func open():
	if opened:
		return
	var tween = create_tween()
	$MarginContainer.visible = false
	tween.tween_property(self, "custom_minimum_size:x", 160.0, 0.2)
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(self, "custom_minimum_size:y", 60.0, 0.1)
	await tween2.finished
	
	$MarginContainer.modulate.a = 0.0
	$MarginContainer.visible = true
	var tween3 = create_tween()
	tween3.tween_property($MarginContainer, "modulate:a", 1.0, 0.2)
	await tween3.finished
	opened = true

func _fade_out(node: Node):
	node.visible = true
	node.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 0.0, 0.2)
	await tween.finished
	node.visible = false

func _fade_in(node: Node):
	node.modulate.a = 0.0
	node.visible = true
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.2)
	await tween.finished

func contract_finished():
	if opened:
		await _fade_out($MarginContainer)
		
		var tween = create_tween()
		tween.tween_property(self, "custom_minimum_size:y", 0.0, 0.2)
		await tween.finished
	queue_free()
