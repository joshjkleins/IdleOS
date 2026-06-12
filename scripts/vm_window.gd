extends Window

var repeat: bool = false
var duration: float = 0.0
var token: ItemData
var min_process: Dictionary
var maj_process: Node
var repeated_times: int = 1

func start():
	transparent = true
	transparent_bg = true
	#modulate.a = 0.5
	$Timer.wait_time = duration
	$Timer.one_shot = true
	$Timer.start()

func _on_timer_timeout():
	if is_instance_valid(self):
		if repeat and Inventory.get_amount(token) > 0:
			repeated_times += 1
			self.title = maj_process.SKILL.name + " | " + min_process.name + " | Tokens used: " + str(repeated_times)
			Inventory.remove_resource(token, 1)
			$Timer.wait_time = duration
			$Timer.one_shot = true
			$Timer.start()
		else:
			self.get_child(1).stop_safely()

func set_time(time: float):
	duration = time

func set_token(vm_token: ItemData):
	token = vm_token

func set_repeat(rep: bool):
	repeat = rep

func set_processes(major: Node, minor: Dictionary):
	maj_process = major
	min_process = minor
