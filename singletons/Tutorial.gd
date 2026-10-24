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
	# Added 2026-10-23 (hack-first tutorial)
	VIEW_SCHOOL,
	RETURN_TO_ROOT,
	EQUIP_FIRST_MOD,
	HACK_STUDENT_TWICE,
	DECODE_2_CACHES,
	UTILITY_COMMAND,
	NAVIGATE_CRACKING,
	START_CRACKING,
}

## The order objectives are shown in (decoupled from the enum so saves stay valid).
## Counts are worked backwards so each section makes a few extra for its upload and the next skill
## still has enough: payloads 4 (3 hacks + 1 upload) <- credentials 5 <- passwords 6 / usernames 5,
## IP addresses 5 (4 payloads + 1 upload), encrypted passwords 6 <- parse 30 logs <- mine 35 (5 uploaded).
## 2026-10-23: hack first. A starter kit (STARTER_KIT) pays for the first hack; its cache feeds the chain
## (parse -> crack -> match -> compile) that builds the next payloads; a mod, two more hacks, uploads, then
## phishing / mining / apt and the utility commands. Old steps not listed here are retired (kept in the enum).
const TUTORIAL_ORDER = [
	TutorialEvent.RUN_HELP_COMMAND, TutorialEvent.NAVIGATE_HACKING, TutorialEvent.VIEW_SCHOOL, TutorialEvent.HACK_STUDENT,
	TutorialEvent.RETURN_TO_ROOT, TutorialEvent.DECODE_1_STUDENT_CACHE, TutorialEvent.LIST_ITEMS,
	TutorialEvent.NAVIGATE_PARSING, TutorialEvent.PARSE_20_LOGS, TutorialEvent.NAVIGATE_CRACKING,
	TutorialEvent.START_CRACKING, TutorialEvent.CRACK_3_PASSWORDS, TutorialEvent.MATCH_3_CREDENTIALS,
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS, TutorialEvent.EQUIP_FIRST_MOD, TutorialEvent.HACK_STUDENT_TWICE,
	TutorialEvent.DECODE_2_CACHES, TutorialEvent.UPLOAD_INFO, TutorialEvent.PACKAGE_5_LOGS, TutorialEvent.UPLOAD_PARENTS_CC,
	TutorialEvent.PHISH_15_SQL_INJECTORS, TutorialEvent.RUN_MINING_LOG, TutorialEvent.MINE_20_LOGS,
	TutorialEvent.STOP_MINING_PROCESS, TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT, TutorialEvent.UTILITY_COMMAND,
]
## the order before 2026-10-23 (saves made then are migrated in load_data)
const OLD_ORDER_V2 = [
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

## the command(s) each step asks for, shown on their own line under the step text ("command to run")
const STEP_COMMANDS = {
	TutorialEvent.RUN_HELP_COMMAND: "-h",
	TutorialEvent.NAVIGATE_HACKING: "cd hacking",
	TutorialEvent.VIEW_SCHOOL: "view school",
	TutorialEvent.HACK_STUDENT: "hack student",
	TutorialEvent.RETURN_TO_ROOT: "cd root",
	TutorialEvent.DECODE_1_STUDENT_CACHE: "decode -cache",
	TutorialEvent.LIST_ITEMS: "ls",
	TutorialEvent.NAVIGATE_PARSING: "cd parsing",
	TutorialEvent.PARSE_20_LOGS: "parse -footprint=logs",
	TutorialEvent.NAVIGATE_CRACKING: "cd ..  ->  cd cracking",
	TutorialEvent.START_CRACKING: "kill  ->  crack -password",
	TutorialEvent.CRACK_3_PASSWORDS: "ssh  ->  ssh crack -password",
	TutorialEvent.MATCH_3_CREDENTIALS: "kill  ->  match -cred",
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: "kill  ->  compile -school",
	TutorialEvent.EQUIP_FIRST_MOD: "mod  ->  mod -add 0",
	TutorialEvent.HACK_STUDENT_TWICE: "cd root  ->  cd hacking  ->  view school  ->  hack student=2",
	TutorialEvent.DECODE_2_CACHES: "cd root  ->  decode -cache",
	TutorialEvent.UPLOAD_INFO: "upload",
	TutorialEvent.PACKAGE_5_LOGS: "upload logs 5",
	TutorialEvent.UPLOAD_PARENTS_CC: "upload parents credit card 1",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "phish -spear",
	TutorialEvent.RUN_MINING_LOG: "kill  ->  mine -logs",
	TutorialEvent.MINE_20_LOGS: "ssh mine -logs  (optional: a second miner)",
	TutorialEvent.STOP_MINING_PROCESS: "kill",
	TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: "apt mining  ->  apt install mining.speed  ->  y",
	TutorialEvent.UTILITY_COMMAND: "utility",
}

## Step text + its command line (tutorial window, terminal messages)
func task_text(e) -> String:
	var t: String = tutorial_tasks.get(e, "")
	if STEP_COMMANDS.has(e):
		var cmds = Array(str(STEP_COMMANDS[e]).split("->")).map(func(c): return c.strip_edges())
		if cmds.size() == 1:
			t += "\n\n[color=#888888]command to run:[/color]  [color=#4ec994]%s[/color]" % cmds[0]
		else: # several: one per line, in order
			t += "\n\n[color=#888888]commands to run, in order:[/color]"
			for c in cmds:
				t += "\n    [color=#4ec994]%s[/color]" % c
	return t

## The step the player is on (-1 when the tutorial is done)
func current_step() -> int:
	for e in TUTORIAL_ORDER:
		if tutorial_tasks.has(e) and !completed_events.has(e):
			return e
	return -1

## Steps that only count while they are the current step (so exploring early can't skip them)
const GATED_STEPS = [TutorialEvent.RETURN_TO_ROOT, TutorialEvent.DECODE_2_CACHES, TutorialEvent.STOP_MINING_PROCESS]

## Given once, when '-h' is done (step 2 introduces it): what the first hack costs
const STARTER_KIT = {"payload": 1, "sql": 35, "spoof": 3}
var kit_given := false
func _give_starter_kit() -> void:
	if kit_given:
		return
	kit_given = true
	Inventory.add_resource(Items.SCHOOL_PAYLOAD, STARTER_KIT.payload)
	Inventory.add_resource(Items.SQL_INJECTOR, STARTER_KIT.sql)
	Inventory.add_resource(Items.PACKET_SPOOF, STARTER_KIT.spoof)


## Upload steps that finish once that item's upload is running (or has finished)
var UPLOAD_STEPS := {} # TutorialEvent -> ItemData, filled in _ready (Items is a later autoload)







var tutorial_tasks := {
	TutorialEvent.RUN_HELP_COMMAND: "Welcome to the Idle Operating System. This tutorial will get you familiar with your new operating system and teach you how to use it to build up resources and successfully hack your targets. To get started, type '-h' in the command terminal to view the list of general commands. If you're ever unsure what to do next, type 'hint'.",
	TutorialEvent.NAVIGATE_MINING: "Navigate to the Mining skill with 'cd mining'. Navigating in the terminal always uses the command 'cd', which stands for Change Directory, followed by where you'd like to go. Tip: press Tab to auto-complete any command (type 'cd mi' and press Tab). Press it again to list the options.",
	TutorialEvent.RUN_MINING_LOG: "Caches won't always have the Logs you need, so you can make your own. Stop phishing and start mining.",
	
	TutorialEvent.INFO_COMMAND: "Use 'info' to view the list of skills. These are all the places you can navigate to and run processes, as well as their current version and level.",
	TutorialEvent.INFO_MINING_COMMAND: "Use 'info mining' to view specific Mining info. This is the same information presented when entering that directory, in case you need to see relevant info from elsewhere.",
	TutorialEvent.USE_FOCUS: "Use 'focus' to bring the active process to the bottom. If you're unsure if you have a process running, you can look in the top right of the terminal next to the system temperature.",
	TutorialEvent.USE_STICKY: "Use 'sticky' to pin the mining process to the top to prevent it from going off screen.",
	TutorialEvent.LIST_ITEMS: "List your items using the 'ls' command. This shows your current items. If you ever want more details on a specific item, use 'ls <item>' to get more info.",
	TutorialEvent.LIST_LOG_DETAILS: "Use 'ls logs' to view information about your Logs item. Additional details for any item can be seen with 'ls <item name>', including where it's used, where it's obtained, drop rates, etc.",
	
	TutorialEvent.MINE_20_LOGS: "Mine 15 Logs. Here's a Mining VM token to speed it up. You can only run 1 VM window for now, so close any other VM window first ('vm -h' lists the commands). Every process adds heat: if your system overheats, everything slows until it cools, so keep an eye on the temperature in the side panel.",
	TutorialEvent.USE_UNSTICKY: "Use 'unsticky' to unpin the mining process.",
	TutorialEvent.STOP_MINING_PROCESS: "Stop the mining process. ('kill -s' finishes the current cycle first so nothing is wasted.)",
	
	TutorialEvent.NAVIGATE_PARSING: "Each skill has its own directory in the terminal, with its processes and info. Navigate into Parsing. 'cd' stands for Change Directory, followed by where you'd like to go.",
	TutorialEvent.PARSE_20_LOGS: "Hacking that Student required a School Payload x1. You'll need to learn to build your own payloads to continue hacking your way through the School, and the cache you just decoded gave you the raw materials to do so. Parse through 10 of the Logs you received with the Footprint process for some necessary data to build your own payload. Parsing through Logs can net you Usernames, Encrypted Passwords and IP Addresses.",
	TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS: "Use the Footprint process to parse through logs and obtain 6 encrypted passwords.",
	TutorialEvent.OBTAIN_3_USERNAMES: "Use the Footprint process to parse through logs and obtain 5 usernames.",
	TutorialEvent.OBTAIN_3_IP_ADDRESSES: "Hacking that Student required a School Payload x1. You'll need to learn to build your own payloads to continue hacking your way through the School, and the cache you just decoded gave you the raw materials to do so. Parse through the Logs you received with the Footprint process for some necessary data to build your own payload. Parsing through Logs can net you Usernames, Encrypted Passwords and IP Addresses.",
	
	TutorialEvent.CRACK_3_PASSWORDS: "Processes can take some time, especially if you have a huge supply of Encrypted Passwords to crack. To speed things up, use Virtual Machines to run multiple processes at once. These require VM Tokens; here's a VM Cracking Token to try it out. Type 'ssh' to see how many VM tokens you have for each skill. To run any process in a VM, put 'ssh' in front of its normal command: here, 'ssh crack -password'. Crack 5 Passwords between the two.",
	
	TutorialEvent.MATCH_3_CREDENTIALS: "Having to navigate to each directory to run a skill can be tedious. Skills have now been added to your [color=#33ff33]$PATH[/color], which means they can be run from anywhere without navigating into their directory (excluding Hacking). So we can run the next step right here in our current directory. Match 3 Credentials using the 'match -cred' command (kill the cracking process first if it's still running).",
	
	TutorialEvent.PHISH_SPEAR_INFO: "Phishing can be used to obtain powerful Hacking items. Use 'info phishing spear' to view what can be obtained from spear phishing.",
	TutorialEvent.TRACK_SQL: "Next up is Phishing, which catches Hacking items like SQL Injectors. Track how many 'SQL Injectors' you have with the 'track' command. Hint: 'track <item name>'. This keeps a live count in the side panel, under the system temperature.",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "Every hack uses SQL Injectors, so phish for 10 more (stop any running process first). Here's a Phishing VM token as well: 'ssh phish -spear' runs a second phisher.",
	TutorialEvent.PHISH_1_PACKET_SPOOFS: "In Phishing, use the Spear skill to phish for 1 Packet Spoof. Learn more about Packet Spoofs with 'ls packet spoof'.",
	TutorialEvent.UNTRACK_ITEMS: "Remove the tracking for your SQL Injectors using 'untrack sql injectors'. If you're tracking multiple items you want removed, you can remove them all with the '-a' flag. Ex. untrack -a",
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: "Stop matching, then compile 2 School Payloads. Each one takes a Credential and an IP Address. These are what a hack costs.",
	
	TutorialEvent.NAVIGATE_HACKING: "You've been given a starter kit: 1 School Payload, 35 SQL Injectors and 3 Packet Spoofs. Everything you need for your first job. Head to the Hacking module. Tip: press Tab to auto-complete any command.",
	TutorialEvent.HACK_STUDENT: "Hack the Student. Your SQL Injectors attack on their own, chipping through the firewall and then the target's integrity. The Student fights back and drains your anonymity; Packet Spoofs restore it automatically below 30%. If anonymity hits 0 you're traced and the hack fails. Breach the Student to win their cache.",
	
	TutorialEvent.DECODE_1_STUDENT_CACHE: "Caches are where the big hauls come from. Decode your Student Cache and watch what spills out.",
	
	TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: "Install your first upgrade. 'apt mining' lists what you can install right now; then install Mining Speed and confirm with 'y'. Upgrades are paid in the skill's own resources: Mining's in Logs.",
	
	TutorialEvent.RUN_VM_WITH_SSH: "You earn a VM token every time a skill levels up, and here's one to start. A VM token runs a process in its own window, alongside your main terminal. Use it to mine faster: 'ssh mining logs'. ('ssh' lists every VM command.)",
	
	TutorialEvent.UPLOAD_PARENTS_CC: "Your rare find counts toward the goal too. Upload your Parents Credit Card. Remember to use Tab to auto-complete long commands.",

	TutorialEvent.UPLOAD_INFO: "Uploading is how you earn access to new places. Each location has an upload goal: some of everything you make there. Check the School's goal; it's also the UPLOADS list in the side panel.",
	TutorialEvent.PACKAGE_5_LOGS: "Upload 5 Logs. Uploads run in the background. Your resources have four jobs: building payloads for your next hacks, buying upgrades, filling the upload goal, and unlocking new targets ('unlock' in the hacking console). Adding an amount lets you decide how much goes where.",
	TutorialEvent.UPLOAD_LOGS: "Your Logs are uploading. Watch them in the UPLOADS list in the side panel.",
	TutorialEvent.UPLOAD_IP_ADDRESS: "Every skill's output counts toward the goal. Upload 1 IP Address: 'upload ip address 1'.",
	TutorialEvent.UPLOAD_PASSWORD: "Upload 1 Password: 'upload passwords 1'. The rest go to Matching.",
	TutorialEvent.UPLOAD_CREDENTIAL: "Upload 1 Credential: 'upload credentials 1'.",
	TutorialEvent.UPLOAD_SCHOOL_PAYLOAD: "Upload 1 School Payload: 'upload school payload 1'. Keep the other 3 for hacking.",
	TutorialEvent.VIEW_SCHOOL: "This is the hacking console. Every location has targets to breach. Look at the School's targets.",
	TutorialEvent.RETURN_TO_ROOT: "Nice work. Head back to the main terminal so we can see what this Cache contains. Use 'cd ..' to move up directories until you're back at the root, or 'cd root' to go directly to root.",
	TutorialEvent.EQUIP_FIRST_MOD: "The cache also held a Hacking Mod: a Handshake Exploit. Mods change how your hacks play, and each lasts a few hacks. List your mods, then equip it. Every equipped mod adds a little bandwidth to each attack, so you choose which ones are worth it.",
	TutorialEvent.HACK_STUDENT_TWICE: "Back to Hacking, and this time hack the Student twice in a row. Watch your first hit, and the first after each firewall reboot. Anonymity carries over between the hacks of a run, so keep an eye on it. (The Hacking module needs the main terminal free: 'kill' anything still running first.)",
	TutorialEvent.DECODE_2_CACHES: "Back at the main terminal, decode both new caches. 'decode -cache' works through them one at a time.",
	TutorialEvent.UTILITY_COMMAND: "One last thing: 'utility' lists the helper commands. Pin a process to the top of the terminal with 'pin', bring the active process back to the bottom with 'focus', keep a live count of an item with 'track', look anything up with 'info', and more. As your skills level up, new processes unlock in each one: keep an eye out for them.",
	TutorialEvent.NAVIGATE_CRACKING: "Next up is Cracking. Go back up to the root with 'cd ..', then into Cracking. (Parsing keeps running in the background while you move around.)",
	TutorialEvent.START_CRACKING: "This operating system can only run one process in the main terminal at a time, so kill the Parsing process if it's still running with 'kill'. Then run the Password Cracking process to turn your Encrypted Passwords into something usable.",
}

signal step_completed(event) # a step finished (the tutorial window moves to the next page)
signal progress_changed       # a counted step moved (e.g. 3/5 logs)
signal tutorial_reset         # 'tutorial reset'
var window_folded := false    # tutorial window folded to its title bar
var window_closed := false    # tutorial window hidden ('tutorial' reopens it)
var window_moved := false     # dragged by the player (double-click the title bar to dock it again)
var window_pos := Vector2.ZERO
var tutorial_progress: Dictionary = {}
var completed_events: Array[TutorialEvent] = []

#### TRACK TUTORIAL EVENTS THAT REQUIRE MULTIPLE OF AN ITEM ####
#Tutorial.track_event(Tutorial.TutorialEvent.MINE_10_LOGS, reward_quantity_gained)
func track_event(event: TutorialEvent, amount: int = 1) -> void:
	if completed_events.has(event):
		return
	if event in GATED_STEPS and current_step() != event:
		return

	tutorial_progress[event] = tutorial_progress.get(event, 0) + amount

	if tutorial_progress[event] >= get_event_requirement(event):
		complete_event(event)
	progress_changed.emit()
	SaveManager.mark_dirty()

func get_event_requirement(event: TutorialEvent) -> int:
	match event:
		TutorialEvent.MINE_20_LOGS:
			return 15
		TutorialEvent.PARSE_20_LOGS:
			return 10
		TutorialEvent.DECODE_2_CACHES:
			return 2
		TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS:
			return 6
		TutorialEvent.CRACK_3_PASSWORDS:
			return 5
		TutorialEvent.OBTAIN_3_USERNAMES:
			return 5
		TutorialEvent.OBTAIN_3_IP_ADDRESSES:
			return 3
		TutorialEvent.MATCH_3_CREDENTIALS:
			return 3
		TutorialEvent.PACKAGE_5_LOGS:
			return 5
		TutorialEvent.PHISH_15_SQL_INJECTORS:
			return 10
		TutorialEvent.PHISH_1_PACKET_SPOOFS:
			return 1
		TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS:
			return 2
		_:
			return 1

### TRACK ONE SHOT TUTORIAL EVENTS ###
#Tutorial.complete_event(Tutorial.TutorialEvent.USE_FOCUS) <- how to complete tutorial events
func complete_event(event: TutorialEvent) -> void:
	if completed_events.has(event):
		return
	
	if not tutorial_tasks.has(event) or not event in TUTORIAL_ORDER:
		return # retired steps (old order) never complete or print
	if event in GATED_STEPS and current_step() != event:
		return
	var was_current = current_step() == event
	
	completed_events.append(event)
	last_completed = event
	if event == TutorialEvent.RUN_HELP_COMMAND:
		_give_starter_kit()
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
		message += "\n\nType 'hint' any time for what to run next, 'flow' for the whole loop, and keep an eye on AVAILABLE TO RUN in the side panel. Hacking is the fastest way to progress."
		message += "\n\n'info <skill>' (ex. info cracking) shows every process a skill has and the command that runs it, and new ones unlock as the skill levels. Explore the Defragging skill ('cd defragging') for temporary system-wide bonuses."
		message += "\n\nThoughts or ideas? Come hang out in the Discord: " + ContextCommands.DISCORD_LINK + "  ('discord -c' copies it)"
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
	if was_current or is_tutorial_complete():
		Signals.tutorial_event_completed(message) # a step finished ahead of time is checked off quietly
	_step_topup()
	SaveManager.mark_dirty()

var last_completed = -1 # the step that just finished (the terminal's OBJECTIVE COMPLETE line names it)

## What each step needs on hand: topped up (silently) when the step comes up, so a short roll or a resource
## spent elsewhere can't stall the tutorial. Most players already have more than this.
func _step_needs() -> Dictionary:
	return {
		TutorialEvent.PARSE_20_LOGS: {Items.LOGS: 10},
		TutorialEvent.START_CRACKING: {Items.ENCRYPTED_PASSWORDS: 5},
		TutorialEvent.CRACK_3_PASSWORDS: {Items.ENCRYPTED_PASSWORDS: 5},
		TutorialEvent.MATCH_3_CREDENTIALS: {Items.USERNAMES: 3, Items.PASSWORDS: 3},
		TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: {Items.CREDENTIALS: 2, Items.IP_ADDRESS: 2},
		TutorialEvent.PACKAGE_5_LOGS: {Items.LOGS: 5},
		TutorialEvent.UPLOAD_PARENTS_CC: {Items.PARENTS_CREDIT_CARD: 1},
		TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: {Items.LOGS: 21},
	}

func _step_topup() -> void:
	if is_tutorial_complete():
		return
	var cur = current_step()
	var needs = _step_needs().get(cur, {})
	# crack 5 counts what's cracked from here on, so it needs 5 more than were already cracked toward it
	for item in needs:
		var want = int(needs[item])
		if cur == TutorialEvent.CRACK_3_PASSWORDS:
			want = max(0, want - int(tutorial_progress.get(cur, 0)))
		var short = want - Inventory.get_amount(item)
		if short > 0:
			Inventory.add_resource(item, short)

## Each process the tutorial introduces comes with 1 VM token of its skill, given when its step comes up
## (once per save; the step text points at the ssh command).
var token_steps_granted: Array = []
func _token_steps() -> Dictionary:
	return {
		TutorialEvent.CRACK_3_PASSWORDS: Items.VM_CRACKING_TOKEN,
		TutorialEvent.PHISH_15_SQL_INJECTORS: Items.VM_PHISHING_TOKEN,
		TutorialEvent.MINE_20_LOGS: Items.VM_MINING_TOKEN,
		TutorialEvent.EQUIP_FIRST_MOD: Items.HANDSHAKE_EXPLOIT, # only if they have no mod (saves that decoded the first cache before mods were in it)
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
		if cur == TutorialEvent.EQUIP_FIRST_MOD and (Inventory.has_mod_item() or !HackingMods.current_mods.is_empty()):
			return
		Inventory.add_resource(steps_map[cur], 1)

## Tutorial safety net for the hack steps: before a tutorial hack of the Student, top the player up so poking at
## 'kill' (or losing) can never leave them unable to finish the step. Per hack: 1 payload, KIT_SQL_PER_HACK SQL
## Injectors (a Student fight uses 8-10), KIT_SPOOFS Packet Spoofs. Returns a line for the hacking console ("" = nothing added).
const KIT_STEPS = [TutorialEvent.HACK_STUDENT, TutorialEvent.HACK_STUDENT_TWICE]
const KIT_SQL_PER_HACK := 12
const KIT_SPOOFS := 3
func ensure_hack_kit(target: Dictionary, hack_count: int) -> String:
	if is_tutorial_complete() or Stats.target_place(target).get("hard", true) or Stats.target_place(target).get("index", 1) != 0:
		return ""
	var cur = null
	for e in TUTORIAL_ORDER:
		if tutorial_tasks.has(e) and !completed_events.has(e):
			cur = e
			break
	if !(cur in KIT_STEPS):
		return ""
	var n = 2 if hack_count < 0 else clamp(hack_count, 1, 3)
	var added = []
	for pair in [[target.requirements.item, int(target.requirements.amount) * n], [Items.SQL_INJECTOR, KIT_SQL_PER_HACK * n], [Items.PACKET_SPOOF, KIT_SPOOFS]]:
		var short = pair[1] - Inventory.get_amount(pair[0])
		if short > 0:
			Inventory.add_resource(pair[0], short)
			added.append("%d %s" % [short, pair[0].name])
	if added.is_empty():
		return ""
	return "Tutorial: topped you up with " + ", ".join(added) + " so this hack can go ahead."

## Short page titles (the enum names kept old counts)
const STEP_TITLES = {
	TutorialEvent.MINE_20_LOGS: "Mine 15 logs",
	TutorialEvent.PARSE_20_LOGS: "Parse 10 logs",
	TutorialEvent.OBTAIN_3_ENCRYPTED_PASSWORDS: "Obtain 6 encrypted passwords",
	TutorialEvent.OBTAIN_3_USERNAMES: "Obtain 5 usernames",
	TutorialEvent.OBTAIN_3_IP_ADDRESSES: "Parse 3 IP addresses",
	TutorialEvent.CRACK_3_PASSWORDS: "Crack 5 passwords (with a VM)",
	TutorialEvent.MATCH_3_CREDENTIALS: "Match 3 credentials",
	TutorialEvent.PHISH_15_SQL_INJECTORS: "Phish 10 SQL injectors",
	TutorialEvent.PHISH_1_PACKET_SPOOFS: "Phish 1 packet spoof",
	TutorialEvent.COMPILE_3_SCHOOL_PAYLOADS: "Compile 2 school payloads",
	TutorialEvent.PACKAGE_5_LOGS: "Upload 5 logs",
	TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT: "Install a Mining upgrade",
	TutorialEvent.RUN_VM_WITH_SSH: "Run a VM with ssh",
	TutorialEvent.UPLOAD_INFO: "Check the upload goal",
	TutorialEvent.UPLOAD_PARENTS_CC: "Upload a parents credit card",
	TutorialEvent.NAVIGATE_HACKING: "Go to Hacking",
	TutorialEvent.VIEW_SCHOOL: "View the School",
	TutorialEvent.HACK_STUDENT: "Hack the Student",
	TutorialEvent.RETURN_TO_ROOT: "Back to the main terminal",
	TutorialEvent.DECODE_1_STUDENT_CACHE: "Decode the cache",
	TutorialEvent.LIST_ITEMS: "See the haul",
	TutorialEvent.EQUIP_FIRST_MOD: "Equip a hacking mod",
	TutorialEvent.HACK_STUDENT_TWICE: "Hack the Student twice",
	TutorialEvent.DECODE_2_CACHES: "Decode both caches",
	TutorialEvent.RUN_MINING_LOG: "Start mining",
	TutorialEvent.STOP_MINING_PROCESS: "Stop mining",
	TutorialEvent.UTILITY_COMMAND: "Utility commands",
	TutorialEvent.NAVIGATE_PARSING: "Go to Parsing",
	TutorialEvent.NAVIGATE_CRACKING: "Go to Cracking",
	TutorialEvent.START_CRACKING: "Start cracking",
	TutorialEvent.RUN_HELP_COMMAND: "See the commands",
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
		message += "\nFrom here, you're on your own. Explore more processes, upgrade to better versions, complete the School uploads ('upload'), and try your hand at the Student (Hard). If you're ever unsure what to do next, type 'hint'."
		message += "\n\nThoughts or ideas? Come hang out in the Discord: " + ContextCommands.DISCORD_LINK + "  ('discord -c' copies it)"
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
			return task_text(event)
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
		"kit_given": kit_given,
		"window_pos": [window_pos.x, window_pos.y] if window_moved else [],
		"order_version": ORDER_VERSION,
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
	kit_given = bool(data.get("kit_given", false))
	var wp: Array = data.get("window_pos", [])
	window_moved = wp.size() == 2
	window_pos = Vector2(float(wp[0]), float(wp[1])) if window_moved else Vector2.ZERO
	if SaveManager.loaded_version < 2: # only saves from before the upload steps existed
		_complete_skipped_new_steps()
	if int(data.get("order_version", 0)) < ORDER_VERSION and !completed_events.is_empty():
		_migrate_to_hack_first()

## 3 = the hack-first order (2026-10-23)
const ORDER_VERSION := 3
## Saves from the old order: a finished tutorial stays finished. Otherwise the steps both orders share keep
## their state and the player picks up at the first one not done, so a mid-tutorial save still gets the
## hack-first part; a new step is checked off when the shared step right after it is already done.
const IMPLIED_BY = {TutorialEvent.VIEW_SCHOOL: TutorialEvent.HACK_STUDENT, TutorialEvent.RETURN_TO_ROOT: TutorialEvent.DECODE_1_STUDENT_CACHE}
func _migrate_to_hack_first() -> void:
	var old_done = OLD_ORDER_V2.filter(func(e): return tutorial_tasks.has(e)).all(func(e): return completed_events.has(e))
	if old_done:
		for e in TUTORIAL_ORDER:
			if !completed_events.has(e):
				completed_events.append(e)
		kit_given = true
		return
	for e in IMPLIED_BY:
		if completed_events.has(IMPLIED_BY[e]) and !completed_events.has(e):
			completed_events.append(e)
	if completed_events.has(TutorialEvent.HACK_STUDENT):
		kit_given = true
	elif completed_events.has(TutorialEvent.RUN_HELP_COMMAND):
		_give_starter_kit.call_deferred() # past '-h' in the old order: the new step 2 promises the kit (Items loads later)

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
	return SaveManager.loaded_version < 4 and !completed_events.is_empty() # DEMO: saves from earlier demo builds

func old_save_notice() -> String:
	var m := "[color=yellow]WELCOME BACK[/color]\n"
	m += "Your save is from an earlier version of the demo. Since then: 'hint' suggests what to run next, fights are faster, there are 5 new Hacking Mods and 5 new one-time items to find in School caches, mods last 5 hacks, and there's music ('music').\n" # DEMO
	m += "Want a refresher? Type 'tutorial reset' to restart the tutorial. [color=#666666]Your items, levels and upgrades stay as they are.[/color]"
	return m

## 'tutorial reset': clears the checklist only. Steps this save can't redo (Mining upgrades maxed, an item's
## upload goal already covered) are checked off so the player can't get stuck. Returns how many were skipped.
func reset_tutorial() -> int:
	completed_events.clear()
	kit_given = true # a reset doesn't hand out another kit (ensure_hack_kit still covers the hack steps)
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
	if item == Items.PARENTS_CREDIT_CARD:
		complete_event(TutorialEvent.UPLOAD_PARENTS_CC) # queued is enough: no waiting on the Logs ahead of it
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
