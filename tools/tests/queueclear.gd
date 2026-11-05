extends Node
## 2026-11-05: 'queue -clear' empties the queue
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	if !(1 in Uploads.completed_tiers): Uploads.completed_tiers.append(1)
	var keep = Queue.steps.duplicate()
	Queue.handle("queue -rm -a")
	Queue.handle("queue -add mine -logs 5")
	Queue.handle("queue -add mine -logs 6")
	print(">>> before %d  clear: %s  after %d" % [Queue.steps.size(), Queue.handle("queue -clear"), Queue.steps.size()])
	print(">>> help has -clear: %s" % str(Queue.handle("queue -h").contains("queue -clear")))
	Queue.steps = keep
	get_tree().quit()
