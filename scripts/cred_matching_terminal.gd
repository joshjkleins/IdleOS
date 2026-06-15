extends PanelContainer

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

var process_running: bool = false
var safely_stop: bool = false

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

var type #which minor process
var is_window: bool = false

enum MatchType {CREDENTIAL, ACCOUNT}
var current_type: MatchType

func set_type(p_type: Dictionary, window: bool = false): #param = minor skill
	type = p_type
	is_window = window
	match p_type.name.to_lower():
		"credential":
			_update_tags(["username DB lookup", "authenticating password", "pen testing", "credential confirmation"])
			current_type = MatchType.CREDENTIAL
			resource_one_title.text = "USERNAME"
			resource_two_title.text = "PASSWORD"
		"account":
			_update_tags(["account # lookup", "authenticating PIN", "pen testing", "account token confirmation"])
			current_type = MatchType.ACCOUNT
			resource_one_title.text = "ACCOUNT #"
			resource_two_title.text = "PIN"


# func set_cred(p_type: Dictionary):
# 	_update_tags(["username DB lookup", "authenticating password", "pen testing", "credential confirmation"])
# 	type = p_type
# 	current_type = MatchType.CREDENTIAL
# 	resource_one_title.text = "USERNAME"
# 	resource_two_title.text = "PASSWORD"

# func set_account(p_type: Dictionary):
# 	_update_tags(["account # lookup", "authenticating PIN", "pen testing", "account token confirmation"])
# 	type = p_type
# 	current_type = MatchType.ACCOUNT
# 	resource_one_title.text = "ACCOUNT #"
# 	resource_two_title.text = "PIN"

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
	for item in type["requirements"]:
		if Inventory.get_amount(item) <= 0:
			return false
	return true

func _consume_required_items():
	for item in type["requirements"]:
		if randf() > type["efficiency"] + Matching.process_upgrades["efficiency"]["amount"]:
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
	var defrag_bonus = Defragging.MATCHING["bonus efficiency"] if Stats.has_bonus(Matching) else 1.0
	var base_eff = type["efficiency"] + Matching.process_upgrades["efficiency"]["amount"]
	var eff = base_eff * defrag_bonus
	efficiency_label.text = "chance for extra %.1f%%" % (eff * 100.0)

func start():
	process_running = true
	safely_stop = false
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

func stop():
	process_running = false
	safely_stop = false

func stop_safely():
	safely_stop = true

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
	_update_last_col_title("username lookup")
	_begin_matching()


func _finished():
	process_running = false
	safely_stop = false
	if is_window:
		Matching.CURRENT_VMS -= 1
		get_parent().queue_free()
	else:
		Signals.end_cred_matching_safely()

func _begin_matching():
	if !process_running:
		_finished()
		return
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
			if !process_running:
				_finished()
				return
		
		match i: #do different things for each iteration
			0:
				_update_last_col_username(u_name)
				match current_type:
					MatchType.CREDENTIAL:
						_update_last_col_title("password match")
					MatchType.ACCOUNT:
						_update_last_col_title("PIN match")
			1:
				_update_last_col_pw("****")
				_update_last_col_title("strength check")
			2:
				_update_last_col_title("assembling")
			3:
				_update_last_col_title("awaiting match")
	
	_match_finished()
	await get_tree().create_timer(0.3).timeout
	if !process_running:
		_finished()
		return
	if safely_stop:
		_finished()
		return
	_repeat_loop()

func _update_resource_amount_labels():
	resource_amount_one.text = "x" + str(Inventory.get_amount(type["requirements"][0]))
	resource_amount_two.text = "x" + str(Inventory.get_amount(type["requirements"][1]))

func _get_speed() -> float:
	var time
	if Stats.overheated:
		time = type["overheat speed"]
	elif Stats.overclocked:
		time = randf_range(type["overclock speed min"], type["overclock speed max"])
	else:
		time = randf_range(type["base speed min"], type["base speed max"])
	
	return time

func _update_matching_terminal(message):
	terminal_label.text += message + "\n"
	terminal_scroll.scroll_vertical = terminal_scroll.get_v_scroll_bar().max_value
	var tween = create_tween()
	tween.tween_property(main_bar, "value", main_bar.value + intervals, _get_speed())
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

func _choose_username(): #sets current iteration username variable
	match current_type:
		MatchType.CREDENTIAL:
			u_name = Matching.RANDOM_USERNAMES.pick_random()
		MatchType.ACCOUNT:
			u_name = _generate_account_number()
	

func _match_finished(): #add heat/resource/xp/emit signals
	var heat
	if Stats.overclocked:
		heat = type["overclock heat"]
	elif Stats.overheated:
		heat = type["overheat heat"]
	else:
		heat = type["heat"]
	var quantity = 1
	var defrag_bonus = Defragging.MATCHING["bonus efficiency"] if Stats.has_bonus(Matching) else 1.0
	var base_eff = type["efficiency"] + Matching.process_upgrades["efficiency"]["amount"]
	var total_eff = base_eff * defrag_bonus
	if randf() <= total_eff:
		quantity += 1
	Inventory.add_resource(type["resource gained"], quantity)
	status_title.text = type["resource gained"]["name"].to_upper() + " ASSEMBLED"
	status_image.texture = cred_image
	var og_box = third_col.get_theme_stylebox("panel").duplicate()
	og_box.border_color = s_border_col
	third_col.add_theme_stylebox_override("panel", og_box)
		
	Stats.update_tempature(heat)
	type.signal.emit(1)
	Exp.add_xp(Matching, type, type["experience per level"] * Matching.process_upgrades["experience"]["amount"])
	
	if randf() <= 0.01:
		Inventory.add_resource(Items.VM_MATCHING_TOKEN, 1)
	_update_efficiency_label()
	Signals.update_hud(Matching)

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
