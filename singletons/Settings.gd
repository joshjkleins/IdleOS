extends Node
## Settings — add as AutoLoad named "Settings".
## Persists to user://settings.cfg (Godot's equivalent of Unity's PlayerPrefs).
## Kept separate from save data: these are per-device preferences, not progress.

const PATH := "user://settings.cfg"

# Definition table: key -> {section, default, type, help}
# "range" = integer 0-100, "enum" = one of the listed values
const DEFS := {
	"volume": {
		"section": "Volume", "default": 100, "type": "range",
		"help": "Sets master percentage",
	},
	"sfx": {
		"section": "Volume", "default": 100, "type": "range",
		"help": "Sets SFX volume percentage",
	},
	"music": {
		"section": "Volume", "default": 70, "type": "range",
		"help": "Sets background music volume percentage",
	},
	"window_mode": {
		"section": "Window", "default": "windowed", "type": "enum",
		"values": {
			"windowed":    "Sets mode to windowed",
			"full_screen": "Sets mode to full screen",
		},
	},
}

var values: Dictionary = {}

signal setting_changed(key: String, value)


func _ready() -> void:
	load_settings()
	apply_all()


# ---------- PUBLIC ----------
## Returns "" on success, otherwise an error message for the terminal.
func set_value(key: String, raw: String) -> String:
	if not DEFS.has(key):
		return "unknown setting '%s'" % key
	var def: Dictionary = DEFS[key]
	var value

	match def.type:
		"range":
			if not raw.is_valid_int():
				return "%s expects a number 0-100" % key
			value = clampi(raw.to_int(), 0, 100)
		"enum":
			raw = raw.to_lower()
			if not def.values.has(raw):
				return "%s must be one of: %s" % [key, ", ".join(def.values.keys())]
			value = raw

	values[key] = value
	_apply(key)
	save_settings()
	setting_changed.emit(key, value)
	return ""


func get_value(key: String):
	return values.get(key, DEFS[key].default if DEFS.has(key) else null)


func reset_defaults() -> void:
	for key in DEFS:
		values[key] = DEFS[key].default
	apply_all()
	save_settings()


func apply_all() -> void:
	for key in values:
		_apply(key)


# ---------- PERSISTENCE ----------
func load_settings() -> void:
	var cfg := ConfigFile.new()
	var ok := cfg.load(PATH) == OK
	for key in DEFS:
		var def: Dictionary = DEFS[key]
		values[key] = cfg.get_value(def.section, key, def.default) if ok else def.default


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value(DEFS[key].section, key, values[key])
	cfg.save(PATH)


# ---------- APPLY ----------
func _apply(key: String) -> void:
	var v = values[key]
	match key:
		"volume":
			Audiomanager.set_master_volume(v / 100.0)
		"sfx":
			Audiomanager.set_sfx_volume(v / 100.0)
		"music":
			Audiomanager.set_music_volume(v / 100.0)
		"window_mode":
			match v:
				"windowed":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				"full_screen":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


const COL_WIDTH := 28  # width of the "key=value" column before the description
const BOX_INNER := 68   # characters between the two | borders
const CMD_INDENT := 3   # spaces before the command
const CMD_WIDTH := 29   # command column width (description starts at col 32)

 
func settings_help() -> String:
	var lines: Array[String] = []
	lines.append(" " + "_".repeat(BOX_INNER))
	lines.append(_box(""))
	lines.append(_box(_center("SETTINGS")))
	lines.append("|" + "_".repeat(BOX_INNER) + "|")
	lines.append(_box(""))
 
	# Group keys by section, preserving DEFS order
	var sections := {}
	for key in DEFS:
		var section: String = DEFS[key].section
		if not sections.has(section):
			sections[section] = []
		sections[section].append(key)
 
	for section in sections:
		lines.append(_box(" " + section.to_upper()))
		for key in sections[section]:
			var def: Dictionary = DEFS[key]
			var current = get_value(key)
			match def.type:
				"range":
					lines.append(_row("%s=<number>" % key, "%s  [%d]" % [def.help, current]))
				"enum":
					for v in def.values:
						var mark := " *" if v == current else ""
						lines.append(_row("%s=%s" % [key, v], def.values[v] + mark))
		lines.append(_box(""))
 
	lines.append(_box(" USAGE"))
	lines.append(_row("settings <key>=<value>", "Apply a setting"))
	lines.append(_row("settings reset", "Restore defaults"))
	lines.append("|" + "_".repeat(BOX_INNER) + "|")
	return "\n".join(lines)

 
 
## Accepts "settings sfx=50", "sfx=50", or several at once: "sfx=50 music=20".
## Returns the text to print in the terminal.
func handle_settings_command(input: String) -> String:
	var text := input.strip_edges()
	if text.begins_with("settings"):
		text = text.trim_prefix("settings").strip_edges()
 
	if text.is_empty():
		return settings_help()
	if text == "reset":
		Settings.reset_defaults()
		return "settings restored to defaults"
 
	var out: Array[String] = []
	for token in text.split(" ", false):
		var parts := token.split("=", true, 1)
		if parts.size() != 2 or parts[0].is_empty() or parts[1].is_empty():
			out.append("error: expected <key>=<value>, got '%s'" % token)
			continue
		var key := parts[0].strip_edges().to_lower()
		var val := parts[1].strip_edges()
		var err := Settings.set_value(key, val)
		if err.is_empty():
			out.append("%s set to %s" % [key, str(Settings.get_value(key))])
		else:
			out.append("error: " + err)
	return "\n".join(out)
 
 
func _row(cmd: String, desc: String) -> String:
	return _box(" ".repeat(CMD_INDENT) + cmd.rpad(CMD_WIDTH) + desc)
 
 
func _box(content: String) -> String:
	if content.length() > BOX_INNER:
		content = content.substr(0, BOX_INNER)
	return "|" + content.rpad(BOX_INNER) + "|"
 
 
func _center(text: String) -> String:
	var left := (BOX_INNER - text.length()) / 2
	return " ".repeat(left) + text
