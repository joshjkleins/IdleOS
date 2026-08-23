extends PanelContainer

@onready var skill_name = $MarginContainer/CenterContainer/HBoxContainer/SkillName
@onready var process_name = $MarginContainer/CenterContainer/HBoxContainer/ProcessName
@onready var time_label = $MarginContainer/CenterContainer/TimeLabel
@onready var running_label = $MarginContainer/CenterContainer/RunningLabel

var _start_time_msec: int = 0
var _timer_running: bool = false
var _pulse_tween: Tween

func _ready():
	visible = false

func _process(_delta):
	if _timer_running:
		_update_time_label()

func process_started(skill: Node, process: Dictionary):
	_update_labels(skill, process)
	_start_timer()
	_start_pulse()
	_show()

func _update_labels(skill: Node, process: Dictionary):
	var col = skill.SKILL.color.to_html()
	skill_name.text = "[color=#%s]%s[/color]" % [col, skill.SKILL.name]
	process_name.text = process.name

func _start_timer():
	_start_time_msec = Time.get_ticks_msec()
	_timer_running = true
	_update_time_label()

func _update_time_label():
	var elapsed_sec := int((Time.get_ticks_msec() - _start_time_msec) / 1000.0)
	var hours := elapsed_sec / 3600
	var minutes := (elapsed_sec % 3600) / 60
	var seconds := elapsed_sec % 60
	if hours > 0:
		time_label.text = "%d:%02d:%02d" % [hours, minutes, seconds]
	else:
		time_label.text = "%02d:%02d" % [minutes, seconds]

func _start_pulse():
	_stop_pulse()
	running_label.modulate = Color.WHITE
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(running_label, "modulate", Color(0.0, 0.8, 0.2), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(running_label, "modulate", Color(0.3, 1.0, 0.5), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_pulse():
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	running_label.modulate = Color.WHITE

func process_killed():
	_stop_timer()
	_stop_pulse()
	await get_tree().create_timer(2.0).timeout
	_hide()

func _stop_timer():
	_timer_running = false

func _hide():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false

func _show():
	self.modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished
