extends VBoxContainer

@onready var overclock_bar = $OverclockBar
@onready var overclock_timer = $OverclockTimer
@onready var time_label = $HBoxContainer/TimeLabel

var OVERCLOCKING = false
var CAN_OVERCLOCK = true

func _ready():
	overclock_bar.max_value = 5.0
	overclock_bar.value = overclock_bar.max_value

func _process(delta):
	#drain
	if OVERCLOCKING and overclock_bar.value > 0.0:
		overclock_bar.value -= delta
		
		if overclock_bar.value <= 0.0:
			overclock_bar.value = 0.0
			end_overclock()
	#fill
	elif !OVERCLOCKING and overclock_bar.value < overclock_bar.max_value:
		overclock_bar.value += delta / 4.0
		print(overclock_bar.value)
		if overclock_bar.value >= overclock_bar.max_value:
			overclock_bar.value = overclock_bar.max_value
			CAN_OVERCLOCK = true

func use_overclock(module: Dictionary):
	if CAN_OVERCLOCK:
		CAN_OVERCLOCK = false
		module["current speed"] = module["overclock speed"]
		OVERCLOCKING = true

func end_overclock():
	OVERCLOCKING = false
	Stats.player_stats["Log Parsing"]["current speed"] = Stats.player_stats["Log Parsing"]["base speed"]


func _on_overclock_bar_value_changed(value):
	time_label.text = "%.2f seconds" % value
