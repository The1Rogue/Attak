extends Resource
class_name SettingData

const savePath = "user://settings.res"


const playtakCap = preload("res://assets/Pieces3D/cap.obj")
const playtakFlat = preload("res://assets/Pieces3D/flat.obj")

static var DA: DirAccess = DirAccess.open("res://")

@export_category("Global")
@export var experimental: bool = false
@export var bgColor: Color = Color("222a61")
@export var is2D: bool = false

@export_category("2D")
@export var sq2DPath: String = "res://assets/Squares/Standard.svg"
var sq2D: Texture2D:
	get: return loadTexture(sq2DPath)
	set(value): sq2DPath = value.resource_path 

@export var white2DPath: String = "res://assets/Pieces2D/White/Standard.svg"
var white2D: Array[Texture2D]:
	get:
		return loadPlaytak2D(white2DPath)
	set(value): assert(false, "Cant set this var!")

@export var black2DPath: String = "res://assets/Pieces2D/Black/Standard.svg"
var black2D: Array[Texture2D]:
	get:
		return loadPlaytak2D(black2DPath)
	set(value): assert(false, "Cant set this var!")

@export var pieceScale2D: float = .5

@export_category("3D")
@export var FOV3D: int = 75

@export var sq3DPath: String = "res://assets/Squares/Standard.svg"
var sq3D: Texture2D:
	get: return loadTexture(sq3DPath)
	set(value): sq3DPath = value.resource_path 

@export var white3DPath: String = "res://assets/Pieces3D/White/Standard.glb"
var white3D: Array[Mesh]:
	get:
		if white3DPath.ends_with(".glb") or white3DPath.ends_with(".gltf"):
			return loadGLB(white3DPath)
		return loadPlaytak3D(white3DPath)
	set(value): assert(false, "Cant set this var!")

@export var black3DPath: String = "res://assets/Pieces3D/Black/Standard.glb"
var black3D: Array[Mesh]:
	get:
		if black3DPath.ends_with(".glb") or black3DPath.ends_with(".gltf"):
			return loadGLB(black3DPath)
		return loadPlaytak3D(black3DPath)
	set(value): assert(false, "Cant set this var!")

@export var wallRotation3D: Vector3 = Vector3(PI/2, PI/4, 0)

@export var pieceSize3D: float = .65
@export var flatHeight3D: float = .14
@export var capHeight3D: float = .65


func repair():
	var defaults = SettingData.new()
	if not DA.file_exists(sq2DPath):
		sq2DPath = defaults.sq2DPath
	
	if not DA.file_exists(sq3DPath):
		sq2DPath = defaults.sq3DPath
	
	var meshes = white3D
	if meshes.size() != 2 or null in meshes:
		white3DPath = defaults.white3DPath
	
	meshes = black3D
	if meshes.size() != 2 or null in meshes:
		black3DPath = defaults.black3DPath

	var texs = white2D
	if texs.size() != 3 or null in texs:
		white2DPath = defaults.white2DPath
	
	texs = black2D
	if texs.size() != 3 or null in texs:
		black2DPath = defaults.black2DPath


func save():
	ResourceSaver.save(self, savePath)


static func loadOrNew() -> SettingData:
	var data
	if ResourceLoader.exists(savePath):
		data = ResourceLoader.load(savePath)
		data.repair() #just to be sure
	else:
		data = SettingData.new()
		data.is2D = Globals.isMobile()
	return data


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


static func loadPlaytak2D(path: String) -> Array[Texture2D]:
	var img: Image
	if path.begins_with("res://"):
		img = load(path).get_image()
	else:
		img = Image.load_from_file(path)
	if img == null: return []
	if img.is_compressed():
		if img.decompress() != OK:
			return []
	img.fix_alpha_edges()
	var s: Vector2i = img.get_size() / 64
	var cap  = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y *  1, s.x * 26, s.y * 26)))
	var flat = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y * 37, s.x * 26, s.y * 26)))
	var wall = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y * 27, s.x * 26, s.y * 10)))
	return [cap, flat, wall]


static func loadTexture(path: String) -> Texture2D:
	if path.begins_with("res://"):
		return load(path)
	else:
		var img = Image.load_from_file(path)
		img.fix_alpha_edges()
		return ImageTexture.create_from_image(img)


static func loadPlaytak3D(path: String) -> Array[Mesh]:
	var tex = loadTexture(path)
	var cap: Mesh = playtakCap.duplicate()
	cap.surface_set_material(0, cap.surface_get_material(0).duplicate())
	cap.surface_get_material(0).albedo_texture = tex
	var flat: Mesh = playtakFlat.duplicate()
	flat.surface_set_material(0, flat.surface_get_material(0).duplicate())
	flat.surface_get_material(0).albedo_texture = tex
	return [cap, flat]
