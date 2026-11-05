extends Node
## 2026-11-02: the end of the game. The first breach of the normal President (the last target of the last location)
## plays the ending cinematic once (scripts/ending_cinematic.gd): glitch-out, data grab, ACCESS GRANTED, the codes
## download, then the white hat / black hat choice. No skip, no replay. Then the outro (idle_os_2._ending_outro) on the
## next return to root (or the next load), typed like the intro with no skip, and the congrats notice in the terminal.

const DEV := false # dev commands: 'finish' (hacking: target integrity to 1) and 'ending reset'. Turn off before release.

enum {NONE, CINEMATIC, OUTRO, CONGRATS, DONE}
var state := NONE    # CINEMATIC = started but not finished (a quit mid-way replays it on the next load)
var choice := ""     # "white" (locked the codes away) or "black" (stole them)
var playing := false

signal choice_changed # the hat icon (HatIcon) next to the SYSTEM title

func _ready() -> void:
	SaveManager.save_loaded.connect(_on_save_loaded)

func save_data() -> Dictionary:
	return {"state": state, "choice": choice}

func load_data(d: Dictionary) -> void:
	state = int(d.get("state", NONE))
	choice = str(d.get("choice", ""))
	choice_changed.emit()

## the President at the Government: the last target of the last location (compromise fights never count)
func is_final_target(target: Dictionary) -> bool:
	if target.has("_base") or Stats.hacking_targets.is_empty():
		return false
	var last: Dictionary = Stats.hacking_targets.values().back().targets.back()
	return str(target.get("name", "")) == str(last.get("name", ""))

## hacking_game.win(): true when this breach starts the ending (the caller stops the run)
func should_trigger(target: Dictionary) -> bool:
	return state == NONE and !playing and is_final_target(target)

func start() -> void:
	if playing:
		return
	playing = true
	state = CINEMATIC
	SaveManager.save_game()
	var c = load("res://scripts/ending_cinematic.gd").new()
	c.finished.connect(_on_cinematic_finished)
	get_tree().root.add_child(c)

func _on_cinematic_finished(picked: String) -> void:
	playing = false
	choice = picked
	state = OUTRO
	choice_changed.emit()
	SaveManager.save_game()

signal outro_requested # idle_os_2 plays the outro (loaded with it still pending)

func _on_save_loaded() -> void:
	if state == CINEMATIC: # quit during the cinematic: play it again once the OS is up
		await get_tree().create_timer(3.0).timeout
		if state == CINEMATIC and !playing:
			start()
	elif state == OUTRO or state == CONGRATS: # quit before the outro / notice: show them once the OS is up
		await get_tree().create_timer(2.0).timeout
		outro_requested.emit()

func finish_outro() -> void:
	state = CONGRATS
	SaveManager.save_game()

func finish_congrats() -> void:
	state = DONE
	SaveManager.save_game()

func dev_reset() -> void:
	state = NONE
	choice = ""
	choice_changed.emit()
	SaveManager.mark_dirty()

#region texts (2026-11-02 drafts, Josh to edit)
const Y := "#e3b341"
const G := "#33ff33"
const D := "#5c6b7a"

func outro_text() -> String:
	var t = "Transmission received.\n\n"
	t += "You were given a terminal, a [color=%s]Student[/color] and a [color=%s]School[/color]. Nothing else.\n\n" % [Y, Y]
	t += "Since then you have walked through a law firm, a hospital, a bank and a police station. Tonight you walked out of the [color=%s]Government[/color] with the one file no one was ever supposed to touch.\n\n" % Y
	t += "We said you would be trusted with more. We did not expect this much.\n\n"
	if choice == "white":
		t += "You could have sold them. You could have kept them. You locked them away instead, and buried the key where no one, not even us, will ever find it.\n\n"
		t += "The world will never know how close it came, or who closed the door.\n\n"
	else:
		t += "The codes are yours now. Every agency on Earth is tearing itself apart looking for a ghost, and the ghost is you.\n\n"
		t += "We will not ask what you plan to do with them. Frankly, we would rather not know.\n\n"
	t += "That was the last door. There is no one left to prove anything to.\n\n"
	t += "You are the best there is."
	return t

func congrats_text() -> String:
	var bar = "════════════════════════════════════════"
	var t = "[color=%s]%s\nMISSION COMPLETE  ·  THE LAUNCH CODES\n%s[/color]\n" % [G, bar, bar]
	if choice == "white":
		t += "[color=#d7dde3]WHITE HAT[/color]  [color=%s]you locked the codes away[/color]\n\n" % D
	else:
		t += "[color=#e5484d]BLACK HAT[/color]  [color=%s]you stole the codes[/color]\n\n" % D
	t += "Congratulations, you finished IdleOS.\n\n"
	t += "[color=#4ec9b0]ONE LAST VICTORY LAP[/color]\n"
	t += "  · Max out every skill (level 99)\n"
	t += "  · Compromise the [color=%s]Government[/color] to earn [color=%s]Firmware[/color], the strongest upgrades in the game  [color=#666666](in Hacking: recon government)[/color]\n\n" % [Y, Y]
	t += "[color=%s]Thanks for playing.[/color]" % D
	return t
#endregion
