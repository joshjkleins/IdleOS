extends Node

var show_intro: bool = true
## TESTING: play the intro + boot on every launch (keeps the save). Turn off before release.
const DEV_ALWAYS_SHOW_INTRO := false

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
	
	#upload
	UPLOAD_PARENTS_CC,

	# Added Oct 2026 (uploads woven through the tutorial). Saves store these enum NUMBERS, so new events
	# only ever go at the END; the order players see is TUTORIAL_ORDER below.
	UPLOAD_INFO,
	PACKAGE_5_LOGS,
	UPLOAD_LOGS,
	UPLOAD_IP_ADDRESS,
	UPLOAD_PASSWORD,
	UPLOAD_CREDENTIAL,
	UPLOAD_SCHOOL_PAYLOAD,
}

## The order objectives are shown in (decoupled from the enum so saves stay valid).
## Counts are worked backwards so each section makes a few extra for its upload and the next skill
## still has enough: payloads 4 (3 hacks + 1 upload) <- credentials 5 <- passwords 6 / usernames 5,
## IP addresses 5 (4 payloads + 1 upload), encrypted passwords 6 <- parse 30 logs <- mine 35 (5 uploaded).
const TUTORIAL_ORDER = [
	TutorialEvent.RUN_HELP_COMMAND, TutorialEvent.NAVIGATE_MINING, TutorialEvent.RUN_MINING_LOG,
	TutorialEvent.INFO_COMMAND, TutorialEvent.INFO_MINING_COMMAND, TutorialEvent.USE_FOCUS, TutorialEvent.USE_STICKY,
	TutorialEvent.LIST_ITEMS, TutorialEvent.LIST_LOG_DETAILS, TutorialEvent.RUN_VM_WITH_SSH, TutorialEvent.MINE_20_LOGS, TutorialEvent.USE_UNSTICKY,
	TutorialEvent.STOP_MINING_PROCESS,
	TutorialEvent.UPLOAD_INFO, TutorialEvent.PACKAGE_5_LOGS, # UPLOAD_LOGS retired: 'upload logs 5' starts the upload
	TutorialEvent.NAVIGATE_PARSING, TutorialEvent.PARSE_20_LOGS, TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS,
	TutorialEvent.OBTAIN_3_USERNAMES, TutorialEvent.OBTAIN_3_IP_ADDRESSES, TutorialEvent.UPLOAD_IP_ADDRESS,
	TutorialEvent.CRACK_3_PASSWORDS, TutorialEvent.UPLOAD_PASSWORD,
	TutorialEvent.MATCH_3_CREDENTIALS, TutorialEvent.UPLOAD_CREDENTIAL,
	TutorialEvent.TRACK_SQL, TutorialEvent.PHISH_15_SQL_INJECTORS, # PHISH_SPEAR_INFO retired
	TutorialEvent.PHISH_1_PACKET_SPOOFS, TutorialEvent.UNTRACK_ITEMS,
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS, TutorialEvent.UPLOAD_SCHOOL_PAYLOAD,
	TutorialEvent.NAVIGATE_HACKING, TutorialEvent.HACK_STUDENT, TutorialEvent.DECODE_1_STUDENT_CACHE,
	TutorialEvent.UPLOAD_PARENTS_CC, TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT,
]

## Upload steps that finish once that item's upload is running (or has finished)
var UPLOAD_STEPS := {} # TutorialEvent -> ItemData, filled in _ready (Items is a later autoload)







var tutorial_tasks := {
	TutorialEvent.RUN_HELP_COMMAND: "This tutorial walks you through preparing and hacking your first target while you learn the terminal. Start by typing '-h' to see the available commands. If you're ever stuck, it's the quickest way to see your options.",
	TutorialEvent.NAVIGATE_MINING: "Navigate to the Mining skill with 'cd mining'. Navigating in the terminal always uses the command 'cd', which stands for Change Directory, followed by where you'd like to go. Tip: press Tab to auto-complete any command (type 'cd mi' and press Tab). Press it again to list the options.",
	TutorialEvent.RUN_MINING_LOG: "Each skill has processes you can run. The pattern to run a process is <singular skill name> -<process name>. Use the run command for the Logs process in Mining. 'mine -logs'",
	
	TutorialEvent.INFO_COMMAND: "Use 'info' to view the list of skills. These are all the places you can navigate to and run processes, as well as their current version and level.",
	TutorialEvent.INFO_MINING_COMMAND: "Use 'info mining' to view specific Mining info. This is the same information presented when entering that directory, in case you need to see relevant info from elsewhere.",
	TutorialEvent.USE_FOCUS: "Use 'focus' to bring the active process to the bottom. If you're unsure if you have a process running, you can look in the top right of the terminal next to the system temperature.",
	TutorialEvent.USE_STICKY: "Use 'sticky' to pin the mining process to the top to prevent it from going off screen.",
	TutorialEvent.LIST_ITEMS: "Use 'ls' to see a list of your items. 'ls' stands for 'list' and will show everything you have obtained so far.",
	TutorialEvent.LIST_LOG_DETAILS: "Use 'ls logs' to view information about your Logs item. Additional details for any item can be seen with 'ls <item name>', including where it's used, where it's obtained, drop rates, etc.",
	
	TutorialEvent.MINE_20_LOGS: "Mine 35 Logs: you'll parse 30 of them soon and upload the rest. While you wait, keep an eye on the system temperature in the side panel. Every process adds heat, and at 100°C your system overheats: everything slows to a crawl until it cools back below 80°C. It cools on its own over time.",
	TutorialEvent.USE_UNSTICKY: "Use 'unsticky' to unpin the mining process.",
	TutorialEvent.STOP_MINING_PROCESS: "Stop the mining process with 'kill' or 'stop'. You can add the '-s' flag to wait until the end of the current cycle to safely end and prevent wasting resources. [kill -s]",
	
	TutorialEvent.NAVIGATE_PARSING: "Head to Parsing. First go back to the root directory with 'cd ..', then into Parsing with 'cd parsing'.",
	TutorialEvent.PARSE_20_LOGS: "Use 'parse -footprint=logs' to Parse through 30 logs with the Footprint process. This process requires 1 Log per cycle. It can also be used to transform Caches to different variants. If you ever need more information on a process use the 'INFO COMMAND' for more details and examples. Here's a Parsing VM token: 'ssh parsing footprint=logs' runs a second parser in its own window.",
	TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS: "Use the Footprint process to parse through logs and obtain 6 encrypted passwords.",
	TutorialEvent.OBTAIN_3_USERNAMES: "Use the Footprint process to parse through logs and obtain 5 usernames.",
	TutorialEvent.OBTAIN_3_IP_ADDRESSES: "Use the Footprint process to parse through logs and obtain 5 IP addresses.",
	
	TutorialEvent.CRACK_3_PASSWORDS: "[color=#33ff33]export PATH=/usr/local/bin:$PATH[/color]  IdleOS has added its skills to your $PATH, so they now run from any directory. Crack 6 encrypted passwords into usable passwords with 'crack -password', right here, no 'cd' needed. ('cd ../cracking' still takes you to Cracking's processes and info.) Here's a Cracking VM token as well: 'ssh cracking password'.",
	
	TutorialEvent.MATCH_3_CREDENTIALS: "Use the Matching skill to match 5 credentials: 'match -cred', from any directory. Matching takes 2 items and combines them. Matching a Username and Password gives you a credential used to build a payload for hacking. Here's a Matching VM token: 'ssh matching credential'.",
	
	TutorialEvent.PHISH_SPEAR_INFO: "Phishing can be used to obtain powerful Hacking items. Use 'info phishing spear' to view what can be obtained from spear phishing.",
	TutorialEvent.TRACK_SQL: "Next up is Phishing, which catches Hacking items like SQL Injectors. Track how many 'SQL Injectors' you have with the 'track' command. Hint: 'track <item name>'. This keeps a live count in the side panel, under the system temperature.",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "Use Phishing's Spear process to phish for 10 SQL Injectors: 'phish -spear'. Learn more about SQL Injectors with 'ls sql injectors'. Here's a Phishing VM token: 'ssh phishing spear'.",
	TutorialEvent.PHISH_1_PACKET_SPOOFS: "In Phishing, use the Spear skill to phish for 1 Packet Spoof. Learn more about Packet Spoofs with 'ls packet spoof'.",
	TutorialEvent.UNTRACK_ITEMS: "Remove the tracking for your SQL Injectors using 'untrack sql injectors'. If you're tracking multiple items you want removed, you can remove them all with the '-a' flag. Ex. untrack -a",
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: "Use the Compiling skill to compile 4 school payloads: 'compile -school'. Payloads require a Credential and IP Address and are required to attempt hacking. Here's a Compiling VM token: 'ssh compiling school'.",
	
	TutorialEvent.NAVIGATE_HACKING: "Navigate to the Hacking skill.",
	TutorialEvent.HACK_STUDENT: "Successfully hack a student and obtain a Student Cache.",
	
	TutorialEvent.DECODE_1_STUDENT_CACHE: "Return to the main terminal ('cd ..' until you're back at the root) and decode 1 Student Cache: 'decode -cache'. Here's a Decoding VM token for later caches: 'ssh decoding cache'.",
	
	TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: "Install your first Mining upgrade. 'apt mining' lists the upgrades you can install right now, then 'apt install <package>' installs one (ex. 'apt install mining.speed'). Upgrades are paid in the skill's own resources: Mining's in Logs, so mine a few more if you're short.",
	
	TutorialEvent.RUN_VM_WITH_SSH: "You earn a VM token every time a skill levels up, and here's one to start. A VM token runs a process in its own window, alongside your main terminal. Use it to mine faster: 'ssh mining logs'. ('ssh' lists every VM command.)",
	
	TutorialEvent.UPLOAD_PARENTS_CC: "Upload a Parents Credit Card straight from your inventory: 'upload parents credit card 1'. Type 'upload' to see the full upload goal.",

	TutorialEvent.UPLOAD_INFO: "Uploading is how you earn access to new places. Each location has an upload goal: some of every resource you make there. Type 'upload' to see the School's goal (it's also the UPLOADS list in the side panel).",
	TutorialEvent.PACKAGE_5_LOGS: "Upload exactly 5 Logs: 'upload logs 5'. They leave your inventory and upload in the background, one at a time; watch them in the UPLOADS list in the side panel. During the tutorial, always add the amount so you keep enough for the next steps. ('upload cancel logs' returns anything still queued.)",
	TutorialEvent.UPLOAD_LOGS: "Your Logs are uploading. Watch them in the UPLOADS list in the side panel.",
	TutorialEvent.UPLOAD_IP_ADDRESS: "Every skill's output counts toward the goal. Upload 1 IP Address: 'upload ip address 1'.",
	TutorialEvent.UPLOAD_PASSWORD: "Upload 1 Password: 'upload passwords 1'. The rest go to Matching.",
	TutorialEvent.UPLOAD_CREDENTIAL: "Upload 1 Credential: 'upload credentials 1'.",
	TutorialEvent.UPLOAD_SCHOOL_PAYLOAD: "Upload 1 School Payload: 'upload school payload 1'. Keep the other 3 for hacking.",
}

signal step_completed(event) # a step finished (the tutorial window moves to the next page)
signal progress_changed       # a counted step moved (e.g. 3/5 logs)
signal tutorial_reset         # 'tutorial reset'
var window_folded := false    # tutorial window folded to its title bar
var window_closed := false    # tutorial window hidden ('tutorial' reopens it)
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
	progress_changed.emit()
	SaveManager.mark_dirty()

func get_event_requirement(event: TutorialEvent) -> int:
	match event:
		TutorialEvent.MINE_20_LOGS:
			return 35
		TutorialEvent.PARSE_20_LOGS:
			return 30
		TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS:
			return 6
		TutorialEvent.CRACK_3_PASSWORDS:
			return 6
		TutorialEvent.OBTAIN_3_USERNAMES:
			return 5
		TutorialEvent.OBTAIN_3_IP_ADDRESSES:
			return 5
		TutorialEvent.MATCH_3_CREDENTIALS:
			return 5
		TutorialEvent.PACKAGE_5_LOGS:
			return 5
		TutorialEvent.PHISH_15_SQL_INJECTORS:
			return 10
		TutorialEvent.PHISH_1_PACKET_SPOOFS:
			return 1
		TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS:
			return 4
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
	# the VM step comes right after 'ls logs': make sure there's a token to use
	if event == TutorialEvent.LIST_LOG_DETAILS and !completed_events.has(TutorialEvent.RUN_VM_WITH_SSH) and Inventory.get_amount(Items.VM_MINING_TOKEN) < 1:
		Inventory.add_resource(Items.VM_MINING_TOKEN, 1)
	_grant_step_token()
	
	var completed_task: String = tutorial_tasks[event]
	var message := ""
	
	if is_tutorial_complete():
		message = "[color=green]════════════════════════════════[/color]\n"
		message += "[color=green]TUTORIAL COMPLETE[/color]\n"
		message += "[color=gray]All objectives completed.[/color]\n"
		message += "[color=green]════════════════════════════════[/color]\n\n"
		
		message += "Congrats on completing the tutorial!\n"
		message += "\nFrom here, you're on your own. Finish the School upload goal ('upload'): unlock the Administrator in Hacking ('unlock'), keep the hacks going and keep upgrading this OS. Then see if you can take down the Student (Hard).\n[color=#33ff33]Do not let us down.[/color]" # DEMO
		message += "\n\nFor help on what to do next, use the 'flow' command to see a flow chart of the steps, and check the AVAILABLE TO RUN section in the side panel. Remember, hacking is the most efficient way to progress."
		message += "\n\nThoughts or ideas? Come hang out in the Discord: https://discord.gg/XnrH7zrdb  ('discord -c' copies it)"
	else:
		var next_task := get_current_task()
		
		message = "[color=green]OBJECTIVE COMPLETE[/color]\n"
		message += "[color=gray]%s[/color]\n\n" % completed_task
		message += "[color=yellow]NEXT OBJECTIVE[/color]\n"
		message += next_task
		message += "\n\n[color=gray]Progress: %d/%d[/color]\n[color=#666666]hint: use 'tutorial' to view tutorial checklist at any time.[/color]\n" % [
			steps_done(),
			steps().size()
		]
	
	step_completed.emit(event)
	Signals.tutorial_event_completed(message)
	SaveManager.mark_dirty()

## Each process the tutorial introduces comes with 1 VM token of its skill, given when its step comes up
## (once per save; the step text points at the ssh command).
var token_steps_granted: Array = []
func _token_steps() -> Dictionary:
	return {
		TutorialEvent.PARSE_20_LOGS: Items.VM_PARSING_TOKEN,
		TutorialEvent.CRACK_3_PASSWORDS: Items.VM_CRACKING_TOKEN,
		TutorialEvent.MATCH_3_CREDENTIALS: Items.VM_MATCHING_TOKEN,
		TutorialEvent.PHISH_15_SQL_INJECTORS: Items.VM_PHISHING_TOKEN,
		TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: Items.VM_COMPILING_TOKEN,
		TutorialEvent.DECODE_1_STUDENT_CACHE: Items.VM_DECODING_TOKEN,
	}

func _grant_step_token() -> void:
	var cur = -1
	for e in TUTORIAL_ORDER:
		if tutorial_tasks.has(e) and !completed_events.has(e):
			cur = e
			break
	var steps_map = _token_steps()
	if cur in steps_map and !(int(cur) in token_steps_granted):
		token_steps_granted.append(int(cur))
		Inventory.add_resource(steps_map[cur], 1)

## Short page titles (the enum names kept old counts)
const STEP_TITLES = {
	TutorialEvent.MINE_20_LOGS: "Mine 35 logs",
	TutorialEvent.PARSE_20_LOGS: "Parse 30 logs",
	TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS: "Obtain 6 encrypted passwords",
	TutorialEvent.OBTAIN_3_USERNAMES: "Obtain 5 usernames",
	TutorialEvent.OBTAIN_3_IP_ADDRESSES: "Obtain 5 IP addresses",
	TutorialEvent.CRACK_3_PASSWORDS: "Crack 6 passwords",
	TutorialEvent.MATCH_3_CREDENTIALS: "Match 5 credentials",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "Phish 10 SQL injectors",
	TutorialEvent.PHISH_1_PACKET_SPOOFS: "Phish 1 packet spoof",
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: "Compile 4 school payloads",
	TutorialEvent.PACKAGE_5_LOGS: "Upload 5 logs",
	TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: "Install a Mining upgrade",
	TutorialEvent.RUN_VM_WITH_SSH: "Run a VM with ssh",
	TutorialEvent.UPLOAD_INFO: "Check the upload goal",
	TutorialEvent.UPLOAD_PARENTS_CC: "Upload a parents credit card",
}
func step_title(e) -> String:
	if STEP_TITLES.has(e):
		return STEP_TITLES[e]
	var t = str(TutorialEvent.keys()[e]).to_lower().replace("_", " ")
	return t[0].to_upper() + t.substr(1)

func test_tutorial_complete():
	#var completed_task: String = tutorial_tasks[event]
	var message := ""
	
	if is_tutorial_complete():
		message = "[color=green]════════════════════════════════[/color]\n"
		message += "[color=green]TUTORIAL COMPLETE[/color]\n"
		message += "[color=gray]All objectives completed.[/color]\n"
		message += "[color=green]════════════════════════════════[/color]\n\n"
		
		message += "Congrats on completing the tutorial!\n"
		message += "\nFrom here, you're on your own. Explore more processes, upgrade to better versions, complete the School uploads ('upload'), and try your hand at the Student (Hard)."
		message += "\n\nThoughts or ideas? Come hang out in the Discord: https://discord.gg/XnrH7zrdb  ('discord -c' copies it)"
	else:
		var next_task := get_current_task()
		
		message = "[color=green]OBJECTIVE COMPLETE[/color]\n"
		message += "[color=gray]%s[/color]\n\n" % "Finished wooo"
		message += "[color=yellow]NEXT OBJECTIVE[/color]\n"
		message += next_task
		message += "\n\n[color=gray]Progress: %d/%d[/color]\n[color=#666666]hint: use 'tutorial' to view tutorial checklist at any time.[/color]\n" % [
			completed_events.size(),
			tutorial_tasks.size()
		]
	
	Signals.tutorial_event_completed(message)

## The steps players see (TUTORIAL_ORDER), and how many are done
func steps() -> Array:
	return TUTORIAL_ORDER.filter(func(e): return tutorial_tasks.has(e))

func steps_done() -> int:
	return steps().filter(func(e): return completed_events.has(e)).size()

func is_tutorial_complete() -> bool:
	return steps_done() >= steps().size()

func get_tutorial_progress_string() -> String:
	return "%d/%d tasks complete" % [steps_done(), steps().size()]

func get_completed_tasks(num_of_tasks: int = 5) -> Array[String]:
	var tasks: Array[String] = []
	for event in completed_events:
		if tutorial_tasks.has(event):
			tasks.append(tutorial_tasks[event])
	if tasks.size() > num_of_tasks:
		tasks = tasks.slice(tasks.size() - num_of_tasks, tasks.size())
	return tasks

func get_current_task() -> String:
	for event in TUTORIAL_ORDER:
		if tutorial_tasks.has(event) and not completed_events.has(event):
			return tutorial_tasks[event]
	return "Tutorial complete!"

func get_next_tasks(num_of_tasks: int) -> Array[String]:
	var tasks: Array[String] = []
	if num_of_tasks <= 0:
		return tasks
	var skipped_current := false
	for event in TUTORIAL_ORDER:
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
		"completed_events": completed_out,
		"show_intro": show_intro,
		"upload_baseline": upload_baseline,
		"window_folded": window_folded,
		"window_closed": window_closed,
		"token_steps_granted": token_steps_granted,
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
	
	show_intro = data.get("show_intro", true)
	upload_baseline = data.get("upload_baseline", {})
	window_folded = bool(data.get("window_folded", false))
	window_closed = bool(data.get("window_closed", false))
	token_steps_granted = Array(data.get("token_steps_granted", [])).map(func(x): return int(x))
	if SaveManager.loaded_version < 2: # only saves from before the upload steps existed
		_complete_skipped_new_steps()

## Saves from before the upload steps existed: a new step that sits before something the player already
## finished is marked done silently (they're past it), so returning players aren't sent back.
func _complete_skipped_new_steps() -> void:
	var furthest := -1
	for i in TUTORIAL_ORDER.size():
		var e = TUTORIAL_ORDER[i]
		if e <= TutorialEvent.UPLOAD_PARENTS_CC and completed_events.has(e):
			furthest = i
	for i in range(0, furthest):
		var e = TUTORIAL_ORDER[i]
		if e > TutorialEvent.UPLOAD_PARENTS_CC and !completed_events.has(e):
			completed_events.append(e)

## Uploaded counts when 'tutorial reset' ran (item name -> amount), so earlier uploads don't tick the upload steps
var upload_baseline: Dictionary = {}

## Returning players: old saves (version < 2) with tutorial progress get a one-time note on load.
func should_show_old_save_notice() -> bool:
	return SaveManager.loaded_version < 3 and !completed_events.is_empty() # DEMO: saves from the Oct demos

func old_save_notice() -> String:
	var m := "[color=yellow]WELCOME BACK[/color]\n"
	m += "Your save is from an earlier version of the demo. Items now upload straight from your inventory ('upload <item> [amount]', no more packaging), targets unlock in Hacking ('unlock'), and the tutorial has its own window.\n" # DEMO
	m += "Want a refresher? Type 'tutorial reset' to restart the tutorial. [color=#666666]Your items, levels and upgrades stay as they are.[/color]"
	return m

## 'tutorial reset': clears the checklist only. Steps this save can't redo (Mining upgrades maxed, an item's
## upload goal already covered) are checked off so the player can't get stuck. Returns how many were skipped.
func reset_tutorial() -> int:
	completed_events.clear()
	tutorial_progress.clear()
	upload_baseline.clear()
	for e in UPLOAD_STEPS:
		var item: ItemData = UPLOAD_STEPS[e]
		upload_baseline[item.name] = Uploads.get_uploaded(item)
	var skip: Array = []
	var mining_left := false
	for p in Upgrades.group_packages("Mining"):
		if !Upgrades.is_at_max_level(p.id):
			mining_left = true
	if !mining_left:
		skip.append(TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT)
	if !Uploads.is_goal_item(Items.LOGS) or Uploads.get_still_needed(Items.LOGS) < get_event_requirement(TutorialEvent.PACKAGE_5_LOGS):
		skip.append(TutorialEvent.PACKAGE_5_LOGS)
	for e in UPLOAD_STEPS:
		var item: ItemData = UPLOAD_STEPS[e]
		if !Uploads.is_goal_item(item) or (Uploads.get_still_needed(item) <= 0 and Uploads.get_staged(item) <= 0):
			skip.append(e)
	if !Uploads.is_goal_item(Items.PARENTS_CREDIT_CARD) or Uploads.get_still_needed(Items.PARENTS_CREDIT_CARD) <= 0:
		skip.append(TutorialEvent.UPLOAD_PARENTS_CC)
	for e in skip:
		if !completed_events.has(e):
			completed_events.append(e)
	if completed_events.has(TutorialEvent.PACKAGE_5_LOGS) and !completed_events.has(TutorialEvent.UPLOAD_LOGS):
		completed_events.append(TutorialEvent.UPLOAD_LOGS) # retired step
	window_closed = false
	token_steps_granted.clear()
	_grant_step_token()
	tutorial_reset.emit()
	SaveManager.mark_dirty()
	return skip.size()

func reset_message(skipped: int) -> String:
	var m := "[color=green]TUTORIAL RESTARTED[/color]\n"
	m += "[color=gray]Checklist cleared. Items, levels and upgrades are untouched.[/color]\n"
	if skipped > 0:
		m += "[color=#666666]%d step%s your save can't redo (already maxed or uploaded) %s checked off.[/color]\n" % [skipped, "" if skipped == 1 else "s", "was" if skipped == 1 else "were"]
	m += "\n[color=yellow]OBJECTIVE[/color]\n" + get_current_task()
	return m

## Upload hooks: 'upload' status, uploaded Logs, and each upload step once its item is uploading.
func _on_uploads_changed() -> void:
	for e in UPLOAD_STEPS:
		var item = UPLOAD_STEPS[e]
		if !completed_events.has(e) and (Uploads.is_uploading(item) or Uploads.get_uploaded(item) > int(upload_baseline.get(item.name, 0))):
			complete_event(e)

func on_items_packaged(item: ItemData, amount: int) -> void:
	if item == Items.LOGS:
		if !completed_events.has(TutorialEvent.UPLOAD_LOGS):
			completed_events.append(TutorialEvent.UPLOAD_LOGS) # retired step: 'upload logs 5' already starts it
		track_event(TutorialEvent.PACKAGE_5_LOGS, amount)


func _ready():
	(func(): Uploads.item_uploaded.connect(_on_item_uploaded)).call_deferred() # Uploads loads after Tutorial
	(func():
		UPLOAD_STEPS = {
			TutorialEvent.UPLOAD_LOGS: Items.LOGS,
			TutorialEvent.UPLOAD_IP_ADDRESS: Items.IP_ADDRESS,
			TutorialEvent.UPLOAD_PASSWORD: Items.PASSWORDS,
			TutorialEvent.UPLOAD_CREDENTIAL: Items.CREDENTIALS,
			TutorialEvent.UPLOAD_SCHOOL_PAYLOAD: Items.SCHOOL_PAYLOAD,
		}
		Uploads.changed.connect(_on_uploads_changed)).call_deferred()


## Tutorial's last step: first Parents Credit Card uploaded through the Uploads system.
func _on_item_uploaded(item: ItemData) -> void:
	if item == Items.PARENTS_CREDIT_CARD:
		complete_event(TutorialEvent.UPLOAD_PARENTS_CC)
