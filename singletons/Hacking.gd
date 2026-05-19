extends Node

#GENERAL MODULE DATA
var SKILL = {
	"name": "Hacking",
	"level": 1,
	"experience": 0,
}


func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount

const minor_processes = []
