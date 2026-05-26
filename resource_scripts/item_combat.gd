class_name CombatItem
extends ItemData

@export var damage: int = 0
@export var heal: int = 0
@export var speed: float = 0.0
@export var speed_name: String = ""
@export var bandwidth_cost: int = 0
@export var data_cost: int = 0
@export var firewall_damage: int = 0
@export_enum("Attack", "Heal")
var type: String = "Attack"
