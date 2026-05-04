extends Control

###NEXT
# BUG: FIX TYPING COMMANDS DURING WAIT PERIODS (maybe implement queue system?)

#next:
#build module for cache decrypting
#finish building out cacheEntry's for each hacking target. use what resources are available and can change later
#add ability to sell stuff in store (ie parents credit card item), maybe give everything a value that can be sold
#offline progression
#save/load

#Laterz:
# pw cracking - show efficiency info and how many encrypted pw available
# cred matching - show how many username/pw available
# log parsing - issue when trying to stop while overheated, takes a second for resources gained message to show up
# log parsing - show players % chance for each resource (40% Data, 29% username etc)
# hacking - update UI and redo sequencial logic so everything is happening at the same time, making it more 'idle' ish
# hacking - think through idea of difficulty per person / area
# think through idea of adding upgrades to process/modules. maybe an item for gaining a level (mastery token esque)
# take another shot at adding a side screen panel that pops in for messages/item gains, maybe bottom right, above typing box?

#module ideas:
#Defragging - takes a long time (30min-1h) gives long term (or even perm) benefits
#non-idle module: Jailbreak / heist mode: use commands to open/close doors to get someone in and out
# Cache decrypting: extract resources from caches received from hacking


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

@onready var logparsing_timer = $Timers/LogparsingTimer
@onready var cooling_timer = $Timers/CoolingTimer

@onready var parser = LogParser.new()
@onready var pw_scram = PasswordCrack.new()
@onready var cred_match = CredentialMatching.new()
@onready var cache_decrypt = CacheDecrypting.new()


enum Context {
	ROOT,
	DATA_MINING,
	LOG_PARSING,
	PASSWORD_CRACKING,
	CRED_MATCHING,
	HACKING,
	DARKWEB,
	MARKETPLACE,
	CACHE_DECRYPTING,
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
var lvl_and_efficiency_index: int
var skill_xp_progress_bar_index: int
var skill_xp_nums_index: int
var skill_specific_info_index: int
#END SKILL HEADER VARIABLES#

var LOG_PARSE_SPEED = 0.4


func _ready():
	update_context(Context.ROOT)
	input_line.grab_focus() #uncomment this when not testing hacking module
	add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")
	Signals.system_temp_updated(30)
	
	#cooling timer
	cooling_timer.wait_time = Stats.cooling_frequency
	cooling_timer.start()

#update previous lines
func set_line(index: int, text: String, scroll_to_line: bool = false):
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
			Context.CACHE_DECRYPTING:
				cache_decrypting_commands(new_text)

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
		Context.CACHE_DECRYPTING:
			return "IdleOS/Modules/CacheDecrypting>"

#Changes context and updates leading text
func update_context(new_context: Context):
	current_context = new_context
	lead_text.text = get_context_lead()

func list_help():
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
overclock               Overclocks the system to massively increase output, also increases system heat
overclock -kill         Stops overclocking
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
		Context.CACHE_DECRYPTING:
			add_line("""
	[CACHE DECRYPTING COMMANDS]
start                   Start cache decrypting process
stop                    Stop cache decrypting process
root                    Exit back to root
info                    Cache decrypting module stats
""")
	
	add_line("""Usage: [command] [flag]

Item Management:
  list -a               Lists all items
  list -r               List all resources (items with specific uses)
  list -v               List all valuables (items only meant to be sold)
  list -c               List all caches (items needing decrypting for more items)

Module Management:
  list -m               List available modules

General:
  -h                    View this help message
  quit -s               Save and quit game
""")
	add_line("[color=gray]Tip: Use ↑ and ↓ to scroll through previous commands[/color]\n")
	

func universal_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"list -r":
			add_line(Inventory.list_inventory(Inventory.InventoryFilter.RESOURCES))
			return true
		"list -a":
			add_line(Inventory.list_inventory())
			return true
		"list -v":
			add_line(Inventory.list_inventory(Inventory.InventoryFilter.VALUABLES))
			return true
		"list -c":
			add_line(Inventory.list_inventory(Inventory.InventoryFilter.CACHES))
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
			if Stats.player_stats["Data Mining"].unlocked:
				add_line("[ .. ] loading data mining module")
				await get_tree().create_timer(0.8).timeout
				add_line("[ OK ] data mining module loaded")
				update_context(Context.DATA_MINING)
				await get_tree().create_timer(0.5).timeout
				add_line(Ascii.data_mining)
				add_line("Welcome to the data mining module.")
				list_help()
			else:
				add_line("Module not found, must be purchased from the marketplace.")
		"load log-parsing":
			if Stats.player_stats["Log Parsing"].unlocked:
				add_line("[ .. ] loading log parsing module")
				await get_tree().create_timer(0.8).timeout
				add_line("[ OK ] log parsing module loaded")
				update_context(Context.LOG_PARSING)
				await get_tree().create_timer(0.5).timeout
				add_line(Ascii.log_parsing)
				add_line("Current available logs: " + str(Inventory.get_amount(Items.LOGS)))
				list_help()
			else:
				add_line("Module not found, must be purchased from the marketplace.")
		"load pw-cracking":
			if Stats.player_stats["Password Cracking"].unlocked:
				add_line("[ .. ] loading password cracking module")
				await get_tree().create_timer(0.8).timeout
				add_line("[ OK ] password cracking module loaded")
				update_context(Context.PASSWORD_CRACKING)
				await get_tree().create_timer(0.5).timeout
				add_line(Ascii.pw_unscramble)
				add_line("Current available scrambled passwords: " + str(Inventory.get_amount(Items.ENCRYPTED_PASSWORDS)))
				list_help()
			else:
				add_line("Module not found, must be purchased from the marketplace.")
		"load cred-matching":
			if Stats.player_stats["Credential Matching"].unlocked:
				add_line("[ .. ] loading credential matching module")
				await get_tree().create_timer(0.8).timeout
				add_line("[ OK ] credential matching module loaded")
				update_context(Context.CRED_MATCHING)
				await get_tree().create_timer(0.5).timeout
				add_line(Ascii.cred_matching)
				add_line("Current available usernames & passwords")
				add_line("Passwords x" + str(Inventory.get_amount(Items.PASSWORDS)) + "   Usernames x" + str(Inventory.get_amount(Items.USERNAMES)))
				list_help()
			else:
				add_line("Module not found, must be purchased from the marketplace.")
		"load hacking":
			if Stats.player_stats["Hacking"].unlocked:
				var tween = create_tween()
				tween.tween_property(terminal_root, "modulate:a", 0.0, 0.5)
				await tween.finished
				terminal_root.visible = false
				await loading.show_loading()
				
				hacking.module_loaded()
			else:
				add_line("Module not found, must be purchased from the marketplace.")
		"marketplace -auth": #Go to marketplace
			add_line("[ .. ] requesting permissions")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] permission granted")
			await get_tree().create_timer(0.5).timeout
			add_line("Connected to online marketplace")
			update_context(Context.MARKETPLACE)
			add_line(Ascii.marketplace)
			add_line("Welcome to the marketplace.")
			add_line("\nCurrent balance: " + str(Inventory.get_amount(Items.DATA)) + " data")
			list_help()
		"load cache-decrypting":
			if Stats.player_stats["Cache Decrypting"].unlocked:
				add_line("[ .. ] loading cache decrypting module")
				await get_tree().create_timer(0.8).timeout
				add_line("[ OK ] cache decrypting module loaded")
				update_context(Context.CACHE_DECRYPTING)
				await get_tree().create_timer(0.5).timeout
				add_line(Ascii.cache_decrypting)
				list_help()
			else:
				add_line("Module not found, must be purchased from the marketplace.")
		_:#default
			add_line("Command not found")

#cache decrypting context commands
func cache_decrypting_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if !process_running:
				start_cache_decrypting()
			else:
				add_line("Cache decrypting is already running")
		"stop":
			process_running = false
			Stats.overclocked = false
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
			add_line("Module: Cache Decrypting")
			add_line("Level:         " + str(Stats.player_stats["Cache Decrypting"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Cache Decrypting"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Cache Decrypting"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Cache Decrypting"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Cache Decrypting"]["efficiency description"])
		"-h":
			list_help()
		"overclock":
			if !Stats.overclocked and process_running and !Stats.overheated:
				if Stats.system_tempature < 60:
					Stats.overclocked = true
				else:
					add_line("System tempature needs to cool to below 60°C before overclocking")
			elif process_running and Stats.overheated:
				add_line("System has been overheated, needs to cool to below 40°C.")
			else:
				add_line("System is already overclocked.")
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_cache_decrypting():
	#here
	
	#check for cache
	if !Inventory.has_cache():
		add_line("No cache")
		return
		
	
	show_module_stats_header("Cache Decrypting")
	var current_cache = Inventory.get_cache()
	
	#build body
	add_line(cache_decrypt.get_starting_dump(current_cache))
	
	
	
	#build body of hex dump - 3 main columns (0x0000 | 43 35 12 23 | nameOfItem)
	#number of rows = how many items can be potentially gained from cache
	#-------------
	#2 columns - Decoded (each row is name of item and amount gained) : Encrypted Rare slot (maybe try to build suspense if it will 'drop'
	
	#

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
			Stats.overclocked = false
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
			var eff = Stats.player_stats["Credential Matching"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Credential Matching"]["efficiency description"])
		"-h":
			list_help()
		"overclock":
			if !Stats.overclocked and process_running and !Stats.overheated:
				if Stats.system_tempature < 60:
					Stats.overclocked = true
				else:
					add_line("System tempature needs to cool to below 60°C before overclocking")
			elif process_running and Stats.overheated:
				add_line("System has been overheated, needs to cool to below 40°C.")
			else:
				add_line("System is already overclocked.")
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_cred_matching():

	if Inventory.get_amount(Items.PASSWORDS) < 1 or Inventory.get_amount(Items.USERNAMES) < 1:
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
	
	while Inventory.get_amount(Items.PASSWORDS) >= 1 and Inventory.get_amount(Items.USERNAMES) >= 1 and process_running:
		var chance_to_find_match = 0.0
		var roll = randf()
		await get_tree().create_timer(0.1).timeout
		while process_running and !match_found:
			cred_match.highlight_index += 1
			if roll < chance_to_find_match:
				match_found = true
			set_line(usernames_index, cred_match.render_list(match_found), false)
			if Stats.overclocked:
				await get_tree().create_timer(Stats.player_stats["Credential Matching"]["overclock speed"]).timeout
			elif Stats.overheated:
				await get_tree().create_timer(Stats.player_stats["Credential Matching"]["overheat speed"]).timeout
			else:
				await get_tree().create_timer(Stats.player_stats["Credential Matching"]["speed"]).timeout
			chance_to_find_match += increase_per_line * (1 + Stats.player_stats["Credential Matching"]["efficiency"])

		if process_running:
			if Stats.overclocked:
				Stats.update_tempature(Stats.player_stats["Credential Matching"]["overclock heat"])
			else:
				Stats.update_tempature(Stats.player_stats["Credential Matching"]["heat"]) #increase tempature
			Stats.add_xp(Stats.player_stats["Credential Matching"], 450)
			update_module_stats_header("Credential Matching")
			cred_match.create_creds()
			creds_created += 1
			await get_tree().create_timer(0.3).timeout
		
			if process_running:
				if Inventory.get_amount(Items.PASSWORDS) >= 1 and Inventory.get_amount(Items.USERNAMES) >= 1:
					match_found = false
					cred_match.usernames = cred_match.get_initial_list()
					cred_match.highlight_index = 0
					set_line(usernames_index, cred_match.render_list(false), false)
	if process_running:
		process_running = false
	show_process_summary("Cred Matching", creds_created, Items.CREDENTIALS)
	add_line("Credential matching stopped")
	
	#next time
	# add summary / header
	# implement efficiency

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
				add_line("Log parsing process stopped.")
			process_running = false
			Stats.overclocked = false
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
			var eff = Stats.player_stats["Log Parsing"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Log Parsing"]["efficiency description"])
		"-h":
			list_help()
		"overclock":
			if !Stats.overclocked and process_running and !Stats.overheated:
				if Stats.system_tempature < 60:
					Stats.overclocked = true
				else:
					add_line("System tempature needs to cool to below 60°C before overclocking")
			elif process_running and Stats.overheated:
				add_line("System has been overheated, needs to cool to below 40°C.")
			else:
				add_line("System is already overclocked.")
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func password_unscramble_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			start_password_unscrambling()
		"stop":
			process_running = false
			Stats.overclocked = false
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
			var eff = Stats.player_stats["Password Cracking"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Password Cracking"]["efficiency description"])
		"-h":
			list_help()
		"overclock":
			if !Stats.overclocked and process_running and !Stats.overheated:
				if Stats.system_tempature < 60:
					Stats.overclocked = true
				else:
					add_line("System tempature needs to cool to below 60°C before overclocking")
			elif process_running and Stats.overheated:
				add_line("System has been overheated, needs to cool to below 40°C.")
			else:
				add_line("System is already overclocked.")
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")
			

func start_password_unscrambling():
	add_line("Verifying passwords available...")
	await get_tree().create_timer(0.8).timeout
	if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
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
	while Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) > 0 and process_running:
		for i in range(15):
			if !process_running:
				break
			set_line(scramble_index, pw_scram.get_current_scramble())
			if Stats.overclocked:
				await get_tree().create_timer(Stats.player_stats["Password Cracking"]["overclock speed"]).timeout
			elif Stats.overheated:
				await get_tree().create_timer(Stats.player_stats["Password Cracking"]["overheat speed"]).timeout
			else:
				await get_tree().create_timer(Stats.player_stats["Password Cracking"]["speed"]).timeout
		if !process_running:
			break
		pw_scram.reveal_letter()
		if Stats.overclocked:
			Stats.update_tempature(Stats.player_stats["Password Cracking"]["overclock heat"])
		else:
			Stats.update_tempature(Stats.player_stats["Password Cracking"]["heat"])
		#check if word is fully revealed
		if pw_scram.is_word_revealed():
			set_line(scramble_index, pw_scram.get_current_scramble())
			await get_tree().create_timer(0.4).timeout
			pw_scram.transform_password() #removes scrambled, adds password
			pw_gained += 1

			Stats.add_xp(Stats.player_stats["Password Cracking"], 200)
			update_module_stats_header("Password Cracking")
			
			if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
				process_running = false
				add_line("No more encrypted passwords.")
			else:
				set_line(scramble_index, pw_scram.get_initial_scrambled_word())
				
	add_line("Finished process.")
	show_process_summary("Password Cracking", pw_gained, Items.PASSWORDS)
			

func start_log_parsing():
	add_line("Verifying logs available...")
	await get_tree().create_timer(0.8).timeout
	if Inventory.get_amount(Items.LOGS) <= 0:
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
	var efficiency = skill["efficiency"]
	var xp_current = skill["experience"]
	var xp_needed = Stats.xp_for_level(level + 1)
	var xp_percent = int(float(xp_current) / xp_needed * 100)
	add_line("\n" + "[color=cyan]=== " + skill_name.to_upper() + " MODULE ===[/color]\n")
	add_line("[color=#aaaaaa]Level:[/color] [color=lime]" + str(level) + "[/color]      " + "[color=#aaaaaa]Efficiency:[/color] [color=lime]+" + str(float(efficiency * 100)) + "%[/color]")
	lvl_and_efficiency_index = lines.size() - 1
	
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
	var efficiency = skill["efficiency"]
	var xp_current = skill["experience"]
	var xp_needed = Stats.xp_for_level(level + 1)
	
	set_line(lvl_and_efficiency_index, "[color=#aaaaaa]Level:[/color] [color=lime]" + str(level) + "[/color]      " + "[color=#aaaaaa]Efficiency:[/color] [color=lime]+" + str(float(efficiency * 100)) + "%[/color]", false)
	
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
	add_line(parser.line("Status: RUNNING   Logs: x" + str(Inventory.get_amount(Items.LOGS))))       # 1
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
	
	while Inventory.get_amount(Items.LOGS) > 0 and process_running:
		Inventory.remove_resource(Items.LOGS, 1)
		
		for i in range(10):
			if process_running:
				var result = parser.generate_log_line(Logs.LOG_LINES)
				push_log_line(result.text)

				if result.reward.size() > 0:
					apply_reward(result.reward)
				
				if Stats.overclocked:
					await get_tree().create_timer(Stats.player_stats["Log Parsing"]["overclock speed"]).timeout
				elif Stats.overheated:
					await get_tree().create_timer(Stats.player_stats["Log Parsing"]["overheat speed"]).timeout
				else:
					await get_tree().create_timer(Stats.player_stats["Log Parsing"]["base speed"]).timeout
		
		if Inventory.get_amount(Items.LOGS) > 0 and process_running:
			clear_logs()
			
		set_line(parse_box_title_line, parser.line("Status: RUNNING   Logs: x" + str(Inventory.get_amount(Items.LOGS))), false)
		Stats.update_tempature(Stats.player_stats["Log Parsing"]["heat"]) #increase tempature
		Stats.add_xp(Stats.player_stats["Log Parsing"], 500)
		update_module_stats_header("Log Parsing")
		
	if process_running:
		add_line("All logs parsed.") 
		set_line(parse_box_title_line, parser.line("Status: FINISHED   Logs: x" + str(Inventory.get_amount(Items.LOGS))))
	
	#add_line(show_batch_total())
	show_batch_total()
	add_line("Process finished")

	process_running = false

func show_batch_total():
	if batch_totals.is_empty():
		add_line("No resources gained from current parsing job.")
		return

	var output := ""

	for item in batch_totals.keys():
		var amount: int = batch_totals[item]
		if amount > 0:
			output += "%s x%d\n" % [item.name, amount]

	add_line("\nResources gained from current parsing job")
	add_line("---------------------------------------")
	add_line(output)

func show_process_summary(process_name: String, amount: int, resource: ItemData):
	add_line("\nResources gained from recent job")
	add_line("--------------------------------")
	add_line(resource.name + " x" + str(int(amount)))

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
	Inventory.add_resource(reward.item, reward.amount)

	# Add to batch summary
	if batch_totals.has(reward.item):
		batch_totals[reward.item] += reward.amount
	else:
		batch_totals[reward.item] = reward.amount

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
			add_line("\nCurrent balance: " + str(Inventory.get_amount(Items.DATA)) + " data")
		
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
	if item["type"] == ShopItems.ItemType.MODULE and amount != 1:
		amount = 1
		add_line("Limited to 1 module per purchase. Adjusting amount to 1.")
		await get_tree().create_timer(0.5).timeout
		
	add_line("Sending order...")
	await get_tree().create_timer(0.5).timeout
	
	# Check availability
	if not item.get("available", false):
		add_line("Item is not available.")
		return
	
	var player_money = Inventory.get_amount(Items.DATA)
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
	if not Inventory.remove_resource(Items.DATA, total_cost):
		add_line("Transaction failed.")
		return
	
	# Grant rewards
	ShopItems.grant_item_reward(item, amount)
	var output_string = "Purchased x" + str(amount) + " " + item["name"]
	if item["type"] == ShopItems.ItemType.MODULE:
		output_string += " module"
	output_string += " for " + str(total_cost) + " Data."
	add_line(output_string)

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
			Stats.overclocked = false
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
			var eff = Stats.player_stats["Data Mining"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Data Mining"]["efficiency description"])
		"-h":
			list_help()
		"overclock":
			if !Stats.overclocked and process_running and !Stats.overheated:
				if Stats.system_tempature < 60:
					Stats.overclocked = true
				else:
					add_line("System cannot activate overclock unless below 60°C")
			elif process_running and Stats.overheated:
				add_line("System has been overheated, needs to cool to below 40C.")
			else:
				add_line("System is already overclocked.")
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_data_mining():
	add_line("Initializing Data Mining module...")
	await get_tree().create_timer(0.6).timeout
	show_module_stats_header("Data Mining")
	
	var skill = Stats.player_stats["Data Mining"]
	var efficiency = skill["efficiency"]
	
	add_line("\n" + "--- Process Running ---")
	add_line("Progress: [                    ] 0%")
	var progress_bar_index = lines.size() - 1
	
	var amount_gained: int = 0
	var dur_amount = 2.5
	var yield_amount = snapped(1.0 / dur_amount, 0.01)
	
	var data_per_completion = 1.0
	add_line("\nData per completion: " + str(data_per_completion))
	add_line("Yield:    +" + str(yield_amount) + " data/sec")
	var yield_text_index = lines.size() - 1
	add_line("Session:  " + str(amount_gained) + " data")
	var total_gained_index = lines.size() - 1
	
	add_line("Total:    " + str(Inventory.get_amount(Items.DATA)) + " data\n\n\n")
	var total_data_line_index = lines.size() - 1
	
	var steps = 20
	#var interval = duration / steps
	process_running = true
	var exp_per_completion = 250
	var interval
	
	while process_running:
		#calc process length
		var og_interval = dur_amount / steps
		var overclock_interval = og_interval / 5
		yield_amount = snapped(data_per_completion / dur_amount, 0.01)
		set_line(yield_text_index, "Yield:    +" + str(yield_amount) + " data/sec")
		for i in range(1, steps + 1):
			if process_running:
				if Stats.overheated:
					interval = 2.0
				elif Stats.overclocked:
					interval = overclock_interval
				else:
					interval = og_interval
				await get_tree().create_timer(interval).timeout
				if process_running:
					var filled = "=".repeat(i)
					var empty = " ".repeat(steps - i)
					var percent = int(float(i) / steps * 100)
					set_line(progress_bar_index, "Progress: [%s>%s] %d%%" % [filled, empty, percent], false)
		
		if process_running:
			var eff = Stats.player_stats["Data Mining"]["efficiency"]
			var quant = 1

			# Guaranteed bonus for each full point of efficiency
			var guaranteed = int(eff)
			quant += guaranteed
			eff -= guaranteed  # leftover fractional part, e.g. 0.5

			# Probabilistic roll for the remaining fraction
			if eff > 0.0:
				if randf() <= eff:
					quant += 1
			Inventory.add_resource(Items.DATA, data_per_completion * quant)
			amount_gained += data_per_completion * quant
			Stats.add_xp(skill, exp_per_completion)
			
			#increase tempature
			if Stats.overclocked:
				Stats.update_tempature(Stats.player_stats["Data Mining"]["overclock heat"])
			else:
				Stats.update_tempature(Stats.player_stats["Data Mining"]["heat"])
			
			# Refresh live stats
			var new_xp = skill["experience"]
			var new_needed = Stats.xp_for_level(skill["level"] + 1)
			
			efficiency = skill["efficiency"]
			update_module_stats_header("Data Mining")
			set_line(total_gained_index, "Session:  " + str(amount_gained) + " data", false)
			set_line(total_data_line_index, "Total:    " + str(Inventory.get_amount(Items.DATA)) + " data\n\n\n", false)
	show_process_summary("Data Mining", amount_gained, Items.DATA)

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
		if event.keycode == KEY_TAB:
			get_viewport().set_input_as_handled()
			return
	if current_context != Context.HACKING:
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


func _on_hacking_start_loading() -> void:
	await loading.show_loading()
	terminal_root.modulate.a = 0.0
	terminal_root.visible = true
	input_line.grab_focus()
	var tween = create_tween()
	tween.tween_property(terminal_root, "modulate:a", 1.0, 1.0)
	await tween.finished


func _on_cooling_timer_timeout():
	Stats.update_tempature(Stats.cooling_amount)
