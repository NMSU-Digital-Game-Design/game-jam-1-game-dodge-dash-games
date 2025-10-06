extends CharacterBody2D

@export var speed: float = 200.0
@export var gravity: float = 980.0
@export var jump_velocity: float = -400.0
@export var jump_buffer_time: float = 0.05
@export var is_active: bool = true
@export var player_id: int = 0
@export var input_suffix: String = "_p1"

@onready var animated_sprite = $AnimatedSprite2D
@onready var jump_buffer_timer = $JumpBufferTimer
var health: float = 100.0
var can_attack_bow: bool = true
var can_attack_sword: bool = true
var attack_bow_cooldown: float = 0.5
var attack_sword_cooldown: float = 0.3
var is_attacking: bool = false
var is_damaged: bool = false

func _ready():
	add_to_group("player")
	animated_sprite.connect("animation_finished", _on_animation_finished)
	if jump_buffer_timer:
		jump_buffer_timer.wait_time = jump_buffer_time
		print("JumpBufferTimer initialized, wait_time: ", jump_buffer_timer.wait_time)
	else:
		push_warning("JumpBufferTimer not found in Player.tscn for player_id: ", player_id)
	print("Player initialized, id: ", player_id, " input_suffix: ", input_suffix, " in group: ", is_in_group("player"))

func _physics_process(delta):
	if not is_active:
#		print("Physics process skipped: is_active=false for player_id: ", player_id)
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left" + input_suffix, "ui_right" + input_suffix)
#	print("Direction: ", direction, " for player_id: ", player_id)
	velocity.x = direction * speed
	
	if Input.is_action_just_pressed("ui_up" + input_suffix):
		if jump_buffer_timer:
			jump_buffer_timer.start()
		else:
			push_warning("JumpBufferTimer missing during jump input for player_id: ", player_id)
	
	if is_on_floor() and jump_buffer_timer and (not jump_buffer_timer.is_stopped() or Input.is_action_pressed("ui_up" + input_suffix)):
		velocity.y = jump_velocity
		if jump_buffer_timer:
			jump_buffer_timer.stop()
	
	if Input.is_action_pressed("ui_down" + input_suffix):
		collision_mask = 10
	else:
		collision_mask = 14
	
	if Input.is_action_just_pressed("attack_bow" + input_suffix) and can_attack_bow and not is_attacking:
		perform_bow_attack()
	if Input.is_action_just_pressed("attack_sword" + input_suffix) and can_attack_sword and not is_attacking:
		if is_on_floor():
			perform_sword_attack()
		else:
			perform_jump_attack()
	
	move_and_slide()
	position = position.round()
	if not is_attacking:
		update_animations(direction)

func perform_bow_attack():
	can_attack_bow = false
	is_attacking = true
	animated_sprite.play("bow_attack")
	print("Bow attack started for player_id: ", player_id)
	var pool_manager = get_tree().root.get_node("ArenaRoot/Projectiles")
	if pool_manager:
		await get_tree().create_timer(1.4).timeout
		var arrow_direction = Vector2(-1, 0) if animated_sprite.flip_h else Vector2(1, 0)
		var arrow_position = position + Vector2(20 * arrow_direction.x, 0)
		pool_manager.spawn_arrow(arrow_position, arrow_direction, player_id)
		print("Arrow spawned, direction: ", arrow_direction, " for player_id: ", player_id)
	else:
		push_warning("PoolManager not found for bow attack, player_id: ", player_id)
	await get_tree().create_timer(attack_bow_cooldown).timeout
	can_attack_bow = true

func perform_sword_attack():
	can_attack_sword = false
	is_attacking = true
	animated_sprite.play("sword_attack")
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var hitbox = RectangleShape2D.new()
	hitbox.extents = Vector2(20, 20)
	collision.shape = hitbox
	collision.position = Vector2(30 * (-1 if animated_sprite.flip_h else 1), 0)
	area.collision_layer = 0
	area.collision_mask = 64  # Orc layer 6
	area.add_child(collision)
	add_child(area)
	area.connect("body_entered", func(body):
		if body.is_in_group("enemy") or body.is_in_group("boss"):
			if "health" in body:
				body.take_damage(10.0, player_id)
				print("Sword hit: ", body.name, " at ", body.position, " by player_id: ", player_id))
	await get_tree().create_timer(0.2).timeout
	area.queue_free()
	await get_tree().create_timer(attack_sword_cooldown - 0.2).timeout
	can_attack_sword = true

func perform_jump_attack():
	can_attack_sword = false
	is_attacking = true
	animated_sprite.play("jump_attack")
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var hitbox = RectangleShape2D.new()
	hitbox.extents = Vector2(30, 30)
	collision.shape = hitbox
	collision.position = Vector2(30 * (-1 if animated_sprite.flip_h else 1), 0)
	area.collision_layer = 0
	area.collision_mask = 64
	area.add_child(collision)
	add_child(area)
	area.connect("body_entered", func(body):
		if body.is_in_group("enemy") or body.is_in_group("boss"):
			if "health" in body:
				body.take_damage(15.0, player_id)
				print("Jump hit: ", body.name, " at ", body.position, " by player_id: ", player_id))
	await get_tree().create_timer(0.2).timeout
	area.queue_free()
	await get_tree().create_timer(attack_sword_cooldown - 0.2).timeout
	can_attack_sword = true

func take_damage(amount: float, attacker_id: int = 0):
	if health <= 0:
		print("Player damage skipped: health=", health, " for player_id: ", player_id)
		return
	is_damaged = true
	health -= amount
	animated_sprite.play("damaged")
	print("Player took damage: ", amount, " health: ", health, " for player_id: ", player_id)
	if health <= 0:
		is_active = false
		animated_sprite.play("death")
		await animated_sprite.animation_finished
		print("Switching to LoseScreen for player_id: ", player_id)
		get_tree().change_scene_to_file("res://scenes/ui/LoseScreen.tscn")

func _on_animation_finished():
	if animated_sprite.animation in ["bow_attack", "sword_attack", "jump_attack"]:
		is_attacking = false
	if animated_sprite.animation == "damaged":
		is_damaged = false
		is_attacking = false
		if health > 0:
			animated_sprite.play("idle")
	print("Player animation finished: ", animated_sprite.animation, " for player_id: ", player_id)

func update_animations(direction):
	if not is_active or is_attacking:
		return
	if direction != 0:
		animated_sprite.flip_h = direction < 0
		if is_on_floor():
			animated_sprite.play("walk")
	else:
		if is_on_floor():
			animated_sprite.play("idle")

func _on_body_entered(body):
	if body.is_in_group("enemy") and "damage" in body:
		take_damage(body.damage, 0)
		print("Player hit by: ", body.name, " for player_id: ", player_id)
