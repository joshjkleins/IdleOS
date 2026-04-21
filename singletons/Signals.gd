extends Node

signal end_hacking_signal

func end_hacking():
	end_hacking_signal.emit()
