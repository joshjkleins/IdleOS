extends MarginContainer

signal start_loading

@onready var header_hacking_box: Control = $VBoxContainer/HeaderHackingBox
@onready var player_hacking_box: Control = $VBoxContainer/HBoxContainer/PlayerHackingBox
@onready var enemy_hacking_box: Control = $VBoxContainer/HBoxContainer/HackingBox

var is_in_hacking_context: bool = false

var can_accept_inputs: bool = true

enum HackingContext {
	TARGETS,
	PERSONS,
	HACKING
}

var current_context: HackingContext = HackingContext.TARGETS

func _ready():
	Signals.hacking_ended_signal.connect(hacking_ended)
	Signals.update_console_signal.connect(message_from_hack_game)
	Signals.tutorial_event_completed_signal.connect(tutorial_event_completed)
	Signals.hacking_can_accept_player_commands_signal.connect(toggle_hacking_accepted_input_text)

func toggle_hacking_accepted_input_text(accept: bool):
	can_accept_inputs = accept

func module_loaded():
	current_context = HackingContext.TARGETS
	header_hacking_box.update_hacking_header()
	header_hacking_box.update_modifiers_ui()
	modulate.a = 0.0
	visible = true
	player_hacking_box.grab()
	player_hacking_box.clear()
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween2.finished
	enemy_hacking_box.update_targets()
	is_in_hacking_context = true
	Tutorial.complete_event(Tutorial.TutorialEvent.NAVIGATE_HACKING)
	player_hacking_box.add_line("Welcome to the hacking module. The hacking module has limited commands.\nUse this module to view and hack potential targets via auto-battler.")
	hacking_help_commands()


func tutorial_event_completed(message: String):
	if is_in_hacking_context:
		player_hacking_box.add_line(message)

func go_to_root() -> void:
	Tutorial.complete_event(Tutorial.TutorialEvent.RETURN_TO_ROOT)
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween2.finished
	visible = false
	is_in_hacking_context = false
	start_loading.emit()
	enemy_hacking_box.persons_to_targets()

func _on_player_hacking_box_command_entered(text):
	if !can_accept_inputs:
		return
	
	if text.to_lower().strip_edges() in ["quit", "exit", "quit -s", "exit -s"]:
		quit_game()
		return
	var low = text.to_lower().strip_edges()
	# one-time items: "<full name> -force"
	if low.ends_with(" -force"):
		var forced = Exploits.find_forced(low)
		if forced == null:
			player_hacking_box.add_line_error("Unknown one-time item '%s'. Type 'run' to see yours." % low.trim_suffix(" -force"))
		else:
			_use_exploit(forced)
		return
	# back to the main terminal from anywhere in the hacking console
	if low in ["cd ~", "cd /", "cd", "home", "root", "cd root"] and current_context != HackingContext.HACKING:
		go_to_root()
		return
	if low == "run" or low.begins_with("run "):
		handle_run_command(low)
		return
	if (low == "unlock" or low.begins_with("unlock ")) and current_context != HackingContext.HACKING:
		handle_unlock_command(low.trim_prefix("unlock").strip_edges())
		return
	if text.to_lower() == "tutorial":
		player_hacking_box.add_line(ContextCommands.get_hacking_tutorial())
	else:
		match current_context:
			HackingContext.TARGETS:
				if text.begins_with("view"):
					handle_view_command(text)
					return
				
				match text:
					"cd ..":
						go_to_root()
					"-h":
						hacking_help_commands()
					"apt":
						player_hacking_box.add_line("Apt upgrade manager not available in hacking console. Return to root to view.")
					_:
						player_hacking_box.add_line("Command not found.")
			HackingContext.PERSONS:
				if text.begins_with("hack"):
					handle_hack_command(text)
					return
				
				match text:
					"cd ..":
						handle_back_command()
					"cd ../..":
						go_to_root()
					"-h":
						hacking_help_commands()
					"apt":
						player_hacking_box.add_line("Apt upgrade manager not available in hacking console. Return to root to view.")
					_:
						player_hacking_box.add_line("Command not found.")
			HackingContext.HACKING:
				match text:
					"kill":
						if Stats.overclocked:
							Stats.overclocked = false
						Signals.end_hacking()
					"kill -s":
						Signals.end_hacking_safely()
					"-h":
						hacking_help_commands()
					"overclock":
						if !Upgrades.can_overclock(Hacking):
							player_hacking_box.add_line_warning("Overclock not available. Unlock with apt package manager.")
							return
						if Stats.overheated:
							player_hacking_box.add_line_warning("System has been overheated, needs to cool to below 40°C.")
							return
						if Stats.overclocked:
							player_hacking_box.add_line("System is already overclocked.")
							return
							
						Stats.overclocked = true
						player_hacking_box.add_line_success("System overclocked. Bandwidth regen x2, heat increased. Use 'overclock -kill' to stop.")
					"overclock -kill", "overclock kill":
						if !Stats.overclocked:
							player_hacking_box.add_line("Not currently overclocking.")
						if Stats.overclocked:
							player_hacking_box.add_line("Killing overclock.")
						Stats.overclocked = false
					"spoof":
						if Inventory.get_amount(Items.PACKET_SPOOF) <= 0:
							player_hacking_box.add_line_error("OUT OF PACKET SPOOFS")
						else:
							Signals.manual_packet_spoof()
					_:
						player_hacking_box.add_line("Hacking in progress, to stop hacking type 'kill'")

## 'run' (list), 'run auto <item>' / 'run auto off'; items are used with '<name> -force' (_use_exploit)
func handle_run_command(text: String) -> void:
	var game = enemy_hacking_box.hacking_game
	var in_hack = current_context == HackingContext.HACKING and game.is_hacking
	var arg = text.substr(3).strip_edges()
	if arg in ["", "-h", "list", "ls"]:
		player_hacking_box.add_line(Exploits.list_text(in_hack))
		return
	if arg == "auto" or arg.begins_with("auto "):
		var name = arg.substr(4).strip_edges()
		if name == "":
			player_hacking_box.add_line("Auto: " + (Exploits.get_item(Exploits.auto_id).name if Exploits.auto_id != "" else "off") + ". Set with 'run auto <item>', stop with 'run auto off'.")
			return
		if name in ["off", "stop", "none", "-kill"]:
			Exploits.auto_id = ""
			SaveManager.mark_dirty()
			player_hacking_box.add_line("Auto use turned off.")
			return
		var auto_item = Exploits.find(name)
		if auto_item == null:
			player_hacking_box.add_line_error("Unknown one-time item '%s'. Type 'run' to see yours." % name)
			return
		Exploits.auto_id = auto_item.exploit_id
		SaveManager.mark_dirty()
		player_hacking_box.add_line_success("Auto: %s is used whenever it's useful and you have %d charge. Stop with 'run auto off'." % [auto_item.name, int(Exploits.cost(auto_item))])
		if Inventory.get_amount(auto_item) <= 0:
			player_hacking_box.add_line_warning("You don't have any %s yet." % auto_item.name)
		return
	var item = Exploits.find(arg) # old 'run <name>' still works (not shown anywhere)
	if item == null:
		player_hacking_box.add_line_error("Unknown one-time item '%s'. Type 'run' to see yours." % arg)
		return
	_use_exploit(item)

func _use_exploit(item) -> void:
	var game = enemy_hacking_box.hacking_game
	var in_hack = current_context == HackingContext.HACKING and game.is_hacking
	if !in_hack:
		player_hacking_box.add_line_warning("One-time items can only be used during a hack.")
		return
	var err = game.use_exploit(item)
	if err != "":
		player_hacking_box.add_line_warning(err)
	else:
		player_hacking_box.add_line_success("%s used (%d left)." % [item.name, Inventory.get_amount(item)])

func handle_hack_command(text):
	var recursive: bool = false
	var overclock: bool = false
	var hack_count: int = 1
	
	var tokens = Array(text.split(" ", false))
	
	# Check for recursive flag
	if "-r" in tokens:
		recursive = true # always available
		tokens.erase("-r")
	
	# Check for overclock flag
	if "-overclock" in tokens:
		tokens.erase("-overclock")
		
		if !Upgrades.can_overclock(Hacking):
			player_hacking_box.add_line_error("Overclocking for hacking not unlocked, continuing without overclock.")
		if Upgrades.can_overclock(Hacking) and !Stats.overheated:
			overclock = true
	
	# Check for hack count (the "=N" can be on any token, e.g. "hack vice principal=25")
	for i in tokens.size():
		var equals_index: int = tokens[i].find("=")
		if equals_index == -1:
			continue
		
		var count_text: String = tokens[i].substr(equals_index + 1)
		tokens[i] = tokens[i].substr(0, equals_index)
		
		if !count_text.is_valid_int():
			player_hacking_box.add_line_error("Invalid hack amount.")
			return
		
		hack_count = int(count_text)
		if hack_count <= 0:
			player_hacking_box.add_line_error("Hack amount must be greater than 0.")
			return
		break
	
	# Command with the "=N" removed, e.g. "hack student" or "hack vice principal"
	var target_name: String = " ".join(tokens)
	text = target_name
	
	# Recursive and specific amount are mutually exclusive
	if recursive:
		hack_count = -1
	
	#var target: Dictionary = Stats.get_hacking_target_by_command(target_name)
	var target: Dictionary = enemy_hacking_box.get_hacking_target(target_name)
	
	# Valid target
	if target.is_empty():
		player_hacking_box.add_line_error("Not a valid command.")
		player_hacking_box.add_line_system("Example: hack student=4")
		player_hacking_box.add_line_system("Example: hack student=4 -overclock")
		player_hacking_box.add_line_system("Example: hack student -overclock")
		return
	
	if !target.get("unlocked", false):
		player_hacking_box.add_line_error("Target is locked: " + Stats.get_unlock_hint(target))
		return
	
	# tutorial hack steps: never short of payloads / SQL (Tutorial.ensure_hack_kit)
	var kit = Tutorial.ensure_hack_kit(target, hack_count)
	if kit != "":
		player_hacking_box.add_line_system(kit)
	# Has requirements in inventory
	if !_has_hacking_requirements(target):
		await enemy_hacking_box.target_select_error(target)
		player_hacking_box.add_line_error("Missing required payloads.")
		player_hacking_box.add_line_error("Missing: " + target.requirements.item.name + " x" + str(target.requirements.amount))
		return
	
	if Inventory.get_amount(Items.SQL_INJECTOR) <= 0:
		player_hacking_box.add_line_error("Missing SQL Injectors.")
		player_hacking_box.add_line_system("Can be found Phishing.")
		return
	
	toggle_hacking_accepted_input_text(false)
	current_context = HackingContext.HACKING
	hacking_help_commands()
	
	Stats.current_anon = Stats.max_anon
	
	await enemy_hacking_box.select_person(target, hack_count, overclock)
	
	toggle_hacking_accepted_input_text(true)

## 'unlock <target>': pays a locked target's access recipe. 'unlock' alone lists what can be unlocked.
var _shown_targets: Array = [] # the cards on screen (PERSONS), redrawn after an unlock
func handle_unlock_command(name: String) -> void:
	if name == "":
		var rows = []
		for loc in Stats.hacking_targets:
			if !Stats.hacking_targets[loc].get("unlocked", false):
				continue
			for tg in Stats.hacking_targets[loc].get("targets", []):
				var r = Stats.get_access_recipe(tg)
				if tg.get("unlocked", false) or r.is_empty() or r.rare == null or !DemoRules.is_demo_target(Stats.target_key(tg)):
					continue # DEMO: only the demo's targets
				var ok = Inventory.get_amount(r.rare) >= int(r.rare_amount) and Inventory.get_amount(r.payload) >= int(r.payload_amount)
				rows.append("  [color=%s]%s[/color] %d/%d %s  ·  %d/%d %s" % ["#33ff33" if ok else "#888888", ("unlock " + tg.name.to_lower()).rpad(28), Inventory.get_amount(r.rare), int(r.rare_amount), r.rare.name, Inventory.get_amount(r.payload), int(r.payload_amount), r.payload.name])
		player_hacking_box.add_line("LOCKED TARGETS\n" + ("\n".join(rows) if !rows.is_empty() else "  [color=#888888]Nothing to unlock right now.[/color]"))
		return
	var res = Stats.buy_access(Stats.find_target_by_name(name))
	if !res.ok:
		player_hacking_box.add_line_error(res.message)
		return
	player_hacking_box.add_line_success(res.message)
	if current_context == HackingContext.PERSONS and !_shown_targets.is_empty():
		enemy_hacking_box._update_persons(_shown_targets)

func handle_back_command():
	match current_context:
		HackingContext.PERSONS:
			await enemy_hacking_box.persons_to_targets()
			current_context = HackingContext.TARGETS
			hacking_help_commands()
		HackingContext.HACKING:
			await enemy_hacking_box.hacking_to_persons()
			current_context = HackingContext.PERSONS
			hacking_help_commands()

func handle_view_command(text):
	var target: Dictionary = Stats.get_hacking_location_by_command(text)
	if target.is_empty():
		player_hacking_box.add_line("Not a valid location.")
		return
	if !target.get("unlocked", false):
		player_hacking_box.add_line(DemoRules.full_game_text("The " + str(target.get("name", "")) + " location")) # DEMO
		return
	if text.contains("-hard") and !target.get("hard mode unlocked", false):
		player_hacking_box.add_line("Hard mode for location not unlocked.")
		return
	var targets: Array = Stats.get_hacking_targets_by_command(text)
	var location_name: String = str(target.get("name", "")) + (" - hard mode" if text.contains("-hard") else "")
	if targets.is_empty():
		player_hacking_box.add_line("Not a valid location.")
	else:
		current_context = HackingContext.PERSONS
		_shown_targets = targets
		if str(target.get("name", "")).to_lower() == "school" and !text.contains("-hard"):
			Tutorial.complete_event(Tutorial.TutorialEvent.VIEW_SCHOOL)
		hacking_help_commands()
		await enemy_hacking_box.select_target(location_name, targets)


func hacking_ended():
	#enemy_hacking_box.end_hack()
	header_hacking_box.update_hacking_header()
	header_hacking_box.update_modifiers_ui()
	current_context = HackingContext.PERSONS
	hacking_help_commands()
	await enemy_hacking_box.hacking_to_persons()

func message_from_hack_game(message: String):
	player_hacking_box.add_line(message)

func format_command_list(title: String, commands: Array) -> String:
	var lines = player_hacking_box.add_line_header(title, true) + "\n"
	
	for cmd in commands:
		var command = cmd[0]
		var description = cmd[1]
		var example = cmd[2] if cmd.size() > 2 else ""
		
		lines += "[color=#4ec994]" + command + "[/color]\n"
		lines += "  [color=#cccccc]" + description + "[/color]\n"
		if example != "":
			lines += "  [color=#888888]" + example + "[/color]\n"
		lines += "\n"
	
	return lines.strip_edges()

func _has_hacking_requirements(target) -> bool:
	var req = target.requirements
	if Inventory.get_amount(req.item) < req["amount"]:
		return false
	return true

func hacking_help_commands():
	match current_context:
		HackingContext.TARGETS:
			player_hacking_box.add_line(format_command_list("[HACKING COMMANDS]", [
				["view [location]", "List targets at location", "e.g. view school"],
				["unlock", "List locked targets and what they cost"],
				["unlock [target]", "Unlock a target", "e.g. unlock administrator"],
				["cd ..",            "Return to terminal root"],
				["cd root",          "Return to terminal root from anywhere in hacking (or cd ~)"]
			]))
		HackingContext.PERSONS:
			var recursive_unlocked = true # '-r' is always available

			var commands = [
				["hack [target]", "Hack target once", "e.g. hack student"],
				["hack [target]=[amount]", "Hack target a set number of times", "e.g. hack student=20"],
				["hack [target] -overclock", "Hack target with overclock (x2 bandwidth regen)", "e.g. hack student -overclock"],
				["unlock [target]", "Unlock a target ('unlock' lists them)", "e.g. unlock administrator"],
				["cd ..", "Return to locations directory", "e.g. 'cd ..'"],
				["cd root", "Return to terminal root (or cd ~)"]
			]

			if recursive_unlocked:
				commands.insert(2, ["hack [target] -r", "Recursively hack target until manually cancelled or defeated", "e.g. hack student -r"])

			player_hacking_box.add_line(format_command_list("COMMANDS", commands))
		HackingContext.HACKING:
			if true: # hacking overclock is always available
				player_hacking_box.add_line(format_command_list("COMMANDS", [
					["spoof", "Start packet spoof to restore anonymity."],
					["[item name] -force", "Use a one-time item ('run' lists yours)."],
					["kill", "Ends the run now (caches already breached are kept)."],
					["kill -s", "Finish the current hack, then end the run (for -r / =N runs)."],
					["overclock", "Doubles bandwidth regen (more heat per action)"],
					["overclock -kill", "Stops overclocking ('overclock kill' works too)"],
				]))
			else:
				player_hacking_box.add_line(format_command_list("COMMANDS", [
					["spoof", "Start packet spoof to restore anonymity."],
					["[item name] -force", "Use a one-time item ('run' lists yours)."],
					["kill", "Ends the run now (caches already breached are kept)."],
				]))


## 'quit' from the hacking console. Hacking doesn't run offline: a hack in progress is abandoned (its
## payload was already used and saved when it started, so quitting can't be used to retry for free).
## Targets already beaten this session are banked first.
func quit_game() -> void:
	can_accept_inputs = false
	var game = enemy_hacking_box.hacking_game
	if game.is_hacking:
		player_hacking_box.add_line("Disconnecting: the hack in progress is abandoned.")
		game.end()
	Exploits.reset_charge()
	game._grant_rewards()
	player_hacking_box.add_line("SAVING")
	await get_tree().create_timer(0.6).timeout
	player_hacking_box.add_line("GOODBYE")
	await get_tree().create_timer(0.8).timeout
	SaveManager.save_game()
	get_tree().quit()
