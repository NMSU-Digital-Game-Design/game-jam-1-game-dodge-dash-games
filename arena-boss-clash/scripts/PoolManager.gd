# scripts/PoolManager.gd
extends Node2D

@export var default_initial_size: int = 50
@export var default_batch_size: int = 20

var pools: Dictionary = {}  # {scene_path: {available: [], active: [], initial_size: int, batch_size: int}}

func ensure_pool_exists(scene: PackedScene, initial_size: int, batch_size: int):
	var key = scene.resource_path
	if not pools.has(key):
		pools[key] = {
			"available": [],
			"active": [],
			"initial_size": initial_size if initial_size > 0 else default_initial_size,
			"batch_size": batch_size if batch_size > 0 else default_batch_size
		}
		create_and_add_to_pool(scene, pools[key]["initial_size"])

func create_and_add_to_pool(scene: PackedScene, count: int):
	var key = scene.resource_path
	for i in count:
		var proj = scene.instantiate()
		proj.visible = false
		proj.set_process(false)
		proj.set_physics_process(false)
		proj.position = Vector2.ZERO
		if proj.has_method("reset"):
			proj.reset()
		add_child(proj)
		pools[key]["available"].append(proj)

func get_projectile(scene: PackedScene, pos: Vector2, vel: Vector2, custom_props: Dictionary = {}) -> Node:
	var key = scene.resource_path
	ensure_pool_exists(scene, custom_props.get("initial_size", 0), custom_props.get("batch_size", 0))
	
	if pools[key]["available"].is_empty():
		create_and_add_to_pool(scene, pools[key]["batch_size"])
	
	var proj = pools[key]["available"].pop_front()
	if proj:
		proj.position = pos
		proj.velocity = vel
		proj.visible = true
		proj.set_process(true)
		proj.set_physics_process(true)
		for prop in custom_props:
			match prop:
				"collision_layer": proj.collision_layer = custom_props[prop]
				"collision_mask": proj.collision_mask = custom_props[prop]
				"sprite_texture":
					if proj.get_node_or_null("Sprite2D"):
						proj.get_node("Sprite2D").texture = custom_props[prop]
				"speed": proj.speed = custom_props[prop]
				"damage": proj.damage = custom_props[prop]
		pools[key]["active"].append(proj)
	return proj

func return_to_pool(scene: PackedScene, proj: Node):
	var key = scene.resource_path
	if proj in pools[key]["active"]:
		pools[key]["active"].erase(proj)
	proj.visible = false
	proj.position = Vector2.ZERO
	proj.velocity = Vector2.ZERO
	proj.set_process(false)
	proj.set_physics_process(false)
	if proj.has_method("reset"):
		proj.reset()
	else:
		proj.collision_layer = 0
		proj.collision_mask = 0
		if proj.get_node_or_null("Sprite2D"):
			proj.get_node("Sprite2D").texture = null
		if "speed" in proj:
			proj.speed = 0
		if "damage" in proj:
			proj.damage = 0
	pools[key]["available"].append(proj)
