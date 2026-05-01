extends Control


@export var title_text: String = "Hacking"
@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel

@onready var targets_container = $PanelContainer/MarginContainer/TargetsContainer
@onready var persons_container = $PanelContainer/MarginContainer/PersonsContainer
@onready var hack_container = $PanelContainer/MarginContainer/HackContainer


const hacking_card: PackedScene = preload("res://scenes/target_card.tscn")
const person_card: PackedScene = preload("res://scenes/person_card.tscn")

func _ready():
	Signals.end_hacking_signal.connect(end_hack)
	targets_container.visible = true
	persons_container.visible = false
	rtl.text = "[bgcolor=#0b0e11]" + title_text + "[/bgcolor]"
	update_targets()

func update_targets():
	for child in targets_container.get_children():
		child.queue_free()
	#await get_tree().process_frame  # wait for frees to process
	
	for target in Stats.hacking_targets:
		var info = Stats.hacking_targets[target]
		
		#instantiate row
		var new_row = hacking_card.instantiate()
		new_row.update_info(info)
		
		#add to ui
		targets_container.add_child(new_row)
	
	

func select_target(target: Dictionary = {}):
	await _green_flash(target, targets_container)
	await _hide_container(targets_container)
	_update_persons(target)
	await _show_container(persons_container)

func select_person(target: Dictionary = {}):
	if Inventory.get_amount(Items.CREDENTIALS) > 0 and Inventory.get_amount(Items.IP_ADDRESS) > 0:
		await _green_flash(target, persons_container)
		await _hide_container(persons_container)
		hack_container.setup_hack()
		await _show_container(hack_container)
		hack_container.target = target
		hack_container.begin_hack()
	else:
		await _red_flash(target, persons_container)

func can_hack_person(target: Dictionary = {}):
	#keep target as param because eventually people will have different requirements for hacking
	if Inventory.get_amount(Items.CREDENTIALS) > 0 and Inventory.get_amount(Items.IP_ADDRESS) > 0:
		return true
	return false

func persons_to_targets():
	await _hide_container(persons_container)
	await _show_container(targets_container)

func hacking_to_persons():
	await _show_container(persons_container)

func end_hack():
	await get_tree().create_timer(1.5).timeout
	await _hide_container(hack_container)
	await _show_container(persons_container)
	Signals.hacking_ended()

func _hide_container(container):
	if !container.visible:
		return
	#assumes container is already visible with modulate = 1.0
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 0.0, 0.3)
	await tween.finished
	container.visible = false

func _show_container(container):
	container.modulate.a = 0.0
	container.visible = true
	#assumes container is already visible with modulate = 0.0
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.3)
	await tween.finished

func _green_flash(target, container):
	for tar in container.get_children():
		if tar.target.name == target.name:
			await tar.flash_green()

func _red_flash(target, container):
	for tar in container.get_children():
		if tar.target.name == target.name:
			await tar.flash_red()

#lists each person at specific location
func _update_persons(target_location):
	for child in persons_container.get_children():
		child.queue_free()
	
	for target in target_location.targets:
		var new_card = person_card.instantiate()
		new_card.update_info(target)
		
		persons_container.add_child(new_card)
