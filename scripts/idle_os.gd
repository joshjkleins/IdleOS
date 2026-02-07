extends Control

@onready var input_line = $Panel/MarginContainer/TerminalRoot/HBoxContainer/InputLine

@onready var basic_process = $Panel/MarginContainer/TerminalRoot/BasicProcess
@onready var password_hacking = $Panel/MarginContainer/TerminalRoot/PasswordHacking
@onready var scrollback = $Panel/MarginContainer/TerminalRoot/Scrollback

var command_history = []
var scrollback_history = []
var history_index = -1
var running_process = false
var current_process

func _ready():
	ContextCommands.current_context = ContextCommands.TerminalContext.ROOT
	input_line.grab_focus()
	input_line.deselect_on_focus_loss_enabled = false


func _on_input_line_text_submitted(new_text):
	if running_process:
		input_line.clear()
		update_scrollback("Error: process in progress, cancel to enter commands")
	else:
		match new_text.to_lower():
			"clear":
				clear_console()
			"ls -p":
				input_line.clear()
				list_processes()
			"lp collect":
				input_line.clear()
				if !running_process:
					running_process = true
					input_line.placeholder_text = "In process, type cmd + c to cancel"
					clear_console()
					basic_process.start_process()
					current_process = basic_process
			"lp unscramble":
				input_line.clear()
				if !running_process:
					running_process = true
					input_line.placeholder_text = "In process, type cmd + c to cancel"
					clear_console()
					password_hacking.start_process()
					current_process = password_hacking
			"dw -auth":
				input_line.clear()
				if ContextCommands.current_context == ContextCommands.TerminalContext.DARKWEB:
					update_scrollback("IdleOS/DarkWeb> Connection to dark web already authorized")
				else:
					dark_web_login()
			"help":
				input_line.clear()
				update_scrollback("IdleOS> " + new_text)
				list_commands()
			"quit":
				get_tree().quit()
			"ls -r": #list resources
				input_line.clear()
				show_resources()
			_: #command not found
				input_line.clear()
				update_scrollback("IdleOS> " + new_text)
				update_scrollback("Command not found, type help for list of available commands.")
				
	command_history.append(new_text)

func list_processes():
	var cmds := """\nAVAILABLE PROCESSES:
collect          Generates data
unscramble       Password unscrambling
analyze_logs     Extract resources from logs
assemble         Matches usernames and passwords to create credentials
hack             Runs hacking module
decrypt_cache    Decrypts and extracts resources from caches
"""
	update_scrollback(cmds)

func list_commands():
	#var cmds := """\nCOMMANDS:
#ls process       List available process
#ls resources     Lists all resources
#dw -auth         Connects to the dark web shop
#clear            Clears console
#-h               Shows this help message
#quit             Quit game
#"""
	update_scrollback(ContextCommands.help_text[ContextCommands.current_context])


func show_resources():
	var resource_string = """\nRESOURCES:
Data             """ + str(Inventory.total_data) + """
Passwords        """ + str(Inventory.total_passwords) + """
"""
	update_scrollback(resource_string)

func clear_console():
	scrollback_history.clear()
	scrollback.text = ""
	input_line.clear()

func start_process():
	input_line.placeholder_text = "In process, type cmd + c to cancel"
	await run_process()
	input_line.placeholder_text = "type a command, type -h for help"

func run_process():
	clear_console()
	update_scrollback("[ .. ] initializing process...")
	
	await get_tree().create_timer(0.5).timeout
	update_last_line("[ OK ] process initialized")
	update_scrollback("[ .. ] allocating resources")
	await get_tree().create_timer(0.5).timeout
	update_scrollback("[ OK ] process running")
	
	# Add initial progress bar line
	update_scrollback("[                    ] 0%") # 20 spaces
	#process_info.text = "[                    ] 0%"
	
	var duration = 0.1 # total time in seconds
	var steps = 20
	var interval = duration / steps
	running_process = true
	while running_process:
		for i in range(1, steps + 1):
			await get_tree().create_timer(interval).timeout
			var filled = "=".repeat(i)
			var empty = " ".repeat(steps - i)
			var percent = int(float(i) / steps * 100)
			update_last_line("[%s>%s] %d%%" % [filled, empty, percent])
			#process_info.text = "[%s>%s] %d%%" % [filled, empty, percent]

		# Process complete
		#update_last_line("[====================] 100% [color=#4caf50]Process complete! Gained: 10 data[/color]")
		update_scrollback("[color=#4caf50]Process complete +10 data[/color]")

func update_scrollback(text: String):
	scrollback_history.append(text)
	scrollback.text += text + "\n"

func update_last_line(text):
	scrollback_history[-1] = text
	scrollback.text = ""
	
	for item in scrollback_history:
		scrollback.text += item + "\n"

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_UP:
			navigate_history(-1)
		elif event.keycode == Key.KEY_DOWN:
			navigate_history(1)
		elif event.keycode == KEY_C and event.is_command_or_control_pressed():
			if running_process:
				cancel_process()

func cancel_process():
	if running_process:
		input_line.placeholder_text = "type a command, type -h for help"
		var process_info = current_process.stop_process()
		update_scrollback(process_info)
		running_process = false
		current_process = null

func navigate_history(delta: int):
	if command_history.size() == 0:
		return
	
	if history_index == -1:
		history_index = command_history.size()
	
	history_index = clamp(history_index + delta, 0, command_history.size() - 1)
	
	input_line.text = command_history[history_index]

	call_deferred("_move_caret_to_end")

func _move_caret_to_end():
	input_line.caret_column = input_line.text.length()

func _on_input_line_editing_toggled(toggled_on):
	if toggled_on:
		input_line.grab_focus()

func dark_web_login():
	input_line.clear()
	ContextCommands.current_context = ContextCommands.TerminalContext.DARKWEB
	
	update_scrollback("Authing into dark web...")
	
	await get_tree().create_timer(0.8).timeout
	update_scrollback("[ .. ] requesting permissions")
	await get_tree().create_timer(0.8).timeout
	update_scrollback("[ OK ] permission granted")
	await get_tree().create_timer(0.5).timeout
	update_scrollback("Access granted to dark web shop")
