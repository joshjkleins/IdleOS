extends Node

#TODO
#LIMIT PREVIOUSLY COMPLETED TUTORIAL EVENTS (SHOULD ONLY SHOW A FEW INSTEAD OF MASSIVE LIST)
#DONT SHOW CURRENT TUTORIAL OBJECTIVE IN 'NEXT' SECTION

enum TutorialEvent {
	# Basic terminal
	RUN_HELP_COMMAND,
	NAVIGATE_MINING,
	RUN_MINING_LOG,

	# Mining
	INFO_COMMAND,
	INFO_MINING_COMMAND,
	USE_FOCUS,
	USE_STICKY,
	LIST_ITEMS,
	LIST_LOG_DETAILS,
	MINE_25_LOGS,
	USE_UNSTICKY,
	STOP_MINING_PROCESS,

	# Parsing
	NAVIGATE_PARSING,
	PARSE_25_LOGS,
	OBTAIN_5_ENCRYPTED_PASSWORDS,
	OBTAIN_5_USERNAMES,
	OBTAIN_5_IP_ADDRESSES,
	# Cracking
	CRACK_5_PASSWORDS,

	# Matching
	MATCH_5_CREDENTIALS,

	# Phishing
	PHISH_SPEAR_INFO, ####<-------TEST
	PHISH_15_SQL_INJECTORS,
	PHISH_5_PACKET_SPOOFS,

	# Compiling
	COMPILE_5_SCHOOL_PAYLOADS,

	# Hacking
	NAVIGATE_HACKING,
	HACK_STUDENT,

	# Decoding
	DECODE_1_STUDENT_CACHE,

	# Upgrades
	UPGRADE_MINING_SPEED_WITH_APT,

	# Advanced
	RUN_VM_WITH_SSH,
}

var tutorial_tasks := {
	TutorialEvent.RUN_HELP_COMMAND: "Type '-h' to see the available commands.",
	TutorialEvent.NAVIGATE_MINING: "Navigate to the Mining skill with 'cd mining'.",
	TutorialEvent.RUN_MINING_LOG: "Run the mining logs process with 'mine -logs'.",
	
	TutorialEvent.INFO_COMMAND: "Use 'info' to view the list of skills.",
	TutorialEvent.INFO_MINING_COMMAND: "Use 'info mining' to view specific Mining info.",
	TutorialEvent.USE_FOCUS: "Use 'focus' to bring the active process to the bottom.",
	TutorialEvent.USE_STICKY: "Use 'sticky' to pin the mining process.",
	TutorialEvent.LIST_ITEMS: "Use 'ls' to see a list your items.",
	TutorialEvent.LIST_LOG_DETAILS: "Use 'ls logs' to view information about your logs. Additional details for any item can be seen with 'ls <item name>'.",
	
	TutorialEvent.MINE_25_LOGS: "Mine 25 logs.",
	TutorialEvent.USE_UNSTICKY: "Use 'unsticky' to unpin the mining process.",
	TutorialEvent.STOP_MINING_PROCESS: "Stop the mining process with 'kill' or 'stop'.",

	TutorialEvent.NAVIGATE_PARSING: "Navigate to the Parsing skill. First return to the root directory with 'cd ..' then to the Parsing skill with 'cd parsing'",
	TutorialEvent.PARSE_25_LOGS: "Parse 25 logs.",
	TutorialEvent.OBTAIN_5_ENCRYPTED_PASSWORDS: "Obtain 5 encrypted passwords from parsing logs.",
	TutorialEvent.OBTAIN_5_USERNAMES: "Obtain 5 usernames from Parsing logs.",
	TutorialEvent.OBTAIN_5_IP_ADDRESSES: "Obtain 5 IP Addresses from Parsing logs.",

	TutorialEvent.CRACK_5_PASSWORDS: "Navigate to and use the Cracking skill to crack 5 encrypted passwords.",
	
	TutorialEvent.MATCH_5_CREDENTIALS: "Navigate to and use the Matching skill to match 5 credentials.",

	TutorialEvent.PHISH_SPEAR_INFO: "Use 'info phishing spear' to view what can be obtained from spear phishing",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "Navigate to and use the Phishing skill to phish for 15 SQL injectors.",
	TutorialEvent.PHISH_5_PACKET_SPOOFS: "Navigate to and use the Phishing skill to phish for 5 packet spoofs.",

	TutorialEvent.COMPILE_5_SCHOOL_PAYLOADS: "Navigate to and use the Compiling skill to compile 5 school payloads.",

	TutorialEvent.NAVIGATE_HACKING: "Navigate to the Hacking terminal.",
	TutorialEvent.HACK_STUDENT: "Successfully hack a student and obtain a Student Cache.",

	TutorialEvent.DECODE_1_STUDENT_CACHE: "Decode 1 student cache.",

	TutorialEvent.UPGRADE_MINING_SPEED_WITH_APT: "Upgrade the Mining skill with 'apt'.",

	TutorialEvent.RUN_VM_WITH_SSH: "Run a VM window with SSH commands. Required a VM Token. For more info on ssh commands use 'ssh'.",
}

var tutorial_progress: Dictionary = {}
var completed_events: Array[TutorialEvent] = []

#### TRACK TUTORIAL EVENTS THAT REQUIRE MULTIPLE OF AN ITEM ####
#Tutorial.track_event(Tutorial.TutorialEvent.MINE_10_LOGS, reward_quantity_gained)
func track_event(event: TutorialEvent, amount: int = 1) -> void:
	if completed_events.has(event):
		return

	tutorial_progress[event] = tutorial_progress.get(event, 0) + amount

	if tutorial_progress[event] >= get_event_requirement(event):
		complete_event(event)

####TESTING VERSION, REAL ONE BELOW
#func get_event_requirement(event: TutorialEvent) -> int:
	#match event:
		#TutorialEvent.MINE_25_LOGS:
			#return 5
		#TutorialEvent.PARSE_25_LOGS:
			#return 5
		#TutorialEvent.OBTAIN_5_ENCRYPTED_PASSWORDS:
			#return 1
		#TutorialEvent.CRACK_5_PASSWORDS:
			#return 1
		#TutorialEvent.OBTAIN_5_USERNAMES:
			#return 1
		#TutorialEvent.MATCH_5_CREDENTIALS:
			#return 1
		#TutorialEvent.PHISH_15_SQL_INJECTORS:
			#return 3
		#TutorialEvent.PHISH_5_PACKET_SPOOFS:
			#return 5
		#TutorialEvent.COMPILE_5_SCHOOL_PAYLOADS:
			#return 5
		#TutorialEvent.DECODE_1_STUDENT_CACHE:
			#return 1
		#_:
			#return 1

##### REAL ONE
func get_event_requirement(event: TutorialEvent) -> int:
	match event:
		TutorialEvent.MINE_25_LOGS:
			return 25
		TutorialEvent.PARSE_25_LOGS:
			return 25
		TutorialEvent.OBTAIN_5_ENCRYPTED_PASSWORDS:
			return 5
		TutorialEvent.CRACK_5_PASSWORDS:
			return 5
		TutorialEvent.OBTAIN_5_USERNAMES:
			return 5
		TutorialEvent.MATCH_5_CREDENTIALS:
			return 5
		TutorialEvent.PHISH_15_SQL_INJECTORS:
			return 15
		TutorialEvent.PHISH_5_PACKET_SPOOFS:
			return 5
		TutorialEvent.COMPILE_5_SCHOOL_PAYLOADS:
			return 5
		_:
			return 1

### TRACK ONE SHOT TUTORIAL EVENTS ###
#Tutorial.complete_event(Tutorial.TutorialEvent.USE_FOCUS) <- how to complete tutorial events
func complete_event(event: TutorialEvent) -> void:
	if completed_events.has(event):
		return
	
	if not tutorial_tasks.has(event):
		return
	
	completed_events.append(event)
	
	var completed_task: String = tutorial_tasks[event]
	var message := ""
	
	if is_tutorial_complete():
		message = "[color=green]════════════════════════════════[/color]\n"
		message += "[color=green]TUTORIAL COMPLETE[/color]\n"
		message += "[color=gray]All objectives completed.[/color]\n"
		message += "[color=green]════════════════════════════════[/color]"
	else:
		var next_task := get_current_task()
		
		message = "[color=green]OBJECTIVE COMPLETE[/color]\n"
		message += "[color=gray]%s[/color]\n\n" % completed_task
		message += "[color=yellow]NEXT OBJECTIVE[/color]\n"
		message += next_task
		message += "\n\n[color=gray]Progress: %d/%d[/color]\n[color=#666666]hint: use 'tutorial' to view tutorial checklist at any time.[/color]\n" % [
			completed_events.size(),
			tutorial_tasks.size()
		]
	
	Signals.tutorial_event_completed(message)

func is_tutorial_complete() -> bool:
	return completed_events.size() >= tutorial_tasks.size()

func get_tutorial_progress_string() -> String:
	return "%d/%d tasks complete" % [
		completed_events.size(),
		tutorial_tasks.size()
	]

func get_completed_tasks() -> Array[String]:
	var tasks: Array[String] = []
	for event in completed_events:
		if tutorial_tasks.has(event):
			tasks.append(tutorial_tasks[event])
	if tasks.size() > 5:
		tasks = tasks.slice(tasks.size() - 5, tasks.size())
	return tasks

func get_current_task() -> String:
	for event in TutorialEvent.values():
		if tutorial_tasks.has(event) and not completed_events.has(event):
			return tutorial_tasks[event]
	return "Tutorial complete!"

func get_next_tasks(num_of_tasks: int) -> Array[String]:
	var tasks: Array[String] = []
	if num_of_tasks <= 0:
		return tasks
	var skipped_current := false
	for event in TutorialEvent.values():
		if not tutorial_tasks.has(event):
			continue
		if completed_events.has(event):
			continue
		if not skipped_current:
			skipped_current = true
			continue
		tasks.append(tutorial_tasks[event])
		if tasks.size() >= num_of_tasks:
			break
	return tasks
