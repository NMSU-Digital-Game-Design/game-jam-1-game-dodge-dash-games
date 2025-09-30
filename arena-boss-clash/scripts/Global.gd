# scripts/Global.gd
extends Node
signal level_up(current_level)

var xp: int = 0
var level: int = 0
var xp_to_next_level: int = 100

func _ready():
	pass

func add_xp(amount: int):
	xp += amount
	while xp >= xp_to_next_level:
		level += 1
		xp -= xp_to_next_level
		xp_to_next_level = int(xp_to_next_level * 1.2)
		emit_signal("level_up", level)
