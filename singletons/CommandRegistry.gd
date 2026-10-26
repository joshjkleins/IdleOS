extends Node
## Tab auto-complete for the main terminal and the Hacking console (bash style, prefix-then-list):
##   one match        -> the input becomes it
##   several matches  -> the input grows to what they all share; if it can't grow, the options are listed
## Matching is start-of-string and case-insensitive. Candidates are whole commands (static ones plus ones
## built from the save: inventory items, caches, unlocked targets, upgrade ids, running VMs), so item names
## with spaces complete like any other word.

const SKILL_DIRS = ["mining", "parsing", "cracking", "matching", "phishing", "hacking", "decoding", "compiling", "defragging"]

## Commands that don't depend on the save
const STATIC = [
	"-h", "help", "info", "ls", "clear", "tree", "flow", "hint", "next", "lost", "utility", "cd root", "music", "music next", "music off", "music on", "date", "system", "settings", "history",
	"tutorial", "tutorial -l", "tutorial reset", "welcome", "discord", "discord -c", "version", "ps",
	"upload", "upload -a", "upload cancel ", "intel", "apt", "apt install ", "apt install all", "mod", "mods",
	"vm", "vm ls", "vm show -a", "vm hide -a", "vm kill -a", "ssh", "ssh -h", "process -h",
	"kill", "kill -s", "stop", "stop -s", "focus", "pin", "unpin", "overclock", "overclock -kill",
	"track ", "untrack ", "untrack -a", "trap", "trap collect", "panel", "cd ..", "quit", "quit -s", "wishlist",
]

func _skills() -> Array:
	return [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Defragging]

func _owned_items() -> Array:
	var out = []
	for it in Inventory.inventory:
		if it is ItemData and int(Inventory.inventory[it]) > 0:
			out.append(it)
	return out

func _n(item: ItemData) -> String:
	return item.name.to_lower()

## Every full command the main terminal could take right now
func main_candidates() -> Array:
	var c: Array = STATIC.duplicate()
	var owned = _owned_items()
	# navigation / info / ssh / apt per skill
	for d in SKILL_DIRS:
		c.append("cd " + d)
		c.append("cd ../" + d)
	for s in _skills() + [Hacking]:
		var d = s.SKILL.name.to_lower()
		c.append("info " + d)
		for mp in s.minor_processes:
			c.append("info %s %s" % [d, str(mp.name).to_lower().replace(" ", "-")])
		if s != Hacking and s != Defragging:
			c.append("ssh " + d) # lists the skill's VM commands; VM runs themselves mirror the main commands (below)
	for g in Upgrades.groups:
		c.append("apt " + g.to_lower())
		c.append("apt install " + g.to_lower())
	for id in Upgrades.packages:
		c.append("apt " + id)
		c.append("apt install " + id)
	# skill processes (they run from any directory) + their arguments
	for s in _skills():
		for mp in s.minor_processes:
			var cmd = str(mp.get("command", ""))
			if cmd == "":
				continue
			c.append(cmd + "=" if s == Parsing else cmd) # parse always takes an item
		for m in s.get("MODIFIERS") if s.get("MODIFIERS") else []:
			if !Upgrades.has(m.package):
				continue # only modifiers the player has
			c.append(m.command)
			c.append(m.command + " -kill")
	# 'ls' filters (2026-10-24): types, skills, locations and t1..t6
	for f in ["-resources", "-payloads", "-combat", "-caches", "-rares", "-mods", "-exploits", "-tokens", "-h"]:
		c.append("ls " + f)
	for sk in ["mining", "parsing", "cracking", "matching", "phishing", "hacking", "decoding", "compiling"]:
		c.append("ls -" + sk)
	for loc in Stats.hacking_targets:
		if !(" " in str(loc)): # 'ls police station' would be read as a search
			c.append("ls " + str(loc).to_lower())
	for t in range(1, 7):
		c.append("ls t%d" % t)
	# 'ls <item>' works for any item, owned or not (caches you haven't found yet, rares, tokens ...)
	for it in Items.ITEM_MAP.values():
		if it is ItemData and it.name != "":
			c.append("ls " + _n(it))
	for it in owned:
		var n = _n(it)
		c.append("track " + n)
		c.append("untrack " + n)
		if it.parsable:
			for mp in Parsing.minor_processes:
				c.append("%s=%s" % [mp.command, n])
		if it is CacheData:
			for p in ["decode -cache=", "decode -skim=", "decode -deep="]:
				c.append(p + n)
		if Decoding.is_salvageable(it):
			c.append("decode -salvage=" + n)

		if Phishing.is_bait(it): # bait: any basic resource
			for mp in Phishing.minor_processes:
				c.append("%s bait=%s" % [mp.command, n])
	for g in Uploads.get_goals():
		c.append("upload " + _n(g.item))
		c.append("ls " + _n(g.item))
	for it in Uploads.staged:
		c.append("upload cancel " + _n(it))
	for t in _unlocked_targets():
		c.append("decode -intel=" + t.name.to_lower())
		c.append("intel " + t.name.to_lower())
		c.append("phish -smish target=" + t.name.to_lower())
	for s in _skills():
		if s != Defragging and s != Cracking:
			c.append("crack -vm use=%s create=" % s.SKILL.name.to_lower())
	# ssh takes the same arguments as the main command: 'decode -intel=x' -> 'ssh decoding intel=x',
	# 'compile -mod=x' -> 'ssh compiling mod=x', 'phish -spear bait=x' -> 'ssh phishing spear bait=x'
	# 'ssh' + any process command runs it in a VM: 'ssh mine -logs', 'ssh parse -footprint=logs', 'ssh phish -spear bait=logs'
	for cmd in c.duplicate():
		var verb = str(cmd).get_slice(" ", 0)
		if verb in ["mine", "parse", "crack", "match", "phish", "decode", "compile"] and str(cmd).contains(" -"):
			c.append("ssh " + str(cmd))
	for vm in VMManager.vms:
		for a in ["show", "hide", "kill"]:
			c.append("vm %s %d" % [a, vm.vm_id])
	return c

## Hacking console: locations, targets, unlocks, one-time items
func hacking_candidates() -> Array:
	var c: Array = ["-h", "cd ..", "cd ~", "tutorial", "kill", "kill -s", "spoof", "overclock", "overclock -kill", "unlock", "run", "run auto ", "run auto off", "quit", "quit -s"]
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if l.get("unlocked", false):
			c.append(str(l.command))
			c.append(str(l.get("hard mode command", "")))
		for t in l.get("targets", []):
			if t.get("unlocked", false):
				for suf in ["", " -r", " -overclock", "="]:
					c.append(str(t.command) + suf)
			elif l.get("unlocked", false):
				c.append("unlock " + t.name.to_lower())
	for it in _owned_items():
		if it.get("exploit_id") != null and str(it.exploit_id) != "":
			c.append(_n(it) + " -force")
			c.append("run auto " + _n(it))
	return c

func _unlocked_targets() -> Array:
	var out = []
	for loc in Stats.hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in Stats.hacking_targets[loc].get(list, []):
				if t.get("unlocked", false) and list == "targets":
					out.append(t)
	return out

## {"text": the new input, "options": [what to list] (empty unless the input couldn't grow)}
func complete(text: String, hacking: bool = false) -> Dictionary:
	var typed = text.to_lower()
	var seen = {}
	var matches: Array = []
	for cand in (hacking_candidates() if hacking else main_candidates()):
		var low = str(cand).to_lower()
		if low != "" and low.begins_with(typed) and !seen.has(low):
			seen[low] = true
			matches.append(low)
	if matches.is_empty():
		return {"text": text, "options": []}
	var cp = _common_prefix(matches)
	if cp.length() > typed.length():
		return {"text": cp, "options": []}
	if matches.size() == 1:
		return {"text": text, "options": []}
	# can't grow: list what comes next after the last separator (space, '=', ',')
	var start = 0
	for sep in [" ", "=", ","]:
		start = max(start, typed.rfind(sep) + 1)
	if typed in matches:
		start = typed.length() # a whole command already: list what can follow it
	# list one word at a time, like bash: cut each option at its next '=' (kept) or ' -' flag; with no space typed
	# yet, or after a command whose arguments are single words (cd, info, ssh, apt, vm ...), also at the next space.
	# Item names (ls / track / upload ...) keep their spaces.
	var head = typed.split(" ", false)[0] if typed.contains(" ") else ""
	var word_args = head == "" or head in ["cd", "info", "ssh", "apt", "vm", "tutorial", "discord", "quit", "trap", "kill", "stop", "overclock", "view", "hack", "run"]
	var opts = []
	for m in matches:
		var rest = m.substr(start)
		var cut = rest.length()
		var eq = rest.find("=")
		if eq >= 0:
			cut = min(cut, eq + 1)
		var fl = rest.find(" -")
		if fl > 0:
			cut = min(cut, fl)
		var sp = rest.find(" ")
		if word_args and sp > 0:
			cut = min(cut, sp)
		rest = rest.substr(0, cut).strip_edges(true, false) if start == typed.length() else rest.substr(0, cut)
		if rest != "" and !(rest in opts):
			opts.append(rest)
	opts.sort()
	return {"text": text, "options": opts}

static func _common_prefix(words: Array) -> String:
	var p: String = words[0]
	for w in words:
		while !w.begins_with(p):
			p = p.substr(0, p.length() - 1)
	return p

## One dim line for the options (capped so a bare Tab doesn't flood the terminal)
func options_text(opts: Array, cap: int = 40) -> String:
	var shown = opts.slice(0, cap)
	var t = "  ".join(shown)
	if opts.size() > cap:
		t += "  ... +%d more" % (opts.size() - cap)
	return "[color=#888888]%s[/color]" % t
