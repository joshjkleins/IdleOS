extends BaseTerminal
## Matching terminal: consumes one of each required item, walks 4 stages of terminal messages
## (each message one speed step), then assembles the result. Efficiency rolls bonus quantity.
## Upgrades: recovery (inputs kept), Auto-Correlate (head start on every match), Hot Cache (speed
## streak), modifiers prebuild/correlate/survey, Rolodex (token x2), Cold Storage (no extra heat).

#@onready var user_row_container = $MarginContainer/VBoxContainer/BottomRow/VBoxContainer/UserRowContainer
@onready var main_bar = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/MainBar
@onready var status_progress_bar = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusProgressBar

@onready var status_image = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusImage
@onready var status_title = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusTitle
@onready var status_username = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusUsername
@onready var status_pw = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusPw
#@onready var status_updater = $MarginContainer/VBoxContainer/BottomRow/StatusUpdater
@onready var userbox_name_label = $MarginContainer/VBoxContainer/TopRow/FirstCol/UsernameBox/MarginContainer/VBoxContainer/UserboxNameLabel
@onready var third_col = $MarginContainer/VBoxContainer/TopRow/ThirdCol

@onready var resource_received_title = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/PlayerAmountReceived/ResourceReceivedTitle
@onready var resource_received_amount = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/PlayerAmountReceived/ResourceReceivedAmount

@onready var resource_one_title = $MarginContainer/VBoxContainer/TopRow/FirstCol/UsernameBox/MarginContainer/VBoxContainer/HBoxContainer/ResourceOneTitle
@onready var resource_two_title = $MarginContainer/VBoxContainer/TopRow/FirstCol/PasswordBox/MarginContainer/VBoxContainer/HBoxContainer/ResourceTwoTitle
@onready var tag_1 = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/MarginContainer/TagContainer/Tag/MarginContainer/Tag1
@onready var tag_2 = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/MarginContainer/TagContainer/Tag2/MarginContainer/Tag2
@onready var tag_3 = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/MarginContainer/TagContainer/Tag3/MarginContainer/Tag3
@onready var tag_4 = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/MarginContainer/TagContainer/Tag4/MarginContainer/Tag4
@onready var resource_amount_one = $MarginContainer/VBoxContainer/TopRow/FirstCol/UsernameBox/MarginContainer/VBoxContainer/HBoxContainer/ResourceAmountOne
@onready var resource_amount_two = $MarginContainer/VBoxContainer/TopRow/FirstCol/PasswordBox/MarginContainer/VBoxContainer/HBoxContainer/ResourceAmountTwo

@export var lock_image: Texture2D
@export var cred_image: Texture2D
@onready var terminal_scroll = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/Terminal/MarginContainer/TerminalScroll
@onready var terminal_label = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/Terminal/MarginContainer/TerminalScroll/VBoxContainer/TerminalLabel
@onready var efficiency_label = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/EfficiencyLabel
@onready var title_label = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/Label
@onready var subtitle_label = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/Label2

var db_lookup_messages: Array[String] = [
	"[color=#555555][DB] [/color] [color=#79c0ff]QUERY    [/color] Scanning user index... [color=#bc8cff]0x4F2A[/color]",
	"[color=#555555][DB] [/color] [color=#79c0ff]FETCH    [/color] Resolving uid -> record match",
	"[color=#555555][DB] [/color] [color=#d29922]CACHE    [/color] Entry found in L2 cache: loading",
	"[color=#555555][DB] [/color] [color=#3fb950]OK       [/color] Record integrity check passed",
	"[color=#555555][DB] [/color] [color=#79c0ff]SYNC     [/color] Replicating metadata to session buffer",
	"[color=#555555][DB] [/color] [color=#3fb950]HIT      [/color] Account located: [color=#bc8cff]usr_7741[/color]",
]
 
var auth_messages: Array[String] = [
	"[color=#555555][AUTH][/color] [color=#79c0ff]INIT     [/color] Spawning bcrypt worker thread",
	"[color=#555555][AUTH][/color] [color=#d29922]HASH     [/color] Salting input: rounds: [color=#bc8cff]12[/color]",
	"[color=#555555][AUTH][/color] [color=#79c0ff]COMPARE  [/color] Matching digest against stored hash",
	"[color=#555555][AUTH][/color] [color=#d29922]VERIFY   [/color] Checking entropy threshold...",
	"[color=#555555][AUTH][/color] [color=#3fb950]TOKEN    [/color] Ttl session token issued: [color=#bc8cff]3600s[/color]",
	"[color=#555555][AUTH][/color] [color=#3fb950]PASS     [/color] Hash comparison successful",
]
 
var pentest_messages: Array[String] = [
	"[color=#555555][PEN] [/color] [color=#79c0ff]PROBE    [/color] Initiating port sweep [color=#bc8cff]192.168.x.x[/color]",
	"[color=#555555][PEN] [/color] [color=#d29922]INJECT   [/color] Testing SQLi vectors on endpoint [color=#bc8cff]/api[/color]",
	"[color=#555555][PEN] [/color] [color=#f85149]ANOMALY  [/color] Unexpected response on port [color=#bc8cff]8443[/color]",
	"[color=#555555][PEN] [/color] [color=#79c0ff]FUZZ     [/color] Sending [color=#bc8cff]512[/color] malformed payloads...",
	"[color=#555555][PEN] [/color] [color=#f85149]EXPOSE   [/color] CVE-2024-1337, potential XSS vector",
	"[color=#555555][PEN] [/color] [color=#3fb950]PATCH    [/color] Exploit confirmed, logging to report",
]
 
var credential_messages: Array[String] = [
	"[color=#555555][CRED][/color] [color=#79c0ff]CHECK    [/color] Cross-referencing against ACL table",
	"[color=#555555][CRED][/color] [color=#d29922]SCOPE    [/color] Evaluating permission set: [color=#bc8cff]read+exec[/color]",
	"[color=#555555][CRED][/color] [color=#79c0ff]MFA      [/color] Second factor binding... TOTP valid",
	"[color=#555555][CRED][/color] [color=#3fb950]GRANT    [/color] Access level confirmed: [color=#bc8cff]OPERATOR[/color]",
	"[color=#555555][CRED][/color] [color=#3fb950]BIND     [/color] Match committed to active session",
	"[color=#555555][CRED][/color] [color=#3fb950]READY    [/color] System access unlocked",
]

var terminal_messages = [db_lookup_messages, auth_messages, pentest_messages, credential_messages]
var intervals #how much each message fills up progress bar


var green = Color("#3b8f68")
var grey = Color("#6b6b78")
var d_border_col = Color("#1e2328")
var s_border_col = Color("#3b8f68")
var f_border_col = Color("#c85660")

var highest_roll: int = 0

var TIME_TO_ROLL: float = 2.0
var TIME_PER_METHOD: float = 0.65

var sb #stylebox global
var u_name: String
var TAG_COLORS = [
	Color("#3B82F6"),
	Color("#10B981"),
	Color("#F59E0B"),
	Color("#8B5CF6")
]


## Per-process look: the 4 stage tags, the two input titles, the stage-1 status and the ID shown.
const THEMES = {
	"credential": {"tags": ["username lookup", "password match", "pen testing", "credential confirm"], "inputs": ["USERNAME", "PASSWORD"], "match": "password match", "id": "username"},
	"certificate": {"tags": ["case # lookup", "signature match", "pen testing", "certificate confirm"], "inputs": ["CASE #", "SIGNATURE"], "match": "signature match", "id": "case"},
	"badge": {"tags": ["staff ID lookup", "badge hash match", "pen testing", "badge confirm"], "inputs": ["STAFF ID", "BADGE HASH"], "match": "badge hash match", "id": "staff"},
	"account": {"tags": ["account # lookup", "PIN match", "pen testing", "account token confirm"], "inputs": ["ACCOUNT #", "PIN"], "match": "PIN match", "id": "account"},
	"officer": {"tags": ["badge # lookup", "key match", "pen testing", "auth key confirm"], "inputs": ["BADGE #", "PRIVATE KEY"], "match": "key match", "id": "officer"},
	"clearance": {"tags": ["clearance ID lookup", "biometric match", "pen testing", "clearance confirm"], "inputs": ["CLEARANCE ID", "BIO TEMPLATE"], "match": "biometric match", "id": "clearance"},
}

var _cycle_mode: Mode = Mode.NORMAL # worst mode seen this match (decides heat)
var _match_seconds := 0.0  # real time the current match took (VM tokens roll on time)
var _head_start := 0.0     # Auto-Correlate: every step of this match is this much shorter
var _streak: int = 0       # Hot Cache: consecutive matches this run (reset when stopped)
var match_theme: Dictionary

func set_type(p_type: Dictionary, window: bool = false): #param = minor skill
	setup_process(Matching, p_type, window)
	match_theme = THEMES.get(p_type.get("match theme", "credential"), THEMES.credential)
	var tags: Array[String] = []
	tags.assign(match_theme.tags)
	_update_tags(tags)
	resource_one_title.text = match_theme.inputs[0]
	resource_two_title.text = match_theme.inputs[1]
	resource_received_title.text = process_data["resource gained"].name.to_upper()
	update_player_amount_received_labels()

#sets text labels on each 'tag' in center column
func _update_tags(tag_names: Array[String]):
	var tags = [tag_1, tag_2, tag_3, tag_4]
	for i in range(tags.size()):
		tags[i].text = tag_names[i]

func _set_interval_time(): #calculate interval time
	var isize = 0
	for i in terminal_messages:
		isize += i.size()
	intervals = 100.0 / isize

func _has_requirements() -> bool:
	for item in process_data["requirements"]:
		if Inventory.get_amount(item) <= 0:
			return false
	return true

func _consume_required_items():
	# Recovery: a chance the inputs aren't used up
	if randf() < Upgrades.cur("matching.recovery"):
		return
	for item in process_data["requirements"]:
		Inventory.remove_resource(item, 1)

func _update_username_password_labels():
	userbox_name_label.text = u_name

func _update_last_col_username(us_name):
	status_username.text = us_name

func _update_last_col_pw(us_name):
	status_pw.text = us_name

func _update_last_col_title(text):
	status_title.text = text

func _update_efficiency_label():
	var eff = _get_efficiency_total()
	efficiency_label.text = "chance for extra (eff): %.1f%%" % (eff * 100.0)

func start():
	begin_run()
	_streak = 0
	_update_title()
	_update_subtitle()
	sb = third_col.get_theme_stylebox("panel")
	if !_has_requirements():
		_finished()
		return
	_choose_username()
	_update_efficiency_label()
	_set_interval_time()
	_consume_required_items()
	_update_resource_amount_labels()
	_update_username_password_labels()
	_begin_matching()

func _repeat_loop():
	if !_has_requirements():
		_finished()
		return
	_consume_required_items()
	_update_resource_amount_labels()
	_choose_username()
	_update_username_password_labels()
	_update_last_col_username("-")
	_update_last_col_pw("-")
	_update_last_col_title(match_theme.tags[0])
	_begin_matching()


## Ran out of items or was asked to stop safely.
func _finished():
	finish_safely()

func _begin_matching():
	if !running:
		return
	_cycle_mode = Mode.NORMAL
	_match_seconds = 0.0
	_head_start = Upgrades.cur("matching.auto_correlate")
	#get current_row
	third_col.add_theme_stylebox_override("panel", sb)
	main_bar.value = 0.0
	#loop through tags
	var tags_size = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/MarginContainer/TagContainer.get_children().size()
	terminal_label.text = ""
	for i in range(tags_size): #loop through each tag (4)
		_update_tag_color(i)
		for message in terminal_messages[i]: #loop through each message in each message array (6 at time)
			await _update_matching_terminal(message)
			if !running:
				return
		
		match i: #do different things for each iteration
			0:
				_update_last_col_username(u_name)
				_update_last_col_title(match_theme.match)
			1:
				_update_last_col_pw("****")
				_update_last_col_title("strength check")
			2:
				_update_last_col_title("assembling")
			3:
				_update_last_col_title("awaiting match")
	
	_match_finished()
	await get_tree().create_timer(0.3).timeout
	if !running:
		return
	if stop_requested:
		_finished()
		return
	_repeat_loop()

func _update_resource_amount_labels():
	str(Inventory.get_amount(process_data.requirements.keys()[0]))
	resource_amount_one.text = "x" + str(Inventory.get_amount(process_data.requirements.keys()[0]))
	resource_amount_two.text = "x" + str(Inventory.get_amount(process_data.requirements.keys()[1]))

func _update_matching_terminal(message):
	terminal_label.text += message + "\n"
	terminal_scroll.scroll_vertical = terminal_scroll.get_v_scroll_bar().max_value
	var tween = create_tween()
	var mode := get_mode()
	_cycle_mode = worst_mode(_cycle_mode, mode)
	var step: float = get_step_time(mode) * (1.0 - _head_start) / (1.0 + _hot_cache_bonus())
	_match_seconds += step
	tween.tween_property(main_bar, "value", main_bar.value + intervals, step)
	await tween.finished

func _update_tag_color(index: int):
	var tags = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/MarginContainer/TagContainer.get_children()
	tags[0].remove_theme_stylebox_override("panel")
	tags[1].remove_theme_stylebox_override("panel")
	tags[2].remove_theme_stylebox_override("panel")
	tags[3].remove_theme_stylebox_override("panel")
	var tag = tags[index]
	tag.remove_theme_stylebox_override("panel")
	var sb_n = tag.get_theme_stylebox("panel").duplicate()
	sb_n.bg_color = TAG_COLORS[index]
	tag.add_theme_stylebox_override("panel", sb_n)

func _generate_account_number() -> String:
	var account = ""
	for i in range(16):
		account += str(randi() % 16)
	return account

func _choose_username(): #sets the ID shown for this match (fits the process)
	match match_theme.id:
		"case":
			u_name = "CV-%d-%04d" % [2020 + randi() % 7, randi() % 10000]
		"staff":
			u_name = "STF-%05d" % (randi() % 100000)
		"account":
			u_name = "%04d %04d %04d" % [randi() % 10000, randi() % 10000, randi() % 10000]
		"officer":
			u_name = "BDG #%04d" % (randi() % 10000)
		"clearance":
			u_name = ["CONF", "SEC", "TS"].pick_random() + "-%05d" % (randi() % 100000)
		_:
			u_name = Matching.RANDOM_USERNAMES.pick_random()

func _match_finished(): #add heat/resource/xp/emit signals
	var quantity = 1
	var total_eff = _get_efficiency_total()
	if randf() <= total_eff:
		quantity += randi_range(3, 10) # extra on a proc
	# Survey: half the output (coin flip on odd amounts), double the XP
	var xp = process_data["experience per level"]
	if has_modifier("survey"):
		quantity = quantity / 2 + (1 if quantity % 2 == 1 and randf() < 0.5 else 0)
		xp *= 2
	if quantity > 0:
		Inventory.add_resource(process_data["resource gained"], quantity)
	# Prebuild: a chance to also produce the tier's payload (skips Compiling)
	if has_modifier("prebuild") and randf() < Matching.PREBUILD_CHANCE:
		var tier = Matching.minor_processes.find(process_data) + 1
		if tier > 0:
			Inventory.add_resource(Decoding.get_tier_resources(tier)[6], 1)
	update_player_amount_received_labels()
	Tutorial.track_event(Tutorial.TutorialEvent.MATCH_3_CREDENTIALS, 1)
	status_title.text = process_data["resource gained"]["name"].to_upper() + " ASSEMBLED"
	status_image.texture = cred_image
	var og_box = third_col.get_theme_stylebox("panel").duplicate()
	og_box.border_color = s_border_col
	third_col.add_theme_stylebox_override("panel", og_box)
		
	apply_heat(_cycle_mode) # same rules as every skill: overclock heat only when overclock is unlocked
	process_data.signal.emit(1)
	record_cycle(quantity)
	Exp.add_xp(Matching, process_data, xp)
	
	if randf() <= _token_chance():
		Inventory.add_resource(Items.VM_MATCHING_TOKEN, 1)
	_streak += 1
	_update_subtitle()
	_update_efficiency_label()
	Signals.update_hud(Matching)

## Hot Cache: +1% speed per consecutive match this run, up to the installed cap
func _hot_cache_bonus() -> float:
	return min(_streak * Matching.HOT_CACHE_STEP, Upgrades.cur("matching.hot_cache"))

## VM token chance for the match just finished, rolled on time spent (speed upgrades, overclock and
## head starts don't change tokens per hour): the process's chance is for a base-speed match, scaled by
## how long this one took. Rolodex and Correlate double it.
func _token_chance() -> float:
	var steps := 0
	for msgs in terminal_messages:
		steps += msgs.size()
	var base_match = (float(process_data["base speed min"]) + float(process_data["base speed max"])) / 2.0 * steps
	var chance = (float(process_data.get("vm token chance", 0.01)) + Exp.vm_token_level_bonus(skill)) * (_match_seconds / max(0.001, base_match))
	if Upgrades.has("matching.rolodex"):
		chance *= 2.0
	if has_modifier("correlate"):
		chance *= 2.0
	return chance

## "MATCHING ENGINE · PREBUILD" while a modifier runs
func _update_title() -> void:
	title_label.text = "MATCHING ENGINE" + ((" · " + modifier.name.to_upper()) if !modifier.is_empty() else "")

## Shows the Hot Cache streak once the track is installed
func _update_subtitle() -> void:
	if Upgrades.cur("matching.hot_cache") > 0.0:
		subtitle_label.text = "hot cache +%d%%" % roundi(_hot_cache_bonus() * 100.0)
	else:
		subtitle_label.text = "confirmation algorithm"

func _on_stopped() -> void:
	_streak = 0

func generate_username_variations(base_username: String) -> Array[String]:
	var variations: Array[String] = []

	# Remove common separators for parsing
	var cleaned = base_username.replace("@", "_")
	cleaned = cleaned.replace(".", "_")
	cleaned = cleaned.replace("-", "_")

	var parts = cleaned.split("_", false)

	var first := ""
	var last := ""
	var number := ""

	# Try extracting name pieces + ending number
	for part in parts:
		if part.is_valid_int():
			number = part
		elif first == "":
			first = part
		else:
			last += part

	if last == "":
		last = first

	var first_initial := first.substr(0, 1)

	# Generate variations
	variations.append("%s_%s" % [first_initial, last])
	variations.append("%s%s@admin" % [first_initial, last])
	variations.append("%s_%s@admin" % [first_initial, last])

	if number != "":
		variations.append("%s_%s_%s" % [last, first, number])
	else:
		variations.append("%s_%s" % [last, first])

	variations.append("%s%s%s" % [first_initial, last, number])

	return variations

func _on_main_bar_value_changed(value):
	status_progress_bar.text = "%.1f%%" % value

func _get_efficiency_total():
	var base_efficiency = process_data["efficiency"]
	var defrag_multiplier = 1.0 # defrag no longer boosts skills
	
	var efficiency_matching_package = Upgrades.get_package_info("matching.efficiency")
	var efficiency_upgrade = efficiency_matching_package.current
	
	return (base_efficiency + efficiency_upgrade) * defrag_multiplier * (2.0 if has_modifier("correlate") else 1.0)

func update_player_amount_received_labels():
	resource_received_amount.text = "x" + str(Inventory.get_amount(process_data["resource gained"]))
