extends VBoxContainer

@onready var defrag_panel = load("res://scenes/defrag_panel.tscn")
@onready var setup_sweep_timer = $SetupSweepTimer
@onready var main_sweep_timer = $MainSweepTimer

var all_panels: Array = []
var red_panels: Array = []
var sweep_index: int = 1
var sweep_timer: Timer
var terminal_text: Array[String]
var active: bool = false

const SECTOR_SPEED = {
	Color.RED:    3.0,
	Color.ORANGE: 1.8,
	Color.BLUE:   0.8,
	Color.BLACK:  0.0,
	Color.GREEN:  0.0,
}

# target order: green first, then blue, then yellow, then black at end
const COLOR_ORDER = [Color.GREEN, Color.BLUE, Color.ORANGE, Color.BLACK]

func start():
	finished()
	#active = true
	#setup_sweep_timer.wait_time = 0.05
	#build_panels()
	#setup_sweep()

func stop():
	active = false
	if !setup_sweep_timer.is_stopped():
		setup_sweep_timer.stop()
	if !main_sweep_timer.is_stopped():
		main_sweep_timer.stop()
	Signals.defrag_finished()

func update_mini_terminal(text: String):
	terminal_text.append(text)
	$PanelContainer/MarginContainer/VBoxContainer/MiniTerminal.text = ""
	for i in terminal_text:
		$PanelContainer/MarginContainer/VBoxContainer/MiniTerminal.text += i + "\n"

func build_panels():
	update_mini_terminal("Allocating memory")
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
	tween.tween_property(panel, "modulate", Color.WHITE, 0.1)
	tween.tween_interval(0.1)
	tween.tween_property(panel, "modulate", panel.color, 0.1)

func swap_panel_color(panel: Node, duration: float):
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color.WHITE, 0.1)
	tween.tween_interval(0.1)
	tween.tween_property(panel, "modulate", panel.color, 0.1)
	await tween.finished


func _on_setup_sweep_timer_timeout():
	reveal_panel_color($DefragContainer.get_children()[sweep_index - 1], 0.1)
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
			await swap_panel_color(cp, 1.0)
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
		await get_tree().create_timer(0.01).timeout

func all_colored(sorted: Array):
	sweep_index = 0
	while sweep_index < sorted.size():
		all_panels[sweep_index].modulate = sorted[sweep_index].color
		
		sweep_index += 1
		await get_tree().create_timer(0.01).timeout

func finished():
	update_mini_terminal("Defragging finished, Mining efficiency x2 for 30 minutes")
	Mining.grant_bonus()
	active = false
	Signals.defrag_finished()
