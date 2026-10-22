class_name CacheData
extends ItemData
## A decodable cache. Variants (Footprint / Network / Corruption / Extraction) share the base cache's
## entries; the variant is read from the item name. The drop rules that use these values live in
## Decoding (get_drop_table / roll_loot) so `ls <cache>` and decoding always agree.
## NOTE: don't reference autoloads (Items, Decoding...) here: Items preloads every cache resource,
## so a reference back would make this script fail to load (circular dependency).

@export var entries: Array[CacheEntry] = []

# Rare slot — one item picked from this pool, can be null if none drops
@export var rare_pool: Array[CacheEntry] = []
@export_range(0.0, 1.0) var rare_drop_chance: float = 0.05 # unused: the rare roll uses Decoding efficiency

enum CacheVariant { BASE, FOOTPRINT, NETWORK, CORRUPTION, EXTRACTION }

# --- variant tuning ---
const FOOTPRINT_MULTIPLIER = 2          # basic resource quantities x2, no rare item
const NETWORK_VM_CHANCE = 0.5           # chance for a bonus random VM token drop
const NETWORK_VM_MIN = 10
const NETWORK_VM_MAX = 20
const CORRUPTION_DROP_BONUS = 0.3       # flat bonus to every drop chance (incl. rare)
const CORRUPTION_CHANCE = 0.2           # chance to corrupt (lose the rest) after each item found
const EXTRACTION_EXTRA_RARE = 1         # extra copies of the rare item when it drops (2026-10-22: was 4)

func get_variant() -> CacheVariant:
	var n = name.to_lower()
	if n.contains("footprint"):
		return CacheVariant.FOOTPRINT
	if n.contains("network"):
		return CacheVariant.NETWORK
	if n.contains("corruption"):
		return CacheVariant.CORRUPTION
	if n.contains("extraction"):
		return CacheVariant.EXTRACTION
	return CacheVariant.BASE

func get_variant_name() -> String:
	return CacheVariant.keys()[get_variant()].capitalize()

func get_variant_description() -> String:
	match get_variant():
		CacheVariant.FOOTPRINT:
			return "Footprint: basic resources x%d, no rare item." % FOOTPRINT_MULTIPLIER
		CacheVariant.NETWORK:
			return "Network: %d%% chance for %d-%d of a random VM token." % [int(NETWORK_VM_CHANCE * 100), NETWORK_VM_MIN, NETWORK_VM_MAX]
		CacheVariant.CORRUPTION:
			return "Corruption: +%d%% to all drop chances, but %d%% chance to corrupt after each item found (rest of the cache is lost). Rare item is decoded last." % [int(CORRUPTION_DROP_BONUS * 100), int(CORRUPTION_CHANCE * 100)]
		CacheVariant.EXTRACTION:
			return "Extraction: if the rare item drops, +%d extra copies." % EXTRACTION_EXTRA_RARE
	return ""
