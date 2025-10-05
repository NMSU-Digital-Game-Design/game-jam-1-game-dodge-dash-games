extends CharacterBody2D
@export var player_id: int = 0
@export var is_active: bool = true  # For testing disablement
@export var jump_buffer_time: float = 0.05  # Grace period in seconds for jump input
var input_suffix: String = "_p" + str(player_id + 1)
var speed: float = 300.0
var jump_velocity: float = -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")  # Default: 980

func _ready():
	add_to_group("player")
	collision_layer = 1  # Player on layer 1
	collision_mask = 14  # Collide with ground (layer 2), platforms (layer 3), hazards (layer 4)
	$JumpBufferTimer.wait_time = jump_buffer_time
	if not is_active:
		visible = false
		set_process(false)
		set_physics_process(false)
		$GroundCollision.disabled = true

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
		$JumpBufferTimer.start()
	
	# Jump execution (buffer or hold)
	if is_on_floor() and (not $JumpBufferTimer.is_stopped() or Input.is_action_pressed("ui_up" + input_suffix)):
		velocity.y = jump_velocity
		$JumpBufferTimer.stop()  # Clear buffer after jumping
	
	# Platform pass-through
	if Input.is_action_pressed("ui_down" + input_suffix):
		collision_mask = 10  # Only collide with ground (layer 2) and hazards (layer 4)
	else:
		collision_mask = 14  # Collide with ground, platforms, hazards
	
	move_and_slide()
