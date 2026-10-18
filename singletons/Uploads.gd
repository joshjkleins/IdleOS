extends Node
## Upload progression. Each tier has an upload goal: 200 of every basic resource in that tier's chain
## plus 10 of each rare item its targets drop. Items get there in two idle steps:
##   1. decode -package=<item> (Decoding): one item per pass moves from the inventory into the staging area
##   2. upload -<item>: staged items upload one every UPLOAD_SECONDS, several items in parallel
## Staged items that aren't needed any more can be returned with unpack -<item>.

signal changed           # staged / uploading / uploaded counts changed
signal tier_completed(tier: int)
signal item_uploaded(item: ItemData)

const BASIC_GOAL = 200
const RARE_GOAL = 10
const UPLOAD_SECONDS = 15.0       # per basic resource (upgradable later)
const RARE_UPLOAD_SECONDS = 60.0  # per rare item
const UPLOAD_HEAT = 1.0           # system heat per basic resource uploaded
const RARE_UPLOAD_HEAT = 3.0      # per rare item
const MAX_TIER = 6

var staged := {}    # ItemData -> packaged, waiting to upload
var uploaded := {}  # ItemData -> uploaded so far (counts toward goals)
var active := {}    # ItemData -> progress on the item currently uploading (0..1)
var completed_tiers: Array = []

#region goals
func current_tier() -> int:
	for t in range(1, MAX_TIER + 1):
		if not t in completed_tiers:
			return t
	return MAX_TIER

func get_location_name(tier: int) -> String:
	var keys = Stats.hacking_targets.keys()
	return keys[tier - 1] if tier - 1 < keys.size() else "?"

## Rare items the tier's (normal) targets can drop, one entry each.
func get_tier_rares(tier: int) -> Array:
	var out := []
	var loc = Stats.hacking_targets.get(get_location_name(tier), {})
	for t in loc.get("targets", []):
		var cache = t.get("loot")
		if cache is CacheData:
			for e in cache.rare_pool:
				if e.item and not e.item in out:
					out.append(e.item)
	return out

## [{item, amount, rare}] for a tier.
func get_goals(tier: int = 0) -> Array:
	if tier <= 0:
		tier = current_tier()
	var goals := []
	for item in Decoding.get_tier_resources(tier):
		goals.append({"item": item, "amount": BASIC_GOAL, "rare": false})
	for item in get_tier_rares(tier):
		goals.append({"item": item, "amount": RARE_GOAL, "rare": true})
	return goals

func get_goal_amount(item: ItemData, tier: int = 0) -> int:
	for g in get_goals(tier):
		if g.item == item:
			return g.amount
	return 0

func is_goal_item(item: ItemData, tier: int = 0) -> bool:
	return get_goal_amount(item, tier) > 0

func get_uploaded(item: ItemData) -> int:
	return uploaded.get(item, 0)

func get_staged(item: ItemData) -> int:
	return staged.get(item, 0)

## Still needed for the current goal, counting what's already staged.
func get_still_needed(item: ItemData) -> int:
	return max(0, get_goal_amount(item) - get_uploaded(item) - get_staged(item))

func is_tier_complete(tier: int) -> bool:
	for g in get_goals(tier):
		if get_uploaded(g.item) < g.amount:
			return false
	return true
#endregion

#region staging
func stage(item: ItemData, amount: int = 1) -> void:
	staged[item] = get_staged(item) + amount
	changed.emit()
	SaveManager.mark_dirty()

## Returns every staged <item> to the inventory (and stops its upload). Returns how many.
func unpack(item: ItemData) -> int:
	var n = get_staged(item)
	if n <= 0:
		return 0
	staged.erase(item)
	active.erase(item)
	Inventory.add_resource(item, n)
	changed.emit()
	SaveManager.mark_dirty()
	return n
#endregion

#region uploading
## Starts uploading staged <item>. Returns "" on success, otherwise why not.
func start_upload(item: ItemData) -> String:
	if get_staged(item) <= 0:
		return "No packaged %s. Package it first with 'decode -package=%s'." % [item.name, item.name.to_lower()]
	if !is_goal_item(item):
		return "%s isn't part of the current upload goal. Use 'unpack -%s' to get it back." % [item.name, item.name.to_lower()]
	if get_uploaded(item) >= get_goal_amount(item):
		return "%s is already fully uploaded for this tier." % item.name
	if active.has(item):
		return "%s is already uploading." % item.name
	active[item] = 0.0
	changed.emit()
	return ""

var _rare_cache := {}
func is_rare(item: ItemData) -> bool:
	if _rare_cache.is_empty():
		for t in range(1, MAX_TIER + 1):
			for r in get_tier_rares(t):
				_rare_cache[r] = true
	return _rare_cache.has(item)

func get_upload_seconds(item: ItemData) -> float:
	return (RARE_UPLOAD_SECONDS if is_rare(item) else UPLOAD_SECONDS) * Defragging.get_upload_time_multiplier()

func is_uploading(item: ItemData) -> bool:
	return active.has(item)

func _process(delta: float) -> void:
	if active.is_empty():
		return
	for item in active.keys():
		active[item] += delta / get_upload_seconds(item)
		while active.has(item) and active[item] >= 1.0:
			active[item] -= 1.0
			_upload_one(item)
	changed.emit()

func _upload_one(item: ItemData) -> void:
	staged[item] = get_staged(item) - 1
	if staged[item] <= 0:
		staged.erase(item)
	uploaded[item] = get_uploaded(item) + 1
	Stats.update_tempature(RARE_UPLOAD_HEAT if is_rare(item) else UPLOAD_HEAT)
	SaveManager.mark_dirty()
	item_uploaded.emit(item)
	# done with this item: nothing left staged, or its goal is met
	if get_staged(item) <= 0 or get_uploaded(item) >= get_goal_amount(item):
		active.erase(item)
	var tier = current_tier()
	if not tier in completed_tiers and is_tier_complete(tier):
		completed_tiers.append(tier)
		tier_completed.emit(tier) # hook for unlock progression later
#endregion

#region save
func _ids(d: Dictionary) -> Dictionary:
	var out := {}
	for item in d:
		out[str(item.id)] = d[item]
	return out

func _items(raw: Dictionary) -> Dictionary:
	var out := {}
	for id_str in raw:
		var item = Items.ITEM_MAP.get(int(id_str))
		if item:
			out[item] = raw[id_str]
	return out

func save_data() -> Dictionary:
	return {"staged": _ids(staged), "uploaded": _ids(uploaded), "active": _ids(active), "completed_tiers": completed_tiers}

func load_data(data: Dictionary) -> void:
	staged = _items(data.get("staged", {}))
	for k in staged: staged[k] = int(staged[k])
	uploaded = _items(data.get("uploaded", {}))
	for k in uploaded: uploaded[k] = int(uploaded[k])
	active = _items(data.get("active", {}))
	for k in active: active[k] = float(active[k])
	completed_tiers = data.get("completed_tiers", []).map(func(t): return int(t))
	changed.emit()
#endregion
