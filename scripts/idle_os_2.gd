extends Control

#FINAL TODO LIST FOR 1.0

#STEAM ACHIEVEMENTS
#CLOUD SAVING
#BUILD OUT ENDING OF GAME

#MINING | PARSING | CRACKING | MATCHING | PHISHING | COMPILING | HACKING | DECODING | DEFRAGGING

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
@onready var hud_process_running = $Panel/SystemDock/VBox/HUDProcessRunning
@onready var system_dock = $Panel/SystemDock
@onready var hud_monitor = $Panel/SystemDock/VBox/TrackedSection/HUDMonitor
@onready var vm_layer = $VMLayer
@onready var overclock = $Panel/SystemDock/VBox/SystemTemp #temperature widget (lives in the side panel)
@onready var input_line_container = $Panel/MarginContainer/TerminalRoot/MarginContainer/TerminalGrandparent/InputLineContainer

@onready var scrollback = preload("res://scenes/scrollback.tscn")
@onready var mining_scene = preload("res://scenes/data_mining_terminal.tscn")
@onready var log_parsing_scene = preload("res://scenes/log_parsing_terminal.tscn")
@onready var pw_cracking_scene = preload("res://scenes/pw_cracking_terminal.tscn")
@onready var cred_matching_scene = preload("res://scenes/cred_matching_terminal.tscn")
@onready var cache_decrypt_scene = preload("res://scenes/cache_decrypt_terminal.tscn")
@onready var phishing_scene = preload("res://scenes/phishing_terminal.tscn")
@onready var defrag_scene = preload("res://scenes/defrag_terminal.tscn")
@onready var compiling_scene = preload("res://scenes/compiling_terminal.tscn")
@onready var flow_chart_scene = preload("res://scenes/flow_chart.tscn")


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
var upgrade_bulk_plan: Array = [] # apt install <skill>/all: [{package, level}]
var upgrade_package_selected = null
var upload_awaiting_player_input: bool = false

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

var major_processes = [Mining, Parsing, Cracking, Matching, Phishing, Compiling, Decoding, Hacking, Defragging] # header order (2026-10-29)

var output_queue: Array[String] = []
var processing_queue = false

var RICHTEXT_LABEL_LINE_LIMIT = 20 #lines per richtextlabel (aka terminal read) before creating a new one
var RICHTEXT_LABEL_LIMIT = 40 #amount of richtextlabels before starting to remove old ones (2026-10-24: was 10 = ~200 lines, a full ls lost its top)

var NOTIFY_OF_OVERHEAT: bool = false

#player_tabbed is so player can press tab for a different option if one exists
var PLAYER_TABBED: int = 0
var SAVED_LAST_SUBMITTED: String = ""

## The command that started the main terminal's process (Offline resumes it): {"context", "text"}
var main_command := {}

func _ready():
	add_to_group("main_os")
	Signals.system_message_signal.connect(add_line)
	# side panel width drives terminal margins + table width (connect before the save loads)
	system_dock.width_changed.connect(_on_panel_width_changed)
	terminal_body.resized.connect(_update_line_capacity)
	_on_panel_width_changed(system_dock.get_panel_width())
	current_scrollback = original_scrollback
	update_context(Context.ROOT)
	header.update()
	input_line.grab_focus()
	
	if not SaveManager.load_game():
		Signals.system_temp_updated(30)
	Offline.compute() # offline gains are applied right away (booting saves); shown after the boot
	Uploads.tier_completed.connect(func(t): add_line(ContextCommands.tier_complete_text(t))) # (after compute: offline ones are in the download)
	Uploads.complete_met_tiers() # goals lowered since the save was made (2026-10-24: School 300 -> 150)
	if Tutorial.DEV_ALWAYS_SHOW_INTRO:
		Tutorial.show_intro = true
	if !Tutorial.show_intro:
		_start_music.call_deferred()
		add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")
		add_line(ContextCommands.demo_welcome_message())
		add_line("To get started, type `-h` in the terminal.")
		if Tutorial.should_show_old_save_notice():
			add_line(Tutorial.old_save_notice())
		_offline_welcome.call_deferred()
	Exp.process_unlocked_signal.connect(_flush_unlocks)
	Signals.process_ended_safely_signal.connect(_on_skill_process_ended)
	Signals.defrag_finished_signal.connect(_on_process_ended.bind("Defragging process ended."))
	Signals.vm_window_focused_signal.connect(grab_all_focus)
	VMManager.set_host(vm_layer)
	tutorial_window = TutorialWindow.new()
	tutorial_window.top_anchor = header
	vm_layer.add_child(tutorial_window)
	Signals.tutorial_event_completed_signal.connect(tutorial_event_completed)
	Signals.system_overheated_signal.connect(overheat_terminal_notice)
	Signals.system_cooled_below_overheat_signal.connect(system_cooled_out_of_overheat_range)
	
	##cooling timer
	cooling_timer.wait_time = Stats.cooling_frequency
	cooling_timer.start()
	
	if Tutorial.show_intro:
		accepting_player_inputs = false
		header.visible = false
		input_line_container.visible = false
		system_dock.modulate.a = 0.0 # the boot sequence brings the panel in section by section
		tutorial_window.set_context_hidden(true) # shown with the welcome message (_finish_boot)
		header.prepare_intro()
		intro_to_game()


#update previous lines
func set_line(index: int, text: String, scroll_to_line: bool = false):
	if index >= 0 and index < lines.size():
		lines[index] = text
	update_terminal(scroll_to_line)

## 2 unrecognized commands in a row -> a one-line nudge toward 'hint' (_on_input_line_text_submitted)
var _cmd_unknown := false
var _unknown_streak := 0
var _unknown_re: RegEx

func add_line(text: String) -> void:
	if _unknown_re == null:
		_unknown_re = RegEx.new()
		_unknown_re.compile("(?i)command not found|not recognized|not a recognized")
	if _unknown_re.search(text) != null:
		_cmd_unknown = true
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

## Posts a box-and-arrow chart (scenes/flow_chart.tscn) into the terminal, below any text still printing.
## <setup> gets the chart and returns false when there's nothing to draw.
func post_flow_chart(setup: Callable) -> void:
	while processing_queue or !output_queue.is_empty():
		await get_tree().process_frame
	var chart = flow_chart_scene.instantiate()
	terminal_body_container.add_child(chart)
	if !setup.call(chart):
		chart.queue_free()
		return
	add_new_scrollback()
	_scroll_to_bottom.call_deferred()

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
	PLAYER_TABBED = 0
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
			
	var text_with_lead = get_context_lead() + " " + new_text
	input_line.clear()
	add_line(text_with_lead)
	command_history.append(new_text)
	
	if new_text == "sudo rm -rf":
		add_line("UNINSTALLING PROCESSES")
		for process in major_processes:
			add_line(process.SKILL.name + ".....removed")
			await get_tree().create_timer(0.1).timeout
		
		add_line("REMOVING ITEMS")
		for item in Inventory.inventory:
			add_line("Deleting " + item.name + " x" + str(Inventory.get_amount(item)))
			await get_tree().create_timer(0.2).timeout
		
		add_line("Uninstalling upgrades....")
		for id in Upgrades.installed_package_ids():
			add_line(id + "......uninstalled")
			await get_tree().create_timer(0.4).timeout
		
		add_line("SAVING")
		await get_tree().create_timer(0.8).timeout
		add_line("GOODBYE")
		await get_tree().create_timer(1.2).timeout
		SaveManager.save_game()
		get_tree().quit()
	
	var was_running = process_running
	_cmd_unknown = false
	if !universal_commands(new_text) and !_run_skill_from_anywhere(new_text):
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
	if !was_running and process_running and current_process != null:
		main_command = {"context": int(current_context), "text": new_text} # what Offline resumes
	if _cmd_unknown:
		_unknown_streak += 1
		if _unknown_streak == 2:
			add_line("[color=#888888]lost? try[/color] [color=#4ec994]hint[/color] [color=#888888]for what to run next[/color]")
	else:
		_unknown_streak = 0

	history_index = -1

## Skills are "installed system-wide" (like binaries on $PATH): 'mine -logs', 'parse -footprint=logs',
## 'crack -password', 'match -credential', 'phish -spear', 'decode -cache', 'compile -school' run from any
## directory. 'cd <skill>' is still where its process table, info and help live. Returns true when <text>
## was a skill command typed outside its own directory (it runs there without changing directory).
const SKILL_BINARIES = {"mine": "MINING", "parse": "PARSING", "crack": "CRACKING", "match": "MATCHING",
	"phish": "PHISHING", "decode": "DECODING", "compile": "COMPILING", "defrag": "DEFRAGGING"}
const SKILL_INFO_ALIASES = {"mine": "mining", "mining": "mining", "parse": "parsing", "parsing": "parsing",
	"crack": "cracking", "cracking": "cracking", "match": "matching", "matching": "matching", "phish": "phishing",
	"phishing": "phishing", "decode": "decoding", "decoding": "decoding", "compile": "compiling", "compiling": "compiling",
	"defrag": "defragging", "defragging": "defragging", "hacking": "hacking"}
func _run_skill_from_anywhere(text: String) -> bool:
	var t = text.to_lower().strip_edges()
	var verb = t.split(" ", false)[0] if t != "" else ""
	if !SKILL_BINARIES.has(verb) or t == verb:
		return false
	var ctx = Context[SKILL_BINARIES[verb]]
	if current_context == ctx or current_context == Context.HACKING:
		return false # in its own directory the skill's handler runs as before
	match ctx:
		Context.MINING: mining_commands(t)
		Context.PARSING: log_parsing_commands(t)
		Context.CRACKING: password_unscramble_commands(t)
		Context.MATCHING: cred_matching_commands(t)
		Context.PHISHING: phishing_commands(t)
		Context.DECODING: cache_decrypting_commands(t)
		Context.COMPILING: compiling_commands(t)
		Context.DEFRAGGING: defragging_commands(t)
	return true

## 'which <command>': where a skill binary lives
func which_text(arg: String) -> String:
	var verb = arg.strip_edges().split(" ", false)[0] if arg.strip_edges() != "" else ""
	if verb == "":
		return "usage: which <command>  [color=#666666]ex. which mine[/color]"
	if SKILL_BINARIES.has(verb):
		return "/usr/local/bin/" + verb
	if verb in ["hack"]:
		return "/opt/idleos/hacking/hack  [color=#666666](runs inside the Hacking module: cd hacking)[/color]"
	return "which: no %s in (/usr/local/bin:/usr/bin:/bin)" % verb

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
var tutorial_window: TutorialWindow
func update_context(new_context: Context):
	current_context = new_context
	# the tutorial window stays up in the Hacking module while the tutorial runs (its steps happen there)
	if tutorial_window and new_context == Context.HACKING and Tutorial.is_tutorial_complete():
		tutorial_window.set_context_hidden(true) # shown again in _on_hacking_start_loading
	lead_text.text = get_context_lead()

## header view for the current directory (for context changes that don't go through 'cd')
func _sync_header_to_context() -> void:
	match current_context:
		Context.MINING: header.display_skill(Mining)
		Context.PARSING: header.display_skill(Parsing)
		Context.CRACKING: header.display_skill(Cracking)
		Context.MATCHING: header.display_skill(Matching)
		Context.DECODING: header.display_skill(Decoding)
		Context.PHISHING: header.display_skill(Phishing)
		Context.COMPILING: header.display_skill(Compiling)
		Context.DEFRAGGING: header.display_defragging()
		_: header.update()

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

## With the tutorial window up the terminal only gets a one-line notice (the window has the step);
## the tutorial-complete message and a closed window still print in full.
func tutorial_event_completed(message: String):
	if current_context == Context.HACKING:
		return
	if tutorial_window and tutorial_window.is_showing() and !Tutorial.is_tutorial_complete():
		add_line("[color=green]✓ OBJECTIVE COMPLETE[/color]  %s  [color=#888888]%s  ·  next step in the tutorial window[/color]" % [Tutorial.step_title(Tutorial.last_completed) if Tutorial.last_completed != -1 else "", Tutorial.get_tutorial_progress_string()])
		return
	add_line(message)

## TESTING: 'add <item>' (+100) and 'rm <item>' (all). Turn off before release (the demo branch removed them).
const DEV_ITEM_COMMANDS := true

func universal_commands(text):
	text = text.to_lower().strip_edges()
	if text.begins_with("settings"):
		if text == "settings":
			add_line(Settings.settings_help())
			return true
		add_line(Settings.handle_settings_command(text))
		return true
	
	if text == "driver" or text == "drivers" or text.begins_with("driver "):
		# 2026-10-27: drivers live inside each skill ('cd mining' -> 'driver'); root shows a summary
		var sk = get_context_name_string(current_context) if current_context in [Context.MINING, Context.PARSING, Context.CRACKING, Context.MATCHING, Context.PHISHING, Context.DECODING, Context.COMPILING] else ""
		var out = Drivers.handle(text, sk)
		add_line(out if out != "" else "usage: driver  ·  driver -add <id>  ·  driver -rm <id>")
		return true
	if text.begins_with("ssh"):
		handle_vm_token_commands(text)
		return true
	if text == "panel" or text.begins_with("panel "):
		handle_panel_commands(text)
		return true
	if text == "vm" or text.begins_with("vm "):
		handle_vm_commands(text)
		return true
	if text.begins_with("which"):
		add_line(which_text(text.trim_prefix("which")))
		return true
	if text == "ls /usr/local/bin" or text == "ls /usr/local/bin/":
		add_line("  ".join(SKILL_BINARIES.keys()) + "  [color=#666666](every skill runs from any directory; 'cd <skill>' shows its processes)[/color]")
		return true
	if text == "trap" or text.begins_with("trap "):
		add_line(Phishing.trap_command_text(text.trim_prefix("trap")))
		return true
	# TESTING (2026-10-30): 'intel full <target>' = max intel (10% off every stat, max hacks); 'intel clear <target>'
	# (any target, locked or not; add ' hard' for the hard version)
	if DEV_ITEM_COMMANDS and (text.begins_with("intel full ") or text.begins_with("intel clear ")):
		var full = text.begins_with("intel full ")
		var tname = text.trim_prefix("intel full ").trim_prefix("intel clear ").strip_edges().to_lower()
		var tgt = {}
		for loc in Stats.hacking_targets:
			for t in Stats.hacking_targets[loc].get("targets", []):
				if t.name.to_lower() == tname:
					tgt = t
		if tgt.is_empty():
			add_line("No target called '%s'. [color=#666666]ex. intel full nurse[/color]" % tname)
			return true
		if full:
			var lv = []
			for k in Decoding.INTEL_STATS.size():
				lv.append(Decoding.INTEL_MAX_STEPS)
			Decoding.intel[Decoding.intel_key(tgt)] = {"lv": lv, "dur": Decoding.intel_max_hacks(), "hacks": Decoding.intel_max_hacks()}
		else:
			Decoding.intel.erase(Decoding.intel_key(tgt))
		add_line("[color=#888888](dev) %s intel %s[/color]" % [tgt.name, "maxed" if full else "cleared"])
		SaveManager.mark_dirty()
		return true
	if text == "intel" or text.begins_with("intel "):
		add_line(Decoding.intel_command_text(text.trim_prefix("intel")))
		return true
	if text == "upload" or text.begins_with("upload ") or text.begins_with("unpack"):
		handle_upload_commands(text)
		return true
	if text.begins_with("info"):
		handle_info_commands(text)
		return true
	# 2026-10-30: a skill's name or verb on its own ('mining', 'mine') = 'info <skill>' (processes keep 'info mining logs')
	if SKILL_INFO_ALIASES.has(text.to_lower().strip_edges()):
		handle_info_commands("info " + SKILL_INFO_ALIASES[text.to_lower().strip_edges()])
		return true
	# 2026-10-30: a location's name on its own ('school', 'police station') = 'info hacking <location>'
	if Compromise.location_key(text) != "":
		add_line(ContextCommands.get_hack_target_info(Stats.hacking_targets[Compromise.location_key(text)]))
		return true
	if text == "flow":
		post_flow_chart(func(c): return c.show_loop())
		return true
	if text == "music" or text.begins_with("music "):
		var arg = text.trim_prefix("music").strip_edges()
		match arg:
			"next", "skip":
				Audiomanager.skip_track()
				add_line.call_deferred(Audiomanager.now_playing_text())
			"off", "stop":
				Settings.set_value("music_player", "off")
				add_line("Music off. 'music on' turns it back on.")
			"on", "start", "play":
				Settings.set_value("music_player", "on")
				add_line("Music on.")
			"":
				add_line(Audiomanager.now_playing_text())
				add_line("[color=#888888]music next · music off · music on · volume: settings music=50[/color]")
			_:
				add_line("music commands: music · music next · music off · music on  [color=#666666](volume: settings music=<0-100>)[/color]")
		return true
	if text in ["utility", "utilities", "util"]:
		add_line(ContextCommands.utility_commands())
		Tutorial.complete_event(Tutorial.TutorialEvent.UTILITY_COMMAND)
		return true
	if text in ["hint", "next", "lost", "hints", "help me"]:
		add_line(HintEngine.text(self))
		return true
	if text.begins_with("track"):
		var item_names = text.trim_prefix("track").strip_edges().split(",")
		add_line(hud_monitor.add_monitored_items(item_names))
		return true

	if text.begins_with("untrack"):
		var item_names = text.trim_prefix("untrack").strip_edges()
		
		if item_names in ["-a", "-all", "all"]:
			add_line(hud_monitor.remove_all())
			Tutorial.complete_event(Tutorial.TutorialEvent.UNTRACK_ITEMS)
			return true
		
		var names = item_names.split(",")
		add_line(hud_monitor.remove_monitored_items(names))
		return true
	
	if text in ["ls -h", "ls help", "ls -types", "ls types"]:
		add_line(Exploits.glossary_text())
		return true

	if text == "run" or text.begins_with("run "):
		add_line(Exploits.list_text(false))
		return true

	if text == "ls mods" or text == "ls mod":
		add_line(Inventory.list_filtered("-mods").text) # the mod items you own (equip with 'mod')
		return true
	
	if text.begins_with("ls"):
		var item_name = text.trim_prefix("ls").strip_edges()
		
		# Just "ls": grouped by type
		if item_name.is_empty():
			add_line(Inventory.list_inventory_grouped())
			Tutorial.complete_event(Tutorial.TutorialEvent.LIST_ITEMS)
			return true
		
		# "ls <item>" (exact name), else filters / name search ("ls -caches school", "ls cred")
		var item = Inventory.get_item_by_name(item_name)
		if item == null:
			var res = Inventory.list_filtered(item_name)
			if res.single == null:
				add_line(res.text)
				return true
			item = res.single
		
		add_line(Inventory.list_specific_item(item))
		
		if item.name.to_lower() == "logs":
			Tutorial.complete_event(Tutorial.TutorialEvent.LIST_LOG_DETAILS)
		
		return true
	
	if text.begins_with("apt"):
		handle_apt_commands(text)
		return true
	
	if text.begins_with("cd"):
		handle_cd_commands(text)
		return true
	
	if DEV_ITEM_COMMANDS and text.begins_with("add"):
		# 'add mods t2' / 'add exploits t2' [amount]: one (or <amount>) of every mod / Exploit of that tier (2026-10-29)
		var bulk = text.trim_prefix("add").strip_edges().split(" ", false)
		if bulk.size() >= 2 and bulk[0] in ["mods", "exploits"] and bulk[1].begins_with("t") and bulk[1].substr(1).is_valid_int():
			var tier = int(bulk[1].substr(1))
			var n = int(bulk[2]) if bulk.size() > 2 and bulk[2].is_valid_int() else 1
			var items = HackingMods.pool_items(tier) if bulk[0] == "mods" else Exploits.tier_items(tier)
			for it in items:
				Inventory.add_resource(it, n)
			add_line("[color=#888888](dev) added %d of each: %s[/color]" % [n, ", ".join(items.map(func(i): return i.name))] if !items.is_empty() else "[color=#888888](dev) no %s in tier %d[/color]" % [bulk[0], tier])
			return true
		# 'add <item>' = 100, 'add <item> <amount>' (ex. add admin cache 1)
		var item_name = text.trim_prefix("add").strip_edges()
		var amount = 100
		var item = Inventory.get_item_by_name(item_name)
		var words = item_name.split(" ", false)
		if item == null and words.size() >= 2 and words[-1].is_valid_int():
			amount = int(words[-1])
			item = Inventory.get_item_by_name(" ".join(words.slice(0, words.size() - 1)))
		if item != null and amount > 0:
			Inventory.add_resource(item, amount)
			return true
	#
	# TESTING (2026-10-30): 'tutorial complete' checks off every tutorial step at once (no step rewards, no messages)
	if DEV_ITEM_COMMANDS and text == "tutorial complete":
		for e in Tutorial.steps():
			if !Tutorial.completed_events.has(e):
				Tutorial.completed_events.append(e)
		Tutorial.step_completed.emit(Tutorial.steps()[-1]) # closes the tutorial window
		SaveManager.mark_dirty()
		add_line("[color=#888888](dev) tutorial complete[/color]")
		return true
	# TESTING (2026-10-30): 'uploads set <item> <n>' sets an item's uploaded count (completes the tier when every
	# goal is met); 'uploads complete' meets every goal of the current tier
	if DEV_ITEM_COMMANDS and (text.begins_with("uploads set ") or text == "uploads complete"):
		if text == "uploads complete":
			var t = Uploads.current_tier()
			for g in Uploads.get_goals(t):
				Uploads.uploaded[g.item] = max(Uploads.get_uploaded(g.item), int(g.amount))
			Uploads.complete_met_tiers()
			add_line("[color=#888888](dev) %s upload goals met[/color]" % Uploads.get_location_name(t))
			SaveManager.mark_dirty()
			return true
		var w = text.trim_prefix("uploads set ").strip_edges().split(" ", false)
		var it = Inventory.get_item_by_name(" ".join(w.slice(0, w.size() - 1))) if w.size() >= 2 and w[-1].is_valid_int() else null
		if it == null:
			add_line("usage: uploads set <item> <amount>  [color=#666666]ex. uploads set logs 99[/color]")
			return true
		Uploads.uploaded[it] = max(0, int(w[-1]))
		Uploads.complete_met_tiers()
		add_line("[color=#888888](dev) %s uploaded: %d[/color]" % [it.name, int(Uploads.uploaded[it])])
		SaveManager.mark_dirty()
		return true
	# TESTING: 'timeskip [minutes]' (default 60): as if you quit and came back that much later (2026-10-29)
	if DEV_ITEM_COMMANDS and (text == "timeskip" or text.begins_with("timeskip ")):
		var arg = text.trim_prefix("timeskip").strip_edges()
		var mins = float(arg) if arg.is_valid_float() else 60.0
		_dev_timeskip(int(mins * 60.0))
		return true
	# TESTING: 'setlevel <skill> <level>' (raising it runs the normal level ups: tokens, driver slot notices)
	if DEV_ITEM_COMMANDS and text.begins_with("setlevel"):
		var parts = text.trim_prefix("setlevel").strip_edges().split(" ", false)
		var sk = null
		for m in [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling]:
			if parts.size() >= 1 and m.SKILL.name.to_lower() == parts[0]:
				sk = m
		if sk == null or parts.size() < 2 or !parts[1].is_valid_int():
			add_line("usage: setlevel <skill> <level>  [color=#666666]ex. setlevel mining 60[/color]")
			return true
		var lvl = clamp(int(parts[1]), 1, Exp.MAX_LEVEL)
		if lvl > int(sk.SKILL.level):
			sk.SKILL.experience = Exp.xp_for_level(lvl)
			Exp.add_xp(sk, null, 0)
		else:
			sk.SKILL.level = lvl
			sk.SKILL.experience = Exp.xp_for_level(lvl)
			Exp.refresh_efficiency(sk)
			Drivers.changed.emit()
		add_line("[color=#888888](dev) %s is now level %d[/color]" % [sk.SKILL.name, int(sk.SKILL.level)])
		SaveManager.mark_dirty()
		return true
	if DEV_ITEM_COMMANDS and text.begins_with("rm"):
		var item_name = text.trim_prefix("rm").strip_edges()
		var item = Inventory.get_item_by_name(item_name)
		if item != null:
			Inventory.remove_resource(item, Inventory.get_amount(item))
			#Inventory.add_resource(item, 1)
			return true
		#
	
	if text.begins_with("mod"):
		if text == "mod" or text == "mods":
			add_line(ContextCommands.get_mod_command())
			return true
		
		if text.begins_with("mod -rm"):
			#NO MODS ACTIVE TO REMOVE
			if HackingMods.current_mods.is_empty():
				add_line("No mods available to remove.")
				return true
			
			# 'mod -rm all' (2026-10-29): every active mod
			if text.trim_prefix("mod -rm").strip_edges() == "all":
				var names = HackingMods.current_mods.keys().map(func(m): return HackingMods.get_mod_name(m))
				for m in HackingMods.current_mods.keys():
					HackingMods.remove_mod(m)
				add_line("%s deleted." % ", ".join(names))
				add_line(ContextCommands.get_mod_command())
				return true
			#CONFIRM ID IS AN INT
			var id_to_remove = text.trim_prefix("mod -rm").strip_edges()
			if !id_to_remove.is_valid_int():
				add_line("Mod ID not recognized. [color=#666666]ex. mod -rm 0[/color]")
				return true
			
			# 2026-10-29: the ID is the slot number (typed slots)
			var mod_to_remove = HackingMods.mod_in_slot(int(id_to_remove)) if int(id_to_remove) >= 0 and int(id_to_remove) < int(HackingMods.max_mods) else -1
			if mod_to_remove == -1:
				add_line("No mod in slot '%s'. [color=#666666]ex. mod -rm 0[/color]" % id_to_remove)
				return true
			HackingMods.remove_mod(mod_to_remove)
			add_line(HackingMods.get_mod_name(mod_to_remove) + " mod deleted.")
			add_line(ContextCommands.get_mod_command())
			return true
		
		if text.begins_with("mod -add"):
			#check player even has mod items
			if !Inventory.has_mod_item():
				add_line("No mod items found in inventory.")
				return true
			
			if HackingMods.at_max_mods():
				add_line("Error: every mod slot is in use. Use the 'mod -rm <id>' command to remove active Hacking Mods.")
				return true
			
			# 'mod -add 1' or several at once: 'mod -add 1, 3, 0' (2026-10-29). IDs are read from the list as shown,
			# before anything is equipped (equipping a last copy shifts the IDs after it).
			var raw = text.trim_prefix("mod -add").strip_edges().replace(",", " ").split(" ", false)
			var mod_items = Inventory.get_hacking_mods_items()
			var picks = []
			for r in raw:
				if !r.is_valid_int() or int(r) < 0 or int(r) >= mod_items.size():
					add_line("Mod ID '%s' not recognized. [color=#666666]ex. mod -add 0  |  mod -add 1, 3, 0[/color]" % r)
					return true
				picks.append(mod_items[int(r)])
			if picks.is_empty():
				add_line("Mod ID not recognized. [color=#666666]ex. mod -add 0  |  mod -add 1, 3, 0[/color]")
				return true
			var added = 0
			for item_mod_to_add in picks:
				var why = HackingMods.add_block_reason(item_mod_to_add) # 2026-10-29: typed slots; a full type refuses (no swap)
				if why != "":
					add_line("[color=#e26d5a]%s not added: %s.[/color]" % [item_mod_to_add.name, why])
					continue
				if Inventory.get_amount(item_mod_to_add) <= 0:
					continue
				HackingMods.add_mod(item_mod_to_add)
				Inventory.remove_resource(item_mod_to_add, 1)
				add_line(item_mod_to_add.name + " added.")
				added += 1
			if added > 0:
				Tutorial.complete_event(Tutorial.TutorialEvent.EQUIP_FIRST_MOD)
			add_line(ContextCommands.get_mod_command()) # IDs shift once an item is used: show the fresh list
			return true
			
			
	match text:
		"-h", "help":
			add_line(ContextCommands.get_help())
			Tutorial.complete_event(Tutorial.TutorialEvent.RUN_HELP_COMMAND)
			return true
		"tutorial":
			if Tutorial.is_tutorial_complete() or tutorial_window == null:
				add_line(ContextCommands.get_tutorial())
			else:
				tutorial_window.open()
				add_line("[color=#888888]Tutorial window open. 'tutorial -l' prints the checklist here.[/color]")
			return true
		"tutorial -l", "tutorial list":
			add_line(ContextCommands.get_tutorial())
			return true
		"tutorial reset", "tutorial -r":
			add_line(Tutorial.reset_message(Tutorial.reset_tutorial()))
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
		"version", "v", "ver", "--version", "-v":
			add_line(ContextCommands.version_text())
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
		"welcome", "demo":
			add_line(ContextCommands.demo_welcome_message())
			return true
		"discord -c":
			var discord_link = ContextCommands.DISCORD_LINK
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
		"stop -s", "kill -s":
			if current_process:
				add_line("Stopping process after current cycle completion.")
				current_process.stop_safely()
				Tutorial.complete_event(Tutorial.TutorialEvent.STOP_MINING_PROCESS)
				return true
			else:
				add_line("No active process to stop.")
				return true
		"focus":
			if current_process:
				bring_process_to_bottom()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_FOCUS)
			else:
				add_line("No process found to focus")
			return true
		"pin", "sticky", "stick": # 'pin' is the documented one; the old names still work
			if current_process != null:
				sticky_current_process()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_STICKY)
			else:
				add_line("No process running")
			return true
		"unpin", "unsticky", "unstick":
			if current_process != null:
				unstick_current_process()
				Tutorial.complete_event(Tutorial.TutorialEvent.USE_UNSTICKY)
			else:
				add_line("No process running")
			return true
		"quit -s", "quit", "exit", "exit -s":
			quit_game()
			return true
		#"cmds":
			#add_line(ContextCommands.all_commands())
			#return true
		"system":
			add_line(ContextCommands.system_commands())
			return true

func handle_cd_commands(text):
	# 'cd root' / 'cd ~' / 'cd /' / bare 'cd': straight to the root (also typed from the hacking console)
	if text.to_lower().strip_edges() in ["cd root", "cd ~", "cd /", "cd"]:
		Tutorial.complete_event(Tutorial.TutorialEvent.RETURN_TO_ROOT)
		if current_context == Context.ROOT:
			add_line("Already at root.")
		else:
			return_to_root()
		return
	if (text.to_lower() == "cd .." or text.to_lower() == "cd ../") and current_context == Context.ROOT:
		add_line("Already at root.")
		return
	if (text.to_lower() == "cd .." or text.to_lower() == "cd ../") and current_context != Context.ROOT:
		return_to_root()
		return

	text = text.trim_prefix("cd").strip_edges()

	var move_up = false

	if text.begins_with("../"):
		move_up = true
		text = text.trim_prefix("../")

	var goal_destination = text.strip_edges()
	# 2026-10-30: 'cd hacking/<location>' opens that location's targets; add -r / -recon for its compromise lineup
	var hack_dest = {}
	if goal_destination.to_lower().begins_with("hacking/"):
		var rest = goal_destination.substr(8).strip_edges()
		var recon = false
		for fl in [" -recon", " -r"]:
			if rest.to_lower().ends_with(fl):
				recon = true
				rest = rest.substr(0, rest.length() - fl.length()).strip_edges()
				break
		var key = Compromise.location_key(rest)
		if key == "":
			add_line("No location called '%s'. [color=#666666]ex. cd hacking/school  ·  cd hacking/school -r[/color]" % rest)
			return
		if !Stats.hacking_targets[key].get("unlocked", false):
			add_line("%s is not unlocked yet." % Stats.hacking_targets[key].name)
			return
		if recon and !Compromise.has_lineup(key):
			add_line("No compromise at %s yet." % Stats.hacking_targets[key].name)
			return
		hack_dest = {"loc": key, "recon": recon}
		goal_destination = "hacking"
	
	if goal_destination == get_context_name_string(current_context).to_lower():
		add_line("Already in %s skill." % goal_destination)
		return
	
	if current_context != Context.ROOT and !move_up:
		add_line("Must move up a directory with 'cd ..'")
		return
	match goal_destination:
		"mining":
			add_line("[ .. ] loading data mining module")
			#header.update_header(Mining)
			header.display_skill(Mining)
			add_line("[ OK ] data mining module loaded")
			update_context(Context.MINING)
			add_line(ContextCommands.get_help_text(Mining))
			Tutorial.complete_event(Tutorial.TutorialEvent.NAVIGATE_MINING)
		"parsing":
			add_line("[ .. ] loading parsing module")
			#header.update_header(Parsing)
			header.display_skill(Parsing)
			add_line("[ OK ] parsing module loaded")
			update_context(Context.PARSING)
			add_line(ContextCommands.get_help_text(Parsing))
			Tutorial.complete_event(Tutorial.TutorialEvent.NAVIGATE_PARSING)
		"cracking":
			add_line("[ .. ] loading cracking module")
			#header.update_header(Cracking)
			header.display_skill(Cracking)
			add_line("[ OK ] cracking module loaded")
			update_context(Context.CRACKING)
			add_line(ContextCommands.get_help_text(Cracking))
			Tutorial.complete_event(Tutorial.TutorialEvent.NAVIGATE_CRACKING)
		"matching":
			add_line("[ .. ] loading matching module")
			#header.update_header(Matching)
			header.display_skill(Matching)
			add_line("[ OK ] matching module loaded")
			update_context(Context.MATCHING)
			add_line(ContextCommands.get_help_text(Matching))
		"hacking":
			if process_running:
				add_line("[color=red]Process currently running. Must kill current process to navigate to Hacking module.[/color]")
				return
			if tutorial_window and Tutorial.is_tutorial_complete():
				tutorial_window.set_context_hidden(true)
			var tween = create_tween()
			tween.tween_property(terminal_root, "modulate:a", 0.0, 0.5)
			tween.parallel().tween_property(system_dock, "modulate:a", 0.0, 0.5)
			await tween.finished
			terminal_root.visible = false
			await loading.show_loading()
			hacking.module_loaded()
			current_context = Context.HACKING
			if !hack_dest.is_empty(): # 'cd hacking/<location> [-r]': straight to its targets / recon lineup
				while !hacking.is_in_hacking_context:
					await get_tree().process_frame
				hacking.open_location(hack_dest.loc, hack_dest.recon)
		"decoding":
			add_line("[ .. ] loading decoding module")
			#header.update_header(Decoding)
			header.display_skill(Decoding)
			add_line("[ OK ] decoding module loaded")
			update_context(Context.DECODING)
			add_line(ContextCommands.get_help_text(Decoding))
		"phishing":
			add_line("[ .. ] loading phishing module")
			#header.update_header(Phishing)
			header.display_skill(Phishing)
			add_line("[ OK ] phishing module loaded")
			update_context(Context.PHISHING)
			add_line(ContextCommands.get_help_text(Phishing))
		"defragging":
			add_line("[ .. ] loading defragging module")
			#header.update_header(Defragging)
			header.display_defragging()
			add_line("[ OK ] defragging module loaded")
			update_context(Context.DEFRAGGING)
			add_line(ContextCommands.get_help_text_defragging(Defragging))
		"compiling":
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
		

#Root context commands
func root_commands(text):
	text = text.to_lower().strip_edges()
	if text.begins_with("hack ") or text == "hack":
		add_line("Hacking runs in its own module. Go there with 'cd hacking'.")
	elif text in ["overclock", "overclock -kill", "overclock kill"] and !process_running:
		add_line("Overclocking requires a process running in the main terminal (not VM window).")
	else:
		# a process started from root can be overclocked / given a modifier from here too
		_handle_process_commands(text, "Stopping after the current cycle...")

func return_to_root():
	header.update()
	update_context(Context.ROOT)
	add_line(Ascii.root)
	add_line(ContextCommands.info_command_text())
	#add_line(ContextCommands.all_commands())

## LEGACY demo ending ('upload parents credit card'), replaced by the Uploads system (handle_upload_commands).
## Kept for reference: player_uploaded_proper_item() still plays the old ending if called.
func _legacy_demo_upload_commands(text):
	if text == "upload":
		add_line(ContextCommands.upload_info())
		return
	
	if process_running:
		add_line("Kill current processes before uploading.")
		return
	if text.begins_with("upload"):
		var item_name = text.trim_prefix("upload").strip_edges()
		var item = Inventory.get_item_by_name(item_name)
		
		if item == null or item != Items.PARENTS_CREDIT_CARD:
			add_line("Upload command not recognized. [color=#666666]example: upload parents credit card[/color]")
			return
		
		if Inventory.get_amount(item) <= 0:
			add_line("No Parents Credit Card found. Decode Student caches for a chance to find this item.")
			return
		
		player_uploaded_proper_item()

func handle_apt_commands(text):
	var parts = Array(text.strip_edges().split(" ", false))
	if parts.size() == 1:
		add_line(ContextCommands.get_root_upgrades_text())
		return
	if parts.size() == 2:
		var arg = parts[1].to_lower()
		for g in Upgrades.groups:
			if arg == g.to_lower():
				add_line(ContextCommands.get_skill_upgrades_text(g))
				return
		if !Upgrades.is_valid_package(arg):
			add_line("Package not found. [color=#666666]example: apt system · apt system.cooling_amount[/color]")
			return
		add_line(ContextCommands.get_upgrades_package_info(arg))
		return
	# 'apt <skill> -installed': everything installed for that skill, across all tiers
	if parts.size() == 3 and parts[2].to_lower() == "-installed":
		for g in Upgrades.groups:
			if parts[1].to_lower() == g.to_lower():
				add_line(ContextCommands.get_installed_upgrades_text(g))
				return
		add_line("Skill not found. [color=#666666]example: apt mining -installed[/color]")
		return
	if parts.size() >= 3 and parts[1] == "install":
		var id = parts[2].to_lower()
		# bulk: 'apt install system' / 'apt install system -a' / 'apt install all' / 'apt install -a'
		var bulk_groups = []
		if id in ["all", "-a"]:
			bulk_groups = Upgrades.groups.duplicate()
		else:
			for g in Upgrades.groups:
				if id == g.to_lower():
					bulk_groups = [g]
		if !bulk_groups.is_empty():
			_apt_prepare_bulk(bulk_groups)
			return
		if !Upgrades.is_valid_package(id):
			add_line("Package not found. [color=#666666]example: apt install system.cooling_amount[/color]")
			return
		var package = Upgrades.get_package_info(id)
		var reason = Upgrades.install_block_reason(package)
		if reason == "Missing requirements.":
			add_line("\nRequirements missing")
			for r in Upgrades.cost_rows(Upgrades.next_level(package)):
				add_line("%s [color=%s]%d/%d[/color]" % [r.name, "green" if r.have >= r.need else "red", r.have, r.need])
			return
		if reason != "":
			add_line(reason)
			return
		var lvl = Upgrades.next_level(package)
		add_line("Preparing to install %s (%s, Tier %d)" % [id, Upgrades.level_name(package, lvl), int(lvl.tier)])
		if package.type == "capstone":
			add_line("  [color=#ffc24a]%s[/color]" % lvl.effect)
		else:
			add_line("  " + Upgrades.level_change(package, lvl, "#4ec994"))
		add_line("This upgrade will consume:")
		for r in Upgrades.cost_rows(lvl):
			add_line("  %s x%d" % [r.name, r.need])
		add_line("[color=green]Install this package?[/color] y/n")
		awaiting_player_input = true
		current_player_input_context = PlayerInputContext.UPGRADES
		upgrade_package_selected = package
		return
	add_line("apt command not recognized. Use 'apt' for the package manager.")

##player gave acceptable input
func accept_player_input(text):
	text = text.to_lower().strip_edges()
	match current_player_input_context:
		PlayerInputContext.NONE:
			return
		PlayerInputContext.UPGRADES:
			if text == "y":
				if !upgrade_bulk_plan.is_empty():
					await apply_apt_bulk_upgrade()
				else:
					await apply_apt_package_upgrade()
			upgrade_bulk_plan = []
			upgrade_package_selected = null
			current_player_input_context = PlayerInputContext.NONE
			awaiting_player_input = false

## apt-style install: package lists, unpack with a progress bar, setup, then the before/after box
## and, when it finishes a tier, the MAJOR RELEASE banner with that tier's changelog.
func apply_apt_package_upgrade():
	var package = upgrade_package_selected
	if Upgrades.install_block_reason(package) != "":
		add_line("You no longer have the required resources for this upgrade. Terminating install.")
		return
	accepting_player_inputs = false
	var lvl = Upgrades.next_level(package)
	var pkg_name = package.id.replace(".", "-").replace("_", "-")
	var new_version = Upgrades.version(package.group) + 0.1
	add_line("Reading package lists... Done")
	await bro_wait(0.25)
	add_line("Unpacking %s (%.1f) ..." % [pkg_name, new_version])
	var bar_index = await _add_live_line(_apt_progress_text(0))
	for step in range(1, 11):
		await bro_wait(0.09)
		set_line(bar_index, _apt_progress_text(step * 10), true)
	add_line("Setting up %s (%.1f) ..." % [pkg_name, new_version])
	await bro_wait(0.3)
	var result = Upgrades.install(package)
	var g_color = Upgrades.group_color(package.group).to_html(false)
	var box = "\n[color=#4ec994]────────────────────────────────────────[/color]\n"
	box += " [color=#4ec994]PACKAGE INSTALLED[/color]\n"
	box += "[color=#4ec994]────────────────────────────────────────[/color]\n"
	box += " [color=#%s]%s[/color]  v%.1f -> [color=#4ec994]v%.1f[/color]\n" % [g_color, package.group, result.version_before, result.version_after]
	if package.type == "capstone":
		box += " [color=#ffc24a]%s[/color]  %s\n" % [package.name, lvl.effect]
	else:
		box += " %s  %s\n" % [Upgrades.level_name(package, lvl), Upgrades.level_change(package, lvl, "#4ec994")]
	add_line(box)
	if result.major:
		await _wait_for_output()
		await bro_wait(0.4)
		add_line(_major_release_text(package.group, result.tier))
	accepting_player_inputs = true

## 'apt install <skill>' / 'all': one confirmation for everything ready
func _apt_prepare_bulk(bulk_groups: Array) -> void:
	var plan = Upgrades.plan_bulk(bulk_groups)
	var label = "all skills" if bulk_groups.size() > 1 else bulk_groups[0]
	if plan.is_empty():
		var wired = bulk_groups.filter(func(g): return Upgrades.is_wired(g))
		if wired.is_empty():
			add_line("%s upgrades can be installed once %s migrated." % [label, "they are" if bulk_groups.size() > 1 else "it is"])
		else:
			add_line("Nothing ready to install for %s. [color=#666666]'apt %s' shows what's missing.[/color]" % [label, wired[0].to_lower()])
		return
	add_line("Ready to install %d package%s for %s:" % [plan.size(), "" if plan.size() == 1 else "s", label])
	var totals = {}
	var order = []
	for e in plan:
		var p = e.package
		var lvl = e.level
		var change = Upgrades.level_change(p, lvl)
		add_line("  [color=#%s]%s[/color]  %s  [color=#888888]%s[/color]" % [Upgrades.group_color(p.group).to_html(false), p.group, Upgrades.level_name(p, lvl), change])
		for c in lvl.costs:
			if !totals.has(c.item):
				order.append(c.item)
			totals[c.item] = totals.get(c.item, 0) + int(c.amount)
	var cost_parts = []
	for k in order:
		var n = "VM tokens (any)" if k == Upgrades.VM_TOKEN_COST else Upgrades.get_item(k).name
		cost_parts.append("%s x%d" % [n, totals[k]])
	add_line("This will consume: " + ", ".join(cost_parts))
	add_line("[color=green]Install all?[/color] y/n")
	upgrade_bulk_plan = plan
	awaiting_player_input = true
	current_player_input_context = PlayerInputContext.UPGRADES

## installs a bulk plan with one shortened sequence, one summary box, and MAJOR banners
func apply_apt_bulk_upgrade():
	accepting_player_inputs = false
	var plan = upgrade_bulk_plan
	var v_before = {}
	for e in plan:
		v_before[e.package.group] = Upgrades.version(e.package.group)
	add_line("Reading package lists... Done")
	await bro_wait(0.2)
	# one download bar per package, each starting a beat after the one above (a cascade); a package
	# installs when its bar fills. All rows live in one terminal line so the block can't be split.
	var names = []
	var w = 8
	for e in plan:
		var n = e.package.id.replace(".", "-").replace("_", "-")
		names.append(n)
		w = max(w, n.length())
	var bar_index = await _add_live_line("")
	var done = []
	var majors = []
	var installed = []
	installed.resize(plan.size())
	installed.fill(false)
	var stagger = min(0.12, 3.0 / max(1, plan.size()))
	var fill_time = 0.45
	var t = 0.0
	var total = fill_time + stagger * (plan.size() - 1)
	while true:
		var rows = []
		for i in plan.size():
			var f = clamp((t - stagger * i) / fill_time, 0.0, 1.0)
			if t < stagger * i:
				break
			if f >= 1.0 and !installed[i]:
				installed[i] = true
				var e = plan[i]
				var p = e.package
				if Upgrades.install_block_reason(p) == "" and Upgrades.next_level(p) == e.level:
					var r = Upgrades.install(p)
					done.append(e)
					if r.major:
						majors.append([p.group, r.tier])
			var c = Upgrades.group_color(plan[i].package.group).to_html(false)
			rows.append("[color=#%s]%s[/color] %s" % [c, names[i].rpad(w), _apt_progress_text(int(f * 100))])
		set_line(bar_index, "\n".join(rows), true) # 2026-10-30: follow the growing list (it only snapped down at the end)
		if t >= total:
			break
		await bro_wait(0.03)
		t += 0.03
	add_line("Setting up %d package%s ..." % [done.size(), "" if done.size() == 1 else "s"])
	await bro_wait(0.3)
	var box = "\n[color=#4ec994]────────────────────────────────────────[/color]\n"
	box += " [color=#4ec994]%d PACKAGE%s INSTALLED[/color]\n" % [done.size(), "" if done.size() == 1 else "S"]
	box += "[color=#4ec994]────────────────────────────────────────[/color]\n"
	for g in v_before:
		box += " [color=#%s]%s[/color]  v%.1f -> [color=#4ec994]%s[/color]\n" % [Upgrades.group_color(g).to_html(false), g, v_before[g], Upgrades.version_text(g)]
	for e in done:
		var lvl = e.level
		if e.package.type == "capstone":
			box += "  [color=#ffc24a]%s[/color]  %s\n" % [e.package.name, lvl.effect]
		else:
			box += "  %s  %s\n" % [Upgrades.level_name(e.package, lvl), Upgrades.level_change(e.package, lvl, "#4ec994")]
	add_line(box)
	for m in majors:
		await _wait_for_output()
		await bro_wait(0.4)
		add_line(_major_release_text(m[0], m[1]))
	accepting_player_inputs = true

func _apt_progress_text(pct: int) -> String:
	var filled = pct / 5
	return "[color=#4ec994][%s%s][/color] %3d%%" % ["#".repeat(filled), "-".repeat(20 - filled), pct]

## why a locked process can't run (2026-10-26: processes open with their tier's location)
func _locked_text(p: Dictionary) -> String:
	var r = Exp.tier_block_reason(null, p)
	return r if r != "" else "Process not unlocked"

## 2026-10-26 (skill revamp): processes only open with tiers, and the UPLOAD GOAL COMPLETE screen
## (ContextCommands.tier_complete_text) lists everything a tier opens, so the per-process banners are gone.
## The queue is still cleared here (held while hacking, booting or showing the offline download).
var _hold_unlocks := true
func _flush_unlocks() -> void:
	if _hold_unlocks or _booting or current_context == Context.HACKING or Exp.unlock_queue.is_empty():
		return
	Exp.unlock_queue.clear()

func _major_release_text(group: String, tier: int) -> String:
	var c = Upgrades.group_color(group).to_html(false)
	var t = "\n[color=#ffc24a]════════════════════════════════════════[/color]\n"
	t += "  [color=#ffc24a]MAJOR RELEASE[/color]  ·  [color=#%s]%s v%d.0[/color]\n" % [c, group.to_upper(), tier]
	t += "[color=#ffc24a]════════════════════════════════════════[/color]\n"
	t += " Changelog · Tier %d (%s)\n" % [tier, Upgrades.tier_name(tier)]
	for e in Upgrades.changelog(group, tier):
		t += "  [color=%s]+[/color] %s  [color=#888888]%s[/color]\n" % ["#ffc24a" if e.type == "capstone" else "#4ec994", e.name, e.after]
	return t

## Adds a line that will be updated in place with set_line (progress bars) and returns its index.
## Every RICHTEXT_LABEL_LINE_LIMIT lines the terminal starts a new text block and clears 'lines', so the
## line is put where the current block still has room; otherwise it could land in the old block and
## leave the index pointing at nothing.
func _add_live_line(text: String) -> int:
	await _wait_for_output()
	if lines.size() >= RICHTEXT_LABEL_LINE_LIMIT - 1:
		add_new_scrollback()
	add_line(text)
	await _wait_for_output()
	return lines.size() - 1

## waits until queued add_line output has been printed (so set_line can target it)
func _wait_for_output() -> void:
	while processing_queue or !output_queue.is_empty():
		await get_tree().process_frame

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
	
	#INFO FOR SKILL
	if command.size() == 2:
		for p in major_processes:
			var n = p.SKILL.name.to_lower()
			if command[1] == n:
				if p == Hacking:
					add_line(ContextCommands.get_help_text_hacking(Hacking))
					return
				
				if p == Defragging:
					add_line(ContextCommands.get_help_text_defragging(Defragging))
					return
				
				
				add_line(ContextCommands.get_help_text(p))
				if n == "mining":
					Tutorial.complete_event(Tutorial.TutorialEvent.INFO_MINING_COMMAND)
				return
	
	if command.size() == 3:
		if command[1].to_lower() == "hacking":
			var locations = Stats.hacking_targets.values()
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
							post_flow_chart(func(c): return c.show_recipe(p, mp))
							return
	add_line("info command not recognized")
	add_line("info commands")
	add_line("-----------------")
	add_line("info                        overview of all main skills                  [color=gray]ex. info[/color]")
	add_line("info [skill]                overview of specific skill and processes     [color=gray]ex. info mining[/color]")
	add_line("info [skill] [process]      details of specific processes                [color=gray]ex. info mining logs[/color]")

##VM TOKENS
#command vm [process] [minor process] [optional flag -r]
#command example: vm mining basic -r
func handle_vm_token_commands(text):
	if text == "ssh -h":
		add_line(ContextCommands.ssh_help_commands())
		add_line(vm_help_text())
		return
		
	var processes = [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling]
	var target_process = null
	if text == "ssh":
		add_line(ContextCommands.ssh_commands(processes))
		return
	var commands = text.split(" ", false)
	# 'ssh <the normal command>' (ssh mine -logs, ssh parse -footprint=logs, ssh crack -password): read as
	# 'ssh <skill> <process>'; the older 'ssh mining logs' form still works
	if commands.size() >= 2 and SKILL_BINARIES.has(commands[1]) and commands[1] != "defrag":
		commands[1] = SKILL_BINARIES[commands[1]].to_lower()
		text = " ".join(commands)
	# 'ssh cracking -password' works like 'ssh cracking password'
	if commands.size() >= 3 and commands[2].begins_with("-"):
		commands[2] = commands[2].trim_prefix("-")
		text = " ".join(commands)
	
	#LIST MINOR PROCESSES AVAILABLE FOR SSH/VM example: ssh mining -> list logs, quality logs, etc
	if text == "ssh hacking":
		add_line("Virtual Machines are not compatable with hacking.")
		return
	if text == "ssh defragging":
		add_line("Virtual Machines are not compatable with defragging.")
		return
	if commands.size() == 2:
		#is 2nd array index a skill name
		for p in processes:
			if commands[1] == p.SKILL.name.to_lower():
				target_process = p
				match p:
					Parsing:
						add_line(Parsing.list_vm_commands())
					_:
						add_line(ContextCommands.list_vm_terminals_for_skill(p))
					
				return
	#confirm commands size
	#if commands.size() < 3 or commands.size() > 4:
		#add_line("SSH command not recognized     [color=#888888]example usage: ssh mining logs[/color]")
		#return
	
		
	#find major process
	for p in processes:
		if p.SKILL.name.to_lower() == commands[1]:
			target_process = p
	if target_process == null:
		add_line(commands[1] + " not a recognized skill.")
		return
	
	#find minor process
	var target_minor_process = null

	if commands.size() < 3:
		add_line("SSH command not recognized     [color=#888888]example usage: ssh mine -logs[/color]")
		return
	var typed = commands[2].split("=")[0]
	for mp in target_process.minor_processes:
		var n = str(mp.name).to_lower()
		# the process's own flag works too: 'ssh phishing whale' = 'ssh phishing whaling' (phish -whale)
		var flag = str(mp.get("command", "")).get_slice(" -", 1).get_slice(" ", 0).get_slice("=", 0).to_lower()
		# singular / plural both work: 'ssh matching credentials' = 'ssh matching credential'
		if typed == n or typed == n + "s" or typed + "s" == n or typed == n.trim_suffix("s") or (flag != "" and typed == flag):
			target_minor_process = mp
			if typed != n:
				commands[2] = n + commands[2].substr(typed.length())
				text = " ".join(commands)
			break
		
	if target_minor_process == null:
		add_line(target_process.name + " process not recognized")
		return
	
	if Inventory.get_amount(target_process.vm_token) <= 0:
		add_line("VM Token for " + target_process.name + " not found.")
		return
	
	if !target_minor_process.unlocked:
		add_line(_locked_text(target_minor_process))
		return
	if Exp.tier_block_reason(target_process, target_minor_process) != "":
		add_line(Exp.tier_block_reason(target_process, target_minor_process))
		return
	
	if target_minor_process.get("not built", false):
		add_line(ContextCommands.not_built_text(target_minor_process))
		return
	
	if target_process != Parsing and target_process != Cracking and target_process != Compiling:
		if !target_process.has_requirements(target_minor_process):
			add_line(target_process.missing_requirements_text(target_minor_process))
			return
		
	#check # of vm processes running
	if target_process.CURRENT_VMS >= target_process.MAX_VMS:
		add_line("Maximum virtual machines running.")
		return
	
	if Stats.CURRENT_ALL_VMS >= Stats.MAX_ALL_VMS:
		add_line("Maximum total virtual machines running. Upgrade [color=#14B8A6]System[/color] with 'apt' to increase capacity.")
		return
	
	#target_process = Decoding | Mining | Parsing etc
	#target_minor_process = Decoding.CACHE | Mining.LOGS | Parsing.FOOTPRINT etc
	var new_window
	if target_process == Decoding:
		var arg_text = text.substr(text.find("=") + 1) if commands[2].contains("=") else ""
		var check = Decoding.validate_start(target_minor_process, arg_text)
		if !check.ok:
			add_line(check.message)
			return
		if !_vm_pay(target_process, target_minor_process, check.arg): return
		new_window = target_process.create_vm_window(target_minor_process, true, check.arg)
	
	elif target_process == Parsing:
		var parsed_cmd = Parsing.parse_through_parse_start_command(text, target_minor_process) #returns dictionary with properties: 'valid' bool, 'items_to_parse' [items], 'message' string
		
		if !parsed_cmd.valid:
			add_line(parsed_cmd.message)
			return
		
		if parsed_cmd.message != "":
			add_line(parsed_cmd.message)
		
		if !_vm_pay(target_process, target_minor_process, parsed_cmd.items_to_parse): return
		new_window = target_process.create_vm_window(target_minor_process, parsed_cmd.items_to_parse, parsed_cmd.target)
	
	elif target_process == Compiling:
		if target_minor_process == Compiling.MOD:
			var check = Compiling.check_mod(text.substr(text.find("=") + 1) if text.contains("=") else "", "ssh compile -mod=logs")
			if !check.ok:
				add_line(check.message)
				return
			var item = check.item
			if !_vm_pay(target_process, target_minor_process, null): return
			new_window = target_process.create_vm_window(target_minor_process, item)
		else:
			var missing = false
			for req in target_minor_process["requirements"]:
				if Inventory.get_amount(req) < target_minor_process['requirements'][req]:
					add_line("Missing required resource: " + req.name + " x" + str(target_minor_process['requirements'][req]))
					missing = true
			if missing:
				return
			
			if !_vm_pay(target_process, target_minor_process, null): return
			new_window = target_process.create_vm_window(target_minor_process)
	
	elif target_process == Cracking:
		var use_item = null
		var create_item = null
		if target_minor_process == Cracking.VM:
			#example command: crack -vm use=mining create=parsing
			var flags = text.trim_prefix(target_minor_process["ssh command"]).strip_edges()
			#confirm command has proper flags (use/create)
			var parts = flags.split(" ", false)
			if parts.size() < 2 or !parts[0].begins_with("use=") or !parts[1].begins_with("create="):
				add_line("ERROR: 'cracking -vm' command not recognized. [color=#666666]example: crack -vm use=mining create=parsing")
				return
			
			#get items from the commands
			use_item = Inventory.get_vm_token_by_skill_name(parts[0].trim_prefix("use="))
			create_item = Inventory.get_vm_token_by_skill_name(parts[1].trim_prefix("create="))
			
			if use_item == null or create_item == null:
				add_line("ERROR: 'cracking -vm' token name not recognized. [color=#666666]example: crack -vm use=mining create=parsing")
				return
			
			#confirm the player has at least 3 of the 'use' items (4 if using a 'cracking' vm token)
			if use_item == Cracking.vm_token and Inventory.get_amount(use_item) < 4:
				add_line("ERROR: not enough " + use_item.name + ". Requires 4 to start cracking in VM window (3 to crack + 1 to run window). Current amount: " + str(Inventory.get_amount(use_item)))
				return
			if Inventory.get_amount(use_item) < 3:
				add_line("ERROR: not enough " + use_item.name + ". Requires 3 to crack. Current amount: " + str(Inventory.get_amount(use_item)))
				return
			
			#pass the use/create items to start_cracking
			#start_cracking(target_minor_process, use_item, create_item)
		
		else:
			if !target_process.has_requirements(target_minor_process):
				add_line(target_process.missing_requirements_text(target_minor_process))
				return
			#start_cracking(target_minor_process)
		
		if !_vm_pay(target_process, target_minor_process, null): return
		new_window = target_process.create_vm_window(target_minor_process, use_item, create_item)
			
	elif target_process == Phishing: # ssh phishing spear bait=logs
		var parsed_bait = Phishing.parse_bait(text)
		if parsed_bait.error != "":
			add_line(parsed_bait.error)
			return
		if target_minor_process == Phishing.TRAP:
			add_line("Traps don't need a VM: set one with 'phish -trap', it fills on its own.")
			return
		if !_vm_pay(target_process, target_minor_process, null): return
		new_window = target_process.create_vm_window(target_minor_process, true, parsed_bait.bait, {"_mod_tier": parsed_bait.mod_tier} if parsed_bait.mod_tier > 0 else parsed_bait.target)
	else:
		if !_vm_pay(target_process, target_minor_process, null): return
		new_window = target_process.create_vm_window(target_minor_process, true)
	
	if new_window:
		new_window.token_cost = _vm_paid
		new_window.tokens_used = _vm_paid
		add_line("Started [color=#%s]vm-%02d[/color] %s / %s%s. Use 'vm -h' to manage VM windows." % [target_process.SKILL.color.to_html(false), new_window.vm_id, target_process.SKILL.name, target_minor_process.name,
			("  [color=#888888](%d tokens per %ds, tier %d)[/color]" % [_vm_paid, int(target_process.VM_UPTIME), _vm_paid]) if _vm_paid > 1 else ""])
	grab_all_focus()
	Tutorial.complete_event(Tutorial.TutorialEvent.RUN_VM_WITH_SSH)

## 'timeskip': everything that runs on the real clock moves back <secs> (Defrag boosts and cooldown, the Phishing
## Trap, skill bonuses), then the main process is stopped and offline progress runs for that long, as on a real
## restart: the download screen, then the process resumes. VM windows keep running.
func _dev_timeskip(secs: int) -> void:
	if secs <= 0:
		return
	for p in Defragging.minor_processes:
		if int(p.get("expires_at", 0)) > 0:
			p["expires_at"] = int(p.expires_at) - secs
	Defragging.SKILL["cooldown"] = int(Defragging.SKILL.get("cooldown", 0)) - secs
	if !Phishing.trap.is_empty():
		Phishing.trap["set_at"] = int(Phishing.trap.set_at) - secs
	for sk in [Mining, Parsing, Cracking, Matching, Phishing, Hacking, Decoding, Compiling]:
		if int(sk.bonus_expires_at) > 0:
			sk.bonus_expires_at = int(sk.bonus_expires_at) - secs
	var snap = Offline.snapshot()
	if process_running and current_process:
		get_tree().call_group("flush_on_quit", "flush_for_quit")
		unstick_current_process()
		current_process.stop()
		current_process = null
		current_process_info = {}
		process_running = false
	Offline.session = {"saved_at": int(Time.get_unix_time_from_system()) - secs, "process": snap}
	Offline.compute()
	add_line("[color=#888888](dev) skipped %s%s[/color]" % [Offline.format_time(secs), "" if !Offline.report.is_empty() else "  (nothing was running)"])
	_offline_welcome()

## Pays a new VM's first uptime period: VMManager.token_cost tokens (2026-10-28: tier 2 work costs 2, ...).
var _vm_paid := 1
func _vm_pay(skill: Node, minor: Dictionary, arg) -> bool:
	_vm_paid = VMManager.token_cost(skill, minor, arg)
	if Inventory.get_amount(skill.vm_token) < _vm_paid:
		add_line("Not enough %s: this VM costs %d per %ds (tier %d work). You have %d." % [skill.vm_token.name, _vm_paid, int(skill.VM_UPTIME), _vm_paid, Inventory.get_amount(skill.vm_token)])
		return false
	Upgrades.spend_vm_token(skill.vm_token, true, _vm_paid)
	return true

## upload | upload <item> [amount] | upload -a | upload cancel <item> (unpack <item>)
func handle_upload_commands(text: String) -> void:
	if text == "upload" or text == "upload -h":
		add_line(ContextCommands.upload_goal_text())
		Tutorial.complete_event(Tutorial.TutorialEvent.UPLOAD_INFO)
		return
	var is_cancel = text.begins_with("unpack") or text.begins_with("upload cancel") or text.begins_with("upload -cancel")
	var arg = text
	for pre in ["upload -cancel", "upload cancel", "unpack", "upload"]:
		if arg.begins_with(pre):
			arg = arg.trim_prefix(pre)
			break
	arg = arg.strip_edges().trim_prefix("-").strip_edges()
	if arg == "":
		add_line("Name an item. [color=#666666]ex. upload logs 5  |  upload -a  |  upload cancel logs[/color]")
		return
	if !is_cancel and (arg == "all" or arg == "a"):
		if !Tutorial.is_tutorial_complete():
			add_line("'upload -a' opens after the tutorial. For now, upload exact amounts, e.g. 'upload logs 5'.")
			return
		var started = []
		for g in Uploads.get_goals():
			var q = Uploads.queue(g.item)
			if q.ok:
				started.append("%d %s" % [q.amount, g.item.name])
		add_line("Queued for upload: " + ", ".join(started) if !started.is_empty() else "Nothing in your inventory that the current goal still needs.")
		return
	# optional trailing amount: 'upload logs 5'
	var amount = 0
	var words = arg.split(" ", false)
	if words.size() > 1 and words[-1].is_valid_int():
		amount = max(1, int(words[-1]))
		arg = " ".join(words.slice(0, words.size() - 1))
	var item = Inventory.get_item_by_name(arg)
	if item == null:
		add_line("Item not recognized: " + arg)
		return
	if !is_cancel and amount == 0 and !Tutorial.is_tutorial_complete():
		add_line("Add how many to upload, e.g. 'upload %s 5'. During the tutorial, always upload an exact amount so you keep enough for the next steps." % item.name.to_lower())
		return
	if is_cancel:
		var n = Uploads.unpack(item)
		add_line("Returned %d queued %s to your inventory." % [n, item.name] if n > 0 else "Nothing queued for " + item.name + ".")
		return
	var res = Uploads.queue(item, amount)
	if !res.ok:
		add_line(res.message)
		return
	add_line("Uploading %d %s, %ds each. Progress is in the side panel. [color=#666666](%d queued, goal %d/%d)[/color]" % [res.amount, item.name, int(Uploads.get_upload_seconds(item)), Uploads.get_staged(item), Uploads.get_uploaded(item), Uploads.get_goal_amount(item)])

## vm ls | vm show <id|all> | vm hide <id|all> | vm kill <id|all> | vm -h
func handle_vm_commands(text: String) -> void:
	var parts = text.split(" ", false)
	if parts.size() == 1 or parts[1] == "-h":
		add_line(vm_help_text())
		return
	var action = parts[1]
	if action == "ls":
		add_line(vm_list_text())
		return
	if !(action in ["show", "hide", "kill"]):
		add_line("Unknown vm command. Use 'vm -h'.")
		return
	if parts.size() < 3:
		add_line("Missing VM id. [color=#666666]example: vm %s 1  |  vm %s -a[/color]" % [action, action])
		return
	var targets: Array[VMWindow] = []
	if parts[2] in ["all", "-a", "a", "-all"]:
		targets.assign(VMManager.vms)
	elif parts[2].trim_prefix("vm-").is_valid_int():
		var vm = VMManager.get_vm(int(parts[2].trim_prefix("vm-")))
		if vm:
			targets.append(vm)
	if targets.is_empty():
		add_line("No VM found for '%s'. Use 'vm ls' to see running VMs." % parts[2])
		return
	for vm in targets:
		match action:
			"show":
				VMManager.set_minimized(vm, false)
			"hide":
				VMManager.set_minimized(vm, true)
			"kill":
				add_line("Killed vm-%02d (%s / %s)." % [vm.vm_id, vm.skill.SKILL.name, vm.minor_process.name])
				VMManager.release(vm)
	if action != "kill":
		add_line("%s %d VM window%s." % ["Restored" if action == "show" else "Minimized", targets.size(), "" if targets.size() == 1 else "s"])

func vm_list_text() -> String:
	if VMManager.vms.is_empty():
		return "No VMs running. Start one with 'ssh' + a process command, e.g. 'ssh mine -logs' ('ssh' lists your tokens)."
	var text = "ID      SKILL        PROCESS          TIME   TOKENS  STATE\n"
	for vm in VMManager.vms:
		text += "%-8s%-13s%-17s%-7s%-8s%s\n" % ["vm-%02d" % vm.vm_id, vm.skill.SKILL.name, str(vm.minor_process.name), str(vm.get_seconds_left()) + "s", str(vm.tokens_used), "minimized" if !vm.visible else ("stopping" if vm.stopping else "running")]
	text += "%d/%d VMs running" % [VMManager.vms.size(), Stats.MAX_ALL_VMS]
	return text

func vm_help_text() -> String:
	return """
 VM WINDOW COMMANDS
   vm ls                    List running VMs
   vm hide <id|all|-a>      Minimize VM window(s) to the dock
   vm show <id|all|-a>      Restore VM window(s)
   vm kill <id|all|-a>      Stop VM(s) immediately (no token refund)
   Tip: click a VM in the dock to minimize/restore it.
"""

## panel | panel hide | panel show
func handle_panel_commands(text: String) -> void:
	match text:
		"panel", "panel toggle":
			system_dock.toggle()
		"panel hide", "panel collapse":
			system_dock.set_collapsed(true)
		"panel show", "panel expand":
			system_dock.set_collapsed(false)
		_:
			add_line("panel commands: [color=#888888]panel (toggle) | panel hide | panel show[/color]")
			return
	add_line("Side panel " + ("collapsed." if system_dock.collapsed else "expanded."))

func _on_panel_width_changed(width: float) -> void:
	# terminal ends exactly at the panel border (Panel/MarginContainer already adds 8px on the right),
	# so the scrollbar sits right against the panel with no dead gap
	$Panel/MarginContainer/TerminalRoot/MarginContainer.add_theme_constant_override("margin_right", int(width - 8))
	$Panel/MarginContainer/TerminalRoot/Header/PanelSpacer.custom_minimum_size.x = width + 8
	_update_line_capacity.call_deferred()

## How many monospace characters fit on a terminal line; tables (ContextCommands.build_table) fit to this.
func _update_line_capacity() -> void:
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var char_width := font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if char_width <= 0.0:
		return
	var usable: float = terminal_body.size.x - 24.0 # scrollbar + label margins
	ContextCommands.max_line_chars = max(40, int(usable / char_width))

## 'quit' / 'exit': save, say goodbye, close (same sign-off as the hacking console).
func quit_game() -> void:
	accepting_player_inputs = false
	add_line("SAVING")
	await get_tree().create_timer(0.8).timeout
	add_line("GOODBYE")
	await get_tree().create_timer(1.2).timeout
	get_tree().call_group("flush_on_quit", "flush_for_quit") # a cache mid-decode finishes instead of being lost
	SaveManager.save_game()
	get_tree().quit()

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
########### SHARED SKILL PROCESS COMMANDS #########
###################################################
## Commands every skill context shares (stop, stop -s, focus, cd .., overclock).
## safe_stop_message: line shown for 'stop -s'. Empty means safe stop isn't supported.
func _handle_process_commands(text: String, safe_stop_message: String, can_overclock: bool = true) -> void:
	if _handle_modifier_command(text):
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
		"stop -s", "kill -s":
			if safe_stop_message == "":
				add_line("Safe stop not available for this process. Use 'stop'.")
				return
			if !current_process:
				add_line("No active process to stop.")
				return
			add_line(safe_stop_message)
			current_process.stop_safely()
		"focus":
			if current_process:
				bring_process_to_bottom()
				if current_context == Context.MINING:
					Tutorial.complete_event(Tutorial.TutorialEvent.USE_FOCUS)
			else:
				add_line("No process found to focus")
		"root", "..", "cd ..", "cd ../":
			return_to_root()
		"overclock":
			if can_overclock:
				overclock_logic()
			else:
				add_line("Overclock not available for this process.")
		"overclock -kill", "overclock kill":
			if !can_overclock:
				add_line("Overclock not available for this process.")
				return
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

## Messages for terminals built on BaseTerminal (they send Signals.process_ended_safely(skill)).
const PROCESS_ENDED_MESSAGES = {
	"Mining": "Mining safely finished.",
	"Parsing": "Parsing safely finished.",
	"Cracking": "Password cracking safely finished.",
	"Matching": "Matching safely finished.",
	"Compiling": "Compiling stopped.",
	"Phishing": "Phishing process finished.",
	"Decoding": "Decoding safely finished.",
}

func _on_skill_process_ended(skill: Node) -> void:
	_on_process_ended(PROCESS_ENDED_MESSAGES.get(skill.SKILL.name, skill.SKILL.name + " process finished."))

## Called when any skill terminal finishes or stops safely.
func _on_process_ended(message: String) -> void:
	unstick_current_process()
	current_process = null
	current_process_info = {}
	process_running = false
	Stats.overclocked = false
	hud_process_running.process_killed()
	add_line(message)

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
	_handle_process_commands(text, "Finishing current mine...")


func start_log_mining(minor_process: Dictionary):
	if !minor_process.unlocked:
		add_line(Exp.tier_block_reason(Mining, minor_process))
		return
	if Exp.tier_block_reason(Mining, minor_process) != "":
		add_line(Exp.tier_block_reason(Mining, minor_process))
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

###################################################
################### PARSING #######################
###################################################
func log_parsing_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Parsing.minor_processes:
		#if text begins with command
		#if it equal exactly then add_line("Missing target item") example: parse -footprint=logs, parse -footprint=all
		#strip out command, try to get inventory item from leftover command
		#check if player has item
		#add item to argument
		if text.begins_with(ms['command']):
			#CHECK IF PROCESS IS UNLOCKED
			if !ms.unlocked:
				add_line(Exp.tier_block_reason(Parsing, ms))
				return
			
			#CHECK IF ANOTHER PROCESS IS RUNNING
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			
			#already remvoe ms command
			var parsed_cmd = Parsing.parse_through_parse_start_command(text, ms) #returns dictionary with properties: 'valid' bool, 'items_to_parse' [items], 'message' string
			
			if !parsed_cmd.valid:
				add_line(parsed_cmd.message)
				return
			
			if parsed_cmd.message != "":
				add_line(parsed_cmd.message)
			
			start_parsing(ms, parsed_cmd.items_to_parse, parsed_cmd.target)
			return
	
	_handle_process_commands(text, "Finishing current log...")

func start_parsing(minor_process: Dictionary, items_to_parse: Array[ItemData], target: ItemData = null):
	#if !minor_process.unlocked:
		#add_line("Requires parsing level " + str(minor_process["unlock level"]))
		#return
	#if !has_requirements(minor_process.requirements):
		#add_line("No logs found.")
		#return
	
	var has_at_least_one_item = false
	for item in items_to_parse:
		if Inventory.get_amount(item) > 0:
			has_at_least_one_item = true
	
	if !has_at_least_one_item:
		add_line("ERROR: item(s) listed not found in inventory.")
		return
	
	var new_log_parsing_terminal = log_parsing_scene.instantiate()
	terminal_body_container.add_child(new_log_parsing_terminal)
	new_log_parsing_terminal.set_parse_type(minor_process, items_to_parse, false, target)
	process_running = true
	current_process = new_log_parsing_terminal
	current_process_info = minor_process
	#new_log_parsing_terminal.start()
	new_log_parsing_terminal.begin()
	hud_process_running.process_started(Parsing, minor_process)
	add_new_scrollback()

###################################################
#################### CRACKING #####################
###################################################
func password_unscramble_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Cracking.minor_processes:
		if text.begins_with(ms["command"]):
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			if ms.get("not built", false):
				add_line(ContextCommands.not_built_text(ms))
				return
			
			if ms == Cracking.VM:
				#example command: crack -vm use=mining create=parsing
				var flags = text.trim_prefix(ms["command"]).strip_edges()
				#confirm command has proper flags (use/create)
				var parts = flags.split(" ", false)
				if parts.size() < 2 or !parts[0].begins_with("use=") or !parts[1].begins_with("create="):
					add_line("ERROR: 'cracking -vm' command not recognized. [color=#666666]example: crack -vm use=mining create=parsing")
					return
				
				#get items from the commands
				var use_item = Inventory.get_vm_token_by_skill_name(parts[0].trim_prefix("use="))
				var create_item = Inventory.get_vm_token_by_skill_name(parts[1].trim_prefix("create="))
				
				if use_item == null or create_item == null:
					add_line("ERROR: 'cracking -vm' token name not recognized. [color=#666666]example: crack -vm use=mining create=parsing")
					return
				
				#confirm the player has at least 3 of the 'use' items
				if Inventory.get_amount(use_item) < 3:
					add_line("ERROR: not enough " + use_item.name + ". Requires 3 to crack. Current amount: " + str(Inventory.get_amount(use_item)))
					return
				
				#pass the use/create items to start_cracking
				start_cracking(ms, use_item, create_item)
			
			else:
				start_cracking(ms)
			return
	_handle_process_commands(text, "Finishing current password...")


func start_cracking(minor_process: Dictionary, use_item: ItemData = null, create_item: ItemData = null):
	if !minor_process.unlocked:
		add_line(_locked_text(minor_process))
		return
	if Exp.tier_block_reason(Cracking, minor_process) != "":
		add_line(Exp.tier_block_reason(Cracking, minor_process))
		return
	#check if requirements are dictionary because if requirements are a String then player is using vm cracking command and initial item check already happened
	if minor_process.requirements is Dictionary:
		if !has_requirements(minor_process.requirements):
			add_line(minor_process.requirements.keys()[0].name + " not found")
			return
	var new_pw_cracking_terminal = pw_cracking_scene.instantiate()
	terminal_body_container.add_child(new_pw_cracking_terminal)
	new_pw_cracking_terminal.set_cracking_type(minor_process, false, use_item, create_item)
	process_running = true
	current_process = new_pw_cracking_terminal
	current_process_info = minor_process
	new_pw_cracking_terminal.start()
	hud_process_running.process_started(Cracking, minor_process)
	add_new_scrollback()

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
	_handle_process_commands(text, "Finishing current match...")


func start_matching(minor_process):
	if !minor_process.unlocked:
		add_line(_locked_text(minor_process))
		return
	if Exp.tier_block_reason(Matching, minor_process) != "":
		add_line(Exp.tier_block_reason(Matching, minor_process))
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

###################################################
############### CACHE DECRYPTING ##################
###################################################
func cache_decrypting_commands(text):
	text = text.to_lower().strip_edges()
	if text.begins_with("decode -package"):
		add_line("Packaging is gone: upload straight from your inventory with 'upload <item> [amount]'. Type 'upload' for the goal.")
		return

	for ms in Decoding.minor_processes:
		if text == ms["command"] or text.begins_with(ms["command"] + "="):
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			var arg_text = text.trim_prefix(ms["command"]).trim_prefix("=")
			var check = Decoding.validate_start(ms, arg_text)
			if !check.ok:
				add_line(check.message)
				return
			start_cache_decrypting(ms, check.arg)
			return
	
	_handle_process_commands(text, "Finishing current cache...")


func start_cache_decrypting(minor_process, cache_item = null):
	if !minor_process.unlocked:
		add_line(_locked_text(minor_process))
		return
		
	var new_cache_decrypt_terminal = cache_decrypt_scene.instantiate()
	terminal_body_container.add_child(new_cache_decrypt_terminal)
	new_cache_decrypt_terminal.set_cache_type(minor_process, false, cache_item)
	process_running = true
	current_process = new_cache_decrypt_terminal
	current_process_info = minor_process
	new_cache_decrypt_terminal.start_decrypting()
	hud_process_running.process_started(Decoding, minor_process)
	add_new_scrollback()

## Modifier commands from skill.MODIFIERS ('sift', 'sift -kill', ...). Returns true when <text> was one.
## One modifier at a time per process, overclock included.
func _handle_modifier_command(text: String) -> bool:
	var parts = text.split(" ", false)
	if parts.is_empty():
		return false
	var cmd = parts[0]
	var kill = parts.size() > 1 and parts[1] in ["-kill", "kill"]
	var major = _get_major_from_minor(current_process_info) if current_process_info else null
	var mod: Dictionary = {}
	var owner: Node = major
	for s in ([major] if major else major_processes):
		for m in s.get("MODIFIERS") if s and s.get("MODIFIERS") else []:
			if m.command == cmd:
				mod = m
				owner = s
	if mod.is_empty():
		return false
	if !Upgrades.has(mod.package):
		var p = Upgrades.get_package_info(mod.package)
		var tier = int(p.levels[0].tier) if p.has("levels") else 0
		add_line("%s isn't unlocked yet: it's the %s v%d.0 capstone ('apt %s')." % [mod.name, owner.SKILL.name, tier, owner.SKILL.name.to_lower()])
		return true
	if !process_running or current_process == null or !("modifier" in current_process):
		add_line("No process running in the main terminal to use %s on." % mod.name)
		return true
	if !kill and current_process.has_method("modifier_block_reason") and current_process.modifier_block_reason() != "":
		add_line(current_process.modifier_block_reason())
		return true
	if !kill and current_process.has_method("modifier_refuses") and current_process.modifier_refuses(cmd) != "":
		add_line(current_process.modifier_refuses(cmd))
		return true
	if kill:
		if current_process.has_modifier(cmd):
			current_process.modifier = {}
			add_line("%s stopped." % mod.name)
		else:
			add_line("%s isn't active." % mod.name)
	else:
		if current_process.has_modifier(cmd):
			add_line("%s is already active." % mod.name)
		elif Stats.overclocked:
			add_line("Overclock is active. One modifier at a time: use 'overclock -kill' first.")
		elif !current_process.modifier.is_empty():
			add_line("%s is active. One modifier at a time: use '%s -kill' first." % [current_process.modifier.name, current_process.modifier.command])
		else:
			current_process.modifier = mod
			add_line("[color=#4ec994]%s on.[/color] %s Stop with '%s -kill'." % [mod.name, mod.effect, cmd])
	if current_process.has_method("_update_title"):
		current_process._update_title()
	return true

func overclock_logic():
	if current_process and current_process.has_method("overclock_block_reason") and current_process.overclock_block_reason() != "":
		add_line(current_process.overclock_block_reason())
		return
	if !process_running: #no process running
		add_line("No process running to overclock")
		return
	if current_process and "modifier" in current_process and !current_process.modifier.is_empty():
		add_line("%s is active. One modifier at a time: use '%s -kill' first." % [current_process.modifier.name, current_process.modifier.command])
		return
	if Stats.overclocked: #already overclocked
		add_line("System is already overclocked")
		return
	if !Upgrades.can_overclock(_get_major_from_minor(current_process_info)):
		add_line("Overclock not available. Check upgrade package manager with 'apt'.")
		return
	var limit = int(Upgrades.get_overheat_clear_temp())
	if Stats.overheated: #overheated - still recovering
		add_line("System has been overheated, needs to cool to below %d°C." % limit)
		return
	if Stats.system_tempature >= limit:
		add_line("System tempature needs to cool to below %d°C before overclocking" % limit)
		return
	Stats.overclocked = true

###################################################
################### PHISHING ######################
###################################################
func phishing_commands(text):
	text = text.to_lower().strip_edges()
	if text == "phish -trap collect" or text == "phish -trap status":
		add_line(Phishing.trap_command_text(text.trim_prefix("phish -trap")))
		return
	var parsed_bait = Phishing.parse_bait(text) # "phish -spear bait=logs", "phish -smish target=student"
	for ms in Phishing.minor_processes:
		if parsed_bait.command == ms["command"]:
			if parsed_bait.error != "":
				add_line(parsed_bait.error)
				return
			if !ms.unlocked:
				add_line(_locked_text(ms))
				return
			if ms == Phishing.TRAP and Phishing.has_trap():
				add_line(Phishing.trap_status_text())
				return
			if !parsed_bait.target.is_empty() and ms != Phishing.SMISH:
				add_line("target= only works with Smish ('phish -smish target=<target>').")
				return
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			if parsed_bait.bait and Inventory.get_amount(parsed_bait.bait) < Phishing.bait_cost(parsed_bait.bait):
				add_line("[color=#d29922]Only %d %s: bait needs %d per cast, so casts go out unbaited until you have more.[/color]" % [Inventory.get_amount(parsed_bait.bait), parsed_bait.bait.name, Phishing.bait_cost(parsed_bait.bait)])
			cast_line(ms, -1, parsed_bait.bait, {"_mod_tier": parsed_bait.mod_tier} if parsed_bait.mod_tier > 0 else parsed_bait.target)
			return
	_handle_process_commands(text, "Finishing current phishing attempt...")


func cast_line(type: Dictionary, t_lines: int, bait: ItemData = null, target: Dictionary = {}):
	if current_process is PhishingTerminal:
		current_process.cast_lines(type, t_lines, bait, target)
	else:
		var new_phishing_terminal = phishing_scene.instantiate()
		terminal_body_container.add_child(new_phishing_terminal)
		process_running = true
		current_process = new_phishing_terminal
		current_process_info = type
		new_phishing_terminal.cast_lines(type, t_lines, bait, target)
		hud_process_running.process_started(Phishing, type)
		add_new_scrollback()

###################################################
################### COMPILING #####################
###################################################
func compiling_commands(text):
	text = text.to_lower().strip_edges()
	for ms in Compiling.minor_processes:
		if text.begins_with(ms["command"]):
			if process_running:
				add_line(ContextCommands.process_already_running_text())
				return
			
			if ms == Compiling.MOD:
				var check = Compiling.check_mod(text.substr(text.find("=") + 1) if text.contains("=") else "")
				if !check.ok:
					add_line(check.message)
					return
				var item = check.item
				start_compiling(ms, item)
				return
			else:
				var missing = false
				for req in ms["requirements"]:
					if Inventory.get_amount(req) < ms['requirements'][req]:
						add_line("Missing required resource: " + req.name + " x" + str(ms['requirements'][req]))
						missing = true
				if missing:
					return
				
				start_compiling(ms)
				return
	_handle_process_commands(text, "Finishing current compile...")


func start_compiling(minor_process: Dictionary, item = null):
	if !minor_process.unlocked:
		add_line(_locked_text(minor_process))
		return
	if Exp.tier_block_reason(Compiling, minor_process) != "":
		add_line(Exp.tier_block_reason(Compiling, minor_process))
		return
	
	var new_compiling_terminal = compiling_scene.instantiate()
	terminal_body_container.add_child(new_compiling_terminal)
	process_running = true
	current_process = new_compiling_terminal
	current_process_info = minor_process
	new_compiling_terminal.start(minor_process, false, item)
	hud_process_running.process_started(Compiling, minor_process)
	add_new_scrollback()

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
				add_line("%s defragging opens with %s access." % [ms.name, Upgrades.tier_name(int(ms.get("unlock tier", 1)))])
				return
			if Defragging.on_cooldown():
				add_line("Defragging is currently cooling down.")
				return
			start_defragging(ms)
			return
	_handle_process_commands(text, "", false)


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
	if event is InputEventMouseButton and event.pressed:
		if current_context == Context.HACKING:
			hacking.player_hacking_box.input_line.grab_focus.call_deferred()
		else:
			input_line.grab_focus()
	if event is InputEventKey and event.pressed:
		if _typing or _booting:
			_skip_requested = true # any key: finish the typing / boot sequence now
			get_viewport().set_input_as_handled()
			return
		if Tutorial.show_intro and event.keycode == KEY_ENTER and accepting_player_inputs:
			install_idle_os()
		if upload_awaiting_player_input and awaiting_player_input and event.keycode == KEY_ENTER:
			finish_player_uploaded_proper_item()
		if event.keycode == KEY_TAB:
			_tab_complete()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_BACKSPACE:
			PLAYER_TABBED = 0
	if current_context != Context.HACKING:
		if event is InputEventKey and event.pressed:
			if event.keycode == Key.KEY_UP:
				_navigate_history(-1)
			elif event.keycode == Key.KEY_DOWN:
				_navigate_history(1)

## Tab: auto-complete the input line (CommandRegistry); the Hacking console has its own input box
func _tab_complete() -> void:
	var in_hack = current_context == Context.HACKING
	var line: LineEdit = hacking.player_hacking_box.input_line if in_hack else input_line
	if line == null or !accepting_player_inputs and !in_hack:
		return
	var r = CommandRegistry.complete(line.text, in_hack)
	if r.text != line.text:
		line.text = r.text
		line.caret_column = line.text.length()
	elif !r.options.is_empty():
		var t = CommandRegistry.options_text(r.options)
		if in_hack:
			hacking.player_hacking_box.add_line(t)
		else:
			add_line(t)

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
	update_context(Context.ROOT)
	await loading.show_loading()
	terminal_root.modulate.a = 0.0
	terminal_root.visible = true
	if tutorial_window:
		tutorial_window.set_context_hidden(false)
	input_line.grab_focus()
	_flush_unlocks() # anything unlocked while you were hacking
	var tween = create_tween()
	tween.tween_property(terminal_root, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(system_dock, "modulate:a", 1.0, 1.0)
	await tween.finished

func _on_cooling_timer_timeout():
	var amount_to_cool = Stats.get_cooling_amount()
	if Stats.OVERHEAT_FAN and Stats.overheated:
		amount_to_cool += -0.3
	if Stats.overheated and Upgrades.has("system.liquid_cooling"):
		amount_to_cool *= 2.0 # Liquid Cooling: overheat recovery twice as fast
	elif Upgrades.has("system.idle_cooling") and _nothing_running():
		amount_to_cool *= 2.0 # Idle Cooling
	Stats.update_tempature(amount_to_cool)

## Idle Cooling: no process in the main terminal, no VMs, no hack
func _nothing_running() -> bool:
	return !process_running and VMManager.vms.is_empty() and !(hacking and hacking.enemy_hacking_box.hacking_game.is_hacking)

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
	add_line("[color=#5599FF]System no longer overheated.[/color]")

func overheat_terminal_notice():
	if NOTIFY_OF_OVERHEAT:
		return
	if Stats.overheated:
		NOTIFY_OF_OVERHEAT = true
		add_line("[color=red]SYSTEM OVERHEATED - ALL PROCESSES SLOWED[/color]")
		add_line("Cool system to < 80 to resume processes as normal.")


func has_requirements(requirements: Dictionary) -> bool:
	for item in requirements:
		if Inventory.get_amount(item) < requirements[item]:
			return false
	
	return true

#region intro + boot
## Intro: a short briefing typed out (any key finishes it), then 'enter' runs the boot sequence, which builds
## the screen in the order it's used: skill modules (header cards), the system panel section by section,
## then the command line. Any key during the boot finishes it instantly.
const INTRO_CPS := 140.0          # typing speed (characters per second, frame-rate independent)
const INTRO_PARAGRAPH_PAUSE := 0.18
var _typing := false
var _booting := false
var _skip_requested := false

const INTRO_TEXT := """[color=#33ff33]WELCOME TO IDLE OPERATING SYSTEM.[/color]

You have been granted access to IdleOS: a specialized operating system built to reach the world's most valuable information.

Your objective is simple: gain access to information, and use it to build a stronger system.

At present, your access is limited. Prove your proficiency with this tool and you will be trusted with more.

Start small. A [color=#e3b341]Student[/color] at the local [color=#e3b341]School[/color]. Inexperienced, poorly secured. Surely a simple task.

You will likely extract some [color=#e3b341]credit card information[/color]. Upload it, and perhaps we will grant you access to more powerful tools.

As for what waits beyond that... the operating system contains everything you will need.

For now, let's see what you can do."""

func intro_to_game():
	await type_text(INTRO_TEXT)
	current_scrollback.append_text("\n\n\n[color=#888888]press [color=#ffffff]enter[/color] to install IdleOS[/color]")
	accepting_player_inputs = true

## Types <text> (bbcode ok) into the terminal at <characters_per_second>, frame-rate independent.
## Pauses briefly between paragraphs. Any key while typing finishes it at once.
func type_text(text: String, characters_per_second: float = INTRO_CPS, label: RichTextLabel = null) -> void:
	if label == null:
		label = current_scrollback
	_typing = true
	_skip_requested = false
	var base: String = label.text
	var plain_len := _visible_length(text)
	var shown := 0.0
	var pause := 0.0
	while shown < plain_len and !_skip_requested:
		await get_tree().process_frame
		if !is_instance_valid(label):
			break # the terminal dropped this block (lots of output): stop typing into it
		var dt := get_process_delta_time()
		if pause > 0.0:
			pause -= dt
			continue
		var before := int(shown)
		shown = min(shown + characters_per_second * dt, float(plain_len))
		var cut := _bbcode_prefix(text, int(shown))
		label.text = base + cut + "[color=#33ff33]_[/color]"
		if int(shown) > before and cut.ends_with("\n\n"):
			pause = INTRO_PARAGRAPH_PAUSE
	if is_instance_valid(label):
		label.text = base + text
	_typing = false
	_skip_requested = false

## visible characters in a bbcode string
static func _visible_length(text: String) -> int:
	var n := 0
	var in_tag := false
	for c in text:
		if c == "[":
			in_tag = true
		elif c == "]" and in_tag:
			in_tag = false
		elif !in_tag:
			n += 1
	return n

## the start of a bbcode string holding <count> visible characters, with its open tags closed
static func _bbcode_prefix(text: String, count: int) -> String:
	var out := ""
	var n := 0
	var i := 0
	var open := 0
	while i < text.length() and n < count:
		var c = text[i]
		if c == "[":
			var close = text.find("]", i)
			var tag = text.substr(i, close - i + 1)
			open += -1 if tag.begins_with("[/") else 1
			out += tag
			i = close + 1
			continue
		out += c
		n += 1
		i += 1
	# include closing tags that directly follow, then close anything still open
	while i < text.length() and text.substr(i, 2) == "[/":
		var close = text.find("]", i)
		out += text.substr(i, close - i + 1)
		open -= 1
		i = close + 1
	for k in max(0, open):
		out += "[/color]"
	return out

## Boot log drawn straight into the terminal (not the add_line queue), so lines can update in place.
var _boot_log: Array[String] = []
func _boot_print(text: String) -> int:
	_boot_log.append(text)
	current_scrollback.text = "\n".join(_boot_log)
	return _boot_log.size() - 1

func _boot_set(index: int, text: String) -> void:
	_boot_log[index] = text
	current_scrollback.text = "\n".join(_boot_log)

## waits <seconds>, or not at all once the player skipped
func _boot_wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds and !_skip_requested:
		await get_tree().process_frame
		t += get_process_delta_time()

const BOOT_OK := "[color=#4ec994][  OK  ][/color] "
const BOOT_WAIT := "[color=#888888][  ..  ][/color] "

## One boot step: "[ .. ] text" -> (callback) -> "[ OK ] text"
func _boot_step(text: String, hold: float, on_ok: Callable = Callable()) -> void:
	var i = _boot_print(BOOT_WAIT + text)
	await _boot_wait(hold)
	if on_ok.is_valid():
		on_ok.call()
	_boot_set(i, BOOT_OK + text)

func _fade_in(node: CanvasItem, seconds: float) -> void:
	node.visible = true
	if _skip_requested:
		node.modulate.a = 1.0
		return
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, seconds)

func install_idle_os():
	accepting_player_inputs = false
	_booting = true
	_skip_requested = false
	_clear_terminal()
	_boot_log.clear()
	_boot_print("[color=#33ff33]IdleOS installer[/color]  [color=#666666](any key to skip)[/color]")
	_boot_print("")
	await _boot_step("Mounting kernel", 0.35)
	await _boot_step("Verifying operator credentials", 0.35)
	_boot_print("")
	# skill modules: their header cards fade in as each one loads
	header.modulate.a = 1.0
	header.visible = true
	for mp in major_processes:
		var color = mp.SKILL.color.to_html(false)
		await _boot_step("Loading module [color=#%s]%s[/color]" % [color, mp.SKILL.name], 0.14, func(): header.intro(mp))
	_boot_print("")
	# system panel: show it, then reveal its sections in order
	var sections: Array = []
	for c in system_dock.full_view.get_children():
		if c is CanvasItem:
			sections.append(c)
			if !c.has_meta("boot_alpha"):
				c.set_meta("boot_alpha", c.modulate.a) # separators are dimmed by design
			c.modulate.a = 0.0
	system_dock.modulate.a = 1.0
	var panel_steps = [
		["Starting process monitor", ["TopBar", "HUDProcessRunning", "ProcessSeparator"]],
		["Calibrating thermal sensors", ["SystemTemp", "TrapStatus", "SystemSeparator", "TrackedSection", "Separator"]],
		["Allocating virtual machines", ["VMSection"]],
		["Opening access + upload channels", ["AccessSection", "UploadSection", "Spacer", "LedgerSeparator", "ItemLedger"]],
	]
	var shown_sections: Array = []
	for step in panel_steps:
		await _boot_step(step[0], 0.3, func():
			for c in sections:
				if c in shown_sections:
					continue
				var key = c.name if !(c is TrapStatus or c is AccessSection or c is UploadSection) else ("TrapStatus" if c is TrapStatus else ("AccessSection" if c is AccessSection else "UploadSection"))
				if key in step[1]:
					shown_sections.append(c)
					var tw = create_tween()
					tw.tween_property(c, "modulate:a", c.get_meta("boot_alpha", 1.0), 0.0 if _skip_requested else 0.4)
		)
	# anything not named above (separators built in code) comes in with the last step
	for c in sections:
		if !(c in shown_sections):
			create_tween().tween_property(c, "modulate:a", c.get_meta("boot_alpha", 1.0), 0.0 if _skip_requested else 0.4)
	await _boot_step("Command line interface", 0.3, func(): _fade_in(input_line_container, 0.5))
	_boot_print("")
	_boot_print("[color=#33ff33]IdleOS installed.[/color] Good luck.")
	await _boot_wait(1.2)
	_finish_boot()

## End state of the boot (also what a skip lands on): everything visible, terminal cleared, welcome shown.
## background playlist: after the boot screen (new game) or right away on a normal load
func _start_music() -> void:
	Settings._started = true
	if Settings.get_value("music_player") == "on":
		Audiomanager.start_playlist()

func _finish_boot() -> void:
	_start_music()
	header.modulate.a = 1.0
	header.visible = true
	for skill in major_processes:
		header.intro(skill)
	system_dock.modulate.a = 1.0
	for c in system_dock.full_view.get_children():
		if c is CanvasItem:
			c.modulate.a = c.get_meta("boot_alpha", 1.0)
	input_line_container.visible = true
	input_line_container.modulate.a = 1.0
	_booting = false
	_skip_requested = false
	_clear_terminal()
	accepting_player_inputs = true
	input_line.grab_focus()
	Tutorial.show_intro = false
	SaveManager.save_game()
	add_line("[color=#33ff33]" + Ascii.welcome + "[/color]")
	add_line(ContextCommands.demo_welcome_message())
	add_line("To get started, type `-h` in the terminal.")
	tutorial_window.set_context_hidden(false)
	_offline_welcome.call_deferred()
#endregion


#region offline welcome back
## "While you were away" as a download: a sync header, then one row per resource whose count climbs from 0
## to what was made offline behind a filling bar, then uploads / levels / notes, then the process resumes.
## Not skippable: every row fills at the same time (~2.5 s). XP gained per skill gets a row of its own after the
## resources.
const OFFLINE_C := "#33ff33"
const OFFLINE_DIM := "#5c6b7a"
const OFFLINE_BAR := 18

func _offline_welcome() -> void:
	var r: Dictionary = Offline.report
	if r.is_empty():
		_hold_unlocks = false
		_flush_unlocks()
		return
	Offline.report = {}
	await _wait_for_output()
	# 2026-10-30: a short absence (under a minute) is one quiet line, then the process resumes
	if r.get("resume_only", false) or r.get("short", false):
		await _offline_short(r)
		return
	accepting_player_inputs = false
	add_new_scrollback() # its own block below the welcome text (writing into current_scrollback replaced it)
	var block = current_scrollback
	add_new_scrollback()
	var head = "\n[color=%s]IDLEOS :: RESTORING OFFLINE SESSION[/color]\n" % OFFLINE_C
	head += "[color=%s]away %s%s%s[/color]\n" % [OFFLINE_DIM, Offline.format_time(r.away),
		("  ·  offline cap %s (Background Services raises it)" % Offline.format_time(Offline.cap_seconds())) if r.capped else "",
		("  ·  " + r.process) if r.process != "" else ""]
	# connect / sync bar
	for i in OFFLINE_BAR + 1:
		block.text = head + "connecting  [color=%s]%s[/color][color=%s]%s[/color]" % [OFFLINE_C, "█".repeat(i), OFFLINE_DIM, "░".repeat(OFFLINE_BAR - i)]
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(0.3).timeout
	var rows: Array = r.gains.slice(0, 12).map(func(g): return {"name": g.item.name, "amount": g.amount})
	for x in r.get("xp", []):
		rows.append({"name": x.skill + " XP", "amount": x.amount, "xp": true})
	for d in r.get("drivers", []): # equipped drivers rank up from offline skill XP too
		rows.append({"name": "%s XP (%s Driver)" % [d.name, d.skill], "amount": d.xp, "xp": true})
	# 2026-10-28: nothing to download (only uploads / notes): skip the bars, they ran 2.5s with nothing on screen
	head += "connected  [color=%s]session found · %s[/color]\n\n" % [OFFLINE_DIM, "downloading offline progress" if !rows.is_empty() else "syncing"]
	# 2026-10-25: every row downloads at the same time (one bar each), then all flip to 'downloaded'
	var done_text = ""
	var name_w = 4
	for g in rows:
		name_w = max(name_w, g.name.length())
	var steps = 60 if !rows.is_empty() else 0
	var duration = 2.5
	for k in (steps + 1 if !rows.is_empty() else 0):
		var f = 1.0 - pow(1.0 - float(k) / steps, 2.0) # ease out: quick start, settles at the end
		var filled = int(round(OFFLINE_BAR * f))
		var live = ""
		for g in rows:
			live += "%s  %s  [color=%s]%s[/color][color=%s]%s[/color]  [color=%s]+%s[/color]\n" % [
				"downloaded " if k == steps else "downloading", g.name.rpad(name_w), OFFLINE_C, "█".repeat(filled), OFFLINE_DIM,
				"░".repeat(OFFLINE_BAR - filled), OFFLINE_C if k == steps else "#cccccc", _commas(int(round(g.amount * f)))]
		block.text = head + live
		if k < steps:
			await get_tree().create_timer(duration / steps).timeout
		else:
			done_text = live
	if !rows.is_empty():
		await get_tree().create_timer(0.25).timeout
	if r.gains.size() > rows.size():
		done_text += "[color=%s]+ %d more items ('ls')[/color]\n" % [OFFLINE_DIM, r.gains.size() - rows.size()]
	var tail = ""
	if !r.spent.is_empty():
		tail += "[color=%s]used: %s[/color]\n" % [OFFLINE_DIM, ", ".join(r.spent.slice(0, 4).map(func(s): return "%s %s" % [_commas(s.amount), s.item.name]))]
	if !r.staged.is_empty():
		tail += "queued: %s\n" % ", ".join(r.staged.map(func(s): return "%s %s" % [_commas(s.amount), s.item.name]))
	for u in r.uploaded:
		tail += "uploaded: %s %s%s\n" % [_commas(u.amount), u.item.name, ("  [color=%s]· goal complete[/color]" % OFFLINE_C) if u.done else ""]
	if r.has("intel"):
		tail += "intel: [color=%s]%s +%d[/color]  [color=%s]now %s[/color]\n" % [OFFLINE_C, r.intel.target, r.intel.points, OFFLINE_DIM, _plain_bb(r.intel.text)]
	for d in r.get("drivers", []):
		if d.to > d.from:
			tail += "[color=#ffc24a]%s driver %s rank %d -> %d[/color]\n" % [d.skill, d.name, d.from, d.to]
	for l in r.levels:
		tail += "[color=%s]%s level %d -> %d[/color]%s\n" % [OFFLINE_C, l.skill, l.from, l.to,
			("  [color=%s]+%d %s[/color]" % [OFFLINE_DIM, l.tokens, l.token.name]) if l.tokens > 0 and l.token else ""]
		for sl in Drivers.SLOT_LEVELS:
			if l.from < sl and l.to >= sl and Drivers.has_drivers(l.skill):
				tail += "[color=#ffc24a]%s Driver slot unlocked.[/color] cd into %s to view more details.\n" % [l.skill, l.skill.to_lower()]
	if r.trap >= 0.0:
		tail += ("[color=%s]trap full: 'trap collect'[/color]\n" % OFFLINE_C) if r.trap >= 1.0 else ("trap: %d%% full  [color=%s](fills on real time)[/color]\n" % [int(r.trap * 100), OFFLINE_DIM])
	for n in r.notes:
		tail += "[color=%s]%s[/color]\n" % [OFFLINE_DIM, n]
	if r.overheat:
		var lost: Dictionary = r.get("lost", {})
		var keys = lost.keys()
		keys.sort_custom(func(a, b): return lost[a] > lost[b])
		var what = ", ".join(keys.slice(0, 4).map(func(k): return "%s %s" % [_commas(lost[k]), k.name]))
		tail += "[color=#e0c068]ran hot: overheating cost you %s[/color]\n" % (what if what != "" else "%d%% of the output" % int(Offline.OVERHEAT_PENALTY * 100))
		tail += "[color=%s]  (-%d%%: the process makes more heat than your system cools; more cooling in 'apt system' fixes it)[/color]\n" % [OFFLINE_DIM, int(Offline.OVERHEAT_PENALTY * 100)]
	block.text = head + done_text + (("\n" if done_text != "" else "") + tail if tail != "" else "")
	await get_tree().create_timer(0.2).timeout
	for t in r.tiers:
		add_line(ContextCommands.tier_complete_text(t))
		await _wait_for_output()
	_hold_unlocks = false
	_flush_unlocks() # processes unlocked by offline level ups
	await _wait_for_output()
	accepting_player_inputs = true
	input_line.grab_focus()
	# resume the process that ran offline
	if !r.resume.is_empty() and !process_running:
		add_line("[color=%s]resuming '%s'[/color]" % [OFFLINE_DIM, r.resume.command])
		update_context(int(r.resume.context))
		_sync_header_to_context() # 2026-10-27: the header stayed on root after coming back into a skill
		_on_input_line_text_submitted(r.resume.command)

## under a minute away: "away 42s · Parsing Network: +1 Student cache network · resuming '...'", no download screen
func _offline_short(r: Dictionary) -> void:
	var parts = []
	if !r.get("resume_only", false):
		parts.append("away %s" % Offline.format_time(r.away))
		if r.get("process", "") != "" and !r.gains.is_empty():
			parts.append("%s: %s" % [r.process, ", ".join(r.gains.slice(0, 3).map(func(g): return "+%s %s" % [_commas(g.amount), g.item.name]))])
		for l in r.get("levels", []):
			parts.append("%s level %d -> %d" % [l.skill, l.from, l.to])
	var resume = !r.resume.is_empty() and !process_running
	if resume:
		parts.append("resuming '%s'" % r.resume.command)
	# a plain restart (under 5s) resumes silently; a short away with nothing running and nothing gained says nothing
	var worth = !r.get("resume_only", false) and (resume or !r.gains.is_empty() or !r.get("levels", []).is_empty())
	if worth:
		add_line("[color=%s]%s[/color]" % [OFFLINE_DIM, "  ·  ".join(parts)])
	for t in r.get("tiers", []):
		add_line(ContextCommands.tier_complete_text(t))
		await _wait_for_output()
	_hold_unlocks = false
	_flush_unlocks()
	await _wait_for_output()
	accepting_player_inputs = true
	input_line.grab_focus()
	if resume:
		update_context(int(r.resume.context))
		_sync_header_to_context()
		_on_input_line_text_submitted(r.resume.command)

static func _plain_bb(t: String) -> String:
	var re = RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(t, "", true)

static func _commas(n: int) -> String:
	var s = str(abs(n))
	var out = ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out
#endregion

func player_uploaded_proper_item():
	accepting_player_inputs = false
	#tween for the following: header, overclock, input_line_container
	#tween should just change opacity to 0.0 then set visibility to false
	
	_clear_terminal()
	var tween = create_tween()
	tween.set_parallel(true)

	for node in [header, overclock, input_line_container, system_dock]:
		tween.tween_property(node, "modulate:a", 0.0, 0.5)

	tween.chain().tween_callback(func():
		for node in [header, overclock, input_line_container]:
			node.visible = false
	)
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	
	add_line("[          ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[=         ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[==        ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[===       ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[====      ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[=====     ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[======    ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[=======   ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[========  ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[========= ]")
	await get_tree().create_timer(0.1).timeout
	add_line("[==========]")
	await get_tree().create_timer(0.1).timeout
	add_line("[color=green]Parents CC Successfully uploaded[/color]")
	Inventory.remove_resource(Items.PARENTS_CREDIT_CARD, 1)
	await type_text("""\n
Well done. It seems you have what it takes after all.

Unfortunately, the rest of IdleOS is still under development. Until version 1.0 is ready, we've prepared one final challenge to test your abilities.

Think you've mastered the system? Try your hand at the Hard Mode Student. This opponent won't go down easily, and brute force alone won't be enough.

You'll need to find powerful Hacking Mods, push your VMs to their full potential, upgrade versions, overclock, and spoof your way to victory.

Good luck.


press 'enter' to return to console""")

	awaiting_player_input = true
	upload_awaiting_player_input = true


func finish_player_uploaded_proper_item():
	awaiting_player_input = false
	upload_awaiting_player_input = false
	
	_clear_terminal()
	for node in [header, overclock, input_line_container, system_dock]:
		node.visible = true
		node.modulate.a = 0.0

	var tween2 = create_tween()
	tween2.set_parallel(true)

	for node in [header, overclock, input_line_container, system_dock]:
		tween2.tween_property(node, "modulate:a", 1.0, 0.3)

	await tween2.finished
	
	###UNLOCK HARD MODE
	Stats.unlock_hard_mode("School")
	Tutorial.complete_event(Tutorial.TutorialEvent.UPLOAD_PARENTS_CC)
	accepting_player_inputs = true
	input_line.grab_focus()
	SaveManager.save_game()
