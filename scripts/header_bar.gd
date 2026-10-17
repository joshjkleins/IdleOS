class_name HeaderBar
extends Control
## Segmented progress bar used by the header cards (same look as the SYSTEM heat bar).

@export var segments: int = 14
@export var gap: float = 2.0
var color: Color = Color.WHITE
var value: float = 0.0 : set = _set_value # 0..1
var _tween: Tween

const C_EMPTY = Color(1, 1, 1, 0.06)

func _set_value(v: float) -> void:
	value = clamp(v, 0.0, 1.0)
	queue_redraw()

## Smoothly move to a new value.
func animate_to(v: float, time: float = 0.35) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", clamp(v, 0.0, 1.0), time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Level-up sweep: fill to full, then drop to the new value.
func sweep_to(v: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_interval(0.35)
	_tween.tween_property(self, "value", 0.0, 0.0)
	_tween.tween_property(self, "value", clamp(v, 0.0, 1.0), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var seg_w = (size.x - gap * (segments - 1)) / segments
	var filled_exact = value * segments
	var filled = int(filled_exact)
	for i in segments:
		var rect = Rect2(i * (seg_w + gap), 0, seg_w, size.y)
		if i < filled:
			draw_rect(rect, color if i < filled - 1 else color.lightened(0.3))
		elif i == filled and filled_exact - filled > 0.0:
			draw_rect(rect, C_EMPTY)
			var part = rect
			part.size.x *= filled_exact - filled
			draw_rect(part, Color(color, 0.55))
		else:
			draw_rect(rect, C_EMPTY)
