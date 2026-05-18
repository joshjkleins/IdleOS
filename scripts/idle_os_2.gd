extends Control

###NEXT
# BUG: FIX TYPING COMMANDS DURING WAIT PERIODS (maybe implement queue system?)

#TODO
# Finish implementing new idea of generalizing modules (cracking/matching/decryption left)
# Marketplace overhaul
#    -Ability to sell valuables
#    -Create contracts and make available w/ algo on when/what appears
#    -Contract types: Hack specific target x times, looking for 3 of x item, will pay inflated value, take 50 encrypted passwords and decrypt them to return them 
#finish hacking TODO's
# add logic that makes terminal like hacking (ie sequential so its easier to follow)
# Phishing - way to maybe get IP addresses or usernames or PW? 

#save/load
#offline progression


#item ideas:
#ONE TIME USES
#Virtual machine tokens - consume to open a new window to run a process for x amount of time
#Efficiency token - consume to increase efficiency of process by 2x for 30 seconds
#Packet spoofers - restores anonymity during hack
#Hardware accelerators - use to rapidly cool CPU for 10 second
#

##Ideas for generalizing modules and adding unlocks at certain levels
#MINING LVL1: Data, LVL10: Logs, LVL20: Quality Data, LVL40: Quality Logs
#PARSING LVL1: Logs (data, pw), LVL10: Logs (username, IP), LVL 20: Quality Logs (Quality Data, pw, un, ip), LVL 30: Specific parsing (only data/pw/un/ip/ found, no longer random mix)
#CRACKING LVL1: Password (encrypted > regular), LVL 30: IP Address (change how they work, uncracked IP address = random hack target, cracked = you know who it is?)
#MATCHING LVL1: Credentials (pw + un = cred), LVL 10: Logs (8 logs = dense log)
#DECRYPTION LVL 1: Caches (decrypt for resource drops), LVL 10: Valuable cache (much slower, no non-rare drops, doubles chance of rare drops), LVL 20: Resource cache (slower, no rare drops, higher quantity of regular drops)


#STEPS FOR ADDING NEW MODULE
#1. ADD TO CONTEXT ENUM
#2. ADD TO GET_CONTEXT_LEAD FUNC
#3. ADD TO INPUT_LINE_SUBMITTED & ADD RELEVENT FUNCTION
#4. ADD TO ROOT COMMAND CONTEXT
#5. ADD LIST HELP CONTEXT

@onready var lead_text = $Panel/MarginContainer/TerminalRoot/InputLineContainer/LeadText
@onready var input_line = $Panel/MarginContainer/TerminalRoot/InputLineContainer/InputLine
@onready var loading = $Panel/MarginContainer/Loading
@onready var terminal_root = $Panel/MarginContainer/TerminalRoot
@onready var hacking = $Panel/MarginContainer/Hacking
@onready var original_scrollback = $Panel/MarginContainer/TerminalRoot/TerminalBody/TerminalBodyContainer/Scrollback
@onready var terminal_body = $Panel/MarginContainer/TerminalRoot/TerminalBody
@onready var terminal_body_container = $Panel/MarginContainer/TerminalRoot/TerminalBody/TerminalBodyContainer
@onready var logparsing_timer = $Timers/LogparsingTimer
@onready var cooling_timer = $Timers/CoolingTimer

@onready var scrollback = preload("res://scenes/scrollback.tscn")
@onready var mining_scene = preload("res://scenes/data_mining_terminal.tscn")
@onready var log_parsing_scene = preload("res://scenes/log_parsing_terminal.tscn")
@onready var pw_cracking_scene = preload("res://scenes/pw_cracking_terminal.tscn")
@onready var cred_matching_scene = preload("res://scenes/cred_matching_terminal.tscn")
@onready var cache_decrypt_scene = preload("res://scenes/cache_decrypt_terminal.tscn")


enum Context {
	ROOT,
	MINING,
	PARSING,
	PASSWORD_CRACKING,
	CRED_MATCHING,
	HACKING,
	DARKWEB,
	MARKETPLACE,
	CACHE_DECRYPTING,
}

var current_scrollback
var current_context: Context = Context.ROOT
var current_process
var lines: Array[String] = []

#past commands using up/down
var command_history = []
var history_index = -1
#end past commands

#module related
var module_running: bool = false
var process_running: bool = false

#SKILL HEADER VARIABLES#
var lvl_and_efficiency_index: int
var skill_xp_progress_bar_index: int
var skill_xp_nums_index: int
var skill_specific_info_index: int
#END SKILL HEADER VARIABLES#

var RICHTEXT_LABEL_LINE_LIMIT = 20 #lines per richtextlabel (aka terminal read) before creating a new one
var RICHTEXT_LABEL_LIMIT = 10 #amount of richtextlabels before starting to remove old ones

func _ready():
	current_scrollback = original_scrollback
	update_context(Context.ROOT)
	input_line.grab_focus() #uncomment this when not testing hacking module
	add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")
	Signals.system_temp_updated(30)
	
	Signals.update_module_header_signal.connect(update_module_stats_header)
	Signals.end_log_parsing_safely_signal.connect(log_parsing_ended_safely)
	Signals.end_pw_cracking_safely_signal.connect(password_cracking_ended_safely)
	Signals.end_cache_decrypting_safely_signal.connect(cache_decrypting_ended_safely)
	Signals.end_data_mining_safely_signal.connect(data_mining_ended_safely)
	Signals.end_cred_matching_safely_signal.connect(cred_matching_ended_safely)
	
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
	current_scrollback.text = "\n".join(lines)
	if scroll_to_line:
		current_scrollback.scroll_to_line(current_scrollback.get_line_count() - 1)
	
		_scroll_to_bottom()
	
	if lines.size() > RICHTEXT_LABEL_LINE_LIMIT:
		add_new_scrollback()

func bring_process_to_bottom():
	if current_process:
		terminal_body_container.move_child(current_process, -1)
		add_new_scrollback()

func add_new_scrollback():
	lines.clear()
	var ns = scrollback.instantiate()
	terminal_body_container.add_child(ns)
	current_scrollback = ns
	print("adding new scrollback")
	var terminals_active = terminal_body_container.get_child_count()

	if terminals_active > RICHTEXT_LABEL_LIMIT:
		var label_to_remove = terminal_body_container.get_child(0)
		if label_to_remove == current_process: #prevents removing currently running process
			label_to_remove = terminal_body_container.get_child(1)
		label_to_remove.queue_free()
		print('removing old scrollback')

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
			Context.MINING:
				mining_commands(new_text)
			Context.PARSING:
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
			Signals.update_hud_root()
			return "IdleOS>"
		Context.DARKWEB:
			return "IdleOS/Darkweb>"
		Context.MARKETPLACE:
			return "IdleOS/Marketplace>"
		Context.MINING:
			Signals.update_hud(Mining)
			return "IdleOS/Modules/Mining>"
		Context.PARSING:
			Signals.update_hud(Parsing)
			return "IdleOS/Modules/Parsing>"
		Context.PASSWORD_CRACKING:
			Signals.update_hud(Stats.player_stats["Password Cracking"])
			return "IdleOS/Modules/PasswordCracking>"
		Context.CRED_MATCHING:
			Signals.update_hud(Stats.player_stats["Credential Matching"])
			return "IdleOS/Modules/CredentialMatching>"
		Context.HACKING:
			return "IdleOS/Modules/Hacking>"
		Context.CACHE_DECRYPTING:
			Signals.update_hud(Stats.player_stats["Cache Decrypting"])
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
load [module name]      Load a module (example: "load mining")
marketplace -auth       Connects to the marketplace
""")
		Context.MARKETPLACE:
			add_line("""
[MARKETPLACE COMMANDS]
list                          List items to purchase
buy id=[itemID] a=[amount]    Purchase x amount of items (default amount = 1)
root                          Disconnect from market
""")
		Context.MINING:
			add_line("""
[DATA MINING COMMANDS]
start                   Start mining data
stop                    Stop mining process
root                    Exit back to root
info                    Mining data module stats
overclock               Overclocks the system to massively increase output, also increases system heat
overclock -kill         Stops overclocking
""")
		Context.PARSING:
			add_line("""
[PARSING COMMANDS]
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
focus                   Bring current process into view
root                    Exit back to root
info                    Cache decrypting module stats
""")
	
	add_line("""Usage: [command] [flag]

Item Management:
  list -a               List all items
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
		"load mining":
			add_line("[ .. ] loading data mining module")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] data mining module loaded")
			update_context(Context.MINING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.mining)
			add_line("Welcome to the mining module.")
		"load parsing":
			add_line("[ .. ] loading parsing module")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] parsing module loaded")
			update_context(Context.PARSING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.parsing)
			add_line("Current available logs: " + str(Inventory.get_amount(Items.LOGS)))
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
				add_line("Module not found.")
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
				add_line("Module not found.")
		"load hacking":
			if Stats.player_stats["Hacking"].unlocked:
				var tween = create_tween()
				tween.tween_property(terminal_root, "modulate:a", 0.0, 0.5)
				await tween.finished
				terminal_root.visible = false
				await loading.show_loading()
				
				hacking.module_loaded()
			else:
				add_line("Module not found.")
		#"marketplace -auth": #Go to marketplace
			#add_line("[ .. ] requesting permissions")
			#await get_tree().create_timer(0.8).timeout
			#add_line("[ OK ] permission granted")
			#await get_tree().create_timer(0.5).timeout
			#add_line("Connected to online marketplace")
			#update_context(Context.MARKETPLACE)
			#add_line(Ascii.marketplace)
			#add_line("Welcome to the marketplace.")
			#add_line("\nCurrent balance: " + str(Inventory.get_amount(Items.DATA)) + " data")
			#list_help()
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
				add_line("Module not found.")
		_:#default
			add_line("Command not found")

###################################################
################### DATA MINING ###################
###################################################
func mining_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if !process_running:
				start_data_mining()
			else:
				add_line("Process already running")
		"start -log":
			if !process_running:
				start_log_mining()
			else:
				add_line("Process already running")
		"stop":
			process_running = false
			if current_process:
				current_process.stop()
				current_process = null
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current data mine...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
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
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_data_mining():
	var new_data_mining_terminal = mining_scene.instantiate()
	terminal_body_container.add_child(new_data_mining_terminal)
	new_data_mining_terminal.set_mine_type(Mining.DATA)
	process_running = true
	current_process = new_data_mining_terminal
	new_data_mining_terminal.start_data_mining()
	add_new_scrollback()

func start_log_mining():
	if Mining.LOGS.unlocked:
		var new_data_mining_terminal = mining_scene.instantiate()
		terminal_body_container.add_child(new_data_mining_terminal)
		new_data_mining_terminal.set_mine_type(Mining.LOGS)
		process_running = true
		current_process = new_data_mining_terminal
		new_data_mining_terminal.start_data_mining()
		add_new_scrollback()
	else:
		add_line("Log mining is not unlocked yet.")

func data_mining_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Data mining safely finished.")

###################################################
################### LOG PARSING ###################
###################################################
func log_parsing_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.LOGS) <= 0:
				add_line("No logs found.")
				return
			
			start_log_parsing()
		"stop":
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current log...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
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
			add_line("Module: Parsing")
			add_line("Level:         " + str(Parsing["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Parsing["experience"]) + " / " + str(Stats.xp_for_level(Parsing["level"] + 1)))
			#Effeciency
			var eff = Parsing["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Parsing["efficiency description"])
		"-h":
			list_help()
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_log_parsing():
	var new_log_parsing_terminal = log_parsing_scene.instantiate()
	terminal_body_container.add_child(new_log_parsing_terminal)
	new_log_parsing_terminal.set_parse_type(Parsing.LOGS)
	process_running = true
	current_process = new_log_parsing_terminal
	new_log_parsing_terminal.start()
	add_new_scrollback()

func log_parsing_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Parsing safely finished.")

###################################################
################### PW CRACKING ###################
###################################################
func password_unscramble_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
				add_line("No encrypted passwords found.")
				return
			
			start_password_unscrambling()
		"stop":
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current password...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
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
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_password_unscrambling():
	var new_pw_cracking_terminal = pw_cracking_scene.instantiate()
	terminal_body_container.add_child(new_pw_cracking_terminal)
	process_running = true
	current_process = new_pw_cracking_terminal
	new_pw_cracking_terminal.start()
	add_new_scrollback()

func password_cracking_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Password cracking safely finished.")

###################################################
################### CRED MATCHING #################
###################################################
func cred_matching_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.USERNAMES) <= 0 or Inventory.get_amount(Items.PASSWORDS) <= 0:
				if Inventory.get_amount(Items.USERNAMES) <= 0:
					add_line("Required resource: Usernames")
				if Inventory.get_amount(Items.PASSWORDS) <= 0:
					add_line("Required resource: Passwords")
				return
			start_cred_matching()
		"stop":
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current credential match...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
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
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_cred_matching():
	var new_cred_matching_terminal = cred_matching_scene.instantiate()
	terminal_body_container.add_child(new_cred_matching_terminal)
	process_running = true
	current_process = new_cred_matching_terminal
	new_cred_matching_terminal.start()
	add_new_scrollback()

func cred_matching_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Credential matching safely finished.")
	

###################################################
############### CACHE DECRYPTING ##################
###################################################
func cache_decrypting_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if process_running:
				add_line("Process already running.")
				return
			if !Inventory.has_cache():
				add_line("No caches found.")
				return
			
			start_cache_decrypting()
		"stop":
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current cache...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
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
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			add_line("Command not found")

func start_cache_decrypting():
	var new_cache_decrypt_terminal = cache_decrypt_scene.instantiate()
	terminal_body_container.add_child(new_cache_decrypt_terminal)
	process_running = true
	current_process = new_cache_decrypt_terminal
	new_cache_decrypt_terminal.start_decrypting()
	add_new_scrollback()

func cache_decrypting_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Cache decrypting safely finished.")

func overclock_logic():
	if !process_running: #no process running
		add_line("No process running to overclock")
		return
	if Stats.overclocked: #already overclocked
		add_line("System is already overclocked")
		return
	if Stats.overheated: #overheated - still recovering
		add_line("System has been overheated, needs to cool to below 40°C.")
		return
	if Stats.system_tempature >= 60: #cant overclock above 60
		add_line("System tempature needs to cool to below 60°C before overclocking")
		return
	Stats.overclocked = true

#Builds header for module running 
func show_module_stats_header(skill_name: String):
	var skill = Stats.player_stats[skill_name]
	var level = skill["level"]
	var efficiency = skill["efficiency"]
	var xp_current = skill["experience"]
	var xp_needed = Stats.xp_for_level(level + 1)
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
		"Parsing":
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
		"Parsing":
			var chance = (LogParser.BASE_REWARD_CHANCE + efficiency) * 100.0
			chance = snapped(chance, 0.1) # rounds to 1 decimal place
			set_line(skill_specific_info_index, "Chance to extract resource: " + str(chance) + "%\n", false)

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
				_navigate_history(-1)
			elif event.keycode == Key.KEY_DOWN:
				_navigate_history(1)

#command history functionality
func _navigate_history(delta: int):
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

func _scroll_to_bottom():
	await get_tree().process_frame #if youre finding one frame is not enough uncomment this
	await get_tree().process_frame
	terminal_body.set_deferred("scroll_vertical", terminal_body.get_v_scroll_bar().max_value)
