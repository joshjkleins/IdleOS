class_name HatIcon
extends Control
## 2026-11-02: the player's hat from the ending choice (Ending.choice), drawn small next to the SYSTEM title (root side
## panel and hacking header). Witch hat with a bent tip; the white hat is the black one mirrored (as in the cinematic).
## Hidden until the choice is made.

const C_WHITE := Color("#d7dde3")
const C_BLACK := Color("#e5484d") # the black hat is drawn red so it reads on the dark panels (same as the cinematic)

func _ready() -> void:
	custom_minimum_size = Vector2(22, 18)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS
	Ending.choice_changed.connect(_refresh)
	SaveManager.save_loaded.connect(_refresh)
	_refresh()

var fixed := "" # 2026-11-02: set to "white" / "black" to draw that hat instead of this game's (launcher cards)

func _choice() -> String:
	return fixed if fixed != "" else Ending.choice

func _refresh() -> void:
	visible = _choice() != ""
	tooltip_text = "White hat: you locked the launch codes away." if _choice() == "white" else "Black hat: you stole the launch codes."
	queue_redraw()

func _draw() -> void:
	if _choice() == "":
		return
	var col = C_WHITE if _choice() == "white" else C_BLACK
	var mirror = _choice() == "white"
	var w = size.x
	var h = size.y
	var pt = func(x: float, y: float) -> Vector2: # x, y in 0..1 of the box; mirrored for the white hat
		return Vector2((1.0 - x if mirror else x) * w, y * h)
	# cone with the tip bent to the side, then the brim
	var cone = PackedVector2Array([pt.call(0.30, 0.80), pt.call(0.45, 0.42), pt.call(0.52, 0.18), pt.call(0.60, 0.06),
		pt.call(0.74, 0.04), pt.call(0.64, 0.14), pt.call(0.60, 0.30), pt.call(0.66, 0.55), pt.call(0.72, 0.80)])
	if mirror:
		cone.reverse()
	draw_colored_polygon(cone, col)
	var brim = PackedVector2Array([pt.call(0.02, 0.86), pt.call(0.12, 0.76), pt.call(0.88, 0.76), pt.call(0.98, 0.86),
		pt.call(0.90, 0.96), pt.call(0.10, 0.96)])
	if mirror:
		brim.reverse()
	draw_colored_polygon(brim, col)
	draw_line(pt.call(0.31, 0.72), pt.call(0.71, 0.72), Color(0.04, 0.06, 0.07, 0.9), 1.5) # hat band
