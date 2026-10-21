extends Control
## Box-and-arrow chart posted into the terminal like a process terminal.
##   'flow'                     -> show_loop(): the whole game loop
##   'info <skill> <process>'   -> show_recipe(): what one process's output is made from
## Everything is laid out in design units (1 unit = 1px at full size) and drawn scaled to the
## terminal's width. Fonts never go below MIN_FONT so it stays readable on narrow windows.

const BOX_W := 200.0
const BOX_H := 96.0
const COL_STEP := 296.0   # box + gap, recipe view
const ROW_STEP := 152.0
const PAD := 16.0
const BG := Color("#10161d")
const LINE := Color("#6b7a89")
const DIM_LINE := Color("#4a5866")
const LABEL := Color("#8b96a3")
const MUTED := Color("#5d6b79")
const GOAL := Color("#33ff33")
const SHORT := Color("#e24b4a")
const MIN_FONT := 11

var nodes := []    # {rect, title, sub, extra, color, extra_color, thick}
var edges := []    # {pts: PackedVector2Array, color, dashed, head}
var labels := []   # {at: Vector2 (center x, top y), text, color}
var design := Vector2.ZERO
var _s := 1.0
var _font: Font
var _bold: Font

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	_bold = load("res://fonts/ttf/JetBrainsMono-Bold.ttf")
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	if design.x <= 0.0 or size.x <= 0.0:
		return
	_s = min(1.0, size.x / design.x)
	var h = ceil(design.y * _s) + 8.0
	if abs(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size.y = h
	queue_redraw()

#region builders
func _box(x: float, y: float, title: String, sub: String, color: Color, extra := "", extra_color := MUTED, thick := false) -> void:
	nodes.append({"rect": Rect2(x, y, BOX_W, BOX_H), "title": title, "sub": sub, "extra": extra,
		"color": color, "extra_color": extra_color, "thick": thick})

func _edge(pts: Array, color := LINE, dashed := false, head := true) -> void:
	edges.append({"pts": PackedVector2Array(pts), "color": color, "dashed": dashed, "head": head})

func _label(cx: float, top: float, text: String, color := LABEL) -> void:
	labels.append({"at": Vector2(cx, top), "text": text, "color": color})

func _done() -> void:
	var r := Rect2()
	var first := true
	for n in nodes:
		r = n.rect if first else r.merge(n.rect)
		first = false
	for e in edges:
		for p in e.pts:
			r = r.expand(p)
	design = Vector2(r.end.x + PAD, r.end.y + PAD)
	_fit()
#endregion

## The whole game loop (same layout as the mockup).
func show_loop() -> bool:
	_clear()
	var o := Vector2(-48, -132) # mockup coordinates -> chart coordinates
	var b := func(x, y, t, s, c): _box(x + o.x, y + o.y, t, s, c)
	var e := func(pts: Array, c := LINE, dashed := false, head := true):
		_edge(pts.map(func(p): return p + o), c, dashed, head)
	var l := func(x, y, t, c := LABEL): _label(x + o.x, y + o.y, t, c)

	b.call(64, 232, "MINING", "logs", Mining.SKILL.color)
	b.call(360, 232, "PARSING", "usernames · IP addresses · encrypted passwords", Parsing.SKILL.color)
	b.call(656, 232, "CRACKING", "passwords", Cracking.SKILL.color)
	b.call(952, 232, "MATCHING", "credentials", Matching.SKILL.color)
	b.call(1248, 232, "COMPILING", "payloads (+ mods)", Compiling.SKILL.color)
	b.call(1248, 456, "HACKING", "breach targets, bank caches", Hacking.SKILL.color)
	b.call(952, 456, "DECODING", "resources · rares · tokens · packaging", Decoding.SKILL.color)
	b.call(656, 456, "UPLOADS", "the location's goal", Color("#e0c068"))
	b.call(360, 456, "NEXT LOCATION", "new targets · Tier N upgrades", GOAL)
	b.call(1248, 680, "PHISHING", "SQL injectors · packet spoofs · mods", Phishing.SKILL.color)
	b.call(1544, 456, "MODS", "equipped for hacks", Color("#d946ef"))

	# main chain
	e.call([Vector2(264, 280), Vector2(360, 280)])
	e.call([Vector2(560, 280), Vector2(656, 280)])
	e.call([Vector2(856, 280), Vector2(952, 280)])
	e.call([Vector2(1152, 280), Vector2(1248, 280)])
	e.call([Vector2(1348, 328), Vector2(1348, 456)])
	e.call([Vector2(1248, 488), Vector2(1152, 488)])
	e.call([Vector2(1152, 520), Vector2(1248, 520)])
	e.call([Vector2(952, 504), Vector2(856, 504)])
	e.call([Vector2(656, 504), Vector2(560, 504)])
	e.call([Vector2(360, 504), Vector2(164, 504), Vector2(164, 328)], GOAL)
	# shortcuts (dashed)
	e.call([Vector2(427, 232), Vector2(427, 176), Vector2(1348, 176), Vector2(1348, 232)], DIM_LINE, true)
	e.call([Vector2(493, 232), Vector2(493, 196), Vector2(1019, 196), Vector2(1019, 232)], DIM_LINE, true)
	# side inputs into hacking
	e.call([Vector2(1348, 680), Vector2(1348, 552)])
	e.call([Vector2(1448, 280), Vector2(1644, 280), Vector2(1644, 456)])
	e.call([Vector2(1448, 728), Vector2(1644, 728), Vector2(1644, 552)])
	e.call([Vector2(1544, 504), Vector2(1448, 504)])

	l.call(312, 252, "logs")
	l.call(608, 252, "encrypted")
	l.call(904, 252, "passwords")
	l.call(1200, 252, "credentials")
	l.call(756, 148, "IP addresses")
	l.call(756, 208, "usernames")
	l.call(1396, 383, "payloads")
	l.call(1200, 460, "caches")
	l.call(1200, 532, "intel")
	l.call(904, 476, "rares")
	l.call(608, 476, "goal done")
	l.call(216, 408, "next tier", GOAL)
	l.call(1276, 608, "SQL · spoofs")
	l.call(1680, 360, "mods")
	l.call(1680, 632, "mods")
	l.call(1496, 476, "equip")
	_done()
	return true

## What <process> (of <skill>) is made from, left to right ending at it. false when it has no inputs.
func show_recipe(skill, process: Dictionary) -> bool:
	_clear()
	if !(process.get("requirements") is Dictionary) or process.requirements.is_empty():
		return false
	var root_item = process.get("resource gained")
	var root := {"id": "root", "item": root_item if root_item is ItemData else null,
		"title": root_item.name if root_item is ItemData else process.name,
		"skill": skill, "inputs": process.requirements.keys().map(func(k): return [k, int(process.requirements[k])])}
	var info := {"root": root}       # id -> node info
	var order := []                  # pre-order ids
	_walk("root", info, order, 0)
	var height := {}
	for id in order:
		_height(id, info, height)
	var cols := {}
	for id in order:
		var c = height[id]
		if !cols.has(c):
			cols[c] = []
		cols[c].append(id)
	# inputs that skip columns go on the outside rows, so their line runs clear of the boxes between
	var reach := {}
	for id in order:
		for inp in info[id].inputs:
			var sid = _id(inp[0])
			reach[sid] = max(int(reach.get(sid, 0)), int(height[id]) - int(height[sid]))
	for c in cols:
		var tops := []
		var mids := []
		var bots := []
		for id in cols[c]:
			if int(reach.get(id, 0)) > 1:
				if tops.size() <= bots.size():
					tops.append(id)
				else:
					bots.append(id)
			else:
				mids.append(id)
		bots.reverse()
		cols[c] = tops + mids + bots
	var max_rows = 1
	for c in cols:
		max_rows = max(max_rows, cols[c].size())
	var mid = PAD + BOX_H / 2.0 + (max_rows - 1) * ROW_STEP / 2.0
	var pos := {}  # id -> Vector2 top-left
	for c in cols:
		var list: Array = cols[c]
		for i in list.size():
			var cy = mid + (i - (list.size() - 1) / 2.0) * ROW_STEP
			pos[list[i]] = Vector2(PAD + c * COL_STEP, cy - BOX_H / 2.0)
	# boxes
	for id in order:
		var n = info[id]
		var p: Vector2 = pos[id]
		var extra := ""
		var ec := MUTED
		if n.item != null:
			var have = Inventory.get_amount(n.item)
			extra = "have " + Inventory._ls_amount(have)
			if n.get("need", 0) > 0:
				extra += " · need %d" % n.need
				if have < n.need:
					ec = SHORT
		var col: Color = n.skill.SKILL.color if n.skill != null else Color.WEB_GRAY
		_box(p.x, p.y, n.title, n.skill.SKILL.name.to_lower() if n.skill != null else "", col, extra, ec, id == "root")
	# arrows: input -> consumer
	var bottom = 0.0
	for id in order:
		bottom = max(bottom, pos[id].y + BOX_H)
	var lanes = 0
	for id in order:
		var n = info[id]
		var t: Vector2 = pos[id]
		var ty = t.y + BOX_H / 2.0
		for inp in n.inputs:
			var sid = _id(inp[0])
			var s: Vector2 = pos[sid]
			var sx = s.x + BOX_W
			var sy = s.y + BOX_H / 2.0
			var span = int(round((t.x - s.x) / COL_STEP))
			if span <= 1:
				if is_equal_approx(sy, ty):
					_edge([Vector2(sx, sy), Vector2(t.x, ty)])
				else:
					var mx = sx + (COL_STEP - BOX_W) / 2.0
					_edge([Vector2(sx, sy), Vector2(mx, sy), Vector2(mx, ty), Vector2(t.x, ty)])
			else:
				var cx = t.x + BOX_W / 2.0
				var blocked := false
				for oid in order:
					var op: Vector2 = pos[oid]
					if op.x > s.x and op.x < t.x and sy > op.y - 8.0 and sy < op.y + BOX_H + 8.0:
						blocked = true
				if !blocked:
					var end_y = t.y if sy < ty else t.y + BOX_H
					_edge([Vector2(sx, sy), Vector2(cx, sy), Vector2(cx, end_y)])
				else: # around the bottom of the chart
					lanes += 1
					var ly = bottom + 28.0 * lanes
					var mx = sx + (COL_STEP - BOX_W) / 2.0
					_edge([Vector2(sx, sy), Vector2(mx, sy), Vector2(mx, ly), Vector2(cx, ly), Vector2(cx, t.y + BOX_H)])
	_done()
	return true

func _id(item) -> String:
	return str(item.get_instance_id()) if item is ItemData else str(item)

func _walk(id: String, info: Dictionary, order: Array, depth: int) -> void:
	order.append(id)
	if depth > 8:
		info[id].inputs = []
		return
	for inp in info[id].inputs:
		var item: ItemData = inp[0]
		var cid = _id(item)
		if !info.has(cid):
			var src = Inventory.producer(item)
			info[cid] = {"id": cid, "item": item, "title": item.name, "skill": src.get("skill"),
				"inputs": src.get("inputs", []), "need": 0}
			info[cid].need = max(int(info[cid].need), int(inp[1]))
			_walk(cid, info, order, depth + 1)
		else:
			info[cid].need = max(int(info[cid].get("need", 0)), int(inp[1]))

func _height(id: String, info: Dictionary, memo: Dictionary) -> int:
	if memo.has(id):
		return memo[id]
	var h = 0
	for inp in info[id].inputs:
		h = max(h, _height(_id(inp[0]), info, memo) + 1)
	memo[id] = h
	return h

func _clear() -> void:
	nodes.clear()
	edges.clear()
	labels.clear()

#region drawing
func _fs(base: float) -> int:
	return max(MIN_FONT, int(round(base * _s)))

func _draw() -> void:
	if design.x <= 0.0:
		return
	var s := _s
	var lw = max(1.5, 2.0 * s)
	for e in edges:
		var pts: PackedVector2Array = e.pts
		var sp := PackedVector2Array()
		for p in pts:
			sp.append(p * s)
		var head = max(7.0, 10.0 * s)
		if e.head and sp.size() >= 2:
			# stop the line under the head so the tip stays sharp
			var a = sp[sp.size() - 2]
			var b = sp[sp.size() - 1]
			var dir = (b - a).normalized()
			sp[sp.size() - 1] = b - dir * head * 0.6
		for i in sp.size() - 1:
			if e.dashed:
				draw_dashed_line(sp[i], sp[i + 1], e.color, lw, 6.0 * max(s, 0.7))
			else:
				draw_line(sp[i], sp[i + 1], e.color, lw, true)
		if e.head and pts.size() >= 2:
			var tip = pts[pts.size() - 1] * s
			var dir2 = (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized()
			var nrm = Vector2(-dir2.y, dir2.x)
			draw_colored_polygon(PackedVector2Array([tip, tip - dir2 * head + nrm * head * 0.5, tip - dir2 * head - nrm * head * 0.5]), e.color)
	for n in nodes:
		var r: Rect2 = n.rect
		var sr = Rect2(r.position * s, r.size * s)
		var sb := StyleBoxFlat.new()
		sb.bg_color = BG
		sb.border_color = n.color
		sb.set_border_width_all(2 if n.thick else 1)
		sb.set_corner_radius_all(int(max(3.0, 6.0 * s)))
		draw_style_box(sb, sr)
		_box_text(n, sr)
	var lf = _fs(13)
	for l in labels:
		var at: Vector2 = l.at * s
		var w = 400.0
		draw_string(_font, Vector2(at.x - w / 2.0, at.y + _font.get_ascent(lf)), l.text, HORIZONTAL_ALIGNMENT_CENTER, w, lf, l.color)

func _box_text(n: Dictionary, r: Rect2) -> void:
	var tf = _fs(15)
	var sf = _fs(13)
	var ef = _fs(12)
	var inner = r.size.x - 20.0 * _s
	var rows := []  # [text, font, size, color]
	var c: Color = n.color
	rows.append([n.title, _bold, tf, c.lightened(0.55 if c.get_luminance() < 0.4 else 0.35)])
	for line in _wrap(n.sub, _font, sf, inner):
		rows.append([line, _font, sf, Color("#d7dde4")])
	if n.extra != "":
		rows.append([n.extra, _font, ef, n.extra_color])
	var total = 0.0
	for row in rows:
		total += row[1].get_height(row[2]) + 2.0
	var y = r.position.y + (r.size.y - total) / 2.0
	for row in rows:
		var f: Font = row[1]
		draw_string(f, Vector2(r.position.x, y + f.get_ascent(row[2])), row[0], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, row[2], row[3])
		y += f.get_height(row[2]) + 2.0

func _wrap(text: String, f: Font, fs: int, max_w: float) -> Array:
	if text == "":
		return []
	var out := []
	var cur := ""
	for word in text.split(" "):
		var t = word if cur == "" else cur + " " + word
		if cur != "" and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
			out.append(cur)
			cur = word
		else:
			cur = t
	if cur != "":
		out.append(cur)
	return out
#endregion
