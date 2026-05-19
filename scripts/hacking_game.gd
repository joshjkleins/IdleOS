extends VBoxContainer

@onready var target_name_label = $TitleRow/HBoxContainer/TargetName
@onready var target_label_2 = $StatsRow/HBoxContainer2/EnemySide/HBoxContainer/TargetLabel2
@onready var status_label_box: PanelContainer = $TitleRow/HBoxContainer/StatusLabelBox
@onready var status_label: Label = $TitleRow/HBoxContainer/StatusLabelBox/MarginContainer/StatusLabel

@onready var attack_amount_label = $AttacksRow/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/AttackAmountLabel
@onready var defense_amount_label = $AttacksRow/HBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer/DefenseAmountLabel

@onready var anon_bar = $StatsRow/HBoxContainer2/PlayerSide/AnonBar
@onready var band_bar = $StatsRow/HBoxContainer2/PlayerSide/BandBar
@onready var integ_bar = $StatsRow/HBoxContainer2/EnemySide/IntegBar
@onready var strength_bar = $StatsRow/HBoxContainer2/EnemySide/StrengthBar
@onready var attack_bar = $AttacksRow/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/AttackBar
@onready var defense_bar = $AttacksRow/HBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/DefenseBar
@onready var counter_bar = $AttacksRow/HBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/CounterBar

@onready var yield_label = $BottomRow/HBoxContainer/YieldCol/YieldLabel
@onready var ip_label = $BottomRow/HBoxContainer/HBoxContainer/IPCol/IPLabel
@onready var cred_label = $BottomRow/HBoxContainer/HBoxContainer/CredCol/CredLabel

@onready var anon_label = $StatsRow/HBoxContainer2/PlayerSide/AnonLabel
@onready var band_label = $StatsRow/HBoxContainer2/PlayerSide/BandLabel
@onready var integ_label = $StatsRow/HBoxContainer2/EnemySide/IntegLabel
@onready var strength_label = $StatsRow/HBoxContainer2/EnemySide/StrengthLabel
@onready var labels_container = $BattleInfo/MarginContainer/ScrollContainer/LabelsContainer
@onready var scroll_container = $BattleInfo/MarginContainer/ScrollContainer
@onready var safe_exit_timer = $SafeExitTimer

var c_green: Color = Color("#2a9a5a")
var c_yellow: Color = Color("#c08020")
var c_blue: Color = Color("#2878c8")
var c_red: Color = Color("#d84040")
var c_white: Color = Color("#FFF")

var is_hacking: bool = false
var player_is_alive: bool = true
var attacking: bool = false
var ATTACK_SPEED: float = 10.0
var ATTACK_AMOUNT: int = 30
var ATTACK_HEAT: int = 3
var defending: bool = false
var DEFEND_SPEED: float = 5.0
var DEFEND_AMOUNT: int = 3
var DEFEND_HEAT: int = 3
var COUNTER_SPEED: float = 12.0
var COUNTER_AMOUNT: int = 2
var COUNTER_HEAT: int = 0
var EXP_AMOUNT: int = 0

var OVERCLOCK_VALUE: float = 1.0
var OVERHEAT_VALUE: float = 1.0
var NEXT_HEAT_APPLICATION: int = 0

var INTEGRITY_AMOUNT: int = 0
var target_reward
var target_name

var reward_amount: int = 0

#TODO:
#add bandwidth cost to combat items resource script
#just changed packet spoof and sql injector to 'combat items'
#also changed progress bar updates for bandwidth and firewall (update ICE strength to firewall in labels next)
#implement combat logic for bandwidth and firewall.
#implement efficiency (critical strike)


# make sure overclock is being stopped when "kill" command given (bug)
# add actual checks for ip & credentials when resetting after defeating enemy
# update HUD with exp
# add repurcusions to losing

# Attack as items (SQL Injectors, Cross site scripts, malware, ransomware, exploit, DDOS)
# Bandwidth as mana (10, injectors require 1) passively restores, attacks still fire if not enough bandwidth but goes really slow or does reduced dmg
# Enemy defense as defense (attack - enemy defense = dmg, then lower enemy defense) passively restores slowly
# EFFICIENCY: critical strike chance

func _ready():
	Signals.end_hacking_safely_signal.connect(kill_hack_safely)
	Signals.end_hacking_signal.connect(kill_hack)

func _process(delta):
	if is_hacking:
		if Stats.overclocked:
			OVERCLOCK_VALUE = 2.0 #x2 speed
			OVERHEAT_VALUE = 1.0
			NEXT_HEAT_APPLICATION = 2
		elif Stats.overheated:
			OVERCLOCK_VALUE = 0.5 #1/2 speed
			OVERHEAT_VALUE = 2.0 #2x speed for enemy
		else:
			OVERCLOCK_VALUE = 1.0
			OVERHEAT_VALUE = 1.0
		if attacking:
			attack_bar.value += ATTACK_SPEED * OVERCLOCK_VALUE * delta
		if defending:
			defense_bar.value += DEFEND_SPEED * OVERCLOCK_VALUE * delta
		if Stats.current_anon > 0:
			counter_bar.value += COUNTER_SPEED * OVERHEAT_VALUE * delta
		
		if attack_bar.value >= attack_bar.max_value:
			attack()
			attack_bar.value = 0.0
		
		if defense_bar.value >= defense_bar.max_value:
			defense()
			defense_bar.value = 0.0
			
		if counter_bar.value >= counter_bar.max_value:
			counter()
			counter_bar.value = 0.0

func setup(target: Dictionary):
	#set anonymity to 100%
	anon_bar.max_value = Stats.max_anon
	anon_bar.value = Stats.current_anon
	#set integrity
	integ_bar.max_value = target.integrity
	integ_bar.value = 0
	#bandwidth
	band_bar.max_value = Hacking.max_bandwidth
	band_bar.value = Hacking.current_bandwidth
	#set target
	target_name_label.text = "-"
	target_label_2.text = "-"
	integ_label.text = "--/--"
	#status_label.text = "finding target"
	update_status_label_badge("finding target", c_yellow)
	#update # of sql injectors (attacks) and packet spoofer (heal)
	attack_amount_label.text = "x" + str(Inventory.get_amount(Items.SQL_INJECTOR))
	defense_amount_label.text = "x" + str(Inventory.get_amount(Items.PACKET_SPOOF))
	
	attack_bar.value = 0
	defense_bar.value = 0
	counter_bar.value = 0
	
	update_bottom_row()
	#clear combat terminal
	if labels_container.get_children().size() > 0:
		for n in labels_container.get_children():
			n.queue_free()
	
	COUNTER_AMOUNT = target["counter"]
	COUNTER_HEAT = target["heat"]
	EXP_AMOUNT = target["exp"]
	INTEGRITY_AMOUNT = target["integrity"]
	target_reward = target["loot"]
	target_name = target["name"]
	if Inventory.get_amount(Items.PACKET_SPOOF) > 0:
		defending = true
	if Inventory.get_amount(Items.SQL_INJECTOR) > 0:
		attacking = true

func attack():
	integ_bar.value -= ATTACK_AMOUNT
	add_heat(ATTACK_HEAT)
	Inventory.remove_resource(Items.SQL_INJECTOR, 1)
	attack_amount_label.text = "x" + str(Inventory.get_amount(Items.SQL_INJECTOR))
	var info_text = "sql_injector fires - integrity -" + str(ATTACK_AMOUNT)
	_update_info_panel(info_text, c_green)
	if Inventory.get_amount(Items.SQL_INJECTOR) <= 0:
		attacking = false
	
	if integ_bar.value <= 0.0:
		win()

func defense():
	Stats.current_anon += DEFEND_AMOUNT
	add_heat(DEFEND_HEAT)
	anon_bar.value = Stats.current_anon
	Inventory.remove_resource(Items.PACKET_SPOOF, 1)
	defense_amount_label.text = "x" + str(Inventory.get_amount(Items.PACKET_SPOOF))
	var info_text = "packet_spoof increased anonymity - anonymity +" + str(DEFEND_AMOUNT)
	_update_info_panel(info_text, c_green)
	if Inventory.get_amount(Items.PACKET_SPOOF) <= 0:
		defending = false

func counter():
	Stats.current_anon -= COUNTER_AMOUNT
	add_heat(COUNTER_HEAT)
	if Stats.current_anon < 0.0:
		Stats.current_anon = 0.0
	anon_bar.value = Stats.current_anon
	var info_text = "countermeasures taken - -" + str(COUNTER_AMOUNT) + " anonymity"
	_update_info_panel(info_text, c_red)
	if Stats.current_anon <= 0.0:
		lose()

func add_heat(amount):
	if Stats.overheated:
		Stats.update_tempature(1)
		return
	if NEXT_HEAT_APPLICATION > 0:
		amount += NEXT_HEAT_APPLICATION
		NEXT_HEAT_APPLICATION = 0
	
	Stats.update_tempature(amount)

func lose():
	is_hacking = false
	attacking = false
	defending = false

func win():
	is_hacking = false
	attacking = false
	defending = false
	Inventory.add_resource(target_reward, 1)
	reward_amount += 1
	update_bottom_row()
	_update_info_panel("target successfully hacked. +1 " + target_reward.name, c_blue)
	Stats.add_xp(Stats.player_stats["Hacking"], EXP_AMOUNT)
	Signals.update_hacking_header()
	reset()

func reset():
	attack_bar.value = 0
	defense_bar.value = 0
	counter_bar.value = 0
	
	integ_bar.max_value = INTEGRITY_AMOUNT
	integ_label.text = "--/--"
	await prepare()
	#integ_bar.max_value = INTEGRITY_AMOUNT
	#integ_bar.value = INTEGRITY_AMOUNT
	start_hack()

func start_hack():
	is_hacking = true
	attacking = true
	defending = true

func _update_info_panel(message: String, color: Color):
	var label = Label.new()
	
	label.text = message
	
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	
	labels_container.add_child(label)
	
	if labels_container.get_children().size() > 50:
		labels_container.get_children()[0].queue_free()
		
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func kill_hack():
	end()
	Stats.current_anon -= 10.0
	Signals.hacking_ended()

func kill_hack_safely():
	safe_exit_timer.start()
	_update_info_panel("Attempting to exit safely in approx. 6 second", c_yellow)

func end():
	attacking = false
	defending = false
	is_hacking = false

func prepare():
	target_name_label.text = "-"
	target_label_2.text = "-"
	_update_info_panel("locating " + target_name, c_white)
	await get_tree().create_timer(1.0).timeout
	_update_info_panel("target found", c_white)
	await get_tree().create_timer(0.3).timeout
	#status_label.text = "gaining access"
	update_status_label_badge("gaining access", c_blue)
	await get_tree().create_timer(0.3).timeout
	target_name_label.text = target_name
	target_label_2.text = target_name
	await get_tree().create_timer(0.3).timeout
	_update_info_panel("using IP Address and Credentials to gain access", c_white)
	await get_tree().create_timer(0.2).timeout
	_update_info_panel("-1 credential", c_blue)
	_update_info_panel("-1 ip address", c_blue)
	update_bottom_row()
	await get_tree().create_timer(0.5).timeout
	Inventory.remove_resource(Items.IP_ADDRESS, 1)
	Inventory.remove_resource(Items.CREDENTIALS, 1)
	update_bottom_row()
	_update_info_panel("access granted", c_green)
	var tween = create_tween()
	tween.tween_property(integ_bar, "value", integ_bar.max_value, 1.0)
	await tween.finished
	await get_tree().create_timer(0.2).timeout
	_update_info_panel("starting hack", c_white)
	#status_label.text = "hacking"
	update_status_label_badge("hacking", c_green)
	

func _on_anon_bar_value_changed(value):
	anon_label.text = "anonymity " + str(int(value)) + "/" + str(Stats.max_anon)

func _on_band_bar_value_changed(value):
	band_label.text = "bandwidth " + str(int(value)) + "/" + str(int(band_bar.max_value))

func _on_integ_bar_value_changed(value):
	integ_label.text = "integrity " + str(int(value)) + "/" + str(int(integ_bar.max_value))

func _on_strength_bar_value_changed(value):
	strength_label.text = "firewall " + str(int(value)) + "/" + str(int(strength_bar.max_value))

func update_bottom_row():
	if reward_amount > 0:
		yield_label.text = target_reward.name + " x" + str(reward_amount)
	else:
		yield_label.text = ""
	
	var ip_amount = Inventory.get_amount(Items.IP_ADDRESS)
	var cred_amount = Inventory.get_amount(Items.CREDENTIALS)
	
	ip_label.text = "x" + str(ip_amount)
	cred_label.text = "x" + str(cred_amount)

func _on_safe_exit_timer_timeout():
	end()
	Signals.hacking_ended()

func update_status_label_badge(text: String, color: Color):
	var b = status_label_box.get_theme_stylebox("panel").duplicate()
	b.bg_color = color
	status_label.text = text
	status_label_box.add_theme_stylebox_override("panel", b)
