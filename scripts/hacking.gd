extends MarginContainer

signal start_loading

@onready var header_hacking_box: Control = $VBoxContainer/HeaderHackingBox
@onready var player_hacking_box: Control = $VBoxContainer/HBoxContainer/PlayerHackingBox
@onready var enemy_hacking_box: Control = $VBoxContainer/HBoxContainer/HackingBox

enum HackingContext {
	TARGETS,
	PERSONS,
	HACKING
}

var current_context: HackingContext = HackingContext.TARGETS

func _ready():
	header_hacking_box.update_header()
	enemy_hacking_box.update_targets()
	

func module_loaded():
	header_hacking_box.update_header()
	enemy_hacking_box.update_targets()
	
	modulate.a = 0.0
	visible = true
	player_hacking_box.grab()
	player_hacking_box.clear()
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 1.0, 0.5)


func go_to_root() -> void:
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween2.finished
	visible = false
	
	start_loading.emit()


func _on_player_hacking_box_command_entered(text):
	match current_context:
		HackingContext.TARGETS:
			if text.begins_with("view"):
				handle_view_command(text)
				return
			
			match text:
				"root":
					go_to_root()
		HackingContext.PERSONS:
			if text.begins_with("hack"):
				handle_hack_command(text)
				return
			
			match text:
				"..":
					handle_back_command()
		HackingContext.HACKING:
			#if text.begins_with("hack"):
				#handle_hack_command(text)
				#return
			
			match text:
				"..":
					handle_back_command()
	

func handle_hack_command(text):
	var target: Dictionary = Stats.get_hacking_target_by_command(text)
	if target != null:
		await enemy_hacking_box.select_person(target)
		current_context = HackingContext.HACKING
	else:
		print("Not valid view target")

func handle_back_command():
	match current_context:
		HackingContext.PERSONS:
			await enemy_hacking_box.persons_to_targets()
			current_context = HackingContext.TARGETS
		HackingContext.HACKING:
			await enemy_hacking_box.hacking_to_persons()
			current_context = HackingContext.PERSONS

func handle_view_command(text):
	var target: Dictionary = Stats.get_hacking_location_by_command(text)
	if target != null:
		await enemy_hacking_box.select_target(target)
		current_context = HackingContext.PERSONS
	else:
		print("Not valid view target")
