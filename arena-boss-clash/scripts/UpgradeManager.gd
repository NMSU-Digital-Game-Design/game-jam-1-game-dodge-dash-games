# scripts/UpgradeManager.gd
extends Node

var upgrades = [
	{"name": "Damage Up", "effect": "damage", "value": 0.1},
	{"name": "Health Up", "effect": "health", "value": 50},
	{"name": "Homing Projectiles", "effect": "homing", "value": true},
	{"name": "Dash Cooldown", "effect": "dash_cooldown", "value": -0.5}
]

func _ready():
	Global.connect("level_up", _on_level_up)

func _on_level_up(level):
	get_tree().paused = true
	var options = generate_random_upgrades()
	show_upgrade_ui(options)

func generate_random_upgrades():
	var available = upgrades.duplicate()
	var selected = []
	for i in 3:
		if available.is_empty(): break
		var index = randi() % available.size()
		selected.append(available[index])
		available.remove_at(index)
	return selected

func show_upgrade_ui(options):
	for i in options.size():
		var button = TextureButton.new()
		button.texture_normal = preload("res://assets/sprites/upgrade_card.png")  # Placeholder
		button.text = options[i].name
		button.position = Vector2(400, 200 + i * 100)
		button.connect("pressed", _on_upgrade_selected.bind(options[i]))
		$CanvasLayer.add_child(button)

func _on_upgrade_selected(upgrade):
	var player = get_tree().get_first_node_in_group("player")
	player.apply_upgrade(upgrade)
	for child in $CanvasLayer.get_children():
		child.queue_free()
	get_tree().paused = false
