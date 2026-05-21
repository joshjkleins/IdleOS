extends MarginContainer

signal start_loading

@onready var header_hacking_box: Control = $VBoxContainer/HeaderHackingBox
@onready var player_hacking_box: Control = $VBoxContainer/HBoxContainer/PlayerHackingBox
@onready var enemy_hacking_box: Control = $VBoxContainer/HBoxContainer/HackingBox

enum HackingContext {
	TARGETS,
	PERSONS,
	HACKING
}

var current_context: HackingContext = HackingContext.TARGETS

func _ready():
	Signals.hacking_ended_signal.connect(hacking_ended)
	Signals.update_console_signal.connect(message_from_hack_game)

func module_loaded():
	header_hacking_box.update_header()
	modulate.a = 0.0
	visible = true
	player_hacking_box.grab()
	player_hacking_box.clear()
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween2.finished
	
	#header_hacking_box.update_header()
	enemy_hacking_box.update_targets()

func go_to_root() -> void:
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween2.finished
	visible = false
	
	start_loading.emit()


func _on_player_hacking_box_command_entered(text):
	if text.to_lower() == "heal":
		#healing logic
		if Inventory.get_amount(Items.PACKET_SPOOF) <= 0:
			player_hacking_box.add_line_error("No Packet Spoof found")
			return
		if Stats.current_anon >= Stats.max_anon:
			player_hacking_box.add_line_warning("Already at max anonymity")
			return
			
		Inventory.remove_resource(Items.PACKET_SPOOF, 1)
		Stats.current_anon += Items.PACKET_SPOOF["heal"]
		if Stats.current_anon > Stats.max_anon:
			Stats.current_anon = Stats.max_anon
		var t = "1 " + Items.PACKET_SPOOF.name + " consumed: +" + str(Items.PACKET_SPOOF.heal) + " anonymity"
		player_hacking_box.add_line_success(t)
	else:
		match current_context:
			HackingContext.TARGETS:
				if text.begins_with("view"):
					handle_view_command(text)
					return
				
				match text:
					"root":
						go_to_root()
					"-h":
						player_hacking_box.add_line(format_command_list("[HACKING COMMANDS]", [
							["view [location]", "List targets at location", "e.g. view school"],
							["root",            "Return to terminal root"]
						]))
					_:
						player_hacking_box.add_line("Command not found.")
			HackingContext.PERSONS:
				if text.begins_with("hack"):
					handle_hack_command(text)
					return
				
				match text:
					"..":
						handle_back_command()
					"-h":
						player_hacking_box.add_line(format_command_list("COMMANDS", [
							["hack [target]", "Start hacking target", "e.g. hack student"],
							["..",            "Return to locations directory", "e.g. '..'"]
						]))
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
						player_hacking_box.add_line(format_command_list("COMMANDS", [
							["kill", "Kills current hack attempt immediately, resources may be lost."],
							["kill -s", "Safely exits hacking attempt at the end of the current attempt."],
							["overclock", "Overclocks system to increase speed and heat output"],
							["overclock -kill", "Stops overclocking"],
							
						]))
					"overclock":
						if !Stats.overclocked and !Stats.overheated:
							if Stats.system_tempature < 60:
								Stats.overclocked = true
							else:
								player_hacking_box.add_line_warning("System tempature needs to cool to below 60°C before overclocking")
						elif Stats.overheated:
							player_hacking_box.add_line_warning("System has been overheated, needs to cool to below 40°C.")
						else:
							player_hacking_box.add_line("System is already overclocked.")
					"overclock -kill":
						if !Stats.overclocked:
							player_hacking_box.add_line("Not currently overclocking.")
						if Stats.overclocked:
							player_hacking_box.add_line("Killing overclock.")
						Stats.overclocked = false
					_:
						player_hacking_box.add_line("Hacking in progress, to stop hacking type '-kill'")
	

func handle_hack_command(text):
	var target: Dictionary = Stats.get_hacking_target_by_command(text)
	if target.is_empty():
		player_hacking_box.add_line_error("Not a valid target.")
	else:
		if enemy_hacking_box.can_hack_person(target):
			if Stats.current_anon > 0:
				await enemy_hacking_box.select_person(target)
				current_context = HackingContext.HACKING
			else:
				player_hacking_box.add_line_error("Anonymity at 0. Increase to above 0 before hacking.")
				player_hacking_box.add_line_system("Use anonymity increase items at any time with command: 'heal'")
		else:
			if Inventory.get_amount(Items.IP_ADDRESS) <= 0:
				player_hacking_box.add_line_error("No IP Addresses")
			if Inventory.get_amount(Items.CREDENTIALS) <= 0:
				player_hacking_box.add_line_error("No Credentials")

func handle_back_command():
	match current_context:
		HackingContext.PERSONS:
			await enemy_hacking_box.persons_to_targets()
			current_context = HackingContext.TARGETS
		HackingContext.HACKING:
			await enemy_hacking_box.hacking_to_persons()
			current_context = HackingContext.PERSONS

func handle_view_command(text):
	var target: Dictionary = Stats.get_hacking_location_by_command(text)
	if target.is_empty():
		player_hacking_box.add_line("Not a valid location.")
	else:
		await enemy_hacking_box.select_target(target)
		current_context = HackingContext.PERSONS


func hacking_ended():
	#enemy_hacking_box.end_hack()
	current_context = HackingContext.PERSONS
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
