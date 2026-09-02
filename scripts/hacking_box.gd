extends Control

@export var title_text: String = "Hacking"
@onready var pc = $PanelContainer
@onready var rtl = $RichTextLabel

@onready var targets_container = $PanelContainer/MarginContainer/TargetsContainer
@onready var persons_container = $PanelContainer/MarginContainer/PersonsContainer
@onready var hacking_game = $PanelContainer/MarginContainer/HackingGame

const hacking_card: PackedScene = preload("res://scenes/target_card.tscn")
const person_card: PackedScene = preload("res://scenes/person_card.tscn")

func _ready():
	targets_container.visible = true
	persons_container.visible = false
	hacking_game.visible = false
	update_box_title(title_text)
	update_targets()

func update_targets():
	for child in targets_container.get_children():
		child.queue_free()
	
	for target in Stats.hacking_targets:
		var info = Stats.hacking_targets[target]
		
		#instantiate row
		var new_row = hacking_card.instantiate()
		new_row.update_info(info)
		
		#add to ui
		targets_container.add_child(new_row)
		break

func select_target(target: Dictionary = {}):
	await _green_flash(target, targets_container)
	await _hide_container(targets_container)
	_update_persons(target)
	update_box_title("IdleOS > Hacking > " + target.name)
	await _show_container(persons_container)

func select_person(target: Dictionary = {}, recursive: bool = false):
	await _green_flash(target, persons_container)
	await _hide_container(persons_container)
	var loadout = {
		"offensive": Items.SQL_INJECTOR,
		"defensive": Items.PACKET_SPOOF
	}
	hacking_game.setup(target, loadout, recursive)
	update_box_title(rtl.text + " > " + target.name)
	await _show_container(hacking_game)
	await hacking_game.prepare()
	hacking_game.start_hack()

func target_select_error(target):
	await _red_flash(target, persons_container)

func can_hack_person(_target: Dictionary = {}):
	var req = _target.requirements
	if Inventory.get_amount(req.item) < req["amount"]:
		return false
	return true

func persons_to_targets():
	await _hide_container(persons_container)
	remove_last_title_update()
	await _show_container(targets_container)

func hacking_to_persons():
	await _hide_container(hacking_game)
	remove_last_title_update()
	await _show_container(persons_container)

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

func remove_last_title_update():
	var split_text = rtl.text.split(">")
	if split_text.size() <= 1:
		return
	split_text.remove_at(split_text.size() - 1)
	rtl.text = ">".join(split_text).strip_edges()
	

func update_box_title(text: String):
	rtl.text = "[bgcolor=#0b0e11]" + text + "[/bgcolor]"
