extends Camera3D

const dist = 300

@onready var pivot: Node3D = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			position.z = clamp(position.z - .5, 1, 15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			position.z = clamp(position.z + .5, 1, 15)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			pivot.rotation.x = clamp(pivot.rotation.x - event.relative.y / dist, -PI/2, 0)
			pivot.rotation.y -= event.relative.x / dist
		
