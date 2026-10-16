extends Panel

@onready var scramble_timer = $ScrambleTimer

## Characters this box flickers through while scrambling (set by the cracking format).
var charset: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
var scramble: bool = false

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
		update_letter(charset[randi() % charset.length()])
	

func reveal(letter: String):
	scramble = false
	scramble_timer.stop()
	update_letter(letter)

func stop_scramble():
	scramble = false
	scramble_timer.stop()
	update_letter(" ")
