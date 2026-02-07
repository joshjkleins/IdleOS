extends VBoxContainer

# Data generating process
# Purpose: Runs idle to generate data (used as currency)
# 


@onready var process_title = $ProcessTitle
@onready var progress = $Progress
@onready var p_yield = $Yield
@onready var total = $Total

var total_gained: float = 0.0
var gained_per_process = 1.0

var process_running = false

var time_started = 0.0
var times_process_completed = 0

func start_process():
	time_started = Time.get_ticks_msec()
	total_gained = 0.0
	times_process_completed = 0
	visible = true
	process_running = true
	process_title.text = "Initializing basic process..."
	await get_tree().create_timer(0.5).timeout
	process_title.text = "Starting basic process"
	progress.text = "progress: [                    ] 0%"
	
	p_yield.text = "yield:    +0.3 data/sec"
	total.text = "total:    " + str(total_gained) + " data"
	
	
	var duration = 5.0 # total time in seconds
	var yield_amount = snapped(gained_per_process / duration, 0.1)
	p_yield.text = "yield:    +" + str(yield_amount) + " data/sec"
	var steps = 23
	var interval = duration / steps
	while process_running:
		for i in range(1, steps + 1):
			if process_running:
				await get_tree().create_timer(interval).timeout
				if process_running:
					var filled = "=".repeat(i)
					var empty = " ".repeat(steps - i)
					var percent = int(float(i) / steps * 100)
					progress.text = "[%s>%s] %d%%" % [filled, empty, percent]
					#process_info.text = "[%s>%s] %d%%" % [filled, empty, percent]
		
		total_gained += 1.0
		Inventory.total_data += 1.0
		total_gained = snapped(total_gained, 0.1)
		times_process_completed += 1
		# Process complete
		progress.text = "[======================] 100%"
		#update_last_line("[====================] 100% [color=#4caf50]Process complete! Gained: 10 data[/color]")
		total.text = "total:    " + str(total_gained) + " data"


func stop_process():
	process_running = false
	visible = false
	var summary = get_process_summary()
	return summary

func get_process_summary():
	var elapsed = Time.get_ticks_msec() - time_started
	var readable_time = format_time(elapsed)
	
	return """\nProcessInfo:
time elapsed     """+str(readable_time)+"""
data gained      """+str(total_gained)+"""
times completed  """+str(times_process_completed)+"""
"""


func format_time(total_msec: int) -> String:
	var msec = total_msec % 1000
	var seconds = (total_msec / 1000) % 60
	var minutes = (total_msec / (1000 * 60)) % 60
	var hours = (total_msec / (1000 * 60 * 60))
	
	# %02d pads to 2 digits, %03d pads to 3 digits
	return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, msec]
