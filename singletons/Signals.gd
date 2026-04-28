extends Node

signal end_hacking_signal
signal system_temp_updated_signal

func end_hacking():
	end_hacking_signal.emit()

func system_temp_updated(temp: int):
	system_temp_updated_signal.emit(temp)
