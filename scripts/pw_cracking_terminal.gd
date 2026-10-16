extends BaseTerminal
## Cracking terminal: a queue of up to 5 encrypted items; each crack scrambles the boxes and
## reveals one character per speed step. Efficiency gives a chance to crack instantly.
## What the boxes show depends on the process: see CRACK_FORMATS / _get_format().

@onready var queue_container = $MarginContainer/VBoxContainer/QueueRow/QueueContainer
@onready var queue_info = $MarginContainer/VBoxContainer/QueueRow/QueueInfo
@onready var cracked_label = $MarginContainer/VBoxContainer/InfoRow/VBoxContainer/CrackedLabel
@onready var remaining_label = $MarginContainer/VBoxContainer/InfoRow/VBoxContainer2/RemainingLabel
@onready var letter_box = $MarginContainer/VBoxContainer/PwRow/CrackingRow/LetterBox
@onready var letter_box_2 = $MarginContainer/VBoxContainer/PwRow/CrackingRow/LetterBox2
@onready var letter_box_3 = $MarginContainer/VBoxContainer/PwRow/CrackingRow/LetterBox3
@onready var letter_box_4 = $MarginContainer/VBoxContainer/PwRow/CrackingRow/LetterBox4
@onready var cracking_current_status = $MarginContainer/VBoxContainer/PwRow/CrackingCurrentStatus
@onready var progress_bar = $MarginContainer/VBoxContainer/PwRow/HBoxContainer/ProgressBar
@onready var progress_bar_label = $MarginContainer/VBoxContainer/PwRow/HBoxContainer/ProgressBarLabel
@onready var title_label = $MarginContainer/VBoxContainer/TitleRow/TitleLabel
@onready var efficiency = $MarginContainer/VBoxContainer/InfoRow/VBoxContainer3/Efficiency
@onready var player_amount_labels = $MarginContainer/VBoxContainer/InfoRow/PlayerAmountLabels

@export var pw_row: PackedScene

const PW_LENGTH: int = 4
const CHARS_ALNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
const CHARS_DIGITS = "1234567890"

var amount_cracked: int = 0
var letter_boxes: Array = []
var current_crack_line
var prog_bar_tween: Tween
var crack_format: Dictionary # {"charset": String, "secret": Callable}

var use_token: ItemData = null
var create_token: ItemData = null

func set_cracking_type(p_type: Dictionary, window: bool = false, use_item: ItemData = null, create_item: ItemData = null):
	setup_process(Cracking, p_type, window)
	use_token = use_item
	create_token = create_item
	letter_boxes = [letter_box, letter_box_2, letter_box_3, letter_box_4]
	crack_format = _get_format(p_type)
	for box in letter_boxes:
		box.charset = crack_format.charset

## How each cracking process fills its boxes: scramble characters + how the answer is picked.
## New processes (badge hash, bio template, digital signature, private keys) add a case here.
func _get_format(p_type: Dictionary) -> Dictionary:
	match str(p_type.name).to_lower():
		"pin":
			return {"charset": CHARS_DIGITS, "secret": func(): return "%04d" % (randi() % 10000)}
		"vm":
			return {"charset": CHARS_ALNUM, "secret": func(): return Cracking.get_vm_cracking_word(create_token)}
		_: # password
			return {"charset": CHARS_ALNUM, "secret": func(): return Cracking.random_four_digit_words.pick_random()}

func start():
	begin_run()
	progress_bar.value = 0
	amount_cracked = 0
	_update_remaining_label()
	cracked_label.text = str(amount_cracked)
	title_label.text = process_data["name"] + " Cracking"
	set_player_amount_labels()
	efficiency.text = str(_get_total_efficiency() * 100.0) + "%"

	if !has_requirements():
		finish_safely() # nothing to crack (previously a VM window would stay open forever)
		return

	while has_requirements() and running:
		_clean_queue()
		var lines_per_page = get_lines_queue_per_page()
		queue_info.text = process_data["name"].to_upper() + " CRACKING - QUEUE (" + str(lines_per_page) + ")"
		for i in range(lines_per_page):
			_generate_initial_queue()

		for j in range(lines_per_page): # crack through the queue (max 5)
			if !has_requirements():
				break
			if stop_requested:
				finish_safely()
				break
			if !running:
				break
			_start_next_crack()
			_start_scrambling()
			var current_word: String = crack_format.secret.call()

			var max_heat_used: float = 0.0 # instant cracks add no heat
			var eff = _get_total_efficiency()
			efficiency.text = str(eff * 100) + "%"
			var instant: bool = randf() < eff
			if instant:
				# instant crack
				_update_progress_bar(PW_LENGTH, 0.1)
				await get_tree().create_timer(0.1).timeout
				if !running:
					break
				for i in range(PW_LENGTH):
					_reveal_letter(i, current_word[i])
			else:
				for i in range(PW_LENGTH): # one character per speed step
					var mode := get_mode()
					max_heat_used = max(max_heat_used, get_heat(mode))
					var step_time := get_step_time(mode)
					_update_progress_bar(i, step_time)
					await get_tree().create_timer(step_time).timeout
					if !running:
						break
					_reveal_letter(i, current_word[i])
				if !running:
					break
			_end_current_crack(current_word, instant)
			_successful_crack(max_heat_used)
			progress_bar.value = 0

	if running:
		_finished()

func _on_stopped():
	if prog_bar_tween and prog_bar_tween.is_valid():
		prog_bar_tween.kill()
	progress_bar.value = 0
	for box in letter_boxes:
		if box.scramble: # blank boxes killed mid-crack, keep the last revealed answer
			box.stop_scramble()

func _update_progress_bar(fill: int, time: float):
	if running:
		if prog_bar_tween:
			prog_bar_tween.kill()
		var target_fill = (fill + 1) * 25
		prog_bar_tween = create_tween()
		prog_bar_tween.tween_property(progress_bar, "value", target_fill, max(0.01, time - 0.1))

## Ran out of items to crack.
func _finished():
	if !in_vm and !has_requirements():
		if process_data == Cracking.VM:
			cracking_current_status.text = "All available " + use_token.name + " cracked to " + create_token.name
		else:
			cracking_current_status.text = "All " + get_requirements().name + " cracked."
	finish_safely()

func _reveal_letter(index: int, letter: String):
	letter_boxes[index].reveal(letter)

func _start_scrambling():
	for n in letter_boxes:
		n.start_scramble()

func _clean_queue():
	for n in queue_container.get_children():
		n.queue_free()

func _generate_initial_queue():
	var new_row = pw_row.instantiate()
	new_row.new_row(process_data, use_token, create_token)
	queue_container.add_child(new_row)

func _end_current_crack(word, instant: bool = false) -> void:
	for n in queue_container.get_children():
		if n.current_status == n.CrackStatus.CRACKING:
			n.end_crack(word, instant)
			return

func _start_next_crack() -> void:
	for n in queue_container.get_children():
		if n.current_status == n.CrackStatus.QUEUED:
			n.start_crack()
			current_crack_line = n
			cracking_current_status.text = "Cracking: " + str(current_crack_line.uuid) +  "..."
			return

func _successful_crack(heat: float):
	process_data.signal.emit(1)

	if process_data == Cracking.VM:
		if Inventory.get_amount(use_token) >= 3:
			remove_requirements()
			Inventory.add_resource(create_token, 1)
		else:
			stop()
	else:
		remove_requirements()
		Inventory.add_resource(process_data["resource gained"], 1)
	set_player_amount_labels()
	if process_data == Cracking.PASSWORD:
		Tutorial.track_event(Tutorial.TutorialEvent.CRACK_3_PASSWORDS, 1)
	amount_cracked += 1
	record_cycle(1)
	Stats.update_tempature(heat)
	Exp.add_xp(Cracking, process_data, process_data["experience per level"])
	efficiency.text = str(_get_total_efficiency() * 100) + "%"

	if randf() <= 0.01:
		Inventory.add_resource(Items.VM_CRACKING_TOKEN, 1)
	Signals.update_hud(Cracking)
	_update_remaining_label()
	cracked_label.text = str(amount_cracked)

func _update_remaining_label():
	if process_data == Cracking.VM:
		remaining_label.text = str(int(Inventory.get_amount(get_requirements()) / 3))
	else:
		remaining_label.text = str(Inventory.get_amount(get_requirements()))

func _on_progress_bar_value_changed(value):
	if running:
		progress_bar_label.text = str(int(value)) + "%"

func _get_total_efficiency() -> float:
	var frag_bonus = Defragging.CRACKING["bonus efficiency"] if Stats.has_bonus(Cracking) else 1.0
	var efficiency_upgrade = Upgrades.get_package_info("cracking.efficiency").current
	return (process_data["efficiency"] + efficiency_upgrade) * frag_bonus

func set_player_amount_labels():
	var required_item_label = player_amount_labels.get_child(0)
	var received_item_label = player_amount_labels.get_child(1)
	var required_item = get_requirements()
	var received_item = get_item_received()
	required_item_label.get_child(0).text = required_item.name
	received_item_label.get_child(0).text = received_item.name
	required_item_label.get_child(1).text = str(Inventory.get_amount(required_item))
	received_item_label.get_child(1).text = str(Inventory.get_amount(received_item))

func has_requirements() -> bool:
	if process_data == Cracking.VM:
		return Inventory.get_amount(use_token) >= 3
	var requirements = process_data.requirements
	for item in requirements:
		if Inventory.get_amount(item) < requirements[item]:
			return false
	return true

func remove_requirements() -> void:
	if process_data == Cracking.VM:
		if Inventory.get_amount(use_token) >= 3:
			Inventory.remove_resource(use_token, 3)
	else:
		var requirements = process_data.requirements
		for item in requirements:
			if Inventory.get_amount(item) >= requirements[item]:
				Inventory.remove_resource(item, requirements[item])

func get_requirements() -> ItemData:
	if process_data == Cracking.VM:
		return use_token
	return process_data.requirements.keys()[0]

func get_item_received() -> ItemData:
	if process_data == Cracking.VM:
		return create_token
	return process_data["resource gained"]

func get_lines_queue_per_page() -> int:
	if process_data == Cracking.VM:
		return clamp(int(Inventory.get_amount(get_requirements()) / 3), 0, 5)
	return clamp(Inventory.get_amount(get_requirements()), 0, 5)
