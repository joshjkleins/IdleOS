class_name ItemData
extends Resource


@export var id: int
@export var name: String
@export var shortened_name: String
@export var description: String
@export var upgrade_ingredient: bool
@export var value: int
@export var parsable: bool
@export var contained_items: Array[ItemData]
## Game tier the item belongs to (1 School, 2 Lawfirm, 3 Hospital, 4 Bank, 5 Police, 6 Government).
## Mining items use it for Parsing (Corruption/Network); Hacking Mods use it to pick which tier drops them.
@export_range(1, 6) var tier: int = 1


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
@export var obtained_from_additional_hint: String = ""

@export var hacking_mod_type: HackingMods.MOD_TYPE = HackingMods.MOD_TYPE.NONE
@export var hacking_mod_value: float
@export var hacking_mod_duration: int
@export var hacking_mod_consumed: int
@export var hacking_mod_item: bool = false

## Set on one-time hacking items (used during a hack with 'run'). Effects live in the Exploits singleton.
@export var exploit_id: String = ""

func get_obtained_from_skills() -> Array:
	var result = []
	for s in obtained_from:
		result.append(ItemColor.keys()[s].capitalize())
	return result

## True when this item can be compiled into a Hacking Mod.
## 2026-10-23: 'compile -mod' is retired. Items keep their hacking_mod_* fields (old saves, future use) but none
## can be compiled into a mod any more; mods only come from mod items (phish -mod, Corruption, caches).
func is_compilable_mod() -> bool:
	return false
