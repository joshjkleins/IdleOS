extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	var stu = Stats.hacking_targets["School"].targets[0]
	print("before: ", Decoding.intel_effect_text(stu))
	for k in 5: print(" find -> ", Compiling.debug_intel(Compiling.SCHOOL).get("name", "-"))
	print("after: ", Decoding.intel_effect_text(stu))
	print("lawfirm (locked): ", Compiling.debug_intel(Compiling.LAWFIRM))
	print(Compiling.MODIFIERS[0].effect)
	get_tree().quit()
