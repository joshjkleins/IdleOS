extends Node
## 2026-11-03: the Steam layer. GodotSteam (GDExtension) is looked up at runtime (Engine.get_singleton), so the game
## builds and runs without the plugin or without the Steam client: every call is then a no-op (available = false).
## App ID: steam_appid.txt in the project root while testing from the editor (don't ship it); Steam supplies it to
## a release build launched from Steam.

var steam: Object = null
var available := false
var init_text := "not started"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # callbacks keep running while the tree is paused
	if !Engine.has_singleton("Steam"):
		init_text = "GodotSteam plugin not installed"
		print("SteamManager: ", init_text)
		return
	steam = Engine.get_singleton("Steam")
	var r = steam.steamInitEx()
	available = r is Dictionary and int(r.get("status", 1)) == 0
	init_text = str(r.get("verbal", r)) if r is Dictionary else str(r)
	print("SteamManager: Steam %s (%s)" % ["ready" if available else "not available", init_text])

func _process(_delta: float) -> void:
	if available:
		steam.run_callbacks()

## Unlocks an achievement (API name) and pushes it to Steam (storeStats shows the pop-up)
func unlock(api_name: String) -> bool:
	if !available:
		return false
	steam.setAchievement(api_name)
	return bool(steam.storeStats())

func is_unlocked(api_name: String) -> bool:
	if !available:
		return false
	var a = steam.getAchievement(api_name)
	return a is Dictionary and bool(a.get("achieved", false))

func set_stat(api_name: String, value: int) -> void:
	if !available:
		return
	steam.setStatInt(api_name, value)
	steam.storeStats()

## DEV: wipes this account's stats and achievements for the game
func reset_all() -> void:
	if !available:
		return
	steam.resetAllStats(true)
	steam.storeStats()
