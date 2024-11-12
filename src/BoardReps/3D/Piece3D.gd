extends StaticBody3D
class_name Piece3D

static var hover: ShaderMaterial
static var highlight: ShaderMaterial
static var dragThreshHold: float = 8

var selected: bool = false
var highlighted: bool = false:
	set(v):
		highlighted = v
		mesh.material_overlay = highlight if v else null


var dragLength: float = 0

var id: int
var mesh: MeshInstance3D

signal click(piece: Piece3D, isRight: bool)

func _init(m: Mesh, shape: Shape3D, id: int):
	self.id = id
	mesh = MeshInstance3D.new()
	mesh.mesh = m
	add_child(mesh)
	var collider = CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

func _mouse_enter() -> void:
	mesh.material_overlay = hover


func _mouse_exit() -> void:
	mesh.material_overlay = highlight if highlighted else null


func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and dragLength < dragThreshHold:
			if event.button_index == MOUSE_BUTTON_LEFT:
				click.emit(self, false)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				click.emit(self, true)
	
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			dragLength += event.relative.length()
		
		else:
			dragLength = 0
