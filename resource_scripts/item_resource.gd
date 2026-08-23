class_name ItemData
extends Resource


@export var id: int
@export var name: String
@export var shortened_name: String
@export var description: String
@export var upgrade_ingredient: bool
@export var value: int


enum ItemColor {
	DEFAULT,  #0
	MINING,   #1
	PARSING,  #2
	CRACKING, #3
	MATCHING, #4
	PHISHING, #5
	HACKING,  #6
	DECODING, #7
	UPGRADE, #8
	CONSUMABLE, #9
	COMPILING, #10
}

@export var color_type: ItemColor
@export var obtained_from: Array[ItemColor] = []

func get_obtained_from_skills() -> Array:
	var result = []
	for s in obtained_from:
		result.append(ItemColor.keys()[s].capitalize())
	return result
