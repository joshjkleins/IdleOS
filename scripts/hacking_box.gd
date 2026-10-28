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

func select_target(location_name: String, targets: Array = []):
	await _green_flash(location_name)
	await _hide_container(targets_container)
	_update_persons(targets)
	update_box_title("IdleOS > Hacking > " + location_name.capitalize())
	await _show_container(persons_container)

#func select_target1(target: Dictionary = {}):
	#await _green_flash(target, targets_container)
	#await _hide_container(targets_container)
	#_update_persons(target)
	#update_box_title("IdleOS > Hacking > " + target.name)
	#await _show_container(persons_container)

func select_person(target: Dictionary = {}, hack_count: int = 1, overclock: bool = false, fights: Array = []):
	#await _green_flash(target, persons_container)
	await _hide_container(persons_container)
	var loadout = {
		"offensive": Items.SQL_INJECTOR,
		"defensive": Items.PACKET_SPOOF
	}
	hacking_game.setup(target, loadout, hack_count, overclock, fights)
	if fights.is_empty(): # a compromise keeps the lineup's title ("... > School compromise")
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
	if _recon_box != null:
		_set_recon_info("")
	remove_last_title_update()
	await _show_container(targets_container)

func hacking_to_persons():
	var was_compromise = !hacking_game.compromise_fights.is_empty()
	# the cards were drawn before the hack: redraw them so requirements (payloads 0/1) are current
	for card in persons_container.get_children():
		if card.has_method("update_info") and card.get("target") != null:
			card.update_info(card.target)
	await _hide_container(hacking_game)
	if !was_compromise:
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

func _green_flash(location: String):
	for tar in targets_container.get_children():
		if tar.target.name.to_lower() == location.to_lower():
			await tar.flash_green()

#func _green_flash1(location_name: String, container):
	#for tar in container.get_children():
		#if tar.target.name == target.name:
			#await tar.flash_green()

func _red_flash(target, container):
	for tar in container.get_children():
		if tar.target.name == target.name:
			await tar.flash_red()

## 'recon <location>': the compromise lineup as numbered cards, with the cost and rules under them
var _recon_box: VBoxContainer = null
func select_recon(location_name: String, fights: Array, info_text: String):
	await _green_flash(location_name)
	await _hide_container(targets_container)
	_update_persons(fights)
	_set_recon_info(info_text)
	update_box_title("IdleOS > Hacking > " + location_name.capitalize() + " compromise")
	await _show_container(persons_container)

## the rules panel under the recon cards (the persons grid is moved into a VBox with it on first use)
func _set_recon_info(info_text: String) -> void:
	if _recon_box == null:
		_recon_box = VBoxContainer.new()
		_recon_box.add_theme_constant_override("separation", 10)
		_recon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var parent = persons_container.get_parent()
		var idx = persons_container.get_index()
		parent.remove_child(persons_container)
		parent.add_child(_recon_box)
		parent.move_child(_recon_box, idx)
		_recon_box.add_child(persons_container)
		var info := RichTextLabel.new()
		info.name = "ReconInfo"
		info.bbcode_enabled = true
		info.fit_content = true
		info.scroll_active = false
		info.add_theme_font_size_override("normal_font_size", 12)
		_recon_box.add_child(info)
		# the rules show only with the cards (they fade out for a hack and back in after it)
		persons_container.visibility_changed.connect(func(): info.visible = persons_container.visible and info.text != "")
	var lbl: RichTextLabel = _recon_box.get_node("ReconInfo")
	lbl.text = info_text
	lbl.visible = info_text != "" and persons_container.visible

#lists each person at specific location
func _update_persons(targets: Array):
	if _recon_box != null:
		_set_recon_info("")
	for child in persons_container.get_children():
		child.queue_free()
	
	for target in targets:
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

func get_hacking_target(target_name: String) -> Dictionary:
	for person in persons_container.get_children():
		if person.target == null or person.is_queued_for_deletion():
			continue
		if target_name == person.target.command:
			return person.target
	return {}
