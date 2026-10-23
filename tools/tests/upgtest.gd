extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	var bad = []
	for g in Upgrades.groups:
		for t in range(1, 7):
			var n = 0
			for p in Upgrades.group_packages(g):
				for l in p.levels: if int(l.tier) == t: n += 1
			if n != 10: bad.append("%s T%d=%d" % [g, t, n])
	print("tiers not 10: ", bad)
	var bg = Upgrades.packages["system.background_services"]
	for n in [0, 1, 2, 3, 6]:
		bg.installed = n; Upgrades._recompute(bg)
		print("BG %d installs -> offline cap %.0fh" % [n, Offline.cap_seconds() / 3600.0])
	Upgrades.load_data({"format": 2, "installed": {"system.background_services": 4, "compiling.mod_tuning": 2}})
	print("migrated: BG installed %d, code_signing %d (cur %.3f)" % [Upgrades.packages["system.background_services"].installed, Upgrades.packages["compiling.code_signing"].installed, Upgrades.cur("compiling.code_signing")])
	var km = Upgrades.packages["system.kernel_modules"]; km.installed = 3; Upgrades._recompute(km)
	print("Burst Buffer with Kernel Modules x3: lasts ", HackingMods.mod_duration(Items.BURST_BUFFER))
	get_tree().quit()
