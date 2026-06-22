extends VBoxContainer

@onready var defrag_panel = load("res://scenes/defrag_panel.tscn")
@onready var setup_sweep_timer = $SetupSweepTimer
@onready var main_sweep_timer = $MainSweepTimer

const SETUP_PANEL_WAIT   = 0.05   # time between each panel reveal
const SETUP_PANEL_TWEEN  = 0.2    # tween duration per panel in setup
const DEFRAG_PANEL_WAIT  = 0.1    # main_sweep_timer wait time
const DEFRAG_PANEL_TWEEN = 0.3    # tween duration per red panel fix
const ORGANIZE_PANEL_WAIT = 0.01  # delay between each panel in organize phase

var all_panels: Array = []
var red_panels: Array = []
var sweep_index: int = 1
var sweep_timer: Timer
var terminal_text: Array[String]
var active: bool = false
var type

const SECTOR_SPEED = {
	Color.RED:    3.0,
	Color.ORANGE: 1.8,
	Color.BLUE:   0.8,
	Color.BLACK:  0.0,
	Color.GREEN:  0.0,
}

# target order: green first, then blue, then yellow, then black at end
const COLOR_ORDER = [Color.GREEN, Color.BLUE, Color.ORANGE, Color.BLACK]

func start(minor_skill: Dictionary):
	type = minor_skill
	
	#finished()
	#return
	
	active = true
	setup_sweep_timer.wait_time = SETUP_PANEL_WAIT
	build_panels()
	#update_mini_terminal("Estimated time: " + _get_estimated_time_string()) 
	update_mini_terminal("Allocating memory")
	setup_sweep()

func stop():
	active = false
	if !setup_sweep_timer.is_stopped():
		setup_sweep_timer.stop()
	if !main_sweep_timer.is_stopped():
		main_sweep_timer.stop()
	Signals.defrag_finished()

func update_mini_terminal(text: String):
	if $PanelContainer/MarginContainer/LabelContainer.get_children().size() > 0:
		var old_label = $PanelContainer/MarginContainer/LabelContainer.get_child(-1)
		old_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	terminal_text.append(text)
	var label = Label.new()
	label.add_theme_font_size_override('font_size', 12)
	label.text = text
	$PanelContainer/MarginContainer/LabelContainer.add_child(label)


func build_panels():
	var colors = [Color.BLUE, Color.GREEN, Color.RED, Color.ORANGE, Color.BLACK]
	for i in range($DefragContainer.columns * 8):
		var panel = defrag_panel.instantiate()
		var color = colors[randi() % colors.size()]
		panel.color = color
		$DefragContainer.add_child(panel)
		all_panels.append(panel)
		if color == Color.RED:
			red_panels.append(panel)

func setup_sweep():
	setup_sweep_timer.start()

func reveal_panel_color(panel: Node, duration: float):
	if duration <= 0.0:
		return
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color.WHITE, duration)
	tween.tween_interval(duration)
	tween.tween_property(panel, "modulate", panel.color, duration)

func swap_panel_color(panel: Node, duration: float):
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color.WHITE, duration)
	await tween.finished
	var tween2 = create_tween()
	tween2.tween_property(panel, "modulate", panel.color, duration)
	await tween2.finished

func _get_estimated_time() -> float:
	var num_panels = $DefragContainer.columns * 8
	
	# Setup sweep: each panel takes setup_sweep_timer.wait_time + ~0.2s tween
	var setup_time = num_panels * (setup_sweep_timer.wait_time + SETUP_PANEL_TWEEN)
	
	# Main defrag: each red panel takes main_sweep_timer.wait_time + ~0.3s tween
	# Red panels are randomly ~1/5 of total (1 color out of 5)
	var expected_red = red_panels.size() if red_panels.size() > 0 else int(num_panels * SETUP_PANEL_TWEEN)
	var defrag_time = expected_red * (main_sweep_timer.wait_time + DEFRAG_PANEL_TWEEN)
	
	# Organize phase: two sweeps at 0.01s per panel each
	var organize_time = num_panels * ORGANIZE_PANEL_WAIT * 2
	
	return setup_time + defrag_time + organize_time

func _get_estimated_time_string() -> String:
	var seconds = _get_estimated_time()
	if seconds < 60:
		return "~%ds" % int(seconds)
	else:
		return "~%dm %ds" % [int(seconds / 60), int(fmod(seconds, 60))]

func _on_setup_sweep_timer_timeout():
	reveal_panel_color($DefragContainer.get_children()[sweep_index - 1], DEFRAG_PANEL_WAIT)
	sweep_index += 1
	if sweep_index <= all_panels.size():
		setup_sweep_timer.start()
	else:
		setup_sweep_finished()

func setup_sweep_finished():
	update_mini_terminal("Defragging sequence beginning")
	sweep_index = 0
	main_sweep_timer.start()

func _on_main_sweep_timer_timeout():
	if active:
		if red_panels.size() > 0:
			var cp = red_panels.pick_random()
			cp.color = Color.GREEN
			await swap_panel_color(cp, DEFRAG_PANEL_TWEEN)
			red_panels.erase(cp)
			main_sweep_timer.start()
		else:
			_on_defrag_complete()

func _on_defrag_complete():
	if active:
		sweep_index = 0
		organize_panels()

func organize_panels():
	var sorted: Array = []
	if active:
		update_mini_terminal("Organizing and optimizing memory")
		for color in COLOR_ORDER:
			for panel in all_panels:
				if panel.color == color:
					sorted.append(panel)

	if active:
		await all_white(sorted)
	if active:
		await all_colored(sorted)
		finished()

func all_white(sorted):
	sweep_index = sorted.size() - 1
	
	while sweep_index > 0:
		all_panels[sweep_index].modulate = Color.WHITE
		sweep_index -= 1
		await get_tree().create_timer(ORGANIZE_PANEL_WAIT).timeout

func all_colored(sorted: Array):
	sweep_index = 0
	while sweep_index < sorted.size():
		all_panels[sweep_index].modulate = sorted[sweep_index].color
		
		sweep_index += 1
		await get_tree().create_timer(ORGANIZE_PANEL_WAIT).timeout

func finished():
	update_mini_terminal("Defragging of " + type.skill.name + " complete: " + type.description)
	Stats.grant_bonus(type)
	Defragging.activate_cooldown()
	active = false
	Signals.defrag_finished()
