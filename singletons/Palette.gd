extends Node

var COLORS = {
	ItemData.ItemColor.DEFAULT: Color.WEB_GRAY,        #0
	ItemData.ItemColor.MINING: Mining.SKILL.color,     #1
	ItemData.ItemColor.PARSING: Parsing.SKILL.color,   #2
	ItemData.ItemColor.CRACKING: Cracking.SKILL.color, #3
	ItemData.ItemColor.MATCHING: Matching.SKILL.color, #4
	ItemData.ItemColor.PHISHING: Phishing.SKILL.color, #5
	ItemData.ItemColor.HACKING: Hacking.SKILL.color,   #6
	ItemData.ItemColor.DECODING: Decoding.SKILL.color, #7
	ItemData.ItemColor.VALUABLE: Color.AQUAMARINE,     #8
	ItemData.ItemColor.CONSUMABLE: Color.CRIMSON,      #9
}


func get_color(color_type: int) -> Color:
	return COLORS.get(color_type, Color.WHITE)
