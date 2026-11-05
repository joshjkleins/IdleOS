extends Node
## 2026-11-05: loss tip for 'decode -intel' when the target's intel isn't maxed
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for e in Tutorial.steps():
		if !Tutorial.completed_events.has(e): Tutorial.completed_events.append(e)
	var g = load("res://scripts/hacking_game.gd").new()
	var t = Stats.hacking_targets["Office"].targets[0] if Stats.hacking_targets.has("Office") else Stats.hacking_targets[Stats.hacking_targets.keys()[1]].targets[0]
	g.current_target = t
	print(">>> tutorial done=%s  maxed=%s  hint='%s'" % [Tutorial.is_tutorial_complete(), Decoding.is_intel_maxed(t), g._intel_hint()])
	g.free()
	get_tree().quit()
