class_name PasswordCrack

var password_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
var random_four_digit_words: Array[String] = [
	"acid", "back", "band", "base", "beam", "bell", "bird", "blue", 
	"boat", "bold", "bone", "book", "born", "cake", "camp", "card", 
	"case", "city", "cold", "dark", "data", "deck", "door", "dust", 
	"echo", "edge", "face", "fact", "fair", "fast", "fire", "fish", 
	"flow", "free", "frog", "fuel", "game", "gate", "gift", "glow", 
	"gold", "gray", "grid", "hand", "hard", "help", "high", "hill", 
	"hope", "icon"
]

var current_word: String = ""
var revealed_chars: int = 0


#returns first instance and sets word
func get_initial_scrambled_word() -> String:
	revealed_chars = 0
	current_word = random_four_digit_words.pick_random()
	return get_current_scramble()

#gets called very often, returns current iteration of scrambled word
func get_current_scramble() -> String:
	var output = ""
	for i in range(current_word.length()):
		if revealed_chars > i: #correct letter
			output += current_word[i]
		else:
			output += password_characters[randi() % password_characters.length()]
	return output

func reveal_letter():
	var chance = 0.05 + Stats.player_stats["Password Cracking"]["effeciency"]
	if randf() > chance:
		revealed_chars += 1
	else:
		print('yep!')
		revealed_chars += 2

func is_word_revealed() -> bool:
	if revealed_chars >= current_word.length():
		return true
	return false

func transform_password():
	if Inventory.get_amount("encrypted passwords") < 1:
		print("No encrypted passwords to transform")
		
	Inventory.remove_resource("encrypted passwords", 1)
	Inventory.add_resource("passwords", 1)
