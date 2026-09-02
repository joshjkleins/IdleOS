extends Window

var repeat: bool = false
var duration: float = 0.0
var token: ItemData
var min_process: Dictionary
var maj_process: Node
var repeated_times: int = 1

var seconds_left: int = 0
var cooling_reduction: float = 0.0

func start():
	$Timer.wait_time = duration
	$Timer.one_shot = true
	$Timer.start()

	start_countdown(duration)

func start_countdown(seconds: int):
	seconds_left = seconds
	_update_title()

	$CountdownTimer.wait_time = 1.0
	$CountdownTimer.one_shot = false
	$CountdownTimer.start()

func _on_countdown_timer_timeout():
	seconds_left -= 1

	if seconds_left <= 0:
		$CountdownTimer.stop()
		_on_countdown_finished()
	else:
		_update_title()

#func _update_title():
	#self.title = maj_process.SKILL.name + " | " + min_process.name + " | Tokens used: " + str(repeated_times) + " | Remaining: " + str(seconds_left) + "s"

func _update_title(status: String = ""):
	var text = maj_process.SKILL.name + " | " + min_process.name + " | Tokens used: " + str(repeated_times)
	if status != "":
		text += " | " + status
	else:
		text += " | Remaining: " + str(seconds_left) + "s"
	self.title = text

func _on_countdown_finished():
	if repeat and Inventory.get_amount(token) > 0:
		start_countdown(int(ceil(duration)))  # loop

func _on_timer_timeout():
	if is_instance_valid(self):
		if repeat and Inventory.get_amount(token) > 0:
			repeated_times += 1
			Inventory.remove_resource(token, 1)
			$Timer.wait_time = duration
			$Timer.one_shot = true
			$Timer.start()
			start_countdown(int(ceil(duration)))  # <-- also resync CountdownTimer here
		else:
			_update_title("Stopping safely...")
			self.get_child(2).stop_safely()
	#if is_instance_valid(self):
		#if repeat and Inventory.get_amount(token) > 0:
			#repeated_times += 1
			#self.title = maj_process.SKILL.name + " | " + min_process.name + " | Tokens used: " + str(repeated_times)
			#Inventory.remove_resource(token, 1)
			#$Timer.wait_time = duration
			#$Timer.one_shot = true
			#$Timer.start()
		#else:
			#self.title = maj_process.SKILL.name + " | " + min_process.name + " | Tokens used: " + str(repeated_times) + " | Stopping safely..."
			#self.get_child(2).stop_safely() #2 (or whatever number) should be the child process added to this popup window. 

func set_time(time: float):
	duration = time

func set_token(vm_token: ItemData):
	token = vm_token

func set_repeat(rep: bool):
	repeat = rep

func set_processes(major: Node, minor: Dictionary):
	maj_process = major
	min_process = minor

func _on_focus_entered():
	pass

#func set_cooling_reduction(VM_COOLING_REDUCTION: float):
	#cooling_reduction = VM_COOLING_REDUCTION
	#Stats.update_cooling_amount(cooling_reduction)
#
#func remove_cooling_reduction():
	#Stats.update_cooling_amount(cooling_reduction * -1.0)
