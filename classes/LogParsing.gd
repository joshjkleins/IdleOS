class_name LogParser

const TERM_WIDTH = 60
const INNER_WIDTH = TERM_WIDTH - 2

var lines_visible := 12
var active := false
var progress := 0.0
var speed := 1.0

const COL_TIME = 9
const COL_LEVEL = 7
const COL_SERVICE = 16

const REWARD_CHANCES = {
	"INFO": 0.10,
	"WARN": 0.18,
	"ALERT": 0.30,
	"ERR": 0.22
}

const BASE_REWARD_CHANCE = 0.05

const REWARD_TABLE = [
	{ "type": "data", "min": 5, "max": 15, "weight": 40, "color": "yellow" },
	{ "type": "usernames", "amount": 1, "weight": 15, "color": "cyan" },
	{ "type": "scrambled passwords", "amount": 1, "weight": 15, "color": "lime" },
	{ "type": "logs", "amount": 1, "weight": 10, "color": "lime" },
	{ "type": "passwords", "amount": 1, "weight": 10, "color": "lime" },
	{ "type": "ip address", "amount": 1, "weight": 8, "color": "orange" },
	{ "type": "credentials", "amount": 1, "weight": 2, "color": "lime" },
]

func get_reward_chances() -> String:
	var output = ""
	for reward in REWARD_TABLE:
		output += reward.type + ": " + str(int(reward.weight)) + "%   "
	output = output.strip_edges()
	return output

func pick_weighted_reward() -> Dictionary:
	var total_weight := 0
	for r in REWARD_TABLE:
		total_weight += r.weight

	var roll = randi_range(1, total_weight)
	var cumulative = 0

	for r in REWARD_TABLE:
		cumulative += r.weight
		if roll <= cumulative:
			return r

	return {} # fallback


func attach_reward(box_line:String, reward_text:String, color:String, total_width:int) -> String:
	if reward_text == "":
		return box_line

	var reward_bb = "[color=%s]%s[/color]" % [color, reward_text]

	var visible_len = box_line.length()
	var spacing = total_width - visible_len - reward_text.length()

	if spacing < 1:
		spacing = 1

	return box_line + " ".repeat(spacing) + reward_bb

func border(title:String="") -> String:
	if title == "":
		return "┌" + "─".repeat(INNER_WIDTH) + "┐"

	var t = " " + title + " "
	var remaining = INNER_WIDTH - t.length()
	var left = int(remaining / 2)
	var right = remaining - left
	return "┌" + "─".repeat(left) + t + "─".repeat(right) + "┐"


func bottom() -> String:
	return "└" + "─".repeat(INNER_WIDTH) + "┘"


func line(text:String) -> String:
	if text.length() > INNER_WIDTH:
		text = text.substr(0, INNER_WIDTH)
	return "│" + text.rpad(INNER_WIDTH, " ") + "│"


func format_log_entry(level:String, service:String, message:String) -> String:
	var time = Time.get_time_string_from_system().substr(0, 8)

	var part_time = time.rpad(COL_TIME, " ")
	var part_level = level.rpad(COL_LEVEL, " ")
	var part_service = service.rpad(COL_SERVICE, " ")

	var remaining = INNER_WIDTH - (COL_TIME + COL_LEVEL + COL_SERVICE)
	if message.length() > remaining:
		message = message.substr(0, remaining - 3) + "..."

	return line(part_time + part_level + part_service + message)


func colored_log(level:String, service:String, message:String) -> String:
	var txt = format_log_entry(level, service, message)

	match level:
		"INFO":
			return "[color=gray]" + txt + "[/color]"
		"WARN":
			return "[color=yellow]" + txt + "[/color]"
		"ALERT":
			return "[color=red]" + txt + "[/color]"
		"ERR":
			return "[color=purple]" + txt + "[/color]"
		_:
			return txt

func roll_reward() -> Dictionary:
	# Flat 5% chance to get ANY reward
	var chance = BASE_REWARD_CHANCE + Stats.player_stats["Log Parsing"]["effeciency"]
	if randf() > chance:
		return {}

	var reward_def = pick_weighted_reward()
	if reward_def.is_empty():
		return {}

	if reward_def.type == "data":
		var amount = randi_range(reward_def.min, reward_def.max)
		return {
			"type": "data",
			"amount": amount,
			"text": "+%d Data" % amount,
			"color": reward_def.color
		}
	else:
		return {
			"type": reward_def.type,
			"amount": reward_def.amount,
			"text": "+%d %s" % [reward_def.amount, reward_def.type.capitalize()],
			"color": reward_def.color
		}




func generate_log_line(log_data:Array, total_width:int=80) -> Dictionary:
	var entry = log_data.pick_random()

	var colored_line = colored_log(entry.level, entry.service, entry.message)

	var reward = roll_reward()

	var final_line = colored_line
	if reward.size() > 0:
		final_line = attach_reward(colored_line, reward.text, reward.color, total_width)

	return {
		"text": final_line,
		"reward": reward
	}
