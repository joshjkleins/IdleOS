extends CanvasLayer
## 2026-11-02: the ending cinematic (Ending.start, once, after the first breach of the normal President).
## Pauses the game; no skip. 1) the whole screen glitches and dissolves to black, 2) a terminal fills with the data
## grab, 3) ACCESS GRANTED + the launch codes download, 4) white hat / black hat: type 'lock' or 'steal',
## 5) the answer, then the glitch runs backwards and the HUD returns. Emits finished("white" | "black").

signal finished(choice: String)

const C_BG := Color("#0b0f12")
const C_GREEN := Color("#4ec994")
const C_DIM := Color("#5c6773")
const C_TEXT := Color("#d7dde3")
const C_RED := Color("#e5484d")
const C_AMBER := Color("#e3b341")
const FONT_SIZE := 15
const LINE_PX := 21.0

const GLITCH_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float t = 0.0;
uniform vec3 bg = vec3(0.043, 0.059, 0.071);
float rand(vec2 c) { return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float a = amount;
	float tt = floor(t * 16.0);
	float rows = 18.0 + 50.0 * a;
	float row = floor(uv.y * rows);
	if (rand(vec2(row, tt)) < a * 0.65) { // torn rows slide sideways
		uv.x += (rand(vec2(row, tt + 1.0)) - 0.5) * 0.3 * a;
	}
	vec2 blk = floor(uv * vec2(9.0, 16.0));
	if (rand(blk + vec2(tt)) < a * 0.15) { // blocks jump
		uv += (vec2(rand(blk + tt + 3.0), rand(blk + tt + 7.0)) - 0.5) * 0.12 * a;
	}
	float s = 0.014 * a; // RGB split
	vec3 col = vec3(texture(screen_tex, uv + vec2(s, 0.0)).r, texture(screen_tex, uv).g, texture(screen_tex, uv - vec2(s, 0.0)).b);
	col *= 1.0 - a * 0.4 * step(0.5, fract(SCREEN_UV.y * 360.0)); // scanlines
	float n = rand(SCREEN_UV * 900.0 + vec2(t));
	col = mix(col, vec3(n) * vec3(0.35, 1.0, 0.6), a * a * 0.4); // green static
	float d = rand(floor(SCREEN_UV * vec2(160.0, 90.0))); // dissolve: cells drop out for good as it rises
	if (d < (a - 0.5) * 2.2) { col = bg; }
	COLOR = vec4(col, 1.0);
}
"""

const HAT_BLACK := """                __
               /  )
              /  /
             /  /
            /    \\
           /      \\
          /        \\
         /          \\
        /____________\\
  _____/______________\\_____
 (__________________________)"""

## the white hat is the black hat mirrored (2026-11-02, Josh: the old white hat read as a lock)
static func mirror_art(art: String) -> String:
	var rows = art.split("\n")
	var w = 0
	for r in rows:
		w = max(w, r.length())
	var swap = {"/": "\\", "\\": "/", "(": ")", ")": "("}
	var out = []
	for r in rows:
		var padded = r + " ".repeat(w - r.length())
		var m = ""
		for k in range(padded.length() - 1, -1, -1):
			var ch = padded[k]
			m += swap.get(ch, ch)
		out.append(m.rstrip(" "))
	return "\n".join(out)

var root: Control
var glitch: ColorRect
var gmat: ShaderMaterial
var black: ColorRect
var term: RichTextLabel
var big: Label
var sub: RichTextLabel # centered text under ACCESS GRANTED (the download)
var out: RichTextLabel # where _add / _type write: term (full screen) or sub (centered)
var hats: HBoxContainer
var prompt_row: HBoxContainer
var input: LineEdit
var lines: Array = []
var max_lines := 40
var _t := 0.0
var _picked := ""
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	get_viewport().gui_release_focus()
	get_tree().paused = true
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = load("res://theme/TerminalTheme.tres")
	add_child(root)
	glitch = ColorRect.new()
	glitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = GLITCH_SHADER
	gmat = ShaderMaterial.new()
	gmat.shader = sh
	gmat.set_shader_parameter("bg", Vector3(C_BG.r, C_BG.g, C_BG.b))
	gmat.set_shader_parameter("amount", 0.0)
	gmat.set_shader_parameter("t", 0.0)
	glitch.material = gmat
	root.add_child(glitch)
	black = ColorRect.new()
	black.color = C_BG
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 0.0
	root.add_child(black)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var col := VBoxContainer.new()
	margin.add_child(col)
	term = RichTextLabel.new()
	term.bbcode_enabled = true
	term.scroll_active = false
	term.size_flags_vertical = Control.SIZE_EXPAND_FILL
	term.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	term.add_theme_constant_override("line_separation", 3)
	term.mouse_filter = Control.MOUSE_FILTER_IGNORE
	term.visible = false
	col.add_child(term)
	out = term
	# the centered stage: ACCESS GRANTED + download, then the hats and the prompt
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var stage := VBoxContainer.new()
	stage.add_theme_constant_override("separation", 28)
	center.add_child(stage)
	col = stage
	big = Label.new()
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_size_override("font_size", 96)
	big.add_theme_color_override("font_color", C_GREEN)
	big.visible = false
	col.add_child(big)
	sub = RichTextLabel.new()
	sub.bbcode_enabled = true
	sub.fit_content = true
	sub.scroll_active = false
	sub.custom_minimum_size.x = 1000
	sub.add_theme_font_size_override("normal_font_size", FONT_SIZE + 1)
	sub.add_theme_constant_override("line_separation", 4)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.visible = false
	col.add_child(sub)
	hats = HBoxContainer.new()
	hats.alignment = BoxContainer.ALIGNMENT_CENTER
	hats.add_theme_constant_override("separation", 120)
	hats.visible = false
	col.add_child(hats)
	_hat_column(mirror_art(HAT_BLACK), "WHITE HAT", C_TEXT, "lock", "Encrypt the codes and destroy the key.\nNobody launches anything. Ever.")
	_hat_column(HAT_BLACK, "BLACK HAT", C_RED, "steal", "Keep a copy for yourself.\nEvery government on Earth will owe you.")
	prompt_row = HBoxContainer.new()
	prompt_row.visible = false
	prompt_row.custom_minimum_size.x = 520
	prompt_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(prompt_row)
	var gt := Label.new()
	gt.text = "> "
	gt.add_theme_color_override("font_color", C_GREEN)
	gt.add_theme_font_size_override("font_size", 18)
	prompt_row.add_child(gt)
	input = LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size", 18)
	input.flat = true
	input.placeholder_text = "lock  or  steal"
	input.context_menu_enabled = false
	input.text_submitted.connect(_on_submit)
	prompt_row.add_child(input)
	max_lines = int(max(12.0, (get_viewport().get_visible_rect().size.y - 140.0) / LINE_PX))
	_run()

func _hat_column(art: String, title: String, color: Color, cmd: String, text: String) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	hats.add_child(v)
	var a := Label.new()
	a.text = art
	a.add_theme_font_size_override("font_size", 16)
	a.add_theme_color_override("font_color", color)
	a.size_flags_vertical = Control.SIZE_SHRINK_END
	a.custom_minimum_size.y = 270
	a.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	v.add_child(a)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.custom_minimum_size.x = 380
	t.add_theme_font_size_override("normal_font_size", 15)
	t.text = "[center][color=#%s]%s[/color]\n\ntype [color=#%s]%s[/color]\n[color=#%s]%s[/color][/center]" % [color.to_html(false), title, C_GREEN.to_html(false), cmd, C_DIM.to_html(false), text]
	v.add_child(t)

func _process(delta: float) -> void:
	_t += delta
	gmat.set_shader_parameter("t", _t)

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout

func _c(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]

func _render() -> void:
	while lines.size() > max_lines:
		lines.pop_front()
	out.text = "\n".join(lines)

func _add(bb: String) -> void:
	lines.append(bb)
	_render()

## types one line at <cps> characters per second (no skipping)
func _type(bb: String, cps: float = 45.0) -> void:
	while lines.size() >= max_lines: # make room first so the count below stays valid
		lines.pop_front()
	_render()
	var before = out.get_total_character_count()
	_add(bb)
	var total = out.get_total_character_count()
	var shown = float(before)
	while shown < total:
		shown += cps * get_process_delta_time()
		out.visible_characters = int(shown)
		await get_tree().process_frame
	out.visible_characters = -1

func _glitch_to(target: float, sec: float) -> void:
	var tw = create_tween()
	tw.tween_method(func(v): gmat.set_shader_parameter("amount", v), float(gmat.get_shader_parameter("amount")), target, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

func _run() -> void:
	# 1) glitch out
	await _wait(0.3)
	for p in [[0.45, 0.12], [0.1, 0.15], [0.6, 0.1], [0.15, 0.3], [0.35, 0.08], [0.2, 0.25]]: # stutters
		await _glitch_to(p[0], p[1])
	await _glitch_to(1.0, 2.4)
	black.modulate.a = 1.0
	await _wait(1.2)
	# 2) the data grab
	term.visible = true
	await _type(_c("root@exec-core-01", C_GREEN) + ":" + _c("~#", C_TEXT) + " ", 30.0)
	await _wait(0.6)
	await _type(_c("session hijacked: PRESIDENT  ·  privilege: absolute", C_AMBER), 40.0)
	await _wait(0.8)
	var n = 150
	for i in n:
		_add(_hack_line())
		await _wait(lerp(0.07, 0.008, float(i) / n))
	await _wait(0.6)
	# 3) access granted + the download
	lines.clear(); _render()
	term.visible = false
	out = sub
	sub.visible = true
	big.text = "ACCESS GRANTED"
	big.visible = true
	for i in 6: # flicker in (modulate, so the layout doesn't jump)
		big.modulate.a = 1.0 if i % 2 == 0 else 0.0
		await _wait(0.12 if i < 5 else 0.0)
	big.modulate.a = 1.0
	await _wait(1.4)
	await _type(_c("locating payload ...", C_DIM), 40.0)
	await _wait(0.7)
	await _type(_c("found", C_GREEN) + "  /classified/nc2/" + _c("nuclear_launch_codes.gpg", C_AMBER) + _c("  (3.61 MB, gold codes, sealed)", C_DIM), 60.0)
	await _wait(0.5)
	_add("")
	var bar_i = lines.size()
	var steps = 60
	for i in steps + 1:
		var p = float(i) / steps
		var w = 40
		var fill = int(round(p * w))
		lines[bar_i - 1] = "downloading  [%s%s]  %3d%%  %s" % [_c("#".repeat(fill), C_GREEN), _c(".".repeat(w - fill), C_DIM), int(p * 100), _c("%.2f / 3.61 MB" % (3.61 * p), C_DIM)]
		_render()
		await _wait(0.06 + rng.randf() * 0.08)
	await _wait(0.4)
	await _type(_c("download complete  ·  checksum verified  ·  1 file", C_GREEN), 50.0)
	await _wait(1.0)
	_add("")
	await _type("The launch codes are yours.", 22.0)
	await _wait(0.8)
	await _type("What happens to them now is your call.", 22.0)
	await _wait(1.8)
	# 4) the choice
	big.visible = false
	lines.clear(); _render()
	sub.visible = false
	out = term
	hats.modulate.a = 0.0
	hats.visible = true
	create_tween().tween_property(hats, "modulate:a", 1.0, 1.2)
	await _wait(1.4)
	prompt_row.visible = true
	input.grab_focus()
	if _picked == "":
		await finished_choice
	# 5) the answer
	prompt_row.visible = false
	var tw = create_tween()
	tw.tween_property(hats, "modulate:a", 0.0, 0.6)
	await tw.finished
	hats.visible = false
	term.visible = true
	await _type(_c("> ", C_GREEN) + ("lock" if _picked == "white" else "steal"), 20.0)
	await _wait(0.5)
	var steps_text = [
		["encrypting nuclear_launch_codes.gpg", "shredding key material", "scrubbing access logs"],
		["mirroring nuclear_launch_codes.gpg to 7 offshore nodes", "planting a false trail", "scrubbing access logs"],
	][0 if _picked == "white" else 1]
	for s in steps_text:
		await _type(s + " ...", 50.0)
		await _wait(0.5 + rng.randf() * 0.5)
		lines[-1] += " " + _c("done", C_GREEN); _render()
	_add("")
	await _wait(0.8)
	if _picked == "white":
		await _type("The codes are sealed behind a door only you could have opened.", 24.0)
		await _wait(0.6)
		await _type("No one will ever know how close it came.", 24.0)
	else:
		await _type("Every government on Earth will be asking who has them.", 24.0)
		await _wait(0.6)
		await _type("None of them will find you.", 24.0)
	await _wait(2.0)
	_add("")
	await _type(_c("session closed.", C_DIM), 30.0)
	await _wait(1.4)
	# glitch back in: the black lifts and the static clears off the HUD
	var tw2 = create_tween()
	tw2.tween_property(term, "modulate:a", 0.0, 0.4)
	await tw2.finished
	black.modulate.a = 0.0
	var tw3 = create_tween()
	tw3.tween_method(func(v): gmat.set_shader_parameter("amount", v), 1.0, 0.0, 2.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw3.finished
	get_tree().paused = false
	finished.emit(_picked)
	queue_free()

signal finished_choice

func _on_submit(text: String) -> void:
	var t = text.strip_edges().to_lower()
	if t in ["lock", "white", "white hat", "whitehat"]:
		_picked = "white"
	elif t in ["steal", "black", "black hat", "blackhat"]:
		_picked = "black"
	else:
		input.clear()
		input.placeholder_text = "type 'lock' or 'steal'"
		return
	input.editable = false
	finished_choice.emit()

## one line of the data grab
func _hack_line() -> String:
	var dirs = ["exec", "nsc", "treasury", "dod", "state", "cabinet", "sitroom", "secret_service", "nc2", "intel"]
	var files = ["briefing", "roster", "keys", "comms", "minutes", "budget", "auth", "itinerary", "cables", "assets"]
	var ext = [".pdf", ".db", ".eml", ".gpg", ".xlsx", ".bak", ".log"]
	match rng.randi_range(0, 7):
		0, 1:
			return _c("[+]", C_GREEN) + " dumping /gov/%s/%s_%d%s %s" % [dirs.pick_random(), files.pick_random(), rng.randi_range(1, 999), ext.pick_random(), _c("%d KB" % rng.randi_range(4, 9000), C_DIM)]
		2:
			var hex = []
			for i in 16:
				hex.append("%02x" % rng.randi_range(0, 255))
			return _c("0x%08x  %s" % [rng.randi(), " ".join(hex)], C_DIM)
		3:
			return _c("[*]", C_AMBER) + " cracking %s key ... %s" % [dirs.pick_random(), _c("ok", C_GREEN)]
		4:
			return _c("[+]", C_GREEN) + " pivot %d.%d.%d.%d -> %s-%02d" % [rng.randi_range(10, 172), rng.randi_range(0, 255), rng.randi_range(0, 255), rng.randi_range(1, 254), dirs.pick_random(), rng.randi_range(1, 40)]
		5:
			return _c("[+]", C_GREEN) + " %s: %s records" % [files.pick_random(), _c(str(rng.randi_range(100, 99999)), C_TEXT)]
		6:
			return _c("[-]", C_RED) + " alarm %s-%d suppressed" % [dirs.pick_random(), rng.randi_range(1, 99)]
		_:
			return _c("[*]", C_AMBER) + " escalating via %s ... %s" % [["kerberos", "ldap", "smb", "vpn", "sso"].pick_random(), _c("granted", C_GREEN)]
