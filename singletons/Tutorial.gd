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
	MINE_20_LOGS,
	USE_UNSTICKY,
	STOP_MINING_PROCESS,

	# Parsing
	NAVIGATE_PARSING,
	PARSE_20_LOGS,
	OBTAIN_3_ENCRYPTED_PASSWORDS,
	OBTAIN_3_USERNAMES,
	OBTAIN_3_IP_ADDRESSES,
	# Cracking
	CRACK_3_PASSWORDS,

	# Matching
	MATCH_3_CREDENTIALS,

	# Phishing
	PHISH_SPEAR_INFO,
	TRACK_SQL,
	PHISH_15_SQL_INJECTORS,
	PHISH_1_PACKET_SPOOFS,
	UNTRACK_ITEMS,
	# Compiling
	COMPILE_3_SCHOOL_PAYLOADS,

	# Hacking
	NAVIGATE_HACKING,
	HACK_STUDENT,

	# Decoding
	DECODE_1_STUDENT_CACHE,

	# Upgrades
	UNLOCK_MINING_OVERCLOCK_WITH_APT,

	# Advanced
	RUN_VM_WITH_SSH,
}







var tutorial_tasks := {
	TutorialEvent.RUN_HELP_COMMAND: "Type '-h' to see the available commands. If you're ever stuck, this is a good way to see your current command options.",
	TutorialEvent.NAVIGATE_MINING: "Navigate to the Mining skill with 'cd mining'. Navigating in the terminal always uses the command 'cd', which stands for Change Directory, followed by where you'd like to go.",
	TutorialEvent.RUN_MINING_LOG: "Each skill has processes you can run. The pattern to run a process is <singular skill name> -<process name>. Run the mine logs process with 'mine -logs'.",
	
	TutorialEvent.INFO_COMMAND: "Use 'info' to view the list of skills. These are all the places you can navigate to and run processes, as well as their current version and level.",
	TutorialEvent.INFO_MINING_COMMAND: "Use 'info mining' to view specific Mining info. This is the same information presented when entering that directory, in case you need to see relevant info from elsewhere.",
	TutorialEvent.USE_FOCUS: "Use 'focus' to bring the active process to the bottom. If you're unsure if you have a process running, you can look in the top right of the terminal next to the system temperature.",
	TutorialEvent.USE_STICKY: "Use 'sticky' to pin the mining process to the top to prevent it from going off screen.",
	TutorialEvent.LIST_ITEMS: "Use 'ls' to see a list of your items. 'ls' stands for 'list' and will show everything you have obtained so far.",
	TutorialEvent.LIST_LOG_DETAILS: "Use 'ls logs' to view information about your Logs item. Additional details for any item can be seen with 'ls <item name>', including where it's used, where it's obtained, drop rates, etc.",
	
	TutorialEvent.MINE_20_LOGS: "Mine 20 logs.",
	TutorialEvent.USE_UNSTICKY: "Use 'unsticky' to unpin the mining process.",
	TutorialEvent.STOP_MINING_PROCESS: "Stop the mining process with 'kill' or 'stop'. You can add the '-s' flag to wait until the end of the current cycle to safely end and prevent wasting resources. [kill -s]",
	
	TutorialEvent.NAVIGATE_PARSING: "Navigate to the Parsing skill. First, return to the root directory with 'cd ..', then go to the Parsing skill with 'cd parsing'.",
	TutorialEvent.PARSE_20_LOGS: "Parse through 20 logs with the Footprint process. You can also view what items you get from this process with 'info <skill> <process>'. Ex. info parsing footprint",
	TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS: "Use the Footprint process to parse through logs and obtain 3 encrypted passwords.",
	TutorialEvent.OBTAIN_3_USERNAMES: "Use the Footprint process to parse through logs and obtain 3 usernames.",
	TutorialEvent.OBTAIN_3_IP_ADDRESSES: "Use the Footprint process to parse through logs and obtain 3 IP addresses.",
	
	TutorialEvent.CRACK_3_PASSWORDS: "Navigate to and use the Cracking skill to crack 3 encrypted passwords into usable passwords. Tip: You can navigate directly without having to go back to the root directory with 'cd ../cracking'.",
	
	TutorialEvent.MATCH_3_CREDENTIALS: "Navigate to and use the Matching skill to match 3 credentials. Matching takes 2 items and combines them. Matching a Username and Password gives you a credential used to build a payload for hacking.",
	
	TutorialEvent.PHISH_SPEAR_INFO: "Use 'info phishing spear' to view what can be obtained from spear phishing.",
	TutorialEvent.TRACK_SQL: "Track how many 'SQL Injectors' you have with the 'track' command. Hint: 'track <item name>'. This keeps a live count in the top right corner of the terminal, below the system temperature.",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "Navigate to Phishing and use the Spear skill to phish for 10 SQL Injectors. Learn more about SQL Injectors with 'ls sql injectors'.",
	TutorialEvent.PHISH_1_PACKET_SPOOFS: "In Phishing, use the Spear skill to phish for 1 Packet Spoof. Learn more about Packet Spoofs with 'ls packet spoof'.",
	TutorialEvent.UNTRACK_ITEMS: "Remove the tracking for your SQL Injectors using 'untrack sql injectors'. If you're tracking multiple items you want removed, you can remove them all with the '-a' flag. Ex. untrack -a",
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: "Navigate to and use the Compiling skill to compile 3 school payloads. Payloads require a Credential and IP Address and are required to attempt hacking.",
	
	TutorialEvent.NAVIGATE_HACKING: "Navigate to the Hacking skill.",
	TutorialEvent.HACK_STUDENT: "Successfully hack a student and obtain a Student Cache.",
	
	TutorialEvent.DECODE_1_STUDENT_CACHE: "Decode 1 Student Cache. To exit the Hacking skill use 'cd ..' until back to root.",
	
	TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: "Upgrade the Mining skill to unlock overclocking with 'apt'.",
	
	TutorialEvent.RUN_VM_WITH_SSH: "Run a VM window with SSH commands. Requires a VM Token. For more info on SSH commands, use 'ssh'.",
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
	SaveManager.mark_dirty()

func get_event_requirement(event: TutorialEvent) -> int:
	match event:
		TutorialEvent.MINE_20_LOGS:
			return 20
		TutorialEvent.PARSE_20_LOGS:
			return 20
		TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS:
			return 3
		TutorialEvent.CRACK_3_PASSWORDS:
			return 3
		TutorialEvent.OBTAIN_3_USERNAMES:
			return 3
		TutorialEvent.OBTAIN_3_IP_ADDRESSES:
			return 3
		TutorialEvent.MATCH_3_CREDENTIALS:
			return 3
		TutorialEvent.PHISH_15_SQL_INJECTORS:
			return 10
		TutorialEvent.PHISH_1_PACKET_SPOOFS:
			return 1
		TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS:
			return 3
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
		message += "[color=green]════════════════════════════════[/color]\n\n"
		
		message += "You have finished the full gameplay loop of IdleOS.\n"
		message += "\nFrom here, you're on your own. Explore more hacking targets, upgrade your processes, and see if you can become efficient enough to hack the Superintendent."
		message += "\n\nThanks for playing IdleOS! If you'd like to share your thoughts or join the community, come hang out in the Discord:"
		message += "\nhttps://discord.gg/XnrH7zrdb"
		message += "\n\nUse 'discord -c' to copy the Discord link."
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
	SaveManager.mark_dirty()

func is_tutorial_complete() -> bool:
	return completed_events.size() >= tutorial_tasks.size()

func get_tutorial_progress_string() -> String:
	return "%d/%d tasks complete" % [
		completed_events.size(),
		tutorial_tasks.size()
	]

func get_completed_tasks(num_of_tasks: int = 5) -> Array[String]:
	var tasks: Array[String] = []
	for event in completed_events:
		if tutorial_tasks.has(event):
			tasks.append(tutorial_tasks[event])
	if tasks.size() > num_of_tasks:
		tasks = tasks.slice(tasks.size() - num_of_tasks, tasks.size())
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


func save_data() -> Dictionary:
	var progress_out := {}
	for event in tutorial_progress:
		progress_out[str(event)] = tutorial_progress[event]

	var completed_out := []
	for event in completed_events:
		completed_out.append(int(event))

	return {
		"tutorial_progress": progress_out,
		"completed_events": completed_out
	}

func load_data(data: Dictionary) -> void:
	tutorial_progress.clear()
	var progress_in: Dictionary = data.get("tutorial_progress", {})
	for key in progress_in:
		tutorial_progress[int(key)] = int(progress_in[key])

	completed_events.clear()
	var completed_in: Array = data.get("completed_events", [])
	for v in completed_in:
		completed_events.append(int(v))
