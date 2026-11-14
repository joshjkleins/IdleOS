extends Node
## 2026-11-09: tab completes unlocked modifiers after a process command (terminal + queue -add)
func _ready() -> void:
	_run.call_deferred()
func _c(t: String) -> void:
	var r = CommandRegistry.complete(t)
	print(">>> '%s' -> '%s'  %s" % [t, r.text, r.options])
func _run() -> void:
	var keep = {}
	for id in ["mining.overclock", "mining.survey", "mining.sift", "mining.prospect"]:
		keep[id] = Upgrades.packages[id].installed
		Upgrades.packages[id].installed = 0
	print(">>> nothing unlocked:")
	_c("mine -logs o")
	_c("mine -logs ")
	Upgrades.packages["mining.overclock"].installed = 1
	print(">>> overclock unlocked:")
	_c("mine -logs o")
	_c("mine -logs 25 o")
	_c("mine -logs ov")
	_c("mine -logs overclock ")
	Upgrades.packages["mining.survey"].installed = 1
	Upgrades.packages["mining.sift"].installed = 1
	print(">>> + survey, sift:")
	_c("mine -logs s")
	_c("mine -logs ")
	_c("mine -lo")
	_c("queue -add mine -logs 10 o")
	for id in keep: Upgrades.packages[id].installed = keep[id]
	get_tree().quit()
