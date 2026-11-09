extends Node
## 2026-11-09: queue templates - save / overwrite / list / load (slot limit) / delete / save round trip
func _ready() -> void:
	_run.call_deferred()
func _p(cmd: String) -> void:
	print(">>> %s\n    %s" % [cmd, ContextCommands.strip_bbcode(Queue.handle(cmd)).strip_edges().replace("\n", "\n    ")])
func _run() -> void:
	if !(1 in Uploads.completed_tiers): Uploads.completed_tiers.append(1)
	var keep = Queue.save_data()
	Queue.templates = {}
	Queue.handle("queue -rm -a")
	_p("queue -save farming")
	Queue.handle("queue -add mine -logs 25")
	Queue.handle("queue -add parse -footprint=logs 25")
	_p("queue -save Morning Run")
	_p("queue -save morning run")
	_p("queue -t")
	_p("queue -rm -a")
	_p("queue -load MORNING RUN")
	_p("queue -load nope")
	Queue.templates["big"] = {"name": "big", "steps": ["mine -logs 1", "mine -logs 2", "mine -logs 3", "mine -logs 4"]}
	_p("queue -load big")
	var d = Queue.save_data()
	Queue.templates = {}
	Queue.load_data(JSON.parse_string(JSON.stringify(d)))
	print(">>> after save/load round trip: %s" % str(Queue.templates.keys()))
	_p("queue -delete Big")
	_p("queue templates")
	print(">>> 'queue' help has -templates: %s" % ContextCommands.strip_bbcode(Queue.handle("queue")).contains("queue -templates"))
	Queue.load_data(keep)
	get_tree().quit()
