extends Area2D

signal despawned(arrow)

var speed: float = 400.0  # pixels/s
var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var player_id: int = 0

func _ready():
	$VisibleOnScreenNotifier2D.connect("screen_exited", _on_screen_exited)

func _physics_process(delta):
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("enemy") or area.is_in_group("boss"):
		if "health" in area:
			area.health -= damage
		despawn()

func _on_screen_exited():
	despawn()

func despawn():
	emit_signal("despawned", self)
	visible = false
	set_physics_process(false)
