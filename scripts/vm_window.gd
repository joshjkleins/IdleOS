class_name VMWindow
extends PanelContainer
## In-game floating terminal for a VM process. Created by VMManager.open().
## Each VM token buys `duration` seconds of uptime; with repeat on, another token
## is consumed automatically when time runs out.

@onready var title_bar: PanelContainer = %TitleBar
@onready var dot: ColorRect = %Dot
@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var minimize_button: Button = %MinimizeButton
@onready var close_button: Button = %CloseButton
@onready var content: MarginContainer = %Content
@onready var run_timer: Timer = $RunTimer

var vm_id: int = 0
var skill: Node
var minor_process: Dictionary
var terminal: Control
var token: ItemData
var duration: float = 30.0
var repeat: bool = true
var tokens_used: int = 1
var token_cost: int = 1 # tokens per uptime period (VMManager.token_cost; set by the ssh command)
var stopping: bool = false

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _last_seconds: int = -1

func configure(id: int, p_skill: Node, p_minor: Dictionary, p_terminal: Control, p_repeat: bool) -> void:
	vm_id = id
	skill = p_skill
	minor_process = p_minor
	terminal = p_terminal
	token = p_skill.vm_token
	duration = p_skill.VM_UPTIME
	repeat = p_repeat

func _ready() -> void:
	content.add_child(terminal)
	title_label.text = "vm-%02d  %s://%s" % [vm_id, skill.SKILL.name.to_lower(), str(minor_process.name).to_lower().replace(" ", "-")]
	dot.color = skill.SKILL.color
	var frame: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	frame.border_color = skill.SKILL.color.darkened(0.45)
	add_theme_stylebox_override("panel", frame)
	title_bar.gui_input.connect(_on_title_bar_gui_input)
	minimize_button.pressed.connect(func(): VMManager.set_minimized(self, true); Signals.vm_window_focused())
	close_button.pressed.connect(func(): VMManager.release(self); Signals.vm_window_focused())
	run_timer.timeout.connect(_on_run_timer_timeout)
	# shrink-wrap to the terminal whenever its size needs change (a free-floating PanelContainer
	# only ever grows on its own; e.g. Phishing's wrapped label reports a huge height for one frame)
	minimum_size_changed.connect(_refit.call_deferred)

func _refit() -> void:
	if !is_inside_tree():
		return
	reset_size()
	position = VMManager._clamp_to_host(self, position)

## Seconds one token buys (skill uptime + Defragging: VM boost, checked each time a token is spent).
func _token_duration() -> float:
	duration = (skill.VM_UPTIME + Defragging.get_vm_uptime_bonus()) * Upgrades.vm_uptime_multiplier() # Scheduler
	return duration

func start() -> void:
	run_timer.start(_token_duration())
	_update_status()

func get_seconds_left() -> int:
	return int(ceil(run_timer.time_left)) if !run_timer.is_stopped() else 0

func get_progress() -> float: # 1.0 = full uptime remaining
	if run_timer.is_stopped() or duration <= 0.0:
		return 0.0
	return run_timer.time_left / duration

func get_status_text() -> String:
	if stopping:
		return "stopping"
	return "%ds  tok:%d" % [get_seconds_left(), tokens_used]

func _process(_delta: float) -> void:
	var s = get_seconds_left()
	if s != _last_seconds:
		_last_seconds = s
		_update_status()

func _update_status() -> void:
	status_label.text = get_status_text()

## Decoding: what the VM decodes now decides the cost (any-cache VMs move between tiers)
func _renew_cost() -> int:
	if skill == Decoding:
		var arg = terminal.get("target_arg") if terminal.get("target_arg") is Dictionary else terminal.get("current_cache")
		if arg == null:
			arg = terminal.get("target_cache")
		token_cost = VMManager.token_cost(skill, minor_process, arg)
	return token_cost

func _on_run_timer_timeout() -> void:
	var cost = _renew_cost()
	if repeat and Inventory.get_amount(token) >= cost:
		if !Upgrades.spend_vm_token(token, false, cost): # VM Snapshot can keep them (silent on renewals)
			tokens_used += cost
		run_timer.start(_token_duration())
	else:
		stopping = true
		_update_status()
		terminal.stop_safely()

func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			_dragging = false
			Signals.vm_window_focused() # hand keyboard focus back to the input line
	elif event is InputEventMouseMotion and _dragging:
		position = VMManager._clamp_to_host(self, get_global_mouse_position() - _drag_offset - get_parent().global_position)
