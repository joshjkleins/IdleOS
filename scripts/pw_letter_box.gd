extends Panel

@onready var scramble_timer = $ScrambleTimer

var password_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
var pin_characters = "1234567890"
var scramble: bool = false

var is_pin: bool = false

func update_letter(letter):
	$MarginContainer/VBoxContainer/Letter.text = letter

func start_scramble():
	scramble = true
	scramble_timer.start()

func _on_scramble_timer_timeout():
	if Stats.overheated:
		scramble_timer.wait_time = 0.5
	else:
		scramble_timer.wait_time = 0.1
	if scramble:
		if is_pin:
			update_letter(pin_characters[randi() % pin_characters.length()])
		else:
			update_letter(password_characters[randi() % password_characters.length()])
	

func reveal(letter: String):
	scramble = false
	scramble_timer.stop()
	update_letter(letter)

func stop_scramble():
	scramble = false
	scramble_timer.stop()
	update_letter(" ")
