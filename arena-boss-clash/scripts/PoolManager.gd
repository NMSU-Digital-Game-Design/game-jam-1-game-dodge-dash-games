extends Node2D

var arrow_scene = preload("res://scenes/entities/Arrow.tscn")
var pool: Array = []
var max_pool_size: int = 500
var active_projectiles: Array = []

func _ready():
	for i in max_pool_size:
		var arrow = arrow_scene.instantiate()
		arrow.visible = false
		arrow.set_physics_process(false)
		arrow.connect("despawned", self._on_arrow_despawned)  # Connect to PoolManager's method
		pool.append(arrow)
		add_child(arrow)

func spawn_arrow(position: Vector2, direction: Vector2, player_id: int) -> Node:
	var arrow = null
	for p in pool:
		if not p.visible:
			arrow = p
			break
	if not arrow:
		return null  # Pool exhausted
	arrow.position = position
	arrow.direction = direction
	arrow.player_id = player_id
	arrow.speed = 400.0  # Reset default speed
	arrow.damage = 10.0  # Reset default damage
	arrow.visible = true
	arrow.set_physics_process(true)
	active_projectiles.append(arrow)
	return arrow

func _on_arrow_despawned(arrow):
	if arrow in active_projectiles:
		active_projectiles.erase(arrow)

func _physics_process(delta):
	for arrow in active_projectiles.duplicate():
		if not arrow.visible:
			active_projectiles.erase(arrow)
