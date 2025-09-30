extends Node2D
func _ready():
	print(Global.xp)  # Should print 0
	Global.add_xp(50)
	print(Global.xp)  # Should print 50
