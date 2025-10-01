# scripts/Player.gd
extends CharacterBody2D

var speed: float = 300
var jump_velocity: float = -400
var dash_cooldown: float = 2.0
var damage: float = 1.0
var health: float = 100
var projectile_type: String = "normal"
var bullet_scene = preload("res://scenes/entities/BaseBullet.tscn")
var pool = null

func _ready():
	add_to_group("player")
	pool = get_node("/root/ArenaRoot/Projectiles/PoolManager")

func _physics_process(delta):
	# Movement
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	move_and_slide()
	
	# Dash
	if Input.is_action_just_pressed("dash") and $DashTimer.time_left == 0:
		velocity.x *= 3
		$DashTimer.start(dash_cooldown)
	
	# Shoot
	if Input.is_action_just_pressed("attack"):
		shoot()

func shoot():
	var props = {
		"collision_layer": 1,
		"collision_mask": 2,
		"sprite_texture": preload("res://assets/sprites/player_bullet.png"),
		"speed": 300,
		"damage": damage
	}
	if projectile_type == "homing":
		props["homing_target"] = get_closest_enemy()
		pool.get_projectile(preload("res://scenes/entities/HomingBullet.tscn"), global_position, Vector2.RIGHT * props.speed, props)
	else:
		pool.get_projectile(bullet_scene, global_position, Vector2.RIGHT * props.speed, props)

func apply_upgrade(upgrade):
	match upgrade.effect:
		"damage": damage += upgrade.value
		"health": health += upgrade.value
		"homing": projectile_type = "homing"
		"dash_cooldown": dash_cooldown += upgrade.value

func _on_area_entered(area):
	if area.is_in_group("enemy_projectile"):
		health -= area.damage
		if health <= 0:
			get_tree().change_scene_to_file("res://scenes/ui/LoseScreen.tscn")
