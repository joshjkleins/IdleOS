extends VBoxContainer

@onready var process_title = $ProcessTitle
@onready var p_yield = $Yield
@onready var total = $Total
@onready var progress = $Progress
@onready var scramble_timer = $ScrambleTimer
@onready var unscramble_timer = $UnscrambleTimer

var password_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
var random_four_digit_words: PackedStringArray = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]
var word_to_unscramble: String
var chars_to_unscramble: int
var chars_to_show = 0

var passwords_obtained = 0
var process_running = false
var time_started = 0.0
var total_gained = 0
var times_process_completed = 0

func start_process():
	word_to_unscramble = get_random_word()
	chars_to_unscramble = word_to_unscramble.length()
	
	time_started = Time.get_ticks_msec()
	total_gained = 0
	times_process_completed = 0
	process_running = true
	visible = true
	process_title.text = "Initializing password hacking..."
	await get_tree().create_timer(0.5).timeout
	process_title.text = "Starting password hacking"
	p_yield.text = "yield:    +0.06 password/sec"
	total.text = "total:    " + str(passwords_obtained) + " passwords"
	scramble_timer.start()
	unscramble_timer.start()

func get_random_word() -> String:
	if random_four_digit_words.is_empty():
		return ""
	
	# Pick a random index
	var index = randi() % random_four_digit_words.size()
	return random_four_digit_words[index]


func get_unique_random_chars(amount: int):
	var char_array = Array(password_characters.split("")) 
	char_array.shuffle()
	var result = "".join(char_array.slice(0, amount))
	return result

func _on_scramble_timer_timeout():
	var random_chars_to_get = chars_to_unscramble - chars_to_show
	var chars = get_unique_random_chars(random_chars_to_get)
	
	if chars_to_show == 0:
		progress.text = chars
	else:
		var new_word = ""
		for i in range(chars_to_show):
			new_word += word_to_unscramble[i]
		
		new_word += chars
		
		progress.text = new_word
	
	if chars_to_show >= word_to_unscramble.length(): #password unscrambled
		await get_tree().create_timer(0.3).timeout
		passwords_obtained += 1
		times_process_completed += 1
		total_gained += 1
		Inventory.total_passwords += 1
		total.text = "total:    " + str(passwords_obtained) + " passwords"
		await get_tree().create_timer(0.5).timeout
		chars_to_show = 0
		word_to_unscramble = get_random_word()
		chars_to_unscramble = word_to_unscramble.length()
		scramble_timer.start()
		unscramble_timer.start()
	else:
		scramble_timer.start()

func _on_unscramble_timer_timeout():
	chars_to_show += 1
	if chars_to_show < chars_to_unscramble:
		unscramble_timer.start()

func stop_process():
	process_running = false
	visible = false
	var summary = get_process_summary()
	return summary

func get_process_summary():
	var elapsed = Time.get_ticks_msec() - time_started
	var readable_time = format_time(elapsed)
	
	return """\nProcessInfo:
time elapsed     """+str(readable_time)+"""
passwords gained """+str(total_gained)+"""
times completed  """+str(times_process_completed)+"""
"""


func format_time(total_msec: int) -> String:
	var msec = total_msec % 1000
	var seconds = (total_msec / 1000) % 60
	var minutes = (total_msec / (1000 * 60)) % 60
	var hours = (total_msec / (1000 * 60 * 60))
	
	# %02d pads to 2 digits, %03d pads to 3 digits
	return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, msec]
