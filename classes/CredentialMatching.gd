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
var max_visible = 15

var base_chance_to_find = 0.0
var increase_per_row = 0.003

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
	for i in range(max_visible):
		list.append(generate_username())
	return list


func render_list(match_found: bool) -> String:
	var header_string = "\nID" + " ".repeat(6) + "USERNAMES" + " ".repeat(16) + "PASSWORD STRENGTH" + " ".repeat(3) + "CHANCE TO MATCH\n"
	var header_sep = "---------------------------------------------------------------------------------------------------------\n"

	var list_output := ""
	var visible_count = min(usernames.size(), max_visible)

	# if highlight index is greater than visible count, remove the first index and generateusername to add at the end
	if highlight_index >= visible_count:
		usernames.remove_at(0)
		usernames.append(generate_username())

	for i in range(visible_count):
		var n = usernames[i]
		var line_num = ""
		if highlight_index < visible_count:
			line_num = i
		else:
			line_num = i + (highlight_index - visible_count + 1)
		var line = str(line_num)
		var perc_chance = line_num * (increase_per_row * (1 + Stats.player_stats["Credential Matching"]["effeciency"]))
		line += " ".repeat(8 - str(i).length())
		line += n
		line += " ".repeat(25 - n.length())
		line += "weak"
		line += " ".repeat(16)
		line += "%.2f" % (perc_chance * 100.0)

		
		if i == highlight_index or (i == max_visible - 1 and highlight_index >= max_visible):
			if match_found:
				list_output += "[bgcolor=#2e7533][color=white]" + line + "[/color][/bgcolor]\n"
			else:
				list_output += "[bgcolor=#2a5fff][color=white]" + line + "[/color][/bgcolor]\n"
		else:
			list_output += line + "\n"

	return header_string + header_sep + list_output


func create_creds():
	if Inventory.get_amount("passwords") < 1 or Inventory.get_amount("usernames") < 1:
		print("No username or password to transform")
		
	Inventory.remove_resource("passwords", 1)
	Inventory.remove_resource("usernames", 1)
	Inventory.add_resource("credentials", 1)
