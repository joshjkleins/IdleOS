class_name CacheData
extends ItemData

@export var entries: Array[CacheEntry] = []

# Rare slot — one item picked from this pool, can be null if none drops
@export var rare_pool: Array[CacheEntry] = []
@export_range(0.0, 1.0) var rare_drop_chance: float = 0.05
