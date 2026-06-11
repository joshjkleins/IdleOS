class_name ItemData
extends Resource


@export var id: int
@export var name: String
@export var shortened_name: String
@export var description: String
@export var valuable: bool
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
	VALUABLE, #8
	CONSUMABLE, #9
}

@export var color_type: ItemColor
