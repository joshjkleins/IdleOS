extends Control

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

@export var pw_row: PackedScene

var process_running: bool = false
var amount_cracked: int = 0
var letter_boxes: Array = []
var PW_LENGTH: int = 4
var current_crack_line
var prog_bar_tween: Tween
var end_safely: bool = false
var is_window: bool

var type: Dictionary

var first_crack: bool = false #this forces first crack to process so it doesnt instantly process a billion

func set_cracking_type(p_type: Dictionary, window: bool = false):
	is_window = window
	type = p_type
	match type.name.to_lower():
		"password":
			set_pw()
		"pin":
			set_pin()
	
	letter_boxes = [letter_box, letter_box_2, letter_box_3, letter_box_4]

func set_pw():
	for i in letter_boxes:
		i.is_pin = false

func set_pin():
	for i in letter_boxes:
		i.is_pin = true

func start():
	if Inventory.get_amount(type["requirements"]) <= 0:
		return #no encrypted passwords
	
	#SETUP
	process_running = true
	end_safely = false
	progress_bar.value = 0
	amount_cracked = 0
	remaining_label.text = str(Inventory.get_amount(type["requirements"]))
	cracked_label.text = str(amount_cracked)
	title_label.text = type["name"] + " Cracking"
	while Inventory.get_amount(type["requirements"]) > 0 and process_running:
		_clean_queue()
		var pw_per_page = clamp(Inventory.get_amount(type["requirements"]), 0, 10)
		queue_info.text = "ENCRYPTED " + type["name"].to_upper() + " - QUEUE (" + str(pw_per_page) + ")"
		for i in range(pw_per_page):
			_generate_initial_queue()
		#END SETUP
		
		#PW LOOP
		
		first_crack = true
		for j in range(pw_per_page): #LOOP THROUGH QUEUE OF 10(MAX)
			if end_safely:
				process_running = false
				if is_window:
					stop()
				else:
					Signals.end_pw_cracking_safely()
				break
			if !process_running:
				break
			_start_next_crack()
			_start_scrambling()
			var current_word
			if letter_boxes[0].is_pin:
				var random_number = randi() % 10000
				current_word = "%04d" % random_number
			else:
				current_word = Cracking.random_four_digit_words.pick_random()
			
			
			var max_heat_used: int = 0
			var defrag_bonus = Defragging.CRACKING["bonus efficiency"] if Stats.has_bonus(Cracking) else 0.0
			var eff = type["efficiency"] + Cracking.process_upgrades["efficiency"]["amount"] + defrag_bonus
			if randf() < eff and !first_crack:
				_end_current_crack(current_word)
				_successful_crack(max_heat_used)
			else:
				first_crack = false
				for i in range(PW_LENGTH): #LOOP THROUGH LETTERS (4)
					if process_running:
						if Stats.overheated:
							var speed = type["overheat speed"] / Cracking.process_upgrades["speed"]["amount"]
							var heat = type["overheat heat"]
							if heat > max_heat_used:
								max_heat_used = heat
							_update_progress_bar(i, speed)
							await get_tree().create_timer(speed).timeout
						elif Stats.overclocked:
							var speed = type["overclock speed"] / Cracking.process_upgrades["speed"]["amount"]
							var heat = type["overclock heat"]
							if heat > max_heat_used:
								max_heat_used = heat
							_update_progress_bar(i, speed)
							await get_tree().create_timer(speed).timeout
						else:
							var speed = type["base speed"] / Cracking.process_upgrades["speed"]["amount"]
							var heat = type["heat"]
							if heat > max_heat_used:
								max_heat_used = speed
							_update_progress_bar(i, speed)
							await get_tree().create_timer(speed).timeout
						if !process_running:
							break
						_reveal_letter(i,current_word[i])
				
				if !process_running:
						break
				_end_current_crack(current_word)
				_successful_crack(max_heat_used)
				progress_bar.value = 0
	
	if process_running:
		_finished()

func stop():
	end_safely = false
	process_running = false
	if prog_bar_tween.is_running():
		prog_bar_tween.kill()
	progress_bar.value = 0
	for n in letter_boxes:
		n.stop_scramble()
	if is_window:
		Cracking.CURRENT_VMS -= 1
		get_parent().queue_free()

func stop_safely():
	end_safely = true

func _update_progress_bar(fill: int, time: float):
	if process_running:
		if prog_bar_tween:
			prog_bar_tween.kill()
		var target_fill = (fill + 1) * 25
		prog_bar_tween = create_tween()
		prog_bar_tween.tween_property(progress_bar, "value", target_fill, time - 0.1)

func _finished():
	if is_window:
		stop()
		return
	if Inventory.get_amount(type["requirements"]) <= 0:
		cracking_current_status.text = "All " + type["requirements"].name + " cracked."
	
	if Stats.overclocked:
		Stats.overclocked = false
	
	prog_bar_tween.kill()
	Signals.end_pw_cracking_safely()

func _reveal_letter(index: int, letter: String):
	letter_boxes[index].reveal(letter)

func _start_scrambling():
	for n in letter_boxes:
		n.start_scramble()

func _clean_queue():
	if queue_container.get_child_count() > 0:
		for n in queue_container.get_children():
			n.queue_free()

func _generate_initial_queue():
	var new_row = pw_row.instantiate()
	new_row.new_row()
	queue_container.add_child(new_row)

func _end_current_crack(word) -> void:
	for n in queue_container.get_children():
		if n.current_status == n.CrackStatus.CRACKING:
			n.end_crack(word)
			return

func _start_next_crack() -> void:
	for n in queue_container.get_children():
		if n.current_status == n.CrackStatus.QUEUED:
			n.start_crack()
			current_crack_line = n
			cracking_current_status.text = "Cracking: " + str(current_crack_line.uuid) +  "..."
			return

func _successful_crack(heat: int):
	type.signal.emit(1)
	Inventory.remove_resource(type["requirements"], 1)
	Inventory.add_resource(type["resource gained"], 1)
	amount_cracked += 1
	Stats.update_tempature(heat)
	Exp.add_xp(Cracking, type, type["experience per level"] / Cracking.process_upgrades["experience"]["amount"])
	Signals.update_hud(Cracking)
	
	remaining_label.text = str(Inventory.get_amount(type["requirements"]))
	cracked_label.text = str(amount_cracked)

func _on_progress_bar_value_changed(value):
	if process_running:
		progress_bar_label.text = str(int(value)) + "%"
