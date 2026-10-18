class_name DemoRules
## Next Fest demo (branch demo-nextfest only): what the demo keeps and the messages for what it doesn't.
## The full game lives on cdd; this file and its call sites are the demo cut.

const LEVEL_CAP := 10                   # every skill and process (Exp.MAX_LEVEL)
const UPLOAD_BASIC_GOAL := 100          # School upload goal (full game: 200 / 10)
const UPLOAD_RARE_GOAL := 5
const UPGRADE_SLOTS := [1, 4, 6]        # Tier 1 installs kept per wired skill (speed, efficiency, third track)
const SYSTEM_UPGRADE_SLOTS := [1, 2, 3] # cooling, heat reduction, VM windows
const TARGETS := ["School/Student", "School/Student (Hard)/hard"]

const STORE_URL := "https://store.steampowered.com/app/3884530/IdleOS/"
const STEAM_URI := "steam://store/3884530"
const FULL_GAME_COLOR := "#e3b341"

static func full_game_tag() -> String:
	return "[color=%s]FULL GAME[/color]" % FULL_GAME_COLOR

## "<thing> is only available in the full game." (no call to action: the welcome and send-off carry that)
static func full_game_text(thing: String, plural: bool = false) -> String:
	return "[color=%s]%s %s only available in the full game.[/color]" % [FULL_GAME_COLOR, thing, "are" if plural else "is"]

static func is_full_game_process(p: Dictionary) -> bool:
	return int(p.get("unlock level", 1)) > LEVEL_CAP

## Text for running a locked process: the full-game note above the cap, the normal message below it
static func locked_process_text(p: Dictionary) -> String:
	if is_full_game_process(p):
		return full_game_text("%s (level %d)" % [p.get("name", "This process"), int(p["unlock level"])])
	return "Process not unlocked"

static func keeps_upgrade_level(group: String, level: Dictionary) -> bool:
	if int(level.tier) != 1:
		return false
	return int(level.slot) in (SYSTEM_UPGRADE_SLOTS if group == "System" else UPGRADE_SLOTS)

## 'wishlist': opens the store page in Steam (browser fallback) and copies the link
static func open_wishlist() -> String:
	DisplayServer.clipboard_set(STORE_URL)
	if OS.shell_open(STEAM_URI) != OK:
		OS.shell_open(STORE_URL)
	return "[color=%s]Opening the IdleOS store page in Steam: press 'Add to your wishlist' there.[/color] Thank you! [color=#888888](link copied too: %s)[/color]" % [FULL_GAME_COLOR, STORE_URL]
