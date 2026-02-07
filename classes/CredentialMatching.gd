class_name CredentialMatching
#ideas
#1
#Set success chance threshold
#Each created credential has specific success threshold
# need to figure out hacking module mechanics before this

#AI: "3 viable credential candidates detected."
#AI: "Recommending pair #2"
#
#> jkleins : p@55w0rd?
#Success Chance: 72%
#Alert Risk: MEDIUM


#2
#Search for directory of usernames
#ID | USERNAME | PASSWORD STRENGTH | CHANCE FOR MATCHING PASSWORD


var usernames = []
var highlight_index = 0
var max_visible = 20

const NAMES = [
	"john","jane","alex","sam","mike","emma","chris","josh","luke",
	"sarah","ben","lucas","nick","dave","kevin","amy","zoe","kate"
]

const WORDS = [
	"cat","dog","toast","noodle","banana","frog","duck","ghost",
	"pizza","coffee","sleepy","potato","pickle","cheese","pancake"
]

const ADJECTIVES = [
	"lazy","spicy","tiny","sleepy","happy","sad","weird","soft",
	"fast","slow","crispy","soggy","grumpy","lucky"
]

const SUFFIXES = [
	"", "", "", "",          # weighted empties
	"lol","xd","irl","pls","ok"
]

func generate_username() -> String:
	var roll := randi() % 100

	if roll < 40:
		return _name()
	elif roll < 65:
		return _name() + _number()
	elif roll < 80:
		return _word_word()
	elif roll < 90:
		return _adjective_word()
	elif roll < 95:
		return _name() + "_" + _word()
	else:
		return _cursed()

func _name() -> String:
	return NAMES.pick_random()

func _word() -> String:
	return WORDS.pick_random()

func _number() -> String:
	return str(randi_range(1, 999))

func _word_word() -> String:
	return _word() + "_" + _word()

func _adjective_word() -> String:
	return ADJECTIVES.pick_random() + "_" + _word()

func _cursed() -> String:
	return _word() + str(randi_range(10, 99)) + SUFFIXES.pick_random()


func get_initial_list() -> Array:
	var list = []
	for i in range(20):
		list.append(generate_username())
	return list


func render_list() -> String:
	var header_string = "\nID" + " ".repeat(6) + "USERNAMES" + " ".repeat(16) + "PASSWORD STRENGTH" + " ".repeat(3) + "CHANCE TO MATCH\n"
	var header_sep = "---------------------------------------------------------------------------------------------------------\n"

	var list_output := ""
	var visible_count = min(usernames.size(), max_visible)

	for i in range(visible_count):
		var n = usernames[i]
		var line := str(i)
		line += " ".repeat(8 - str(i).length())
		line += n
		line += " ".repeat(25 - n.length())
		line += "weak"
		line += " ".repeat(16)
		line += "4%"

		if i == highlight_index:
			list_output += "[bgcolor=#2a5fff][color=white]" + line + "[/color][/bgcolor]\n"
		else:
			list_output += line + "\n"

	return header_string + header_sep + list_output
