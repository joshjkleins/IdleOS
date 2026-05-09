extends Panel

@onready var scramble_timer = $ScrambleTimer

var password_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
var scramble: bool = false

func update_letter(letter):
	$MarginContainer/VBoxContainer/Letter.text = letter

func start_scramble():
	scramble = true
	scramble_timer.start()

func _on_scramble_timer_timeout():
	if scramble:
		update_letter(password_characters[randi() % password_characters.length()])

func reveal(letter: String):
	scramble = false
	scramble_timer.stop()
	update_letter(letter)
