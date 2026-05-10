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

@export var pw_row: PackedScene

var process_running: bool = false
var amount_cracked: int = 0
var letter_boxes: Array = []
var PW_LENGTH: int = 4
var current_crack_line
var prog_bar_tween: Tween
var end_safely: bool = false

var random_four_digit_words: Array = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]

func start():
	letter_boxes = [letter_box, letter_box_2, letter_box_3, letter_box_4]
	if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
		return #no encrypted passwords
	
	#SETUP
	process_running = true
	end_safely = false
	progress_bar.value = 0
	amount_cracked = 0
	remaining_label.text = str(Inventory.get_amount(Items.ENCRYPTED_PASSWORDS))
	cracked_label.text = str(amount_cracked)
	while Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) > 0 and process_running:
		_clean_queue()
		var pw_per_page = clamp(Inventory.get_amount(Items.ENCRYPTED_PASSWORDS), 0, 10)
		queue_info.text = "ENCRYPTED PASSWORDS - QUEUE (" + str(pw_per_page) + ")"
		for i in range(pw_per_page):
			_generate_initial_queue()
		#END SETUP
		
		#PW LOOP
		for j in range(pw_per_page): #LOOP THROUGH QUEUE OF 10(MAX)
			if end_safely:
				process_running = false
				Signals.end_pw_cracking_safely()
				break
			if !process_running:
				break
			_start_next_crack()
			_start_scrambling()
			var current_word = random_four_digit_words.pick_random()
			
			var max_heat_used: int = 0
			for i in range(PW_LENGTH): #LOOP THROUGH LETTERS (4)
				if process_running:
					if Stats.overheated:
						var speed = Stats.player_stats["Password Cracking"]["overheat speed"]
						var heat = Stats.player_stats["Password Cracking"]["overheat heat"]
						if heat > max_heat_used:
							max_heat_used = heat
						_update_progress_bar(i, speed)
						await get_tree().create_timer(speed).timeout
					elif Stats.overclocked:
						var speed = Stats.player_stats["Password Cracking"]["overclock speed"]
						var heat = Stats.player_stats["Password Cracking"]["overclock heat"]
						if heat > max_heat_used:
							max_heat_used = heat
						_update_progress_bar(i, speed)
						await get_tree().create_timer(speed).timeout
					else:
						var speed = Stats.player_stats["Password Cracking"]["base speed"]
						var heat = Stats.player_stats["Password Cracking"]["heat"]
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
	if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
		cracking_current_status.text = "All passwords cracked."
	
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
	Inventory.remove_resource(Items.ENCRYPTED_PASSWORDS, 1)
	Inventory.add_resource(Items.PASSWORDS, 1)
	amount_cracked += 1
	Stats.update_tempature(heat)
	Stats.add_xp(Stats.player_stats["Password Cracking"])
	
	remaining_label.text = str(Inventory.get_amount(Items.ENCRYPTED_PASSWORDS))
	cracked_label.text = str(amount_cracked)

func _on_progress_bar_value_changed(value):
	if process_running:
		progress_bar_label.text = str(int(value)) + "%"
