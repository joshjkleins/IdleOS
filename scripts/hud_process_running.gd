extends VBoxContainer
## PROCESS section at the top of the side panel: what's running in the main terminal and for how long.
## API used by idle_os_2: process_started(skill, process) / process_killed().

const C_RUNNING = Color("#2d9e75")
const C_IDLE = Color(0.36, 0.42, 0.48, 1)

@onready var status_pill: PanelContainer = %StatusPill
@onready var status_label: Label = %StatusLabel
@onready var dot: ColorRect = %Dot
@onready var process_label: Label = %ProcessLabel
@onready var time_label: Label = %TimeLabel

var _start_time_msec: int = 0
var _timer_running: bool = false
var _pulse_tween: Tween

func _ready():
	_set_idle()

func _process(_delta):
	if _timer_running:
		_update_time_label()

func process_started(skill: Node, process: Dictionary):
	dot.color = skill.SKILL.color
	dot.visible = true
	process_label.text = "%s://%s" % [skill.SKILL.name.to_lower(), str(process.name).to_lower().replace(" ", "-")]
	process_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.91, 1))
	_set_status("RUNNING", C_RUNNING)
	_start_time_msec = Time.get_ticks_msec()
	_timer_running = true
	_update_time_label()
	_start_pulse()

func process_killed():
	_timer_running = false
	_stop_pulse()
	_set_status("STOPPED", C_IDLE)
	await get_tree().create_timer(2.0).timeout
	if !_timer_running: # a new process may have started during the 2s window
		_set_idle()

func _set_idle():
	dot.visible = false
	process_label.text = "idle  ·  cd <skill> to start"
	process_label.add_theme_color_override("font_color", Color(0.3, 0.34, 0.38, 1))
	time_label.text = ""
	_set_status("IDLE", C_IDLE)

func _set_status(text: String, color: Color):
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	var box: StyleBoxFlat = status_pill.get_theme_stylebox("panel").duplicate()
	box.border_color = color.darkened(0.25)
	box.bg_color = Color(color, 0.12)
	status_pill.add_theme_stylebox_override("panel", box)

func _update_time_label():
	var elapsed_sec := int((Time.get_ticks_msec() - _start_time_msec) / 1000.0)
	var hours := elapsed_sec / 3600
	var minutes := (elapsed_sec % 3600) / 60
	var seconds := elapsed_sec % 60
	time_label.text = "%d:%02d:%02d" % [hours, minutes, seconds] if hours > 0 else "%02d:%02d" % [minutes, seconds]

func _start_pulse():
	_stop_pulse()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(status_pill, "modulate:a", 0.55, 0.8).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(status_pill, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _stop_pulse():
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	status_pill.modulate.a = 1.0
