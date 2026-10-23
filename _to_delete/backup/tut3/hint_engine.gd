class_name HintEngine
## 'hint' / 'next' / 'lost': reads the game state and suggests the next 1-3 commands, most important first.
## Each hint is {cmd, why}. Rules in priority order (first three that apply):
##   tutorial step · overheated · caches to decode · ready to hack · target access affordable · affordable upgrade ·
##   production bottleneck (forced in when the main terminal is idle) · spare VM tokens · upload surplus · next goal.
## Uploads only ever suggest the SURPLUS: what's left after the next upgrades and target unlocks are paid for
## (so a player never uploads the stock they need and has to rebuild the loop).

const GREEN := "#4ec994"
const DIM := "#888888"
const GOLD := "#ffc24a"
const MAX_HINTS := 3
const SQL_SAFETY := 1.25 # recommended SQL = expected use x this

const VERB_SKILL = {"mine": "mining", "parse": "parsing", "crack": "cracking", "match": "matching",
	"phish": "phishing", "decode": "decoding", "compile": "compiling"}

## os: the idle_os_2 node (what the main terminal is running)
static func text(os) -> String:
	var hints = build(os)
	var t = "\n[bgcolor=#1a2a1a][color=%s] NEXT STEPS [/color][/bgcolor]\n" % GREEN
	var w = 4
	for h in hints:
		w = max(w, h.cmd.length())
	w = min(w + 3, 44)
	for i in hints.size():
		var h = hints[i]
		var cmd = h.cmd if h.cmd != "" else "-"
		t += " [color=%s]%d[/color]  [color=%s]%s[/color]%s[color=%s]%s[/color]\n" % [DIM, i + 1, GREEN if h.cmd != "" else DIM, cmd,
			" ".repeat(max(2, w - cmd.length())), DIM, h.why]
	return t

static func build(os) -> Array:
	var out: Array = []
	var add = func(cmd: String, why: String):
		if out.size() < MAX_HINTS and !out.any(func(h): return h.cmd == cmd and cmd != ""):
			out.append({"cmd": cmd, "why": why})
	var tier = clamp(Uploads.current_tier(), 1, 6)
	var running = _running(os)
	# 1 tutorial: while it runs, its step is the hint (other hints could pull against it)
	if !Tutorial.is_tutorial_complete():
		var steps = Tutorial.steps()
		var i = TutorialWindow.current_page()
		if i < steps.size():
			add.call("tutorial", "step %d/%d: %s  (the tutorial window has the details)" % [i + 1, steps.size(), Tutorial.step_title(steps[i])])
			out.append({"cmd": "", "why": "more hints unlock once the tutorial is done"})
			return out
	# 2 overheated
	if Stats.overheated:
		add.call("apt system", "overheated: everything runs slower until it cools below 40°C; cooling upgrades are in apt system")
	# 3 caches waiting
	var caches = Inventory.inventory.keys().filter(func(i): return Inventory.item_type(i) == "cache" and Inventory.get_amount(i) > 0)
	if !caches.is_empty() and !running.has(Decoding):
		caches.sort_custom(func(a, b): return Exploits.cache_tier(a) > Exploits.cache_tier(b))
		var n = 0
		for c in caches: n += Inventory.get_amount(c)
		add.call("decode -cache=" + caches[0].name.to_lower(), "%d cache%s waiting: they hold most of your resources" % [n, "" if n == 1 else "s"])
	# 4 ready to hack
	var best = best_target()
	if !best.is_empty():
		var need = hack_needs(best)
		if need.ready:
			add.call(str(best.command), "you have what %s needs (%s): each hack drops a cache" % [best.name, need.summary])
	# 5 target access
	for t in _locked_targets():
		var r = Stats.get_access_recipe(t)
		if !r.is_empty() and r.rare != null and Inventory.get_amount(r.rare) >= int(r.rare_amount) and Inventory.get_amount(r.payload) >= int(r.payload_amount):
			add.call("unlock " + t.name.to_lower(), "you can afford access (%d %s + %d %s): a new target and its rares" % [int(r.rare_amount), r.rare.name, int(r.payload_amount), r.payload.name])
			break
	# 6 affordable upgrade
	var ready_pkgs = affordable_packages()
	if !ready_pkgs.is_empty():
		var p = ready_pkgs[0]
		var lvl = Upgrades.next_level(p)
		var why = "you can afford it: %s %s -> %s" % [p.name, lvl.get("before", ""), lvl.get("after", "")]
		if ready_pkgs.size() > 1:
			why += "  (%d packages ready, see 'apt')" % ready_pkgs.size()
		add.call("apt install " + str(p.id), why)
	# 7 production bottleneck
	var b = bottleneck(tier, best, os == null or !os.process_running)
	if !b.is_empty():
		if os != null and !os.process_running and out.size() >= MAX_HINTS:
			out.pop_back() # the main terminal is idle: getting something running beats the last hint
		add.call(b.cmd, b.why)
	# 8 spare VM tokens, nothing in VMs
	if VMManager.vms.is_empty() and !b.is_empty() and b.has("skill"):
		var tok = b.skill.vm_token
		if Inventory.get_amount(tok) > 0:
			add.call(ssh_cmd(b.cmd), "you have %d %s: run it in a VM alongside the main terminal" % [Inventory.get_amount(tok), tok.name])
	# 9 upload surplus
	var u = upload_hint()
	if !u.is_empty():
		add.call(u.cmd, u.why)
	# 10 fallback: the goal
	if out.is_empty():
		add.call("upload", "everything's running. %s goal: %d%% uploaded" % [Uploads.get_location_name(tier), goal_pct(tier)])
	return out

#region helpers
static func _plain(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]")
	return r.sub(s, "", true).replace("\n", " ").strip_edges()

## skills running right now (main terminal + VMs)
static func _running(os) -> Array:
	var r = []
	if os != null and os.process_running and !os.current_process_info.is_empty():
		for s in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Defragging]:
			if s.minor_processes.has(os.current_process_info):
				r.append(s)
	for vm in VMManager.vms:
		if vm.skill and !r.has(vm.skill):
			r.append(vm.skill)
	return r

static func goal_pct(tier: int) -> int:
	var got = 0; var need = 0
	for g in Uploads.get_goals(tier):
		got += min(Uploads.get_uploaded(g.item), g.amount); need += g.amount
	return int(100.0 * got / max(1, need))

## the strongest normal-mode target you can hack (unlocked location + target)
static func best_target() -> Dictionary:
	var best = {}
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if !l.get("unlocked", false):
			continue
		for t in l.get("targets", []):
			if t.get("unlocked", false):
				best = t
	return best

## {sql_have, sql_rec, payload, payload_have, payload_need, ready, summary}
static func hack_needs(t: Dictionary) -> Dictionary:
	var req = t.requirements
	var rec = recommended_sql(t)
	var sql = Inventory.get_amount(Items.SQL_INJECTOR)
	var have = Inventory.get_amount(req.item)
	return {"sql_have": sql, "sql_rec": rec, "payload": req.item, "payload_have": have, "payload_need": int(req.amount),
		"ready": have >= int(req.amount) and sql >= rec,
		"summary": "%d %s, %d SQL" % [int(req.amount), req.item.name, rec]}

## SQL Injectors one hack of <t> should take: your past hacks of it when there are any, else a no-reboot estimate
static func recommended_sql(t: Dictionary) -> int:
	var u = Stats.get_usage(t)
	if int(u.get("n", 0)) > 0:
		return int(ceil(float(u.sql) * SQL_SAFETY))
	var sql = Items.SQL_INJECTOR
	var dmg = float(sql.damage + Upgrades.cur("hacking.damage"))
	var fw_dmg = float(sql.firewall_damage + Upgrades.cur("hacking.firewall"))
	var hp = float(t.integrity); var fw = float(t.firewall); var n = 0
	while hp > 0.0 and n < 999:
		hp -= max(0.0, dmg - fw)
		fw = max(0.0, fw - fw_dmg)
		n += 1
	return int(ceil(n * SQL_SAFETY * 1.2)) # +20%: the firewall reboots in a real fight

static func _locked_targets() -> Array:
	var out = []
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if !l.get("unlocked", false):
			continue
		for t in l.get("targets", []):
			if !t.get("unlocked", false):
				out.append(t)
	return out

## packages whose next level can be installed now (lowest tier first)
static func affordable_packages() -> Array:
	var out = []
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		if Upgrades.install_block_reason(p) == "":
			out.append(p)
	out.sort_custom(func(a, b):
		var ta = int(Upgrades.next_level(a).tier); var tb = int(Upgrades.next_level(b).tier)
		if ta != tb: return ta < tb
		return _pkg_rank(a) < _pkg_rank(b))
	return out

## upgrade suggestion order within a tier: speed first, then hacking power, then the rest
static func _pkg_rank(p: Dictionary) -> int:
	var id = str(p.id)
	if id.ends_with(".speed"): return 0
	if id.begins_with("hacking.") and p.get("type", "") != "capstone": return 1
	if id.ends_with(".efficiency"): return 2
	if p.get("type", "") == "capstone": return 4
	return 3

## what the next upgrades and unlocks want: item -> amount (the stock uploads must not touch)
static func reserved() -> Dictionary:
	var r = {}
	for id in Upgrades.packages:
		var p = Upgrades.packages[id]
		var lvl = Upgrades.next_level(p)
		if lvl.is_empty() or !Upgrades.is_wired(p.group) or !Upgrades.tier_unlocked(int(lvl.tier)) or int(lvl.tier) > Upgrades.working_tier(p.group):
			continue
		for c in lvl.get("costs", []):
			var it = Upgrades.get_item(c.item)
			if it:
				r[it] = int(r.get(it, 0)) + int(c.amount)
	for t in _locked_targets():
		var a = Stats.get_access_recipe(t)
		if !a.is_empty() and a.rare != null:
			r[a.rare] = int(r.get(a.rare, 0)) + int(a.rare_amount)
			r[a.payload] = int(r.get(a.payload, 0)) + int(a.payload_amount)
	var best = best_target()
	if !best.is_empty():
		var req = best.requirements
		r[req.item] = int(r.get(req.item, 0)) + int(req.amount) * 3 # a few hacks' worth of payload
	return r

static func upload_hint() -> Dictionary:
	var res = reserved()
	var pick = {}
	for g in Uploads.get_goals():
		var still = Uploads.get_still_needed(g.item)
		if still <= 0:
			continue
		var spare = Inventory.get_amount(g.item) - int(res.get(g.item, 0))
		var n = min(spare, still)
		var worth = n >= (1 if g.rare else max(10, int(g.amount * 0.1)))
		if worth and (pick.is_empty() or g.rare and !pick.rare or n > pick.n):
			pick = {"item": g.item, "n": n, "rare": g.rare}
	if pick.is_empty():
		return {}
	return {"cmd": "upload %s %d" % [pick.item.name.to_lower(), pick.n],
		"why": "spare %s for the %s goal (keeps what your next upgrades and unlocks need)" % [pick.item.name, Uploads.get_location_name(Uploads.current_tier())]}

## Walks the tier's chain back from the payload: the furthest step you can run now, or SQL when that's what hacking lacks.
static func bottleneck(tier: int, best: Dictionary, idle: bool = true) -> Dictionary:
	if !best.is_empty():
		var need = hack_needs(best)
		if !idle and need.payload_have >= need.payload_need * 3 and need.sql_have >= need.sql_rec:
			return {} # stocked for a few hacks: leave room for other hints
		if need.payload_have >= need.payload_need and need.sql_have < need.sql_rec and Phishing.SPEAR.get("unlocked", false):
			return {"cmd": "phish -spear", "skill": Phishing, "why": "%s wants ~%d SQL Injectors, you have %d" % [best.name, need.sql_rec, need.sql_have]}
	var rows = AvailableSection.chain(tier)
	var procs = [Mining.minor_processes[tier - 1], Parsing.FOOTPRINT,
		Cracking.minor_processes.filter(func(p): return p != Cracking.VM)[tier - 1], Matching.minor_processes[tier - 1],
		Compiling.get_payload_processes()[tier - 1]]
	for i in range(rows.size() - 1, -1, -1):
		var r = rows[i]
		var p = procs[i]
		if p == null or !p.get("unlocked", false) or Exp.tier_block_reason(r.skill, p) != "":
			continue
		if AvailableSection.runs(r.needs) == 0:
			continue
		var cmd = str(p.command)
		if r.skill == Parsing:
			cmd += "=" + r.what.to_lower()
		var makes = p.get("resource gained")
		var made = makes.name if makes is ItemData else r.what
		if r.skill == Parsing:
			made = rows[2].what # footprint: the encrypted item Cracking takes (+ IP addresses)
		if i == rows.size() - 1:
			return {"cmd": cmd, "skill": r.skill, "why": "makes %s: what hacking %s costs" % [made, best.name if !best.is_empty() else "a target"]}
		var nxt = rows[i + 1]
		return {"cmd": cmd, "skill": r.skill, "why": "makes %s for %s (the next step toward a payload)" % [made, nxt.skill.SKILL.name]}
	return {}

## 'mine -logs' -> 'ssh mining logs', 'parse -footprint=logs' -> 'ssh parsing footprint=logs'
static func ssh_cmd(cmd: String) -> String:
	var verb = cmd.get_slice(" ", 0)
	if !VERB_SKILL.has(verb) or !cmd.contains(" -"):
		return cmd
	return "ssh %s %s" % [VERB_SKILL[verb], cmd.substr(cmd.find(" -") + 2)]
#endregion
