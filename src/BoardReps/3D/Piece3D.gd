extends StaticBody3D
class_name Piece3D

static var highlight: ShaderMaterial
static var dragThreshHold: float = 8

var selected: bool = false

var dragLength: float = 0

var id: int
var mesh: MeshInstance3D

signal click(Piece3D)

func _init(m: Mesh, shape: Shape3D, id: int):
	self.id = id
	mesh = MeshInstance3D.new()
	mesh.mesh = m
	add_child(mesh)
	var collider = CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)


func _mouse_enter() -> void:
	mesh.material_overlay = highlight


func _mouse_exit() -> void:
	mesh.material_overlay = null


func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and dragLength < dragThreshHold:
			click.emit(self)
	
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			dragLength += event.relative.length()
		
		else:
			dragLength = 0
