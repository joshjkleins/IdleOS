extends Node

var current_anon = 100
var max_anon = 100
var current_bandwidth = 10
var max_bandwidth = 10
var bandwidth_recovery_rate = 1
var bandwidth_recovery_speed = 1.0

#GENERAL MODULE DATA
var SKILL = {
	"name": "Hacking",
	"level": 1,
	"experience": 0,
	"efficiency": 0.05,
	"efficiency rate": 0.001
}


func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount

const minor_processes = []
