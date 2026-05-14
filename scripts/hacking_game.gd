extends VBoxContainer

@onready var target_name = $TitleRow/HBoxContainer/TargetName
@onready var target_label_2 = $StatsRow/HBoxContainer2/EnemySide/HBoxContainer/TargetLabel2

@onready var status_label = $TitleRow/HBoxContainer/StatusLabel
@onready var attack_amount_label = $AttacksRow/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/AttackAmountLabel
@onready var defense_amount_label = $AttacksRow/HBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/HBoxContainer/DefenseAmountLabel

@onready var anon_bar = $StatsRow/HBoxContainer2/PlayerSide/AnonBar
@onready var band_bar = $StatsRow/HBoxContainer2/PlayerSide/BandBar
@onready var integ_bar = $StatsRow/HBoxContainer2/EnemySide/IntegBar
@onready var strength_bar = $StatsRow/HBoxContainer2/EnemySide/StrengthBar
@onready var attack_bar = $AttacksRow/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/AttackBar
@onready var defense_bar = $AttacksRow/HBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/DefenseBar
@onready var counter_bar = $AttacksRow/HBoxContainer/PanelContainer3/MarginContainer/VBoxContainer/CounterBar

@onready var anon_label = $StatsRow/HBoxContainer2/PlayerSide/AnonLabel
@onready var band_label = $StatsRow/HBoxContainer2/PlayerSide/BandLabel
@onready var integ_label = $StatsRow/HBoxContainer2/EnemySide/IntegLabel
@onready var strength_label = $StatsRow/HBoxContainer2/EnemySide/StrengthLabel
@onready var labels_container = $BattleInfo/MarginContainer/ScrollContainer/LabelsContainer
@onready var scroll_container = $BattleInfo/MarginContainer/ScrollContainer

var c_green: Color = Color("#2a9a5a")
var c_yellow: Color = Color("#c08020")
var c_blue: Color = Color("#2878c8")
var c_red: Color = Color("#d84040")

var is_hacking: bool = false
var player_is_alive: bool = true
var attacking: bool = false
var ATTACK_SPEED: float = 10.0
var ATTACK_AMOUNT: int = 3
var defending: bool = false
var DEFEND_SPEED: float = 5.0
var DEFEND_AMOUNT: int = 3
var COUNTER_SPEED: float = 12.0
var COUNTER_AMOUNT: int = 2

#TODO:
#temp, exp, overclock, stop, stop safe, bottom row updates (yield), header
#update 'hacking''completed''lost' badges in top right
#update target titles to show location + target
#think about adding more clarity on how much damage/defense is happening 

#figure out: 
#efficiency
#bandwidth (or second bar) idea: bandwidth needs to be larger than ice strength? if ice strength is larger then sql injection goes super slow
#ICE strength (second enemy bar)
#how to obtain sql injectors and packet spoofers
#figure out what to do with IP addresses and Credentials now


#func _ready():
	#setup(Stats.hacking_targets["School"]["targets"][0])
	#start_hack()

func _process(delta):
	if is_hacking:
		if attacking:
			attack_bar.value += ATTACK_SPEED * delta
		if defending:
			defense_bar.value += DEFEND_SPEED * delta
		if Stats.current_anon > 0:
			counter_bar.value += COUNTER_SPEED * delta
		
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
	integ_bar.value = target.integrity
	#set target
	target_name.text = target.name
	target_label_2.text = target.name
	status_label.text = "hacking"
	#update # of sql injectors (attacks) and packet spoofer (heal)
	attack_amount_label.text = "x" + str(Inventory.get_amount(Items.SQL_INJECTOR))
	defense_amount_label.text = "x" + str(Inventory.get_amount(Items.PACKET_SPOOF))
	
	attack_bar.value = 0
	defense_bar.value = 0
	counter_bar.value = 0
	
	COUNTER_AMOUNT = target["counter"]
	if Inventory.get_amount(Items.PACKET_SPOOF) > 0:
		defending = true
	if Inventory.get_amount(Items.SQL_INJECTOR) > 0:
		attacking = true
	
	start_hack()

func attack():
	integ_bar.value -= ATTACK_AMOUNT
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
	anon_bar.value = Stats.current_anon
	Inventory.remove_resource(Items.PACKET_SPOOF, 1)
	attack_amount_label.text = "x" + str(Inventory.get_amount(Items.PACKET_SPOOF))
	var info_text = "packet_spoof increased anonymity - anonymity +" + str(DEFEND_AMOUNT)
	_update_info_panel(info_text, c_green)
	if Inventory.get_amount(Items.PACKET_SPOOF) <= 0:
		defending = false

func counter():
	Stats.current_anon -= COUNTER_AMOUNT
	if Stats.current_anon < 0.0:
		Stats.current_anon = 0.0
	anon_bar.value = Stats.current_anon
	var info_text = "countermeasures taken - -" + str(COUNTER_AMOUNT) + " anonymity"
	_update_info_panel(info_text, c_red)
	if Stats.current_anon <= 0.0:
		lose()

func lose():
	is_hacking = false
	attacking = false
	defending = false

func win():
	pass
	#get reward
	#reset and go again

func start_hack():
	is_hacking = true

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
	#stop hack right away, take a loss to anonymity
	pass

func kill_hack_safely():
	#stop hack after a countdown? or maybe after defeating the enemy
	pass


func _on_anon_bar_value_changed(value):
	var percent = value / anon_bar.max_value * 100
	anon_label.text = "anonymity " + str(int(percent)) + "%"

func _on_band_bar_value_changed(value):
	var percent = value / band_bar.max_value * 100
	band_label.text = "bandwidth " + str(int(percent)) + "%"

func _on_integ_bar_value_changed(value):
	var percent = value / integ_bar.max_value * 100
	integ_label.text = "integrity " + str(int(percent)) + "%"

func _on_strength_bar_value_changed(value):
	var percent = value / strength_bar.max_value * 100
	strength_label.text = "strength " + str(int(percent)) + "%"
