extends BoardSettings
class_name Settings3D


const path: String = "user://Settings3D.res"
const scene = preload("res://scenes/Settings3D.tscn")

const playtakCap = preload("res://assets/Pieces3D/cap.obj")
const playtakFlat = preload("res://assets/Pieces3D/flat.obj")

@export var fov: int = 75:
	set(value): 
		fov = value
		save(); update.emit()

@export var size: float = .65:
	set(value): 
		size = value
		save(); update.emit()

@export var flatH: float = .14:
	set(value): 
		flatH = value
		save(); update.emit()

@export var capH: float = .65:
	set(value): 
		capH = value
		save(); update.emit()

@export var wall: int = 45:
	set(value): 
		wall = value
		save(); update.emit()

@export var sqName: String
@export var sq: Texture
func setSq(value):
	sq = ImageTexture.create_from_image(value[0])
	sqName = value[1]
	save(); update.emit()

@export var whiteName: String
@export var white: Array[Mesh]
func setWhite(value):
	whiteName = value[1]
	if value[0] is Image:
		white = splitImg(value[0])
	elif value[0] is Array:
		white.assign(value[0])
	save(); update.emit()

@export var blackName: String
@export var black: Array[Mesh]
func setBlack(value):
	blackName = value[1]
	if value[0] is Image:
		black = splitImg(value[0])
	elif value[0] is Array:
		black.assign(value[0])
	save(); update.emit()

func getScene():
	var s = scene.instantiate()
	
	s.get_child(0).setNoSignal(fov)
	s.get_child(0).setSetting.connect(func(value): fov = value; save())
	
	s.get_child(1).setNoSignal(sqName)
	s.get_child(1).setSetting.connect(setSq)
	
	s.get_child(2).setNoSignal(whiteName)
	s.get_child(2).setSetting.connect(setWhite)
	
	s.get_child(3).setNoSignal(blackName)
	s.get_child(3).setSetting.connect(setBlack)
	
	s.get_child(4).setNoSignal(wall)
	s.get_child(4).setSetting.connect(func(value): wall = value; save())
	
	s.get_child(5).setNoSignal(size)
	s.get_child(5).setSetting.connect(func(value): size = value; save())
	
	s.get_child(6).setNoSignal(flatH)
	s.get_child(6).setSetting.connect(func(value): flatH = value; save())
	
	s.get_child(7).setNoSignal(capH)
	s.get_child(7).setSetting.connect(func(value): capH = value; save())
	return s


func check():
	fov = clamp(10, fov, 90)
	size = clamp(.3, size, 1)
	flatH = clamp(.05, flatH, .5)
	capH = clamp(.4, capH, 2)
	wall = clamp(0, wall, 90)
	
	
	if sq == null:
		sq = ImageTexture.create_from_image(loadImg("res://assets/Squares/Standard.svg"))
	
	if white == null or white.size() != 2 or null in white:
		white = loadGLB("res://assets/Pieces3D/White/Standard.glb")
	
	if black == null or black.size() != 2 or null in black:
		black = loadGLB("res://assets/Pieces3D/Black/Standard.glb")


static func loadGLB(path: String) -> Array[Mesh]:
	var root: Node
	if path.begins_with("res://"):
		var tmp = load(path)
		if tmp == null: return []
		root = tmp.instantiate()
		
	else:
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		var error = doc.append_from_file(path, state)
		if error != OK:
			return [null, null]
		root = doc.generate_scene(state)
		
	var paths = [root.get_node("Cap"), root.get_node("Flat")]
	if paths[0] == null or paths[1] == null:
		return []
	return [paths[0].mesh, paths[1].mesh]


static func splitImg(img: Image) -> Array[Mesh]:
	var tex = ImageTexture.create_from_image(img)
	var cap: Mesh = playtakCap.duplicate()
	cap.surface_set_material(0, cap.surface_get_material(0).duplicate())
	cap.surface_get_material(0).albedo_texture = tex
	var flat: Mesh = playtakFlat.duplicate()
	flat.surface_set_material(0, flat.surface_get_material(0).duplicate())
	flat.surface_get_material(0).albedo_texture = tex
	return [cap, flat]
