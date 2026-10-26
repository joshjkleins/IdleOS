extends Node
## Upload progression. Each tier has an upload goal: BASIC_GOALS[tier] of every basic resource in that tier's chain
## plus RARE_GOALS[tier] of each rare item its targets drop.
##   upload <item> <amount>: moves that many from the inventory into the upload queue ("staged") and starts it;
##   queued items upload one every get_upload_seconds(), several items in parallel.
## Economy pass (2026-10-20, tools/balance/econ2.py): goals fit each tier's active play time (T1 1-2 h ... T6 6-7 h)
## with cache loot counted; upload time makes a tier's goal take ~70% of its play time, all items in parallel.
## Queued items can be returned with upload cancel <item>.

signal changed           # staged / uploading / uploaded counts changed
signal tier_completed(tier: int)
signal item_uploaded(item: ItemData)

const BASIC_GOALS = [150, 300, 600, 1000, 1600, 2500] # 2026-10-24 playthrough: T1 300 -> 150 (and T1 rares 3 -> 1)
const RARE_GOALS = [1, 5, 6, 10, 15, 20]
const UPLOAD_SECONDS_BY_TIER = [15.0, 15.0, 15.0, 11.0, 9.0, 7.0] # per basic resource, by the item's tier
const RARE_UPLOAD_SECONDS = 45.0  # per rare item
## Upload heat per second of uploading, per item, by tier (~3.5% of that tier's cooling each: all of a tier's
## items uploading at once is a light, steady load)
const UPLOAD_HEAT_PER_SECOND = [0.009, 0.02, 0.035, 0.058, 0.088, 0.133]
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
		goals.append({"item": item, "amount": BASIC_GOALS[clamp(tier, 1, MAX_TIER) - 1], "rare": false})
	for item in get_tier_rares(tier):
		goals.append({"item": item, "amount": RARE_GOALS[clamp(tier, 1, MAX_TIER) - 1], "rare": true})
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

## 'upload <item> <amount>': takes up to <amount> (0 = all the goal still needs) from the inventory, queues
## them and starts the upload. Returns {ok, amount, message}.
func queue(item: ItemData, amount: int = 0) -> Dictionary:
	var out = {"ok": false, "amount": 0, "message": ""}
	if !is_goal_item(item):
		out.message = "%s isn't part of the current upload goal. Type 'upload' to see it." % item.name
		return out
	var need = get_still_needed(item)
	if need <= 0:
		out.message = "%s is already %s for this goal." % [item.name, "fully uploaded" if get_uploaded(item) >= get_goal_amount(item) else "queued"]
		return out
	var have = Inventory.get_amount(item)
	if have <= 0:
		out.message = "No %s in inventory." % item.name
		return out
	var n = min(need, have) if amount <= 0 else min(amount, need, have)
	Inventory.remove_resource(item, n)
	stage(item, n)
	Tutorial.on_items_packaged(item, n)
	if !active.has(item):
		active[item] = 0.0
	changed.emit()
	out.ok = true
	out.amount = n
	return out

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
		return "Nothing queued for %s. Queue it with 'upload %s <amount>'." % [item.name, item.name.to_lower()]
	if !is_goal_item(item):
		return "%s isn't part of the current upload goal. Use 'upload cancel %s' to get it back." % [item.name, item.name.to_lower()]
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

## Tier an upload item counts for (its location, else the current goal's tier)
func _item_tier(item: ItemData) -> int:
	var t = Inventory.item_tier(item) if item else 0
	return clamp(t if t > 0 else current_tier(), 1, MAX_TIER)

func get_upload_seconds(item: ItemData) -> float:
	var base = RARE_UPLOAD_SECONDS if is_rare(item) else UPLOAD_SECONDS_BY_TIER[_item_tier(item) - 1]
	return base * Defragging.get_upload_time_multiplier()

func get_upload_heat(item: ItemData) -> float:
	return UPLOAD_HEAT_PER_SECOND[_item_tier(item) - 1] * get_upload_seconds(item)

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
	Stats.update_tempature(get_upload_heat(item))
	SaveManager.mark_dirty()
	item_uploaded.emit(item)
	# done with this item: nothing left staged, or its goal is met
	if get_staged(item) <= 0 or get_uploaded(item) >= get_goal_amount(item):
		active.erase(item)
	var tier = current_tier()
	if not tier in completed_tiers and is_tier_complete(tier):
		completed_tiers.append(tier)
		tier_completed.emit(tier) # hook for unlock progression later

## A save whose uploads already meet a goal that has since been lowered completes that tier on load
func complete_met_tiers() -> void:
	for guard in MAX_TIER:
		var tier = current_tier()
		if tier in completed_tiers or !is_tier_complete(tier):
			break
		completed_tiers.append(tier)
		tier_completed.emit(tier)
		SaveManager.mark_dirty()
	for item in active.keys(): # items whose goal is now met stop uploading (the rest stays queued)
		if get_uploaded(item) >= get_goal_amount(item):
			active.erase(item)
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
	# saves from the packaging days: queued goal items just start uploading
	for k in staged:
		if is_goal_item(k) and get_uploaded(k) < get_goal_amount(k) and !active.has(k):
			active[k] = 0.0
	changed.emit()
#endregion
