class_name CombatItem
extends ItemData

@export var amount: int = 0
@export var speed: float = 0.0
@export_enum("Attack", "Defend", "Utility")
var type: String = "Attack"
