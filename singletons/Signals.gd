extends Node

signal end_hacking_signal
signal system_temp_updated_signal
signal hacking_ended_signal
signal update_hacking_header_signal
signal end_hacking_safely_signal

#FILES WHERE end_hacking IS CONNECTED
#hacking.gd - updates current context from HACKING to PERSONS
#hacking_box.gd - handles changing screen from hacking process to list of persons at location
#hack_container.gd - sets hacking_active to false to bail from sequence hacking event
func end_hacking():
	end_hacking_signal.emit()

func system_temp_updated(temp: int):
	system_temp_updated_signal.emit(temp)

func hacking_ended():
	hacking_ended_signal.emit()

func end_hacking_safely():
	end_hacking_safely_signal.emit()

#hack_container.gd - called when exp, lvl, efficiency, resources etc. are updated
func update_hacking_header():
	update_hacking_header_signal.emit()
