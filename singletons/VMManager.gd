extends Node
## Owns every running VM window: opening, VM counts, minimize/restore and closing.
## Skill singletons call open(); terminals call release(self) when their VM run ends.

signal vms_changed

const VM_WINDOW_SCENE = preload("res://scenes/vm_window.tscn")
const CASCADE_STEP = Vector2(28, 28)

var host: Control          # layer the windows are added to (set by idle_os_2)
var vms: Array[VMWindow] = []
var _next_id: int = 1

func set_host(layer: Control) -> void:
	host = layer

## skill: Mining, Parsing, etc. terminal: un-added terminal instance.
## setup: called with the terminal once it is in the tree (set type + start it).
func open(skill: Node, minor_process: Dictionary, terminal: Control, setup: Callable, repeat: bool = true) -> VMWindow:
	var window: VMWindow = VM_WINDOW_SCENE.instantiate()
	window.configure(_next_id, skill, minor_process, terminal, repeat)
	_next_id += 1
	host.add_child(window)
	vms.append(window)
	skill.CURRENT_VMS += 1
	Stats.CURRENT_ALL_VMS += 1
	setup.call(terminal)
	window.start()
	window.reset_size() # shrink-wrap to the terminal's minimum size
	window.position = _spawn_position(window)
	vms_changed.emit()
	return window

## Ends a VM. Accepts the window or any node inside it (terminals pass self).
func release(node: Node) -> void:
	var window := _find_window(node)
	if window == null or !vms.has(window):
		return
	vms.erase(window)
	window.skill.CURRENT_VMS = max(0, window.skill.CURRENT_VMS - 1)
	Stats.remove_vm_count(1)
	window.queue_free()
	if vms.is_empty():
		_next_id = 1
	vms_changed.emit()

func get_vm(id: int) -> VMWindow:
	for vm in vms:
		if vm.vm_id == id:
			return vm
	return null

func set_minimized(window: VMWindow, minimized: bool) -> void:
	window.visible = !minimized
	if !minimized:
		window.position = _clamp_to_host(window, window.position)
		window.move_to_front()
	vms_changed.emit()

func toggle(window: VMWindow) -> void:
	set_minimized(window, window.visible)

func set_all_minimized(minimized: bool) -> void:
	for vm in vms:
		vm.visible = !minimized
	vms_changed.emit()

func _find_window(node: Node) -> VMWindow:
	while node != null:
		if node is VMWindow:
			return node
		node = node.get_parent()
	return null

func _spawn_position(window: VMWindow) -> Vector2:
	# cascade down-left from the top right of the terminal area
	var visible_count = 0
	for vm in vms:
		if vm != window and vm.visible:
			visible_count += 1
	var start = Vector2(host.size.x - window.size.x - 320.0, 110.0)
	return _clamp_to_host(window, start + Vector2(-CASCADE_STEP.x, CASCADE_STEP.y) * (visible_count % 8))

func _clamp_to_host(window: Control, pos: Vector2) -> Vector2:
	var max_pos = host.size - window.size
	return Vector2(clamp(pos.x, 0.0, max(0.0, max_pos.x)), clamp(pos.y, 0.0, max(0.0, max_pos.y)))
