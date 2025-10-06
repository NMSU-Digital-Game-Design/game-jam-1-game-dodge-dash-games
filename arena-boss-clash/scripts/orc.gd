extends CharacterBody2D

var health: float = 50.0
var damage: float = 10.0
var speed: float = 100.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")  # 980
var xp_value: int = 20
var attack_cooldown: float = 0.5
var can_attack: bool = true
var is_attacking: bool = false
var is_hurt: bool = false

@onready var animated_sprite = $OrcAnimatedSprite

signal died(xp_value, player_id)

func _ready():
	add_to_group("enemy")  # Ensure orc is in enemy group
	animated_sprite.play("idle")
	animated_sprite.connect("animation_finished", _on_animation_finished)
#	print("Orc initialized at position: ", position)

func _physics_process(delta):
	if is_hurt or is_attacking:
		velocity.x = 0
#		print("Orc halted: is_hurt=", is_hurt, " is_attacking=", is_attacking)
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# AI: Move towards nearest player
	var players = get_tree().get_nodes_in_group("player")
#	print("Players found: ", players.size())
	if players.size() > 0:
		var target_player = players[0]
		var target_player_id = target_player.player_id if "player_id" in target_player else 0
		for p in players:
			if p.position.distance_to(position) < target_player.position.distance_to(position):
				target_player = p
				target_player_id = p.player_id if "player_id" in p else 0
		var direction = (target_player.position - position).normalized()
		velocity.x = direction.x * speed
		animated_sprite.flip_h = direction.x < 0
		animated_sprite.play("walk")
#		print("Orc moving to player at ", target_player.position, " velocity: ", velocity)
		
		# Attack if close
		var distance = position.distance_to(target_player.position)
		if distance < 50 and can_attack:
			perform_attack(target_player_id)
	else:
		velocity.x = 0
		animated_sprite.play("idle")
		print("No players found, idling")
	
	move_and_slide()

func perform_attack(target_player_id: int):
	is_attacking = true
	can_attack = false
	animated_sprite.play("attack01" if randf() < 0.5 else "attack02")
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var hitbox = RectangleShape2D.new()
	hitbox.extents = Vector2(20, 20)
	collision.shape = hitbox
	collision.position = Vector2(30 * (-1 if animated_sprite.flip_h else 1), 0)
	area.collision_layer = 0
	area.collision_mask = 1  # Player layer
	area.add_child(collision)
	add_child(area)
	area.connect("body_entered", func(body):
		if body.is_in_group("player") and "health" in body:
			body.take_damage(damage, target_player_id))
	await get_tree().create_timer(0.2).timeout
	area.queue_free()
	await get_tree().create_timer(attack_cooldown - 0.2).timeout
	can_attack = true

func take_damage(amount: float, attacker_id: int = 0):
	if is_hurt or health <= 0:
#		print("Orc damage skipped: is_hurt=", is_hurt, " health=", health)
		return
	health -= amount
	is_hurt = true
	animated_sprite.play("hurt")
#	print("Orc took damage: ", amount, " health remaining: ", health)
	if health <= 0:
		animated_sprite.play("death")
		$DeathParticles.emitting = true
		await animated_sprite.animation_finished
		emit_signal("died", xp_value, attacker_id)
		queue_free()

func _on_animation_finished():
	if animated_sprite.animation in ["attack01", "attack02"]:
		is_attacking = false
	if animated_sprite.animation == "hurt":
		is_hurt = false
		if health > 0:
			animated_sprite.play("idle")
#	print("Animation finished: ", animated_sprite.animation)
