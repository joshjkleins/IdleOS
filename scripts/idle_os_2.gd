extends Control

###NEXT
# BUG: FIX TYPING COMMANDS DURING WAIT PERIODS (maybe implement queue system?)

# Planning stage
# Plan out how hacking fully works
# Figure out different resources that can be used during a 'hack'
# load hacking -> can type in commands to browse hacking targets -> each target should give stats/difficulty/drops/drop rates -> commence hacking -> start 'battle' using 
# resources: Credentials used to 'attack', 'x' used to heal, 


#STEPS FOR ADDING NEW MODULE
#1. ADD TO CONTEXT ENUM
#2. ADD TO GET_CONTEXT_LEAD FUNC
#3. ADD TO INPUT_LINE_SUBMITTED & ADD RELEVENT FUNCTION
#4. ADD TO ROOT COMMAND CONTEXT
#5. ADD LIST HELP CONTEXT

@onready var lead_text = $Panel/MarginContainer/TerminalRoot/InputLineContainer/LeadText
@onready var input_line = $Panel/MarginContainer/TerminalRoot/InputLineContainer/InputLine
@onready var scrollback = $Panel/MarginContainer/TerminalRoot/Scrollback
@onready var loading = $Panel/MarginContainer/Loading
@onready var terminal_root = $Panel/MarginContainer/TerminalRoot
@onready var hacking = $Panel/MarginContainer/Hacking

@onready var parser = LogParser.new()
@onready var pw_scram = PasswordCrack.new()
@onready var cred_match = CredentialMatching.new()

enum Context {
	ROOT,
	DATA_MINING,
	LOG_PARSING,
	PASSWORD_CRACKING,
	CRED_MATCHING,
	HACKING,
	DARKWEB,
	MARKETPLACE
}

var current_context: Context = Context.ROOT
var lines: Array[String] = []

#past commands using up/down
var command_history = []
var history_index = -1
#end past commands

#module related
var module_running: bool = false
var process_running: bool = false

#LOG PARSING SPECIFIC
var log_start_index : int
var max_log_lines := 10
var visible_logs : Array[String] = []
var parse_box_title_line: int
var batch_totals = {
	"data": 0,
	"logs": 0,
	"encrypted passwords": 0,
	"passwords": 0,
	"usernames": 0,
	"credentials": 0,
	"ip address": 0
}

#END LOG PARSING SPECIFIC


#SKILL HEADER VARIABLES#
var lvl_and_effeciency_index: int
var skill_xp_progress_bar_index: int
var skill_xp_nums_index: int
var skill_specific_info_index: int
#END SKILL HEADER VARIABLES#


func _ready():
	update_context(Context.ROOT)
	#input_line.grab_focus() #uncomment this when not testing hacking module
	add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")

#update previous lines
func set_line(index: int, text: String, scroll_to_line: bool = true):
	if index < lines.size():
		lines[index] = text
	update_terminal(scroll_to_line)

#Add new line 
func add_line(text: String):
	lines.append(text)
	update_terminal()

#apply updates to line or new line
func update_terminal(scroll_to_line: bool = true):
	scrollback.text = "\n".join(lines)
	if scroll_to_line:
		scrollback.scroll_to_line(scrollback.get_line_count() - 1)

#player submits text
func _on_input_line_text_submitted(new_text):
	var text_with_lead = get_context_lead() + new_text
	input_line.clear()
	add_line(text_with_lead)
	command_history.append(new_text)
	if !universal_commands(new_text):
		match current_context:
			Context.ROOT:
				root_commands(new_text)
			Context.MARKETPLACE:
				marketplace_commands(new_text)
			Context.DATA_MINING:
				data_mining_commands(new_text)
			Context.LOG_PARSING:
				log_parsing_commands(new_text)
			Context.PASSWORD_CRACKING:
				password_unscramble_commands(new_text)
			Context.CRED_MATCHING:
				cred_matching_commands(new_text)
			Context.HACKING:
				hacking_commands(new_text)

	history_index = -1
	

#return text before command
func get_context_lead():
	match current_context:
		Context.ROOT:
			return "IdleOS>"
		Context.DARKWEB:
			return "IdleOS/Darkweb>"
		Context.MARKETPLACE:
			return "IdleOS/Marketplace>"
		Context.DATA_MINING:
			return "IdleOS/Modules/DataMining>"
		Context.LOG_PARSING:
			return "IdleOS/Modules/LogParsing>"
		Context.PASSWORD_CRACKING:
			return "IdleOS/Modules/PasswordCracking>"
		Context.CRED_MATCHING:
			return "IdleOS/Modules/CredentialMatching>"
		Context.HACKING:
			return "IdleOS/Modules/Hacking>"

#Changes context and updates leading text
func update_context(new_context: Context):
	current_context = new_context
	lead_text.text = get_context_lead()

func list_help():
	#add_line("""
#[UNIVERSAL COMMANDS]
#list -r                 Lists all resources
#list -m                 List available modules
#-h                      View this help message
#quit -s                 Save and quit game
#""")
	match current_context:
		Context.ROOT:
			add_line("""
[ROOT COMMANDS]
load [module name]      Load a module (example: "load data-mining")
marketplace -auth       Connects to the marketplace
""")
		Context.MARKETPLACE:
			add_line("""
[MARKETPLACE COMMANDS]
list                          List items to purchase
buy id=[itemID] a=[amount]    Purchase x amount of items (default amount = 1)
root                          Disconnect from market
""")
		Context.DATA_MINING:
			add_line("""
[DATA MINING COMMANDS]
start                   Start mining data
stop                    Stop mining process
root                    Exit back to root
info                    Mining data module stats
""")
		Context.LOG_PARSING:
			add_line("""
[LOG PARSING COMMANDS]
start                   Start log parsing process
stop                    Stop log parsing process
root                    Exit back to root
info                    Log parsing module stats
""")
			
		Context.PASSWORD_CRACKING:
			add_line("""
[PASSWORD UNSCRAMBLE COMMANDS]
start                   Start password cracking process
stop                    Stop password cracking process
root                    Exit back to root
info                    Password cracking module stats
""")
		Context.CRED_MATCHING:
			add_line("""
	[CREDENTIAL MATCHING COMMANDS]
start                   Start credential matching process
stop                    Stop credential matching process
root                    Exit back to root
info                    Credential matching module stats
""")
	
	add_line("""list -r                 Lists all resources
list -m                 List available modules
-h                      View this help message
quit -s                 Save and quit game
""")
	add_line("[color=gray]Tip: Use ↑ and ↓ to scroll through previous commands[/color]\n")
	

func universal_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"list -r":
			add_line(Inventory.list_inventory_items())
			return true
		"list -m": #List processes
			add_line(Stats.list_unlocked_processes())
			return true
		"-h":
			list_help()
			return true
		"quit -s":
			get_tree().quit()

#Root context commands
func root_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"load data-mining":
			add_line("[ .. ] loading data mining module")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] data mining module loaded")
			update_context(Context.DATA_MINING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.data_mining)
			add_line("Welcome to the data mining module.")
			list_help()
		"load log-parsing":
			add_line("[ .. ] loading log parsing module")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] log parsing module loaded")
			update_context(Context.LOG_PARSING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.log_parsing)
			add_line("Current available logs: " + str(Inventory.get_amount("logs")))
			list_help()
		"load pw-cracking":
			add_line("[ .. ] loading password cracking module")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] password cracking module loaded")
			update_context(Context.PASSWORD_CRACKING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.pw_unscramble)
			add_line("Current available scrambled passwords: " + str(Inventory.get_amount("encrypted passwords")))
			list_help()
		"load cred-matching":
			add_line("[ .. ] loading credential matching module")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] credential matching module loaded")
			update_context(Context.CRED_MATCHING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.cred_matching)
			add_line("Current available usernames & passwords")
			add_line("Passwords x" + str(Inventory.get_amount("passwords")) + "   Usernames x" + str(Inventory.get_amount("usernames")))
			list_help()
		"load hacking":
			var tween = create_tween()
			tween.tween_property(terminal_root, "modulate:a", 0.0, 1.0)
			await tween.finished
			terminal_root.visible = false
			await loading.show_loading()
			
			hacking.modulate.a = 0.0
			hacking.visible = true
			var tween2 = create_tween()
			tween2.tween_property(hacking, "modulate:a", 1.0, 0.5)
		"marketplace -auth": #Go to marketplace
			add_line("[ .. ] requesting permissions")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] permission granted")
			await get_tree().create_timer(0.5).timeout
			add_line("Connected to online marketplace")
			update_context(Context.MARKETPLACE)
			add_line(Ascii.marketplace)
			add_line("Welcome to the marketplace.")
			add_line("\nCurrent balance: " + str(Inventory.get_amount("data")) + " data")
			list_help()
		_:#default
			add_line("Command not found")

func hacking_commands(text):
	pass

#cred matching context commands
func cred_matching_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if !process_running:
				start_cred_matching()
			else:
				add_line("Credential matching already running")
		"stop":
			process_running = false
		"root":
			if process_running:
				add_line("Cannot safetly shut down module while process is running")
				add_line("Stop process to exit module")
			else:
				add_line("Safetly shutting down module")
				await get_tree().create_timer(0.8).timeout
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("Module: Credential Matching")
			add_line("Level:         " + str(Stats.player_stats["Credential Matching"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Credential Matching"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Credential Matching"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Credential Matching"]["effeciency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Credential Matching"]["effeciency description"])
		"-h":
			list_help()
		_:
			add_line("Command not found")

func start_cred_matching():

	if Inventory.get_amount("passwords") < 1 or Inventory.get_amount("usernames") < 1:
		add_line("You do not have suffecient usernames or passwords")
		return

	process_running = true
	show_module_stats_header("Credential Matching")
	cred_match.usernames = cred_match.get_initial_list()
	cred_match.highlight_index = 0
	var match_found = false
	
	
	var increase_per_line = 0.003
	add_line(cred_match.render_list(false))
	var usernames_index = lines.size() - 1
	
	var creds_created = 0
	
	while Inventory.get_amount("passwords") >= 1 and Inventory.get_amount("usernames") >= 1 and process_running:
		var chance_to_find_match = 0.0
		var roll = randf()
		await get_tree().create_timer(0.1).timeout
		while process_running and !match_found:
			cred_match.highlight_index += 1
			if roll < chance_to_find_match:
				match_found = true
			set_line(usernames_index, cred_match.render_list(match_found), false)
			await get_tree().create_timer(0.05).timeout
			chance_to_find_match += increase_per_line * (1 + Stats.player_stats["Credential Matching"]["effeciency"])

		if process_running:
			Stats.add_xp(Stats.player_stats["Credential Matching"], 450)
			update_module_stats_header("Credential Matching")
			cred_match.create_creds()
			creds_created += 1
			await get_tree().create_timer(0.3).timeout
		
			if process_running:
				if Inventory.get_amount("passwords") >= 1 and Inventory.get_amount("usernames") >= 1:
					match_found = false
					cred_match.usernames = cred_match.get_initial_list()
					cred_match.highlight_index = 0
					set_line(usernames_index, cred_match.render_list(false), false)
	if process_running:
		process_running = false
	show_process_summary("Cred Matching", creds_created, "credentials")
	add_line("Credential matching stopped")
	
	#next time
	# add summary / header
	# implement effeciency

#Log parsing context commands
func log_parsing_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if !process_running:
				start_log_parsing()
			else:
				add_line("Log parsing already running")
		"stop":
			if process_running:
				add_line("Waiting for current log to finish...")
			process_running = false
		"root":
			if process_running:
				add_line("Cannot safetly shut down module while process is running")
				add_line("Stop process to exit module")
			else:
				add_line("Safetly shutting down module")
				await get_tree().create_timer(0.8).timeout
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("Module: Log Parsing")
			add_line("Level:         " + str(Stats.player_stats["Log Parsing"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Log Parsing"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Log Parsing"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Log Parsing"]["effeciency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Log Parsing"]["effeciency description"])
		"-h":
			list_help()
		_:
			add_line("Command not found")

func password_unscramble_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			start_password_unscrambling()
		"stop":
			process_running = false
		"root":
			if process_running:
				add_line("Cannot safetly shut down module while process is running")
				add_line("Stop process to exit module")
			else:
				add_line("Safetly shutting down module")
				await get_tree().create_timer(0.8).timeout
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("Module: Password Cracking")
			add_line("Level:         " + str(Stats.player_stats["Password Cracking"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Password Cracking"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Password Cracking"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Password Cracking"]["effeciency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Password Cracking"]["effeciency description"])
		"-h":
			list_help()
		_:
			add_line("Command not found")
			

func start_password_unscrambling():
	add_line("Verifying passwords available...")
	await get_tree().create_timer(0.8).timeout
	if Inventory.get_amount("encrypted passwords") <= 0:
		add_line("No passwords available")
		return
	add_line("Starting password cracking process.\n\n")
	var pw_gained: int = 0
	await get_tree().create_timer(0.8).timeout
	process_running = true
	show_module_stats_header("Password Cracking")
	
	add_line("Cracking Password")
	add_line(pw_scram.get_initial_scrambled_word())
	var scramble_index = lines.size() - 1
	##password unscramble loop
	while Inventory.inventory["encrypted passwords"]["amount"] > 0 and process_running:
		for i in range(5):
			if !process_running:
				break
			set_line(scramble_index, pw_scram.get_current_scramble())
			await get_tree().create_timer(0.2).timeout
		if !process_running:
			break
		pw_scram.reveal_letter()
		
		#check if word is fully revealed
		if pw_scram.is_word_revealed():
			set_line(scramble_index, pw_scram.get_current_scramble())
			await get_tree().create_timer(0.4).timeout
			pw_scram.transform_password() #removes scrambled, adds password
			pw_gained += 1
			Stats.add_xp(Stats.player_stats["Password Cracking"], 200)
			update_module_stats_header("Password Cracking")
			
			if Inventory.inventory["encrypted passwords"]["amount"] <= 0:
				process_running = false
				add_line("No more encrypted passwords.")
			else:
				set_line(scramble_index, pw_scram.get_initial_scrambled_word())
				
	add_line("Finished process.")
	show_process_summary("Password Cracking", pw_gained, "Password")
			

func start_log_parsing():
	add_line("Verifying logs available...")
	await get_tree().create_timer(0.8).timeout
	if Inventory.get_amount("logs") <= 0:
		add_line("No logs available")
		return
	add_line("Starting log parsing process.\n\n")
	await get_tree().create_timer(0.8).timeout
	process_running = true
	show_module_stats_header("Log Parsing")
	start_parser_ui()
	clear_logs()
	start_log_stream()

#Builds header for module running 
func show_module_stats_header(skill_name: String):
	var skill = Stats.player_stats[skill_name]
	var level = skill["level"]
	var efficiency = skill["effeciency"]
	var xp_current = skill["experience"]
	var xp_needed = Stats.xp_for_level(level + 1)
	var xp_percent = int(float(xp_current) / xp_needed * 100)
	add_line("\n" + "[color=cyan]=== " + skill_name.to_upper() + " MODULE ===[/color]\n")
	add_line("[color=#aaaaaa]Level:[/color] [color=lime]" + str(level) + "[/color]      " + "[color=#aaaaaa]Efficiency:[/color] [color=lime]+" + str(float(efficiency * 100)) + "%[/color]")
	lvl_and_effeciency_index = lines.size() - 1
	
	# XP BAR
	add_line(get_skill_xp_bar(skill))
	skill_xp_progress_bar_index = lines.size() - 1
	
	add_line(
		"[color=#aaaaaa]XP:[/color] [color=yellow]" + str(xp_current) + "[/color] / " + "[color=yellow]" + str(xp_needed) + "[/color]"
	)
	skill_xp_nums_index = lines.size() - 1
	
	match skill_name:
		"Log Parsing":
			var chance = (LogParser.BASE_REWARD_CHANCE + efficiency) * 100.0
			chance = snapped(chance, 0.1) # rounds to 1 decimal place
			add_line("Chance to extract resource: " + str(chance) + "%\n")
			skill_specific_info_index = lines.size() - 1

#Updates built header for module running
func update_module_stats_header(skill_name: String):
	var skill = Stats.player_stats[skill_name]
	var level = skill["level"]
	var efficiency = skill["effeciency"]
	var xp_current = skill["experience"]
	var xp_needed = Stats.xp_for_level(level + 1)
	
	set_line(lvl_and_effeciency_index, "[color=#aaaaaa]Level:[/color] [color=lime]" + str(level) + "[/color]      " + "[color=#aaaaaa]Efficiency:[/color] [color=lime]+" + str(float(efficiency * 100)) + "%[/color]", false)
	
	# XP BAR
	set_line(skill_xp_progress_bar_index, get_skill_xp_bar(skill), false)
	
	set_line(skill_xp_nums_index, "[color=#aaaaaa]XP:[/color] [color=yellow]" + str(xp_current) + "[/color] / " + "[color=yellow]" + str(xp_needed) + "[/color]", false)
	
	#Skill specific text, if any
	match skill_name:
		"Log Parsing":
			var chance = (LogParser.BASE_REWARD_CHANCE + efficiency) * 100.0
			chance = snapped(chance, 0.1) # rounds to 1 decimal place
			set_line(skill_specific_info_index, "Chance to extract resource: " + str(chance) + "%\n", false)

func start_parser_ui():
	add_line(parser.border("LOG PARSER v1.0"))     # 0
	add_line(parser.line("Status: RUNNING   Logs: x" + str(Inventory.get_amount("logs"))))       # 1
	parse_box_title_line = lines.size() - 1
	add_line("├" + "─".repeat(parser.INNER_WIDTH) + "┤")  # 2

	log_start_index = lines.size()  # First log line will go here

	# Fill empty space initially
	for i in range(max_log_lines):
		add_line(parser.line(""))   # placeholder log lines

	add_line(parser.bottom())        # bottom border stays LAST

func push_log_line(new_line:String):
	# Add to buffer
	visible_logs.append(new_line)

	# Keep buffer size fixed
	if visible_logs.size() > max_log_lines:
		visible_logs.pop_front()

	# Rewrite only the log area
	for i in range(max_log_lines):
		var line_index = log_start_index + i
		var text = ""
		if i < visible_logs.size():
			text = visible_logs[i]
		else:
			text = parser.line("")

		lines[line_index] = text

	update_terminal(false)

func start_log_stream():
	reset_batch_totals()
	
	while Inventory.inventory["logs"]["amount"] > 0 and process_running:
		Inventory.inventory["logs"]["amount"] -= 1
		
		for i in range(10):
			var result = parser.generate_log_line(Logs.LOG_LINES)
			push_log_line(result.text)

			if result.reward.size() > 0:
				apply_reward(result.reward)

			await get_tree().create_timer(0.4).timeout
		
		if Inventory.inventory["logs"]["amount"] > 0 and process_running:
			clear_logs()
			
		set_line(parse_box_title_line, parser.line("Status: RUNNING   Logs: x" + str(Inventory.get_amount("logs"))), false)
		Stats.add_xp(Stats.player_stats["Log Parsing"], 500)
		update_module_stats_header("Log Parsing")
		
	if process_running:
		add_line("All logs parsed.") 
		set_line(parse_box_title_line, parser.line("Status: FINISHED   Logs: x" + str(Inventory.get_amount("logs"))))
	
	#add_line(show_batch_total())
	show_batch_total()
	add_line("Process finished")

	process_running = false

func show_batch_total():

	var output = ""
	var title_chars = 25
	for k in batch_totals.keys():
		if batch_totals[k] > 0:
			var spaces = 25 - k.length()
			output += k + " x" + str(int(batch_totals[k])) + "\n"
	if output != "":
		add_line("\nResources gained from current parsing job")
		add_line("---------------------------------------")
		add_line(output)
	else:
		add_line("No resources gained from current parsing job.")

func show_process_summary(process_name: String, amount: int, resource: String):
	add_line("\nResources gained from recent job")
	add_line("--------------------------------")
	add_line(resource + " x" + str(int(amount)))

func clear_logs():
	visible_logs.clear()

	for i in range(max_log_lines):
		var line_index = log_start_index + i
		lines[line_index] = parser.line("")

	update_terminal(false)

func reset_batch_totals():
	for k in batch_totals.keys():
		batch_totals[k] = 0

func apply_reward(reward:Dictionary):
	if reward.is_empty():
		return
	# Add to inventory
	if Inventory.inventory.has(reward.type):
		Inventory.add_resource(reward.type, reward.amount)

	
	# Add to batch summary
	if batch_totals.has(reward.type):
		print(reward.text)
		batch_totals[reward.type] += reward.amount

#Marketplace context commands
func marketplace_commands(text):
	text = text.to_lower().strip_edges()
	
	# --- BUY COMMAND PARSING ---
	if text.begins_with("buy"):
		handle_buy_command(text)
		return
		
	match text:
		"list":
			add_line(ShopItems.list_available_items())
			add_line("\nCurrent balance: " + str(Inventory.get_amount("data")) + " data")
		
		"marketplace -auth":
			add_line("Already connected to marketplace")
		"-h":
			list_help()
		"root":
			update_context(Context.ROOT)
			add_line("Saftely exiting marketplace")
			await get_tree().create_timer(0.8).timeout
			add_line(Ascii.root)
			list_help()
		_:#default
			add_line("Command not found")

#Marketplace buy command
func handle_buy_command(text: String) -> void:
	var parts = text.split(" ")
	
	var item_id := -1
	var amount := 1 # default
	
	for part in parts:
		if part.begins_with("id="):
			item_id = int(part.trim_prefix("id="))
		elif part.begins_with("a="):
			amount = int(part.trim_prefix("a="))
	
	# Validate ID
	if item_id == -1:
		add_line("Buy command not recognized")
		add_line("Usage: buy id=[itemID] a=[amount]")
		add_line("Example: buy id=0 a=12")
		return
	
	purchase_item(item_id, amount)


func purchase_item(id: int, amount: int):
	# Validate item
	if not ShopItems.items.has(id):
		add_line("Item ID not found.")
		return
	
	# Validate amount
	if amount <= 0:
		add_line("Invalid purchase amount.")
		return
	
	var item = ShopItems.items[id]
	
	add_line("Sending order...")
	await get_tree().create_timer(0.5).timeout
	
	# Check availability
	if not item.get("available", false):
		add_line("Item is not available.")
		return
	
	var player_money = Inventory.get_amount("data")
	var cost_per_item = item["cost"]
	var total_cost = cost_per_item * amount
	
	# Check funds
	if player_money < total_cost:
		add_line("Not enough Data. Need " + str(total_cost) + ", you have " + str(player_money) + ".")
		return
	

	add_line("Order received")
	await get_tree().create_timer(0.5).timeout
	add_line("Transfering funds")
	await get_tree().create_timer(0.2).timeout
	add_line("Funds received")
	await get_tree().create_timer(0.2).timeout
	add_line("Downloading items")
	await get_tree().create_timer(1.0).timeout
	#
	# Deduct cost
	#idk why this is here, this should never be hit if the above statement exists
	if not Inventory.remove_resource("data", total_cost):
		add_line("Transaction failed.")
		return
	
	# Grant rewards
	ShopItems.grant_item_reward(item, amount)
	
	add_line("Purchased x" + str(amount) + " " + item["name"] + " for " + str(total_cost) + " Data.")

#Data mining context commands
func data_mining_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if !process_running:
				start_data_mining()
			else:
				add_line("Process already running")
		"stop":
			process_running = false
		"root":
			if process_running:
				add_line("Cannot safetly shut down module while process is running")
				add_line("Stop process to exit module")
			else:
				add_line("Safetly shutting down module")
				await get_tree().create_timer(0.8).timeout
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("Module: Data Mining")
			add_line("Level:         " + str(Stats.player_stats["Data Mining"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Data Mining"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Data Mining"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Data Mining"]["effeciency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Data Mining"]["effeciency description"])
		"-h":
			list_help()
		_:
			add_line("Command not found")

func start_data_mining():
	add_line("Initializing Data Mining module...")
	await get_tree().create_timer(0.6).timeout
	show_module_stats_header("Data Mining")
	
	var skill = Stats.player_stats["Data Mining"]
	var efficiency = skill["effeciency"]
	
	add_line("\n" + "--- Process Running ---")
	add_line("Progress: [                    ] 0%")
	var progress_bar_index = lines.size() - 1
	
	var amount_gained: int = 0
	
	var duration = 5.0 / (1 + efficiency)
	var yield_amount = snapped(1.0 / duration, 0.01)
	
	var data_per_completion = 2.0
	add_line("\nData per completion: " + str(data_per_completion))
	add_line("Yield:    +" + str(yield_amount) + " data/sec")
	var yield_text_index = lines.size() - 1
	add_line("Session:  " + str(amount_gained) + " data")
	var total_gained_index = lines.size() - 1
	
	add_line("Total:    " + str(Inventory.get_amount("data")) + " data\n\n\n")
	var total_data_line_index = lines.size() - 1
	
	var steps = 20
	var interval = duration / steps
	process_running = true
	var exp_per_completion = 250
	
	while process_running:
		#calc process length
		duration = 5.0 / (1 + Stats.player_stats["Data Mining"]["effeciency"])
		interval = duration / steps
		yield_amount = snapped(data_per_completion / duration, 0.01)
		set_line(yield_text_index, "Yield:    +" + str(yield_amount) + " data/sec")
		for i in range(1, steps + 1):
			if process_running:
				await get_tree().create_timer(interval).timeout
				if process_running:
					var filled = "=".repeat(i)
					var empty = " ".repeat(steps - i)
					var percent = int(float(i) / steps * 100)
					set_line(progress_bar_index, "Progress: [%s>%s] %d%%" % [filled, empty, percent], false)
		
		if process_running:
			Inventory.add_resource("data", data_per_completion)
			amount_gained += data_per_completion
			Stats.add_xp(skill, exp_per_completion)
			
			# Refresh live stats
			var new_xp = skill["experience"]
			var new_needed = Stats.xp_for_level(skill["level"] + 1)
			
			efficiency = skill["effeciency"]
			update_module_stats_header("Data Mining")
			set_line(total_gained_index, "Session:  " + str(amount_gained) + " data", false)
			set_line(total_data_line_index, "Total:    " + str(Inventory.get_amount("data")) + " data\n\n\n", false)
	show_process_summary("Data Mining", amount_gained, "Data")

func get_skill_xp_bar(skill_data: Dictionary, steps:int = 20) -> String:
	var progress = Stats.get_xp_progress(skill_data)
	var filled_steps = int(progress * steps)

	var filled = "=".repeat(filled_steps)
	var empty = " ".repeat(steps - filled_steps)
	var percent = int(progress * 100)

	return "[%s>%s] %d%%" % [filled, empty, percent]

#used when navigating past commands with up/down arrows
func _move_caret_to_end():
	input_line.caret_column = input_line.text.length()

#handle up/down input for history commands
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_UP:
			navigate_history(-1)
		elif event.keycode == Key.KEY_DOWN:
			navigate_history(1)

#command history functionality
func navigate_history(delta: int):
	if command_history.size() == 0:
		return
	
	if history_index == -1:
		history_index = command_history.size()
	
	history_index = clamp(history_index + delta, 0, command_history.size() - 1)
	
	input_line.text = command_history[history_index]

	call_deferred("_move_caret_to_end")
