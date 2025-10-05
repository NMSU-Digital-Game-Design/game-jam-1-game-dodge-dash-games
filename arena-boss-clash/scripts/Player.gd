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
var can_attack_bow: bool = true
var can_attack_sword: bool = true
var attack_bow_cooldown: float = 0.5  # seconds
var attack_sword_cooldown: float = 0.3  # seconds
var is_attacking: bool = false

func _ready():
	jump_buffer_timer.wait_time = jump_buffer_time
	animated_sprite.connect("animation_finished", _on_animation_finished)

func _physics_process(delta):
	if not is_active:
		return
	
	# Apply gravity when not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Horizontal movement
	var direction = Input.get_axis("ui_left" + input_suffix, "ui_right" + input_suffix)
	velocity.x = direction * speed
	
	# Jump input buffering
	if Input.is_action_just_pressed("ui_up" + input_suffix):
		jump_buffer_timer.start()
	
	# Jump execution
	if is_on_floor() and (not jump_buffer_timer.is_stopped() or Input.is_action_pressed("ui_up" + input_suffix)):
		velocity.y = jump_velocity
		jump_buffer_timer.stop()
	
	# Platform pass-through
	if Input.is_action_pressed("ui_down" + input_suffix):
		collision_mask = 10
	else:
		collision_mask = 14
	
	# Attacks
	if Input.is_action_just_pressed("attack_bow" + input_suffix) and can_attack_bow and not is_attacking:
		perform_bow_attack()
	if Input.is_action_just_pressed("attack_sword" + input_suffix) and can_attack_sword and not is_attacking:
		if is_on_floor():
			perform_sword_attack()
		else:
			perform_jump_attack()
	
	move_and_slide()
	
	# Pixel snapping
	position = position.round()
	
	# Animation handling
	update_animations(direction)

func perform_bow_attack():
	can_attack_bow = false
	is_attacking = true
	animated_sprite.play("bow_attack")
	var pool_manager = get_tree().root.get_node("ArenaRoot/Projectiles")
	if pool_manager:
		await get_tree().create_timer(1.4).timeout  # Delay for 7 frames at 5 FPS
		var arrow_direction = Vector2(-1, 0) if animated_sprite.flip_h else Vector2(1, 0)
		var arrow_position = position + Vector2(20 * arrow_direction.x, 0)
		pool_manager.spawn_arrow(arrow_position, arrow_direction, player_id)
	await get_tree().create_timer(attack_bow_cooldown).timeout
	can_attack_bow = true

func perform_sword_attack():
	can_attack_sword = false
	is_attacking = true
	animated_sprite.play("sword_attack")
	var hitbox = RectangleShape2D.new()
	hitbox.extents = Vector2(20, 20)
	var collision = CollisionShape2D.new()
	collision.shape = hitbox
	collision.position = Vector2(30 * (-1 if animated_sprite.flip_h else 1), 0)
	add_child(collision)
	await get_tree().create_timer(0.2).timeout
	collision.queue_free()
	await get_tree().create_timer(attack_sword_cooldown - 0.2).timeout
	can_attack_sword = true

func perform_jump_attack():
	can_attack_sword = false
	is_attacking = true
	animated_sprite.play("jump_attack")
	var hitbox = RectangleShape2D.new()
	hitbox.extents = Vector2(30, 30)
	var collision = CollisionShape2D.new()
	collision.shape = hitbox
	collision.position = Vector2(30 * (-1 if animated_sprite.flip_h else 1), 0)
	add_child(collision)
	for area in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("boss"):
		if area.get("health") != null:
			var area_pos = area.global_position
			var hitbox_rect = Rect2(collision.global_position - hitbox.extents, hitbox.extents * 2)
			if hitbox_rect.has_point(area_pos):
				area.health -= 15.0
	await get_tree().create_timer(0.2).timeout
	collision.queue_free()
	await get_tree().create_timer(attack_sword_cooldown - 0.2).timeout
	can_attack_sword = true

func _on_animation_finished():
	if animated_sprite.animation in ["bow_attack", "sword_attack", "jump_attack"]:
		is_attacking = false

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
	# Jump animation commented out due to missing animation
	# if not is_on_floor() and animated_sprite.animation != "jump_attack":
	#     animated_sprite.play("jump")
