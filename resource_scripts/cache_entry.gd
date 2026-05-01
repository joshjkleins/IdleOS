class_name CacheEntry
extends Resource

@export var item: ItemData
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export_range(0.0, 1.0) var drop_chance: float = 1.0
