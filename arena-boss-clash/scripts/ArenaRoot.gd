extends Node2D

var orc_scene = preload("res://scenes/entities/Orc.tscn")
var spawn_timer: Timer

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = randf_range(5.0, 10.0)
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	var orc = orc_scene.instantiate()
	orc.position = Vector2(randf_range(100, 1900), 0)
	$Enemies.add_child(orc)
	orc.connect("died", _on_orc_died)
	spawn_timer.wait_time = randf_range(5.0, 10.0)

func _on_orc_died(xp_value: int, player_id: int):
	Global.add_xp(xp_value)
