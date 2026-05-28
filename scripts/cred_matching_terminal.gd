extends PanelContainer

@onready var user_row_container = $MarginContainer/VBoxContainer/BottomRow/VBoxContainer/UserRowContainer
@onready var main_bar = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/MainBar
@onready var status_progress_bar = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusProgressBar

@onready var status_image = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusImage
@onready var status_title = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusTitle
@onready var status_username = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusUsername
@onready var status_pw = $MarginContainer/VBoxContainer/TopRow/ThirdCol/MarginContainer/VBoxContainer/StatusPw
@onready var status_updater = $MarginContainer/VBoxContainer/BottomRow/StatusUpdater
@onready var userbox_name_label = $MarginContainer/VBoxContainer/TopRow/FirstCol/UsernameBox/MarginContainer/VBoxContainer/UserboxNameLabel
@onready var third_col = $MarginContainer/VBoxContainer/TopRow/ThirdCol

@onready var resource_one_title = $MarginContainer/VBoxContainer/TopRow/FirstCol/UsernameBox/MarginContainer/VBoxContainer/HBoxContainer/ResourceOneTitle
@onready var resource_two_title = $MarginContainer/VBoxContainer/TopRow/FirstCol/PasswordBox/MarginContainer/VBoxContainer/HBoxContainer/ResourceTwoTitle

@export var lock_image: Texture2D
@export var cred_image: Texture2D

var target_row = preload("res://scenes/cred_match_target_row.tscn")
var separator = preload("res://scenes/separator_cred.tscn")

var USER_ROWS: int = 5

var process_running: bool = false
var safely_stop: bool = false
var current_progress: int = 0
var current_iteration: int = 0
var fill = [10, 25, 35, 65, 100]

var tween: Tween

var green = Color("#3b8f68")
var grey = Color("#6b6b78")
var d_border_col = Color("#1e2328")
var s_border_col = Color("#3b8f68")
var f_border_col = Color("#c85660")

var highest_roll: int = 0

var TIME_TO_ROLL: float = 2.0
var TIME_PER_METHOD: float = 0.65

var sb
const RANDOM_USERNAMES := [
	"byteRunner77",
	"neonTiger",
	"silentProxy",
	"darkKernel",
	"pixelRaider",
	"ghostCipher",
	"ironSpectre",
	"lunarSyntax",
	"zeroDayFox",
	"voidCrawler",
	"turboHydra",
	"omegaPulse",
	"echoVector",
	"rapidDelta",
	"nightAssembler",
	"hexCrawler",
	"frostByte",
	"alphaCircuit",
	"gammaNode",
	"dataMantis",
	"vortexDrive",
	"silentCrate",
	"quantumPixel",
	"binaryLancer",
	"crimsonPacket",
	"shadowSocket",
	"omegaClaw",
	"nightSignal",
	"ravenUpload",
	"staticHunter",
	"deltaMachine",
	"hyperBreach",
	"nanoRunner",
	"vaporKernel",
	"electricNomad",
	"stormCache",
	"glitchNova",
	"radarGhost",
	"iceProtocol",
	"pixelNomad",
	"lunarSignal",
	"vectorShadow",
	"solarRogue",
	"rapidSocket",
	"bytePirate",
	"frozenRoot",
	"turboHex",
	"crashOverride",
	"steelCrawler",
	"silentOverflow",
	"toxicMatrix",
	"omegaTrace",
	"voidHunter",
	"quantumEcho",
	"cyberAnchor",
	"blackoutNode",
	"phantomByte",
	"novaSignal",
	"darkPacket",
	"hexRaider",
	"pixelDrifter",
	"cyberNova",
	"binaryFang",
	"terminalGhost",
	"echoCrawler",
	"nightPulse",
	"lunarNode",
	"staticCipher",
	"rapidHex",
	"stormRunner",
	"hyperThread",
	"crimsonRoot",
	"shadowOverride",
	"voidPacket",
	"alphaMantis",
	"vaporSignal",
	"gammaGhost",
	"electricFox",
	"zeroSpectre",
	"silentThread",
	"turboTrace",
	"pixelPulse",
	"quantumSocket",
	"binaryDrifter",
	"novaKernel",
	"omegaRoot",
	"stormHex",
	"darkSyntax",
	"ravenCipher",
	"nightSocket",
	"frostSignal",
	"vectorHydra",
	"phantomProxy",
	"cyberMantis",
	"dataNomad",
	"rapidCrawler",
	"blackoutPulse",
	"shadowKernel",
	"electricPacket",
	"silentRogue",
	"voidTrace",
	"omegaByte",
	"hyperGhost",
	"vaporFox",
	"crimsonHex",
	"novaDrive",
	"ghostThread",
	"staticRaider",
	"binaryPulse",
	"echoSocket",
	"frozenCipher",
	"nightKernel",
	"pixelHunter",
	"stormProxy",
	"darkRoot",
	"quantumTrace",
	"vectorSignal",
	"alphaPacket",
	"cyberDrive",
	"silentMantis",
	"lunarHex",
	"rapidGhost",
	"turboCipher",
	"vaporNode",
	"shadowFox",
	"zeroRunner",
	"blackoutCrawler",
	"novaByte",
	"ghostSocket",
	"frostOverride",
	"binaryTrace",
	"nightRaider",
	"electricSignal",
	"echoHydra",
	"stormDrifter",
	"pixelKernel",
	"crimsonProxy",
	"staticThread",
	"voidCipher",
	"hyperPulse",
	"alphaFox",
	"quantumRunner",
	"cyberSocket",
	"shadowSignal",
	"vaporHex",
	"novaMantis",
	"darkPacket77",
	"silentNova",
	"lunarCipher",
	"frozenDrive",
	"rapidByte",
	"turboGhost",
	"stormSocket",
	"binaryNomad",
	"omegaCrawler",
	"nightTrace",
	"pixelOverride",
	"vectorRaider",
	"electricKernel",
	"echoPacket",
	"cyberRoot",
	"blackoutFox",
	"crimsonSignal",
	"voidHydra",
	"ghostProxy",
	"alphaTrace",
	"staticNomad",
	"hyperByte",
	"shadowPulse",
	"frostSocket",
	"novaHex",
	"binaryHunter",
	"rapidKernel",
	"silentPacket",
	"vaporThread",
	"darkCrawler",
	"turboRunner",
	"nightCipher",
	"pixelFox",
	"vectorDrive",
	"echoGhost",
	"stormOverride",
	"quantumKernel",
	"cyberRaider",
	"zeroSignal",
	"shadowTrace",
	"alphaSocket",
	"ghostByte",
	"binaryHydra",
	"staticRunner",
	"omegaSignal",
	"novaThread",
	"rapidPulse",
	"silentFox",
	"lunarRoot",
	"frostKernel",
	"hyperNomad",
	"darkSocket",
	"stormByte",
	"pixelCipher",
	"cyberGhost",
	"vectorPacket",
	"voidSignal",
	"turboRoot",
	"electricTrace",
	"echoRunner",
	"binarySocket",
	"novaProxy",
	"shadowKernelX",
	"nightHydra",
	"rapidSignal",
	"silentTrace",
	"frostPulse",
	"vaporRaider",
	"ghostNomad",
	"crimsonSocket",
	"omegaThread",
	"pixelByte",
	"stormCrawler",
	"darkProxy",
	"quantumSignal",
	"alphaGhost",
	"hyperRoot",
	"binaryCipher",
	"vectorPulse",
	"cyberThread",
	"zeroKernel",
	"electricSocket",
	"silentHydra",
	"novaSignalX",
	"voidRunner",
	"pixelTrace",
	"nightProxy",
	"frostNomad",
	"shadowByte",
	"echoSignal",
	"stormGhost",
	"rapidThread",
	"turboPacket",
	"cyberCipher",
	"binaryRoot",
	"omegaRunner",
	"vectorKernel",
	"lunarTrace",
	"ghostSignal",
	"hyperSocket",
	"darkHydra",
	"silentKernel",
	"novaPacket",
	"pixelRunner",
	"frozenSignal",
	"alphaOverride",
	"cyberPulse",
	"shadowNomad",
	"rapidSocketX",
	"stormKernelX",
	"voidGhost",
	"electricByte"
]

var TAG_COLORS = [
	Color("#3B82F6"),
	Color("#10B981"),
	Color("#F59E0B"),
	Color("#8B5CF6")
]

var type

enum MatchType {CREDENTIAL, ACCOUNT}
var current_type: MatchType

func set_cred(p_type: Dictionary):
	type = p_type
	current_type = MatchType.CREDENTIAL
	resource_one_title.text = "USERNAME"
	resource_two_title.text = "PASSWORD"

func set_account(p_type: Dictionary):
	type = p_type
	current_type = MatchType.ACCOUNT
	resource_one_title.text = "ACCOUNT #"
	resource_two_title.text = "PIN"

func start():
	process_running = true
	safely_stop = false
	sb = third_col.get_theme_stylebox("panel")
	_reset_rows()
	_build_rows()
	#check if player has required amounts
	for item in type["requirements"]:
		if Inventory.get_amount(item) <= 0:
			_finished()
			return
	
	#roll of efficiency and remove items
	for item in type["requirements"]:
		if randf() > type["efficiency"]:
			Inventory.remove_resource(item, 1)
	_begin_matching()

func stop():
	process_running = false
	safely_stop = false
	_cancel_tweens()

func stop_safely():
	safely_stop = true

func _repeat_loop():
	for item in type["requirements"]:
		if Inventory.get_amount(item) <= 0:
			_finished()
			return
	if process_running:
		#roll of efficiency and remove items
		for item in type["requirements"]:
			if randf() > type["efficiency"]:
				Inventory.remove_resource(item, 1)
		_reset_rows()
		_build_rows()
		_begin_matching()
	else:
		_finished()

func _cancel_tweens():
	if tween:
		tween.kill()
	for n in user_row_container.get_children():
		if n is PanelContainer:
				n.cancel()

func _finished():
	process_running = false
	safely_stop = false
	Signals.end_cred_matching_safely()

func _begin_matching():
	if process_running:
		#get current_row
		third_col.add_theme_stylebox_override("panel", sb)
		var current_row = _get_current_row()
		if current_row != null:
			#highlight tag
			status_updater.text = "FINDING CLOSEST MATCHING ALGORITHM"
			var current_tag = 0
			current_row.fade_in()
			current_row.update_state(current_row.MATCH_STATE.ATTEMPTING)
			var tags = $MarginContainer/VBoxContainer/TopRow/SecondCol/MarginContainer/VBoxContainer/TagContainer.get_children()
			var rolls = []
			for i in range(4):
				rolls.append(randi_range(1, 100))
			#rolls.sort()
			for n in tags:
				tags[0].remove_theme_stylebox_override("panel")
				tags[1].remove_theme_stylebox_override("panel")
				tags[2].remove_theme_stylebox_override("panel")
				tags[3].remove_theme_stylebox_override("panel")
				
				var sb_n = n.get_theme_stylebox("panel").duplicate()
				sb_n.bg_color = TAG_COLORS[current_tag]
				tags[current_tag].add_theme_stylebox_override("panel", sb_n)
				
				var roll = rolls[current_tag]
				
				if !process_running:
					_finished()
					return
				var speed
				var heat
				if Stats.overclocked:
					speed = type["overclock speed"]
					heat = type["overclock heat"]
				elif Stats.overheated:
					speed = type["overheat speed"]
					heat = type["overheat heat"]
				else:
					speed = type["base speed"]
					heat = type["heat"]
				#if roll > highest_roll:
					#highest_roll = roll
					#status_progress_bar.text = "success chance: " + str(highest_roll) + "%"
				current_row.update_label_chances(current_tag, roll, TAG_COLORS[current_tag])
				await current_row.start_progress(roll, speed)
				Stats.update_tempature(heat)
				if !process_running:
					_finished()
					return
				if roll > highest_roll:
					highest_roll = roll
					status_progress_bar.text = "success chance: " + str(highest_roll) + "%"
				#current_row.update_label_chances(current_tag, roll, TAG_COLORS[current_tag])
				current_tag += 1
				
			current_row.set_highest_color()
			#await current_row.start_progress(highest_roll, 0.65)
			current_row.update_state(current_row.MATCH_STATE.LOCKED)
			if !process_running:
				_finished()
				return
			_begin_matching()
		else: #finished looping through 5 rows
			#loop through rows to find highest chance and highlight
			if !process_running:
				_finished()
				return
			var highest_chance = 0
			var t_row = null
			for n in user_row_container.get_children():
				if n is PanelContainer:
					if n.highest_chance > highest_chance:
						highest_chance = n.highest_chance
						t_row = n
						
			t_row.highlight()
			if !process_running:
				_finished()
				return
			
			await prepare_cred_roll(t_row.highest_chance, t_row.u_name)
			if !process_running:
				_finished()
				return
			await get_tree().create_timer(1.0).timeout
			if !process_running:
				_finished()
				return
			if !safely_stop:
				_repeat_loop()
			else:
				_finished()

func prepare_cred_roll(chance: int, u_name: String):
	if !process_running:
		return
	status_updater.text = "ATTEMPTING MATCH USING HIGHEST CHANCE"
	status_title.text = "ATTEMPING MATCH"
	status_username.text = u_name
	status_pw.text = "****"
	
	var speed
	var heat
	if Stats.overclocked:
		speed = type["overclock speed"]
		heat = type["overclock heat"]
	elif Stats.overheated:
		speed = type["overheat speed"]
		heat = type["overheat heat"]
	else:
		speed = type["base speed"]
		heat = type["heat"]
		
	tween = create_tween()
	tween.tween_property(main_bar, "value", 100, speed * 3)
	await tween.finished
	if !process_running:
		return
	
	var roll = randi_range(1, 100)
	if roll > chance:
		#fail
		status_title.text = "FAILED"
		var og_box = third_col.get_theme_stylebox("panel").duplicate()
		og_box.border_color = f_border_col
		third_col.add_theme_stylebox_override("panel", og_box)
	else:
		Inventory.add_resource(type["resource gained"], 1)
		status_title.text = type["resource gained"]["name"].to_upper() + " ASSEMBLED"
		status_image.texture = cred_image
		var og_box = third_col.get_theme_stylebox("panel").duplicate()
		og_box.border_color = s_border_col
		third_col.add_theme_stylebox_override("panel", og_box)
		
	Stats.update_tempature(heat)
	type.signal.emit(1)
	Exp.add_xp(Matching, type, type["experience per level"])
	Signals.update_hud(Matching)

func _reset_rows():
	highest_roll = 0
	current_iteration = 0
	main_bar.value = 0
	status_image.texture = lock_image
	status_title.text = "AWAITING MATCH"
	status_username.text = "-"
	status_pw.text = "-"
	status_progress_bar.text = "success chance: -"
	if user_row_container.get_children().size() > 0:
		for n in user_row_container.get_children():
			n.queue_free()

func _build_rows():
	var random_user = RANDOM_USERNAMES.pick_random()
	userbox_name_label.text = random_user
	var variations = generate_username_variations(random_user)
	for i in range(USER_ROWS):
		var r = target_row.instantiate()
		var s = separator.instantiate()
		r.update(variations[i])
		r._hide()
		user_row_container.add_child(r)
		
		if i != USER_ROWS - 1:
			user_row_container.add_child(s)

func _get_current_row():
	for n in user_row_container.get_children():
		if n is PanelContainer:
			if n.current_state == n.MATCH_STATE.WAITING:
				return n
	return null


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
