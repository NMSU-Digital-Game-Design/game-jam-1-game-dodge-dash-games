extends Camera2D

func _physics_process(delta: float) -> void:
	print(position)
	if Input.is_action_pressed("ui_left"):
		offset.x -= 10
	if Input.is_action_pressed("ui_right"):
		offset.x += 10
	if Input.is_action_pressed("ui_up"):
		offset.y -= 10
	if Input.is_action_pressed("ui_down"):
		offset.y += 10
