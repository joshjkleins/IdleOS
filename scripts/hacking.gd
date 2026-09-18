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
						player_hacking_box.add_line_success("System overclocked. Speed and heat increased. Use 'overclock kill' to stop.")
					"overclock -kill":
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

func handle_hack_command(text):
	var recursive: bool = false
	var overclock: bool = false
	var hack_count: int = 1
	
	var tokens = Array(text.split(" ", false))
	
	# Check for recursive flag
	if "-r" in tokens:
		if !Upgrades.get_package_info("hacking.recursive_hacking").current:
			player_hacking_box.add_line_error("Recursive functionality not unlocked. Unlock with apt upgrade manager.")
			return
		else:
			recursive = true
		
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
	
	var target: Dictionary = Stats.get_hacking_target_by_command(target_name)
	
	# Valid target
	if target.is_empty():
		player_hacking_box.add_line_error("Not a valid command.")
		player_hacking_box.add_line_system("Example: hack student=4")
		player_hacking_box.add_line_system("Example: hack student=4 -overclock")
		player_hacking_box.add_line_system("Example: hack student -overclock")
		return
	
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
	else:
		current_context = HackingContext.PERSONS
		hacking_help_commands()
		await enemy_hacking_box.select_target(target)


func hacking_ended():
	#enemy_hacking_box.end_hack()
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
				["cd ..",            "Return to terminal root"]
			]))
		HackingContext.PERSONS:
			var recursive_unlocked = Upgrades.get_package_info("hacking.recursive_hacking").current

			var commands = [
				["hack [target]", "Hack target once", "e.g. hack student"],
				["hack [target]=[amount]", "Hack target a set number of times", "e.g. hack student=20"],
				["hack [target] -overclock", "Hack target with overclock", "e.g. hack student -overclock"],
				["cd ..", "Return to locations directory", "e.g. 'cd ..'"]
			]

			if recursive_unlocked:
				commands.insert(2, ["hack [target] -r", "Recursively hack target until manually cancelled or defeated", "e.g. hack student -r"])

			player_hacking_box.add_line(format_command_list("COMMANDS", commands))
		HackingContext.HACKING:
			if Upgrades.get_package_info("hacking.overclock").current:
				player_hacking_box.add_line(format_command_list("COMMANDS", [
					["spoof", "Start packet spoof to restore anonymity."],
					["kill", "Kills current hack attempt immediately."],
					#["kill -s", "Safely exits hacking attempt at the end of the current attempt."],
					["overclock", "Overclocks system to increase speed and heat output"],
					["overclock -kill", "Stops overclocking"],
				]))
			else:
				player_hacking_box.add_line(format_command_list("COMMANDS", [
					["spoof", "Start packet spoof to restore anonymity."],
					["kill", "Kills current hack attempt immediately."],
				]))
