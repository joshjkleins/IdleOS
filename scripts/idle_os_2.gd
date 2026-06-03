extends Control

###NEXT
# BUG: FIX TYPING COMMANDS DURING WAIT PERIODS (maybe implement queue system?)
# BUG: Fix Parsing script to have dynamic amount of labels instead of hardcoded 4
# BUG: weird color matching issue with MINING contracts (not the right green?)
# BUG: when exp is added in 'root' make sure it updates header (probs just need to trigger signal)

#where u at: Defragging, add overclock maybe minor skills, figure out what you want it to do ideas below
# takes a moderate time (5-10 min) and gives a 60 min boost to something (faster cooling / more exp / better hacking / maybe can defrag specific modules?)
# Defrag specific mods as minor skills: Mining defrag: effciency increased by 200% for 60 min, Parsing: double quantity of resources found for 60 min, Cracking: 
#update HUD so defragging is different, no experience or levels in this skill

#TODO
# Add Defragging and update Matching
# Add unlocks for minor skills (example: PIN cracking requires Cracking to be level 15)
# Update -h commands. add the main welcome screen for each process as the new -h for each. Redesign -h to show info for each process, use more width
#simplify run commands (run/start/cast) in tandem with above updates
# add combat equip screen before hack (and/or figure out a way for player to choose which offensive/defensive items to use, maybe prompts before hack starts?)
# then after above is done, add more combat items to test with (utility items), and one time use items
# add logic that makes terminal like hacking (ie sequential so its easier to follow: make everything sent to add_line an array split by \n?)
#save/load
#offline progression - cap at 24 hours?
#export to desktop and play through

#stop adding to above > playthrough w/ notes > balance/bug patches > build store page > demo > playtesters > feedback > demo live

########item ideas:
## ONE TIME USES ##
# Virtual machine tokens - consume to open a new window to run a process for x amount of time
# Efficiency token - consume to increase efficiency of process by 2x for 30 seconds
# Hardware accelerators - use to rapidly cool CPU for 10 second

#combat
# SQL Injector - deals integrity damage
# Cross site script - deals integ damage
# Malware - deals integ damage
# Ransomeware - deals integ damage
# Exploits = deals integ damage
# DDoS = deals integ damage
# Packet spoofers - restores anonymity during hack
# VPN Token - restores anonymity

######## PROCESSES ##
# Phishing - send out phishing emails, etc. and after 30 min - 1h get random assortment if emails/usernames/passwords/pins back
# Defragging - passive? Cost random stuff (huge data sink, maybe other resources) over time gives perm increase to anonymity

##Ideas for generalizing modules and adding unlocks at certain levels
#MINING LVL1: Data, LVL10: Logs, LVL20: Quality Data, LVL40: Quality Logs
#PARSING LVL1: Logs (data, pw), LVL10: Logs (username, IP), LVL 20: Quality Logs (Quality Data, pw, un, ip), LVL 30: Specific parsing (only data/pw/un/ip/ found, no longer random mix)

######## MARKETPLACE
# Contracts - Randomly available - can either purchase one for data to complete work (i need 10 Parents CCs) for bloated amount of money
# Contracts - Randomly available - can be posting to look for work. You pay 5k data and provide 200 encrypted passwords and they will return 200 passwords ie do idle for you
# Contracts - Hacking target - buy, hack x target x times - get reward
# Valuable - Can sell valuables (only purpose)

#CONTRACTS: can only have 3 at one time
# [1] AVAILABLE JOBS
#		[1] MINING
#			[1] cost: 500 data - Mine 200 data: reward: Mining/data exp: 5,000, +25 logs
#			[2] cost: 800 data - Mine 100 logs: reward: Mining/Logs exp: 5,000, +500 data
#		[2] PARSING
#		[3] CRACKING
#		[4] MATCHING
#		[5] DECODING
# [2] REQUEST JOBS
# [3] HACKING REQUESTS

####### MODULE UPGRADES INSTALL
# Each skill has 2 slots (speed slot and efficiency slot) applies to all minor skills within
# Everything to be purchased from marketplace

#STEPS FOR ADDING NEW MODULE
#1. ADD TO CONTEXT ENUM
#2. ADD TO GET_CONTEXT_LEAD FUNC
#3. ADD TO INPUT_LINE_SUBMITTED & ADD RELEVENT FUNCTION
#4. ADD TO ROOT COMMAND CONTEXT
#5. ADD LIST HELP CONTEXT

#colors
# exp green #2a9a5a
# icons #bbbbbb

@onready var lead_text = $Panel/MarginContainer/TerminalRoot/MarginContainer/VBoxContainer/InputLineContainer/LeadText
@onready var input_line = $Panel/MarginContainer/TerminalRoot/MarginContainer/VBoxContainer/InputLineContainer/InputLine
@onready var loading = $Panel/MarginContainer/Loading
@onready var terminal_root = $Panel/MarginContainer/TerminalRoot
@onready var hacking = $Panel/MarginContainer/Hacking
@onready var logparsing_timer = $Timers/LogparsingTimer
@onready var cooling_timer = $Timers/CoolingTimer
@onready var original_scrollback = $Panel/MarginContainer/TerminalRoot/MarginContainer/VBoxContainer/TerminalBody/TerminalBodyContainer/Scrollback
@onready var terminal_body = $Panel/MarginContainer/TerminalRoot/MarginContainer/VBoxContainer/TerminalBody
@onready var terminal_body_container = $Panel/MarginContainer/TerminalRoot/MarginContainer/VBoxContainer/TerminalBody/TerminalBodyContainer
@onready var header = $Panel/MarginContainer/TerminalRoot/Header/HEADER
@onready var contracts_container = $Panel/ContractsContainer

@onready var scrollback = preload("res://scenes/scrollback.tscn")
@onready var mining_scene = preload("res://scenes/data_mining_terminal.tscn")
@onready var log_parsing_scene = preload("res://scenes/log_parsing_terminal.tscn")
@onready var pw_cracking_scene = preload("res://scenes/pw_cracking_terminal.tscn")
@onready var cred_matching_scene = preload("res://scenes/cred_matching_terminal.tscn")
@onready var cache_decrypt_scene = preload("res://scenes/cache_decrypt_terminal.tscn")
@onready var phishing_scene = preload("res://scenes/phishing_terminal.tscn")
@onready var defrag_scene = preload("res://scenes/defrag_terminal.tscn")


enum Context {
	ROOT,
	MINING,
	PARSING,
	CRACKING,
	MATCHING,
	HACKING,
	DARKWEB,
	MARKETPLACE,
	DECODING,
	PHISHING,
	DEFRAGGING
}

enum MarketContext {
	MAIN,
	CONTRACTS,
	VALUABLES,
	VALUABLES_DETAILS,
	BLACK_MARKET,
	BLACK_MARKET_OFFENSIVE,
	BLACK_MARKET_OFFENSIVE_DETAILS,
	BLACK_MARKET_DEFENSIVE,
	BLACK_MARKET_DEFENSIVE_DETAILS,
	BLACK_MARKET_UTILITY,
	BLACK_MARKET_UTILITY_DETAILS,
	UPGRADES,
	UPGRADES_DETAILS
}

var current_marketplace_context = MarketContext.MAIN

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
	header.update_header()
	input_line.grab_focus() #uncomment this when not testing hacking module
	add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")
	Signals.system_temp_updated(30)
	
	Signals.end_log_parsing_safely_signal.connect(log_parsing_ended_safely)
	Signals.end_pw_cracking_safely_signal.connect(password_cracking_ended_safely)
	Signals.end_cache_decrypting_safely_signal.connect(cache_decrypting_ended_safely)
	Signals.end_phishing_safely_signal.connect(phishing_ended_safely)
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
	var terminals_active = terminal_body_container.get_child_count()

	if terminals_active > RICHTEXT_LABEL_LIMIT:
		var label_to_remove = terminal_body_container.get_child(0)
		if label_to_remove == current_process: #prevents removing currently running process
			label_to_remove = terminal_body_container.get_child(1)
		label_to_remove.queue_free()

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
			Context.CRACKING:
				password_unscramble_commands(new_text)
			Context.MATCHING:
				cred_matching_commands(new_text)
			Context.DECODING:
				cache_decrypting_commands(new_text)
			Context.PHISHING:
				phishing_commands(new_text)
			Context.DEFRAGGING:
				defragging_commands(new_text)

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
			match current_marketplace_context:
				MarketContext.MAIN:
					return "IdleOS/Marketplace>"
				MarketContext.VALUABLES:
					return "IdleOS/Marketplace/Valuables>"
				MarketContext.VALUABLES_DETAILS:
					return "IdleOS/Marketplace/Valuables>"
				MarketContext.BLACK_MARKET:
					return "IdleOS/Marketplace/BlackMarket>"
				MarketContext.BLACK_MARKET_OFFENSIVE:
					return "IdleOS/Marketplace/BlackMarket/Offensive>"
				MarketContext.BLACK_MARKET_OFFENSIVE_DETAILS:
					return "IdleOS/Marketplace/BlackMarket/Offensive>"
				MarketContext.BLACK_MARKET_DEFENSIVE:
					return "IdleOS/Marketplace/BlackMarket/Defensive>"
				MarketContext.BLACK_MARKET_DEFENSIVE_DETAILS:
					return "IdleOS/Marketplace/BlackMarket/Defensive>"
				MarketContext.BLACK_MARKET_UTILITY:
					return "IdleOS/Marketplace/BlackMarket/Utility>"
				MarketContext.BLACK_MARKET_UTILITY_DETAILS:
					return "IdleOS/Marketplace/BlackMarket/Utility>"
				MarketContext.CONTRACTS:
					return "IdleOS/Marketplace/Contracts>"
				MarketContext.UPGRADES:
					return "IdleOS/Marketplace/Upgrades>"
				MarketContext.UPGRADES_DETAILS:
					return "IdleOS/Marketplace/Upgrades/Details>"
				
		Context.MINING:
			Signals.update_hud(Mining)
			return "IdleOS/Modules/Mining>"
		Context.PARSING:
			Signals.update_hud(Parsing)
			return "IdleOS/Modules/Parsing>"
		Context.CRACKING:
			Signals.update_hud(Cracking)
			return "IdleOS/Modules/Cracking>"
		Context.MATCHING:
			Signals.update_hud(Matching)
			return "IdleOS/Modules/Matching>"
		Context.HACKING:
			return "IdleOS/Modules/Hacking>"
		Context.DECODING:
			Signals.update_hud(Decoding)
			return "IdleOS/Modules/Decoding>"
		Context.PHISHING:
			Signals.update_hud(Phishing)
			return "IdleOS/Modules/Phishing>"
		Context.DEFRAGGING:
			Signals.update_hud(Defragging)
			return "IdleOS/Modules/Defragging>"


#Changes context and updates leading text
func update_context(new_context: Context):
	current_context = new_context
	lead_text.text = get_context_lead()

func update_market_context(new_context: MarketContext):
	current_marketplace_context = new_context
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
			
		Context.CRACKING:
			add_line("""
[CRACKING COMMANDS]
start                   Start password cracking process
stop                    Stop password cracking process
root                    Exit back to root
info                    Password cracking module stats
""")
		Context.MATCHING:
			add_line("""
	[MATCHING COMMANDS]
start                   Start matching process
stop                    Stop matching process
root                    Exit back to root
info                    Matching module stats
""")
		Context.DECODING:
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
		"show contracts":
			add_line(ContractsManager.show_contracts())
			return true
		"open contracts":
			contracts_container.open_contracts()
			return true
		"close contracts":
			contracts_container.min_contracts()
			return true
		"complete -c":
			add_line(ContractsManager.complete_contracts())
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
			header.update_header(Mining)
			add_line("[ OK ] data mining module loaded")
			update_context(Context.MINING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.mining)
			add_line("Welcome to the mining module.")
		"load parsing":
			add_line("[ .. ] loading parsing module")
			await get_tree().create_timer(0.8).timeout
			header.update_header(Parsing)
			add_line("[ OK ] parsing module loaded")
			update_context(Context.PARSING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.parsing)
			add_line("Current available logs: " + str(Inventory.get_amount(Items.LOGS)))
		"load cracking":
			add_line("[ .. ] loading cracking module")
			await get_tree().create_timer(0.8).timeout
			header.update_header(Cracking)
			add_line("[ OK ] cracking module loaded")
			update_context(Context.CRACKING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.cracking)
		"load matching":
			add_line("[ .. ] loading matching module")
			await get_tree().create_timer(0.8).timeout
			header.update_header(Matching)
			add_line("[ OK ] matching module loaded")
			update_context(Context.MATCHING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.matching)
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
		"marketplace -auth": #Go to marketplace
			add_line("[ .. ] requesting permissions")
			await get_tree().create_timer(0.8).timeout
			add_line("[ OK ] permission granted")
			await get_tree().create_timer(0.5).timeout
			add_line("Connected to online marketplace")
			update_context(Context.MARKETPLACE)
			add_line(Marketplace.marketplace_welcome())
		"load decoding":
			add_line("[ .. ] loading decoding module")
			await get_tree().create_timer(0.8).timeout
			header.update_header(Decoding)
			add_line("[ OK ] decoding module loaded")
			update_context(Context.DECODING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.decoding)
		"load phishing":
			add_line("[ .. ] loading phishing module")
			await get_tree().create_timer(0.8).timeout
			header.update_header(Phishing)
			add_line("[ OK ] phishing module loaded")
			update_context(Context.PHISHING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.phishing)
		"load defragging":
			add_line("[ .. ] loading defragging module")
			await get_tree().create_timer(0.8).timeout
			header.update_header(Defragging)
			add_line("[ OK ] defragging module loaded")
			update_context(Context.DEFRAGGING)
			await get_tree().create_timer(0.5).timeout
			add_line(Ascii.defragging)
			
		_:#default
			add_line("Command not found")

###################################################
################### MINING ########################
###################################################
func mining_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if !process_running:
				start_log_mining()
			else:
				add_line("Process already running")
		#"start -log":
			#if !process_running:
				#start_log_mining()
			#else:
				#add_line("Process already running")
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
				header.update_header()
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
	new_data_mining_terminal.set_mine_type(Mining.LOGS)
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
################### PARSING #######################
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
		"start -creds":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.LOGS) <= 0:
				add_line("No logs found.")
				return
			
			start_log_cred_parsing()
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
				header.update_header()
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

func start_log_cred_parsing():
	var new_log_parsing_terminal = log_parsing_scene.instantiate()
	terminal_body_container.add_child(new_log_parsing_terminal)
	new_log_parsing_terminal.set_parse_type(Parsing.CRED_LOGS)
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
#################### CRACKING #####################
###################################################
func password_unscramble_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start pw":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
				add_line("No encrypted passwords found.")
				return
			
			start_password_cracking()
		"start pin":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
				add_line("No encrypted passwords found.")
				return
			
			start_pin_cracking()
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
				header.update_header()
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("Module: Cracking")
			add_line("Level:         " + str(Stats.player_stats["Cracking"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Cracking"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Cracking"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Cracking"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Cracking"]["efficiency description"])
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

func start_password_cracking():
	if Inventory.get_amount(Items.ENCRYPTED_PASSWORDS) <= 0:
		add_line("Encrypted passwords not found")
		return
	var new_pw_cracking_terminal = pw_cracking_scene.instantiate()
	terminal_body_container.add_child(new_pw_cracking_terminal)
	new_pw_cracking_terminal.set_cracking_type(Cracking.PASSWORD)
	new_pw_cracking_terminal.set_pw()
	process_running = true
	current_process = new_pw_cracking_terminal
	new_pw_cracking_terminal.start()
	add_new_scrollback()

func start_pin_cracking():
	if Inventory.get_amount(Items.ENCRYPTED_PINS) <= 0:
		add_line("Encrypted pins not found")
		return
	var new_pw_cracking_terminal = pw_cracking_scene.instantiate()
	terminal_body_container.add_child(new_pw_cracking_terminal)
	new_pw_cracking_terminal.set_cracking_type(Cracking.PINS)
	new_pw_cracking_terminal.set_pin()
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
		"start -cred":
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
		"start -account":
			if process_running:
				add_line("Process already running.")
				return
			if Inventory.get_amount(Items.PINS) <= 0 or Inventory.get_amount(Items.ACCOUNT_NUMBERS) <= 0:
				if Inventory.get_amount(Items.PINS) <= 0:
					add_line("Required resource: PINS")
				if Inventory.get_amount(Items.ACCOUNT_NUMBERS) <= 0:
					add_line("Required resource: Account numbers")
				return
			start_account_matching()
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
			add_line("Finishing current match...")
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
				header.update_header()
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("Module: Matching")
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
	new_cred_matching_terminal.set_cred(Matching.CREDENTIAL)
	process_running = true
	current_process = new_cred_matching_terminal
	new_cred_matching_terminal.start()
	add_new_scrollback()

func start_account_matching():
	var new_cred_matching_terminal = cred_matching_scene.instantiate()
	terminal_body_container.add_child(new_cred_matching_terminal)
	new_cred_matching_terminal.set_account(Matching.ACCOUNT)
	process_running = true
	current_process = new_cred_matching_terminal
	new_cred_matching_terminal.start()
	add_new_scrollback()

func cred_matching_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Matching safely finished.")
	

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
				header.update_header()
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
	new_cache_decrypt_terminal.set_cache_type(Decoding.CACHE)
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

###################################################
################### PHISHING ######################
###################################################
func phishing_commands(text):
	if text.begins_with("cast"):
		if Phishing.current_lines.size() >= Phishing.max_lines:
			add_line("At max phishing attempts.")
			return
			
		text = text.strip_edges().to_lower()
		var split = text.split(" ")
		var p_type
		var lines_num = 0
		for type in Phishing.minor_processes:
			if split[1] == type.name.to_lower():
				p_type = type
				if split[2].is_valid_int():
					if int(split[2]) > 0:
						lines_num = int(split[2])
				elif split[2] == "max" or split[2] == "all":
					lines_num = -1 # -1 means all or max
				else:
					lines_num = split[2]
				break
		if lines_num == 0:
			add_line("Amount not valid")
			return
		if lines_num > Phishing.max_lines - Phishing.current_lines.size():
			add_line("Unable to cast that many lines, clear some first.")
			return
		if p_type == null:
			add_line("Phishing type not found")
			return
		
		cast_line(p_type, lines_num)
	else:
		match text:
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
				add_line("Finishing current phishing attempt...")
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
					header.update_header()
					update_context(Context.ROOT)
					add_line(Ascii.root)
					list_help()
			"info":
				add_line("Module: Phishing")
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

func cast_line(type: Dictionary, lines: int):
	if current_process is PhishingTerminal:
		current_process.cast_lines(type, lines)
	else:
		var new_phishing_terminal = phishing_scene.instantiate()
		terminal_body_container.add_child(new_phishing_terminal)
		process_running = true
		current_process = new_phishing_terminal
		new_phishing_terminal.cast_lines(type, lines)
		add_new_scrollback()

func phishing_ended_safely():
	current_process = null
	process_running = false
	Stats.overclocked = false
	add_line("Phishing process finished.")


###################################################
################### DEFRAGGING ####################
###################################################
func defragging_commands(text):
	text = text.to_lower().strip_edges()
	match text:
		"start":
			if process_running:
				add_line("Process already running.")
				return
			
			start_defragging()
		"stop":
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
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
				header.update_header()
				update_context(Context.ROOT)
				add_line(Ascii.root)
				list_help()
		"info":
			add_line("???")
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

func start_defragging():
	var new_defrag_terminal = defrag_scene.instantiate()
	terminal_body_container.add_child(new_defrag_terminal)
	process_running = true
	current_process = new_defrag_terminal
	new_defrag_terminal.start()
	add_new_scrollback()


###################################################
################# MARKETPLACE #####################
###################################################
func marketplace_commands(text):
	text = text.to_lower().strip_edges()
	
	if text == "exit":
		header.update_header()
		update_context(Context.ROOT)
		update_market_context(MarketContext.MAIN)
		Marketplace.viewing_item = null
		Marketplace .viewing_skill = null
		add_line("Saftely exiting marketplace")
		await get_tree().create_timer(0.5).timeout
		add_line(Ascii.root)
	else:
		match current_marketplace_context:
			MarketContext.MAIN:
				marketplace_main_commands(text)
			MarketContext.CONTRACTS:
				marketplace_contract_commands(text)
			MarketContext.VALUABLES:
				marketplace_valuable_commands(text)
			MarketContext.VALUABLES_DETAILS:
				marketplace_valuable_details_commands(text)
			MarketContext.BLACK_MARKET:
				marketplace_black_market_main_commands(text)
			MarketContext.BLACK_MARKET_OFFENSIVE, MarketContext.BLACK_MARKET_OFFENSIVE_DETAILS, MarketContext.BLACK_MARKET_DEFENSIVE, MarketContext.BLACK_MARKET_DEFENSIVE_DETAILS, MarketContext.BLACK_MARKET_UTILITY, MarketContext.BLACK_MARKET_UTILITY_DETAILS:
				marketplace_black_market_category_commands(text)
			MarketContext.UPGRADES:
				marketplace_upgrades_commands(text)
			MarketContext.UPGRADES_DETAILS:
				marketplace_upgrades_details_commands(text)

#current_market_context == MarketContext.MAIN
func marketplace_main_commands(text):
	match text:
		"1":
			update_market_context(MarketContext.CONTRACTS)
			add_line(Marketplace.contracts())
		"2":
			if !Inventory.has_valuables():
				add_line("No valuables found")
				return
			update_market_context(MarketContext.VALUABLES)
			add_line(Marketplace.maretplace_valuables_main())
		"3":
			update_market_context(MarketContext.BLACK_MARKET)
			add_line(Marketplace.black_market_main())
		"4":
			update_market_context(MarketContext.UPGRADES)
			add_line(Marketplace.upgrades_main())
		"list":
			add_line(Marketplace.marketplace_welcome())
		_:#default
			add_line("Command not found")

#CONTRACTS
func marketplace_contract_commands(text):
	if text.is_valid_int():
		var purchase_attempt = Marketplace.purchase_contract(int(text))
		add_line(purchase_attempt["message"])
		if purchase_attempt["purchased"]:
			add_line(Marketplace.contracts())
	else:
		match text:
			"refresh":
				var refresh_attempt = Marketplace.refresh_contracts()
				if refresh_attempt['successful']:
					add_line(refresh_attempt["message"])
					await get_tree().create_timer(1.0).timeout
					add_line(Marketplace.contracts())
					add_line("Contracts refreshed")
				else:
					add_line(refresh_attempt["message"])
			"back":
				update_market_context(MarketContext.MAIN)
				add_line(Marketplace.marketplace_welcome())
			_:#default
				add_line("Command not found")

func marketplace_upgrades_commands(text):
	match text:
		"1": #Mining
			add_line(Marketplace.upgrades_details(Mining))
			update_market_context(MarketContext.UPGRADES_DETAILS)
		"2": #Parsing
			add_line(Marketplace.upgrades_details(Parsing))
			update_market_context(MarketContext.UPGRADES_DETAILS)
		"3": #Cracking
			add_line(Marketplace.upgrades_details(Cracking))
			update_market_context(MarketContext.UPGRADES_DETAILS)
		"4": #Matching
			add_line(Marketplace.upgrades_details(Matching))
			update_market_context(MarketContext.UPGRADES_DETAILS)
		"5": #Hacking
			add_line(Marketplace.upgrades_details(Hacking))
			update_market_context(MarketContext.UPGRADES_DETAILS)
		"6": #Decoding
			add_line(Marketplace.upgrades_details(Decoding))
			update_market_context(MarketContext.UPGRADES_DETAILS)
		"7": #Phishing
			add_line(Marketplace.upgrades_details(Phishing))
			update_market_context(MarketContext.UPGRADES_DETAILS)
			
		"back":
			update_market_context(MarketContext.MAIN)
			add_line(Marketplace.marketplace_welcome())

func marketplace_upgrades_details_commands(text):
	if text.is_valid_int():
		var purchase_attempt = Marketplace.purchase_upgrade(int(text))
		add_line(purchase_attempt["message"])
		if purchase_attempt["purchased"]:
			add_line(Marketplace.upgrades_details(Marketplace.viewing_skill))
	else:
		match text:
			"back":
				update_market_context(MarketContext.UPGRADES)
				add_line(Marketplace.upgrades_main())

#current_market_context == MarketContext.BLACK_MARKET
func marketplace_black_market_main_commands(text):
	match text:
		"1": #[1] OFFENSIVE ITEMS
			add_line(Marketplace.black_market_items("offensive"))
			update_market_context(MarketContext.BLACK_MARKET_OFFENSIVE)
		"2": #[2] DEFENSIVE ITEMS
			add_line(Marketplace.black_market_items("defensive"))
			update_market_context(MarketContext.BLACK_MARKET_DEFENSIVE)
		"3": #[3] UTILITY ITEMS
			add_line(Marketplace.black_market_items("utility"))
			update_market_context(MarketContext.BLACK_MARKET_UTILITY)
		"back":
			update_market_context(MarketContext.MAIN)
			add_line(Marketplace.marketplace_welcome())
		_:#default
			add_line("Command not found")

func marketplace_black_market_category_commands(text):
	match current_marketplace_context:
		#VIEWING ALL OFFENSIVE ITEMS
		MarketContext.BLACK_MARKET_OFFENSIVE:
			if text.is_valid_int():
				add_line(Marketplace.black_market_item_details(int(text), "offensive"))
				if Marketplace.viewing_item:
					update_market_context(MarketContext.BLACK_MARKET_OFFENSIVE_DETAILS)
			else:
				match text:
					"back":
						add_line(Marketplace.black_market_main())
						update_market_context(MarketContext.BLACK_MARKET)
					_:#default
						add_line("Command not found")
		MarketContext.BLACK_MARKET_DEFENSIVE:
			if text.is_valid_int():
				add_line(Marketplace.black_market_item_details(int(text), "defensive"))
				if Marketplace.viewing_item:
					update_market_context(MarketContext.BLACK_MARKET_DEFENSIVE_DETAILS)
			else:
				match text:
					"back":
						add_line(Marketplace.black_market_main())
						update_market_context(MarketContext.BLACK_MARKET)
					_:#default
						add_line("Command not found")
		MarketContext.BLACK_MARKET_UTILITY:
			if text.is_valid_int():
				add_line(Marketplace.black_market_item_details(int(text), "utility"))
				if Marketplace.viewing_item:
					update_market_context(MarketContext.BLACK_MARKET_UTILITY_DETAILS)
			else:
				match text:
					"back":
						add_line(Marketplace.black_market_main())
						update_market_context(MarketContext.BLACK_MARKET)
					_:#default
						add_line("Command not found")
			
		#VIEWING SPECIFIC DEFENSIVE ITEM
		MarketContext.BLACK_MARKET_OFFENSIVE_DETAILS:
			if text.begins_with("buy"):
				add_line(Marketplace.handle_black_market_buy_command(text))
				if Marketplace.viewing_item == null: #successful because viewing_item was bought and set to null
					update_market_context(MarketContext.BLACK_MARKET_OFFENSIVE)
					add_line(Marketplace.black_market_items("offensive"))
			else:
				match text:
					"back":
						add_line(Marketplace.black_market_items("offensive"))
						update_market_context(MarketContext.BLACK_MARKET_OFFENSIVE)
					_:#default
						add_line("Command not found")
		MarketContext.BLACK_MARKET_DEFENSIVE_DETAILS:
			if text.begins_with("buy"):
				add_line(Marketplace.handle_black_market_buy_command(text))
				if Marketplace.viewing_item == null: #successful because viewing_item was bought and set to null
					update_market_context(MarketContext.BLACK_MARKET_DEFENSIVE)
					add_line(Marketplace.black_market_items("defensive"))
			else:
				match text:
					"back":
						add_line(Marketplace.black_market_items("defensive"))
						update_market_context(MarketContext.BLACK_MARKET_DEFENSIVE)
					_:#default
						add_line("Command not found")
		MarketContext.BLACK_MARKET_UTILITY_DETAILS:
			if text.begins_with("buy"):
				add_line(Marketplace.handle_black_market_buy_command(text))
				if Marketplace.viewing_item == null: #successful because viewing_item was bought and set to null
					update_market_context(MarketContext.BLACK_MARKET_UTILITY)
					add_line(Marketplace.black_market_items("utility"))
			else:
				match text:
					"back":
						add_line(Marketplace.black_market_items("utility"))
						update_market_context(MarketContext.BLACK_MARKET_UTILITY)
					_:#default
						add_line("Command not found")

#current_market_context == MarketContext.VALUABLES_DETAILS
func marketplace_valuable_details_commands(text):
	if text.is_valid_int() and Marketplace.viewing_item:
		add_line(Marketplace.handle_valuable_details_sell(int(text)))
		if Marketplace.viewing_item == null: #null means a sale was made
			update_market_context(MarketContext.VALUABLES)
			add_line(Marketplace.maretplace_valuables_main())
		
	else:
		match text:
			#selling all of a specific valuable
			"all":
				add_line(Marketplace.handle_valuable_details_sell_all())
				update_market_context(MarketContext.VALUABLES)
				add_line(Marketplace.maretplace_valuables_main())
			"back":
				update_market_context(MarketContext.VALUABLES)
				add_line(Marketplace.maretplace_valuables_main())
			_:#default
				add_line("Command not found")

#current_market_context == MarketContext.VALUABLES
func marketplace_valuable_commands(text):
	if text.is_valid_int():
		if Inventory.has_item_by_id(int(text)):
			add_line(Marketplace.view_valuable_item(int(text)))
			update_market_context(MarketContext.VALUABLES_DETAILS)
		else:
			add_line("No item found with that ID")
	else:
		match text:
			"sell -a":
				add_line(Marketplace.sell_all_valuables())
				add_line("Returning to main menu")
				update_market_context(MarketContext.MAIN)
				add_line(Marketplace.marketplace_welcome())
			"back":
				update_market_context(MarketContext.MAIN)
				add_line(Marketplace.marketplace_welcome())
			_:#default
				add_line("Command not found")

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
	header.update_header()
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
