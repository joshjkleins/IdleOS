extends Control

# Welcome message : Thank you for playing Tutorial message : Discord message

#Export and play through.

#create discord server for playtest
#add copy function for playtest Discord server
#Export and test on pc
#Upload playtest

#STEPS FOR ADDING NEW MODULE
#1. ADD TO CONTEXT ENUM
#2. ADD TO GET_CONTEXT_LEAD FUNC
#3. ADD TO INPUT_LINE_SUBMITTED & ADD RELEVENT FUNCTION
#4. ADD TO ROOT COMMAND CONTEXT
#5. ADD LIST HELP CONTEXT

@onready var lead_text = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent/InputLineContainer/LeadText
@onready var input_line = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent/InputLineContainer/InputLine
@onready var loading = $Panel/MarginContainer/Loading
@onready var terminal_root = $Panel/MarginContainer/TerminalRoot
@onready var hacking = $Panel/MarginContainer/Hacking
@onready var logparsing_timer = $Timers/LogparsingTimer
@onready var cooling_timer = $Timers/CoolingTimer
@onready var original_scrollback = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent/TerminalBody/TerminalBodyContainer/Scrollback
@onready var terminal_body = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent/TerminalBody
@onready var terminal_body_container = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent/TerminalBody/TerminalBodyContainer
@onready var header = $Panel/MarginContainer/TerminalRoot/Header/HEADER
#@onready var contracts_container = $Panel/ContractsContainer
@onready var terminal_grandparent = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent
@onready var hud_process_running = $Panel/MarginContainer/TerminalRoot/Header/HUDProcessRunning
@onready var hud_monitor = $Panel/TrackingContainer/HUDMonitor

@onready var scrollback = preload("res://scenes/scrollback.tscn")
@onready var mining_scene = preload("res://scenes/data_mining_terminal.tscn")
@onready var log_parsing_scene = preload("res://scenes/log_parsing_terminal.tscn")
@onready var pw_cracking_scene = preload("res://scenes/pw_cracking_terminal.tscn")
@onready var cred_matching_scene = preload("res://scenes/cred_matching_terminal.tscn")
@onready var cache_decrypt_scene = preload("res://scenes/cache_decrypt_terminal.tscn")
@onready var phishing_scene = preload("res://scenes/phishing_terminal.tscn")
@onready var defrag_scene = preload("res://scenes/defrag_terminal.tscn")
@onready var compiling_scene = preload("res://scenes/compiling_terminal.tscn")


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
	DEFRAGGING,
	COMPILING
}

func get_context_name_string(current_context: Context) -> String:
	return Context.keys()[current_context].capitalize()

enum PlayerInputContext {
	NONE,
	UPGRADES,
}

var current_player_input_context: PlayerInputContext = PlayerInputContext.NONE
var awaiting_player_input: bool = false
var accepting_player_inputs: bool = true
var upgrade_package_selected = null

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
var current_process_info: Dictionary
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

var major_processes = [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling, Defragging]

var output_queue: Array[String] = []
var processing_queue = false

var RICHTEXT_LABEL_LINE_LIMIT = 20 #lines per richtextlabel (aka terminal read) before creating a new one
var RICHTEXT_LABEL_LIMIT = 10 #amount of richtextlabels before starting to remove old ones

var NOTIFY_OF_OVERHEAT: bool = false

func _ready():
	current_scrollback = original_scrollback
	update_context(Context.ROOT)
	header.update()
	input_line.grab_focus() #uncomment this when not testing hacking module
	
	add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")
	add_line(ContextCommands.playtest_welcome_message())
	if not SaveManager.load_game():
		Signals.system_temp_updated(30)
		add_line("To get started, type `-h` in the terminal.")
	
	Signals.end_log_parsing_safely_signal.connect(log_parsing_ended_safely)
	Signals.end_pw_cracking_safely_signal.connect(password_cracking_ended_safely)
	Signals.end_cache_decrypting_safely_signal.connect(cache_decrypting_ended_safely)
	Signals.end_phishing_safely_signal.connect(phishing_ended_safely)
	Signals.end_data_mining_safely_signal.connect(data_mining_ended_safely)
	Signals.end_cred_matching_safely_signal.connect(cred_matching_ended_safely)
	Signals.end_compiling_safely_signal.connect(compiling_ended_safely)
	Signals.defrag_finished_signal.connect(defrag_finished)
	Signals.vm_window_focused_signal.connect(grab_all_focus)
	Signals.tutorial_event_completed_signal.connect(tutorial_event_completed)
	Signals.system_overheated_signal.connect(overheat_terminal_notice)
	Signals.system_cooled_below_overheat_signal.connect(system_cooled_out_of_overheat_range)
	
	##cooling timer
	cooling_timer.wait_time = Stats.cooling_frequency
	cooling_timer.start()
	
	
	
	

#update previous lines
func set_line(index: int, text: String, scroll_to_line: bool = false):
	if index < lines.size():
		lines[index] = text
	update_terminal(scroll_to_line)

func add_line(text: String) -> void:
	output_queue.append(text)

	if not processing_queue:
		process_queue()

func process_queue() -> void:
	processing_queue = true

	while output_queue.size() > 0:
		var text = output_queue.pop_front()

		for line in text.split("\n"):
			lines.append(line)
			update_terminal()
			await get_tree().create_timer(0.03).timeout

	processing_queue = false

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
		if current_process.get_parent() == terminal_body_container:
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
	if !accepting_player_inputs:
		input_line.clear()
		return
	if awaiting_player_input:
		if new_text.to_lower().strip_edges() == "y" or new_text.to_lower().strip_edges() == "n":
			add_line(get_context_lead() + new_text)
			input_line.clear()
			accept_player_input(new_text)
		else:
			add_line(get_context_lead() + "Input not recognized. type y for yes or n for no.")
			input_line.clear()
		return
			
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
			Context.COMPILING:
				compiling_commands(new_text)

	history_index = -1

#return text before command
func get_context_lead():
	match current_context:
		Context.ROOT:
			Signals.update_hud_root()
			return "IdleOS>"
		Context.MINING:
			Signals.update_hud(Mining)
			return "IdleOS/[color=#%s]Mining[/color]>" % Mining.SKILL.color.to_html(false)
		Context.PARSING:
			Signals.update_hud(Parsing)
			return "IdleOS/[color=#%s]Parsing[/color]>" % Parsing.SKILL.color.to_html(false)
		Context.CRACKING:
			Signals.update_hud(Cracking)
			return "IdleOS/[color=#%s]Cracking[/color]>" % Cracking.SKILL.color.to_html(false)
		Context.MATCHING:
			Signals.update_hud(Matching)
			return "IdleOS/[color=#%s]Matching[/color]>" % Matching.SKILL.color.to_html(false)
		Context.HACKING:
			return "IdleOS/Hacking>"
		Context.DECODING:
			Signals.update_hud(Decoding)
			return "IdleOS/[color=#%s]Decoding[/color]>" % Decoding.SKILL.color.to_html(false)
		Context.PHISHING:
			Signals.update_hud(Phishing)
			return "IdleOS/[color=#%s]Phishing[/color]>" % Phishing.SKILL.color.to_html(false)
		Context.DEFRAGGING:
			Signals.update_hud(Defragging)
			return "IdleOS/[color=#%s]Defragging[/color]>" % Defragging.SKILL.color.to_html(false)
		Context.COMPILING:
			Signals.update_hud(Compiling)
			return "IdleOS/[color=#%s]Compiling[/color]>" % Compiling.SKILL.color.to_html(false)
		#Context.DARKWEB:
			#return "IdleOS/Darkweb>"
		#Context.MARKETPLACE:
			#match current_marketplace_context:
				#MarketContext.MAIN:
					#return "IdleOS/Marketplace>"
				#MarketContext.VALUABLES:
					#return "IdleOS/Marketplace/Valuables>"
				#MarketContext.VALUABLES_DETAILS:
					#return "IdleOS/Marketplace/Valuables>"
				#MarketContext.BLACK_MARKET:
					#return "IdleOS/Marketplace/BlackMarket>"
				#MarketContext.BLACK_MARKET_OFFENSIVE:
					#return "IdleOS/Marketplace/BlackMarket/Offensive>"
				#MarketContext.BLACK_MARKET_OFFENSIVE_DETAILS:
					#return "IdleOS/Marketplace/BlackMarket/Offensive>"
				#MarketContext.BLACK_MARKET_DEFENSIVE:
					#return "IdleOS/Marketplace/BlackMarket/Defensive>"
				#MarketContext.BLACK_MARKET_DEFENSIVE_DETAILS:
					#return "IdleOS/Marketplace/BlackMarket/Defensive>"
				#MarketContext.BLACK_MARKET_UTILITY:
					#return "IdleOS/Marketplace/BlackMarket/Utility>"
				#MarketContext.BLACK_MARKET_UTILITY_DETAILS:
					#return "IdleOS/Marketplace/BlackMarket/Utility>"
				#MarketContext.CONTRACTS:
					#return "IdleOS/Marketplace/Contracts>"
				#MarketContext.UPGRADES:
					#return "IdleOS/Marketplace/Upgrades>"
				#MarketContext.UPGRADES_DETAILS:
					#return "IdleOS/Marketplace/Upgrades/Details>"
				



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
			add_line(ContextCommands.all_commands())
		Context.MARKETPLACE:
			add_line("add -help stuff here")
		Context.MINING:
			add_line(ContextCommands.get_help_text(Mining))
		Context.PARSING:
			add_line(ContextCommands.get_help_text(Parsing))
		Context.CRACKING:
			add_line(ContextCommands.get_help_text(Cracking))
		Context.MATCHING:
			add_line(ContextCommands.get_help_text(Matching))
		Context.DECODING:
			add_line(ContextCommands.get_help_text(Decoding))
		Context.PHISHING:
			add_line(ContextCommands.get_help_text(Phishing))

	add_line("[color=gray]Tip: Use ↑ and ↓ to scroll through previous commands[/color]\n")

func tutorial_event_completed(message: String):
	if current_context == Context.HACKING:
		return
	add_line(message)

func universal_commands(text):
	text = text.to_lower().strip_edges()
	if text.begins_with("settings"):
		if text == "settings":
			add_line(Settings.settings_help())
			return true
		add_line(Settings.handle_settings_command(text))
		return true
	if text.begins_with("ssh"):
		handle_vm_token_commands(text)
		return true
	if text.begins_with("info"):
		handle_info_commands(text)
		return true
	if text.begins_with("track"):
		var item_names = text.trim_prefix("track").strip_edges().split(",")
		add_line(hud_monitor.add_monitored_items(item_names))
		return true

	if text.begins_with("untrack"):
		var item_names = text.trim_prefix("untrack").strip_edges()
		
		if item_names in ["-a", "-all", "all"]:
			add_line(hud_monitor.remove_all())
			return true
		
		var names = item_names.split(",")
		add_line(hud_monitor.remove_monitored_items(names))
		return true
		
	if text.begins_with("ls"):
		var item_name = text.trim_prefix("ls").strip_edges()
		
		# Just "ls"
		if item_name.is_empty():
			add_line(Inventory.list_inventory())
			Tutorial.complete_event(Tutorial.TutorialEvent.LIST_ITEMS)
			return true
		
		# "ls <item>"
		var item = Inventory.get_item_by_name(item_name)
		
		if item == null:
			add_line("Item not found: " + item_name)
			return true
		
		add_line(Inventory.list_specific_item(item))
		
		if item.name.to_lower() == "logs":
			Tutorial.complete_event(Tutorial.TutorialEvent.LIST_LOG_DETAILS)
		
		return true
	
	#if text.begins_with("add"):
		#var item_name = text.trim_prefix("add").strip_edges()
		#var item = Inventory.get_item_by_name(item_name)
		#if item != null:
			#Inventory.add_resource(item, 50)
			#return true
		
	
	if text.begins_with("apt"):
		handle_apt_commands(text)
		return true
	match text:
		"-h", "help":
			add_line(ContextCommands.get_help())
			Tutorial.complete_event(Tutorial.TutorialEvent.RUN_HELP_COMMAND)
			return true
		"tutorial":
			add_line(ContextCommands.get_tutorial())
			return true
		"tree":
			add_line(ContextCommands.get_ascii_tree(get_context_name_string(current_context)))
			return true
		"history":
			add_line(ContextCommands.get_history_commands(command_history))
			return true
		"process -h":
			add_line(ContextCommands.process_commands())
			return true
		"ps":
			if current_process_info == {}:
				add_line("No process current running.")
				return true
			unstick_current_process()
			bring_process_to_bottom()
			var p: Node = _get_major_from_minor(current_process_info)
			add_line(ContextCommands.get_mp_info(p, current_process_info))
			return true
		"date":
			add_line(ContextCommands.get_date_command())
			return true
		"playtest":
			add_line(ContextCommands.playtest_welcome_message())
			return true
		"discord -c":
			var discord_link = "https://discord.gg/bWFwUsF9a"
			DisplayServer.clipboard_set(discord_link)
			add_line("[color=green]Discord invite copied to clipboard.[/color]")
			return true
		"discord":
			add_line(ContextCommands.discord_message())
			return true
		"clear":
			_clear_terminal()
			return true
		"stop", "kill":
			process_running = false
			unstick_current_process()
			if current_process:
				_kill_current_process()
				
				Tutorial.complete_event(Tutorial.TutorialEvent.STOP_MINING_PROCESS)
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
			return true
		"focus":
			if current_process:
				bring_process_to_bottom()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_FOCUS)
			else:
				add_line("No process found to focus")
			return true
		"sticky", "stick":
			if current_process != null:
				sticky_current_process()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_STICKY)
			else:
				add_line("No process running")
			return true
		"unsticky", "unstick":
			if current_process != null:
				unstick_current_process()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_UNSTICKY)
			else:
				add_line("No process running")
			return true
		"quit -s", "quit", "exit", "exit -s":
			SaveManager.save_game()
			get_tree().quit()
		#"cmds":
			#add_line(ContextCommands.all_commands())
			#return true
		"system":
			add_line(ContextCommands.system_commands())
			return true

#Root context commands
func root_commands(text):
	text = text.to_lower().strip_edges()
	
	match text:
		"load mining", "cd mining":
			add_line("[ .. ] loading data mining module")
			#header.update_header(Mining)
			header.display_skill(Mining)
			add_line("[ OK ] data mining module loaded")
			update_context(Context.MINING)
			add_line(ContextCommands.get_help_text(Mining))
			Tutorial.complete_event(Tutorial.TutorialEvent.NAVIGATE_MINING)
		"load parsing", "cd parsing":
			add_line("[ .. ] loading parsing module")
			#header.update_header(Parsing)
			header.display_skill(Parsing)
			add_line("[ OK ] parsing module loaded")
			update_context(Context.PARSING)
			add_line(ContextCommands.get_help_text(Parsing))
			Tutorial.complete_event(Tutorial.TutorialEvent.NAVIGATE_PARSING)
		"load cracking", "cd cracking":
			add_line("[ .. ] loading cracking module")
			#header.update_header(Cracking)
			header.display_skill(Cracking)
			add_line("[ OK ] cracking module loaded")
			update_context(Context.CRACKING)
			add_line(ContextCommands.get_help_text(Cracking))
		"load matching", "cd matching":
			add_line("[ .. ] loading matching module")
			#header.update_header(Matching)
			header.display_skill(Matching)
			add_line("[ OK ] matching module loaded")
			update_context(Context.MATCHING)
			add_line(ContextCommands.get_help_text(Matching))
		"load hacking", "cd hacking":
			if process_running:
				add_line("[color=red]Process currently running. Must kill current process to navigate to Hacking module.")
				return
			var tween = create_tween()
			tween.tween_property(terminal_root, "modulate:a", 0.0, 0.5)
			tween.parallel().tween_property(hud_monitor, "modulate:a", 0.0, 0.5)
			await tween.finished
			terminal_root.visible = false
			await loading.show_loading()
			hacking.module_loaded()
			current_context = Context.HACKING
		#"marketplace -auth": #Go to marketplace
			#add_line("[ .. ] requesting permissions")
			#add_line("[ OK ] permission granted")
			#add_line("Connected to online marketplace")
			#update_context(Context.MARKETPLACE)
			#add_line(Marketplace.marketplace_welcome())
		"load decoding", "cd decoding":
			add_line("[ .. ] loading decoding module")
			#header.update_header(Decoding)
			header.display_skill(Decoding)
			add_line("[ OK ] decoding module loaded")
			update_context(Context.DECODING)
			add_line(ContextCommands.get_help_text(Decoding))
		"load phishing", "cd phishing":
			add_line("[ .. ] loading phishing module")
			#header.update_header(Phishing)
			header.display_skill(Phishing)
			add_line("[ OK ] phishing module loaded")
			update_context(Context.PHISHING)
			add_line(ContextCommands.get_help_text(Phishing))
		"load defragging", "cd defragging":
			add_line("[ .. ] loading defragging module")
			#header.update_header(Defragging)
			header.display_defragging()
			add_line("[ OK ] defragging module loaded")
			update_context(Context.DEFRAGGING)
			add_line(ContextCommands.get_help_text(Defragging))
		"load compiling", "cd compiling":
			add_line("[ .. ] loading compiling module")
			header.display_skill(Compiling)
			update_context(Context.COMPILING)
			add_line(ContextCommands.get_help_text(Compiling))
		_:#default
			if text.begins_with("cd"):
				var nt = text.substr(2).strip_edges()
				add_line("Cannot find path %s. [color=#666666]example cd command: cd mining[/color]" % nt)
			else:
				add_line("Command not found")

func return_to_root():
	header.update()
	update_context(Context.ROOT)
	add_line(Ascii.root)
	add_line(ContextCommands.info_command_text())
	#add_line(ContextCommands.all_commands())

func handle_apt_commands(text):
	if text == "apt":
		add_line(ContextCommands.get_root_upgrades_text())
		return
	
	var t_array = text.split(" ")
	
	if t_array.size() == 2:
		#check if its an "apt <skill>" command
		for upgrade_name in Upgrades.all_upgrades:
			if t_array[1].to_lower() == upgrade_name.skill.SKILL.name.to_lower():
				add_line(ContextCommands.get_skill_upgrades_text(upgrade_name))
				return
		#see if [1] is a valid package to get info from
		if !Upgrades.is_valid_package(t_array[1]):
			add_line("Package not found. [color=#666666]example: apt mining.speed[/color]")
			return
			
		add_line(ContextCommands.get_upgrades_package_info(t_array[1]))
		return
			
	if t_array.size() != 3 and t_array.size() != 2:
		add_line("Apt command not recognized. [color=#666666]example: apt mining.speed[/color]")
		return
		
	if !Upgrades.is_valid_package(t_array[2]):
		add_line("Package not found. [color=#666666]example: apt install mining.speed[/color]")
		return
	if t_array[1] == "install":
		if Upgrades.is_at_max_level(t_array[2]):
			add_line("Package fully upgraded.")
			return
		
		var package = Upgrades.get_package_info(t_array[2])
		var req = Upgrades.get_upgrade_requirement_from_package(package)
		if !Upgrades.has_upgrade_requirements(t_array[2]):
			add_line("\nRequirements missing")
			for r in req:
				var player_amount = Inventory.get_amount(r.item)
				if player_amount < r.amount:
					add_line(r.item.name + " [color=red]" + str(player_amount) + "/" + str(r.amount) + "[/color]")
				else:
					add_line(r.item.name + " [color=green]" + str(player_amount) + "/" + str(r.amount) + "[/color]")
			return
			
		#at this point player has requirements and the package can be upgraded
		add_line("Preparing to install " + t_array[2] + " package.")
		add_line("This upgrade will consume the following:")
		for r in req:
			add_line(r.item.name + " x" + str(r.amount))
		add_line("[color=green]Are you sure you want install this package?[/color] y/n")
		awaiting_player_input = true
		current_player_input_context = PlayerInputContext.UPGRADES
		upgrade_package_selected = package
		return
	
	add_line("apt command not recognized. Use 'apt' for upgrade manager.")

##player gave acceptable input
func accept_player_input(text):
	text = text.to_lower().strip_edges()
	match current_player_input_context:
		PlayerInputContext.NONE:
			return
		PlayerInputContext.UPGRADES:
			if text == "y":
				await apply_apt_package_upgrade()
			upgrade_package_selected = null
			current_player_input_context = PlayerInputContext.NONE
			awaiting_player_input = false

func apply_apt_package_upgrade():
	#RECONFIRM PLAYER HAS REQUIREMENTS
	var req = Upgrades.get_upgrade_requirement_from_package(upgrade_package_selected)
	for r in req:
		if Inventory.get_amount(r.item) < r.amount:
			add_line("You no longer have required resources for this upgrade. Terminating install.")
			return
	#REMOVE REQUIREMENTS FROM PLAYER
	for r in req:
		Inventory.remove_resource(r.item, r.amount)
		add_line("removing " + r.item.name + " x" + str(r.amount))
	
	accepting_player_inputs = false
	add_line("downloading updated package...")
	await bro_wait(0.2)
	add_line("unpacking update packages..")
	await bro_wait(0.6)
	add_line("installing upgrades")
	await bro_wait(2.0)
	add_line("configuring optimal settings")
	await bro_wait(0.8)
	add_line("upgrade complete")
	var completion_text = Upgrades.get_completion_text(upgrade_package_selected)

	add_line(completion_text)
	
	Upgrades.package_aquired(upgrade_package_selected)
	accepting_player_inputs = true
	#do awaits, add_line(ascii progress bar download (maybe multiple)) and random text
	# apply upgrades (i'll do this)
	#satisfying finish
	#unlock player

func bro_wait(time: float):
	await get_tree().create_timer(time).timeout

##INFO COMMANDS
func handle_info_commands(text):
	if text == "info":
		add_line(ContextCommands.info_command_text())
		Tutorial.complete_event(Tutorial.TutorialEvent.INFO_COMMAND)
		return
	
	var command = text.split(" ")
	if command.size() < 2 or command.size() > 3:
		add_line("info command not recognized")
		return
	
	if command.size() == 2:
		for p in major_processes:
			var n = p.SKILL.name.to_lower()
			if command[1] == n:
				
				add_line(ContextCommands.get_help_text(p))
				if n == "mining":
					Tutorial.complete_event(Tutorial.TutorialEvent.INFO_MINING_COMMAND)
				return
	
	if command.size() == 3:
		if command[1].to_lower() == "hacking":
			var locations = [Stats.hacking_targets["School"], Stats.hacking_targets["Library"], Stats.hacking_targets["Small Business"]]
			for loc in locations:
				if loc["name"].to_lower().replace(" ", "-") == command[2]:
					add_line(ContextCommands.get_hack_target_info(loc))
					return
		elif command[1].to_lower() == "defragging":
			for minor_p in Defragging.minor_processes:
				if command[2].to_lower() == minor_p.name.to_lower():
					add_line(ContextCommands.get_mp_dfg_info(Defragging, minor_p))
					return
		else:
			for p in major_processes:
				var n = p.SKILL.name.to_lower()
				if command[1] == n:
					for mp in p.minor_processes:
						if command[2] == mp.name.to_lower().replace(" ", "-"):
							add_line(ContextCommands.get_mp_info(p, mp))
							if p == Phishing and mp == Phishing.SPEAR:
								Tutorial.complete_event(Tutorial.TutorialEvent.PHISH_SPEAR_INFO)
							return
	add_line("info command not recognized")
	add_line("info commands")
	add_line("-----------------")
	add_line("info                        overview of all main skills                  [color=gray]ex. info[/color]")
	add_line("info [skill]                overview of specific skill and processes     [color=gray]ex. info mining[/color]")
	add_line("info [skill] [process]      overview of specific processes               [color=gray]ex. info mining logs[/color]")

##VM TOKENS
#command vm [process] [minor process] [optional flag -r]
#command example: vm mining basic -r
func handle_vm_token_commands(text):
	if text == "ssh -h":
		add_line(ContextCommands.ssh_help_commands())
		return
		
	var processes = [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling]
	var target_process = null
	if text == "ssh":
		add_line(ContextCommands.ssh_commands(processes))
		return
	var commands = text.split(" ")
	
	#LIST MINOR PROCESSES AVAILABLE FOR SSH/VM example: ssh mining -> list logs, quality logs, etc
	if commands.size() == 2:
		#is 2nd array index a skill name
		for p in processes:
			if commands[1] == p.SKILL.name.to_lower():
				add_line(ContextCommands.list_vm_terminals_for_skill(p))
				return
	#confirm commands size
	if commands.size() < 3 or commands.size() > 4:
		add_line("SSH command not recognized     [color=#888888]example usage: ssh mining logs[/color]")
		return
	
		
	#find major process
	for p in processes:
		if p.SKILL.name.to_lower() == commands[1]:
			target_process = p
	if target_process == null:
		add_line("process not recognized")
		return
	
	#find minor process
	var target_minor_process = null
	if commands[2].is_valid_int():
		if int(commands[2]) >= 0 and int(commands[2]) < target_process.minor_processes.size():
			target_minor_process = target_process.minor_processes[int(commands[2])]
	else:
		for mp in target_process.minor_processes:
			if commands[2] == mp.name.to_lower():
				target_minor_process = mp
	if target_minor_process == null:
		add_line(target_process.name + " process not recognized")
		return
	
	if Inventory.get_amount(target_process.vm_token) <= 0:
		add_line("VM Token for " + target_process.name + " not found.")
		return
	
	if !target_minor_process.unlocked:
		add_line("Process is not unlocked")
		return
	
	if !target_process.has_requirements(target_minor_process):
		add_line(target_process.missing_requirements_text(target_minor_process))
		return
	#check # of vm processes running
	if target_process.CURRENT_VMS >= target_process.MAX_VMS:
		add_line("Maximum virtual machines running.")
		return
	
	if Stats.CURRENT_ALL_VMS >= Stats.MAX_ALL_VMS:
		add_line("Maximum total virtual machines running.")
		return
		
	
	Inventory.remove_resource(target_process.vm_token, 1)
	
	var new_window = target_process.create_vm_window(target_minor_process, true)
	
	add_child(new_window)


	var parent_window = get_window()
	var center_pos = parent_window.position + parent_window.size - new_window.size
	new_window.position = center_pos
	new_window.popup_centered()
	new_window.transient = false
	new_window.always_on_top = true
	new_window.start()
	new_window.size = new_window.min_size
	await get_tree().process_frame
	grab_all_focus()
	Tutorial.complete_event(Tutorial.TutorialEvent.RUN_VM_WITH_SSH)

func grab_all_focus():
	get_window().grab_focus()
	input_line.grab_focus()
	

func sticky_current_process():
	current_process.reparent(terminal_grandparent, false)
	terminal_grandparent.call_deferred("move_child", current_process, 0)
	add_line("Process stickied to top.")

func unstick_current_process():
	if current_process:
		current_process.reparent(terminal_body_container, false)
		add_new_scrollback()

###################################################
################### MINING ########################
###################################################
func mining_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Mining.minor_processes:
		if text == ms["command"]:
			if !process_running:
				start_log_mining(ms)
			else:
				add_line(ContextCommands.process_already_running_text())
			return
	match text:
		"stop":
			process_running = false
			unstick_current_process()
			if current_process:
				current_process.stop()
				current_process = null
				current_process_info = {}
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current data mine...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_FOCUS)
			else:
				add_line("No process found to focus")
		"root", "..", "cd ..":
			return_to_root()
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_log_mining(minor_process: Dictionary):
	if !minor_process.unlocked:
		add_line("Requires mining level " + str(minor_process["unlock level"]))
		return
	var new_data_mining_terminal = mining_scene.instantiate()
	terminal_body_container.add_child(new_data_mining_terminal)
	new_data_mining_terminal.set_mine_type(minor_process)
	process_running = true
	current_process = new_data_mining_terminal
	current_process_info = minor_process
	new_data_mining_terminal.start_data_mining()
	hud_process_running.process_started(Mining, minor_process)
	add_new_scrollback()
	Tutorial.complete_event(Tutorial.TutorialEvent.RUN_MINING_LOG)

func data_mining_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Data mining safely finished.")

###################################################
################### PARSING #######################
###################################################
func log_parsing_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Parsing.minor_processes:
		if text == ms["command"]:
			if !process_running:
				start_parsing(ms)
			else:
				add_line(ContextCommands.process_already_running_text())
			return
	match text:
		"stop":
			process_running = false
			unstick_current_process()
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
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
		"root", "..", "cd ..":
			return_to_root()
		"info":
			add_line("Module: Parsing")
			add_line("Level:         " + str(Parsing["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Parsing["experience"]) + " / " + str(Stats.xp_for_level(Parsing["level"] + 1)))
			#Effeciency
			var eff = Parsing["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Parsing["efficiency description"])
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_parsing(minor_process: Dictionary):
	if !minor_process.unlocked:
		add_line("Requires parsing level " + str(minor_process["unlock level"]))
		return
	if Inventory.get_amount(minor_process["requirements"]) <= 0:
		add_line("No logs found.")
		return
	var new_log_parsing_terminal = log_parsing_scene.instantiate()
	terminal_body_container.add_child(new_log_parsing_terminal)
	new_log_parsing_terminal.set_parse_type(minor_process)
	process_running = true
	current_process = new_log_parsing_terminal
	current_process_info = minor_process
	new_log_parsing_terminal.start()
	hud_process_running.process_started(Parsing, minor_process)
	add_new_scrollback()

func log_parsing_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Parsing safely finished.")

###################################################
#################### CRACKING #####################
###################################################
func password_unscramble_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Cracking.minor_processes:
		if text == ms["command"]:
			if !process_running:
				start_cracking(ms)
			else:
				add_line(ContextCommands.process_already_running_text())
			return
	match text:
		"stop":
			unstick_current_process()
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
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
		"root", "..", "cd ..":
			return_to_root()
		"info":
			add_line("Module: Cracking")
			add_line("Level:         " + str(Stats.player_stats["Cracking"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Cracking"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Cracking"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Cracking"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Cracking"]["efficiency description"])
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_cracking(minor_process: Dictionary):
	if !minor_process.unlocked:
		add_line("Process not unlocked")
		return
	if Inventory.get_amount(minor_process["requirements"]) <= 0:
		add_line(minor_process["requirements"]["name"] + " not found")
		return
	var new_pw_cracking_terminal = pw_cracking_scene.instantiate()
	terminal_body_container.add_child(new_pw_cracking_terminal)
	new_pw_cracking_terminal.set_cracking_type(minor_process)
	process_running = true
	current_process = new_pw_cracking_terminal
	current_process_info = minor_process
	new_pw_cracking_terminal.start()
	hud_process_running.process_started(Cracking, minor_process)
	add_new_scrollback()

func password_cracking_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Password cracking safely finished.")

###################################################
################### CRED MATCHING #################
###################################################
func cred_matching_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Matching.minor_processes:
		if text == ms["command"]:
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			var missing = false
			for item in ms["requirements"]:
				if Inventory.get_amount(item) <= 0:
					add_line("Missing required resource: " + item.name)
					missing = true
			if missing:
				return
			
			start_matching(ms)
			return
	match text:
		"stop":
			unstick_current_process()
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
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
		"root", "..", "cd ..":
			return_to_root()
		"info":
			add_line("Module: Matching")
			add_line("Level:         " + str(Stats.player_stats["Credential Matching"]["level"]))
			#Level
			#Experience
			add_line("Experience:    " + str(Stats.player_stats["Credential Matching"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Credential Matching"]["level"] + 1)))
			#Effeciency
			var eff = Stats.player_stats["Credential Matching"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Credential Matching"]["efficiency description"])
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_matching(minor_process):
	if !minor_process.unlocked:
		add_line("Process not unlocked")
		return
	
	var new_cred_matching_terminal = cred_matching_scene.instantiate()
	terminal_body_container.add_child(new_cred_matching_terminal)
	new_cred_matching_terminal.set_type(minor_process)
	process_running = true
	current_process = new_cred_matching_terminal
	current_process_info = minor_process
	new_cred_matching_terminal.start()
	hud_process_running.process_started(Matching, minor_process)
	add_new_scrollback()

func cred_matching_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Matching safely finished.")
	

###################################################
############### CACHE DECRYPTING ##################
###################################################
func cache_decrypting_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Decoding.minor_processes:
		if text == ms["command"]:
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			if !Inventory.has_cache():
				add_line("No caches found.")
				return
				
			start_cache_decrypting(ms)
			return
	
	match text:
		"stop":
			unstick_current_process()
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
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
		"root", "..", "cd ..":
			return_to_root()
		"info":
			add_line("Module: Cache Decrypting")
			add_line("Level:         " + str(Stats.player_stats["Cache Decrypting"]["level"]))
			add_line("Experience:    " + str(Stats.player_stats["Cache Decrypting"]["experience"]) + " / " + str(Stats.xp_for_level(Stats.player_stats["Cache Decrypting"]["level"] + 1)))
			var eff = Stats.player_stats["Cache Decrypting"]["efficiency"]
			add_line("Efficiency:    " + str(float(eff * 100.0)) + "%     " + Stats.player_stats["Cache Decrypting"]["efficiency description"])
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_cache_decrypting(minor_process):
	if !minor_process.unlocked:
		add_line("Process not unlocked")
		return
		
	var new_cache_decrypt_terminal = cache_decrypt_scene.instantiate()
	terminal_body_container.add_child(new_cache_decrypt_terminal)
	new_cache_decrypt_terminal.set_cache_type(minor_process)
	process_running = true
	current_process = new_cache_decrypt_terminal
	current_process_info = minor_process
	new_cache_decrypt_terminal.start_decrypting()
	hud_process_running.process_started(Decoding, minor_process)
	add_new_scrollback()

func cache_decrypting_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Cache decrypting safely finished.")

func overclock_logic():
	if !process_running: #no process running
		add_line("No process running to overclock")
		return
	if Stats.overclocked: #already overclocked
		add_line("System is already overclocked")
		return
	if !Upgrades.can_overclock(_get_major_from_minor(current_process_info)):
		add_line("Overclock not available. Check upgrade package manager with 'apt'.")
		return
	if Stats.overheated: #overheated - still recovering
		add_line("System has been overheated, needs to cool to below 80°C.")
		return
	if Stats.system_tempature >= 80: #cant overclock above 60
		add_line("System tempature needs to cool to below 80°C before overclocking")
		return
	Stats.overclocked = true

###################################################
################### PHISHING ######################
###################################################
func phishing_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Phishing.minor_processes:
		if text == ms["command"]:
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			if !ms.unlocked:
				add_line("Process not unlocked")
				return
				
			cast_line(ms, -1)
			return
	match text:
		"stop":
			unstick_current_process()
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
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
		"root", "..", "cd ..":
			return_to_root()
		"info":
			add_line("Module: Phishing")
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func cast_line(type: Dictionary, t_lines: int):
	if current_process is PhishingTerminal:
		current_process.cast_lines(type, t_lines)
	else:
		var new_phishing_terminal = phishing_scene.instantiate()
		terminal_body_container.add_child(new_phishing_terminal)
		process_running = true
		current_process = new_phishing_terminal
		current_process_info = type
		new_phishing_terminal.cast_lines(type, t_lines)
		hud_process_running.process_started(Phishing, type)
		add_new_scrollback()

func phishing_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Phishing process finished.")

###################################################
################### COMPILING #####################
###################################################
func compiling_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Compiling.minor_processes:
		if text == ms["command"]:
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			var missing = false
			for req in ms["requirements"]:
				if Inventory.get_amount(req.item) < req.amount:
					add_line("Missing required resource: " + req.item.name + " x" + str(req.amount))
					missing = true
			if missing:
				return
			
			start_compiling(ms)
			return
	match text:
		"stop":
			unstick_current_process()
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"stop -s":
			add_line("Finishing current compile...")
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
		"root", "..", "cd ..":
			return_to_root()
		"overclock":
			overclock_logic()
		"overclock -kill":
			if !Stats.overclocked:
				add_line("Not currently overclocking.")
			if Stats.overclocked and process_running:
				add_line("Killing overclock.")
			Stats.overclocked = false
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_compiling(minor_process: Dictionary):
	if !minor_process.unlocked:
		add_line("Process not unlocked")
		return
	
	var new_compiling_terminal = compiling_scene.instantiate()
	terminal_body_container.add_child(new_compiling_terminal)
	process_running = true
	current_process = new_compiling_terminal
	current_process_info = minor_process
	new_compiling_terminal.start(minor_process)
	hud_process_running.process_started(Compiling, minor_process)
	add_new_scrollback()

func compiling_ended_safely():
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Compiling stopped.")

###################################################
################### DEFRAGGING ####################
###################################################
func defragging_commands(text):
	text = text.to_lower().strip_edges()
	
	for ms in Defragging.minor_processes:
		if text == ms["command"]:
			if process_running:
				add_line("Process already running.")
				return
			if !ms.unlocked:
				add_line(ms.name + " defragging not unlocked. Purchase from marketplace.")
				return
			if Defragging.on_cooldown():
				add_line("Defragging module is currently cooling down.")
				return
			start_defragging(ms)
			return
	match text:
		"stop":
			unstick_current_process()
			process_running = false
			if current_process:
				add_line("Killing process immediately")
				current_process.stop()
				current_process = null
				current_process_info = {}
			else:
				add_line("No active process to stop.")
			Stats.overclocked = false
		"focus":
			if current_process:
				bring_process_to_bottom()
			else:
				add_line("No process found to focus")
		"root", "..", "cd ..":
			return_to_root()
		"info":
			add_line("???")
		"overclock":
			add_line("Overclock not available for defragging.")
		_:
			if text.begins_with("cd"):
				add_line(ContextCommands.cd_not_at_root())
			else:
				add_line("Command not found")

func start_defragging(minor_skill: Dictionary):
	if !Defragging.has_requirements(minor_skill):
		add_line("Missing requirements: " +  minor_skill.requirements.item.name + " x" + str(minor_skill.requirements.amount))
		return

	var new_defrag_terminal = defrag_scene.instantiate()
	terminal_body_container.add_child(new_defrag_terminal)
	process_running = true
	current_process = new_defrag_terminal
	current_process_info = minor_skill
	new_defrag_terminal.start(minor_skill)
	hud_process_running.process_started(Defragging, minor_skill)
	add_new_scrollback()

func defrag_finished():
	unstick_current_process()
	process_running = false
	current_process = null
	current_process_info = {}
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line("Defragging process ended.")

###################################################
################# MARKETPLACE #####################
###################################################
func marketplace_commands(text):
	text = text.to_lower().strip_edges()
	
	if text == "exit":
		#header.update_header()
		header.update()
		update_context(Context.ROOT)
		update_market_context(MarketContext.MAIN)
		Marketplace.viewing_item = null
		Marketplace .viewing_skill = null
		add_line("Saftely exiting marketplace")
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
		"8": #DEFRAGGING
			add_line(Marketplace.upgrades_details(Defragging))
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
			_:
				add_line("Command not found")

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
	header.update()
	await loading.show_loading()
	terminal_root.modulate.a = 0.0
	terminal_root.visible = true
	input_line.grab_focus()
	var tween = create_tween()
	tween.tween_property(terminal_root, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(hud_monitor, "modulate:a", 1.0, 1.0)
	await tween.finished
	current_context = Context.ROOT

func _on_cooling_timer_timeout():
	var amount_to_cool = Stats.cooling_amount
	if Stats.OVERHEAT_FAN and Stats.overheated:
		amount_to_cool += -0.3
	Stats.update_tempature(amount_to_cool)

func _scroll_to_bottom():
	await get_tree().process_frame
	await get_tree().process_frame
	terminal_body.set_deferred("scroll_vertical", terminal_body.get_v_scroll_bar().max_value)

func _get_major_from_minor(current_process_info: Dictionary):
	for major in major_processes:
		for min in major.minor_processes:
			if current_process_info == min:
				return major

func _clear_terminal():
	if terminal_body_container.get_children().size() > 0:
		for child in terminal_body_container.get_children():
			if child != current_process:
				child.queue_free()
		lines.clear()
		var ns = scrollback.instantiate()
		terminal_body_container.add_child(ns)
		current_scrollback = ns

func _kill_current_process():
	var main_skill = _get_major_from_minor(current_process_info)
	add_line("Process killed: " + main_skill.SKILL.name + " - " + current_process_info.name)
	hud_process_running.process_killed()
	current_process.stop()
	current_process = null
	current_process_info = {}

func system_cooled_out_of_overheat_range():
	NOTIFY_OF_OVERHEAT = false
	add_line("[color=blue]System no longer overheated.[/color]")

func overheat_terminal_notice():
	if NOTIFY_OF_OVERHEAT:
		return
	if Stats.overheated:
		NOTIFY_OF_OVERHEAT = true
		add_line("[color=red]SYSTEM OVERHEATED - ALL PROCESSES SLOWED[/color]")
		add_line("Cool system to < 80 to resume processes as normal.")
