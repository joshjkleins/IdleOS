extends Node
func _ready() -> void:
	print(">>> music default %s  bus db %.1f" % [Settings.get_value("music"), AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))])
	get_tree().quit()
