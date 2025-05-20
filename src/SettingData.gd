extends Resource
class_name SettingData

const savePath = "user://settings.res"

const playtakCap = preload("res://assets/Pieces3D/cap.obj")
const playtakFlat = preload("res://assets/Pieces3D/flat.obj")

static var DA: DirAccess = DirAccess.open("res://")

signal boardUpdate

@export_category("Global")
@export var experimental: bool = false
@export var bgColor: Color = Color("222a61")
@export var is2D: bool = false

@export_category("2D")
@export var sq2DPath: String = "res://assets/Squares/Standard.svg":
	set = setSq2D
func setSq2D(value):
	var tex = loadTexture(value)
	if tex == null: return 
	sq2D = tex; sq2DPath = value
	save(); boardUpdate.emit()
var sq2D: Texture2D

@export var white2DPath: String = "res://assets/Pieces2D/White/Standard.svg":
	set = setWhite2D
func setWhite2D(value):
	var tex = imgToPlaytak(loadImg(value))
	if tex.size() != 3 or null in tex: return 
	white2D = tex; white2DPath = value
	tex.append(ImageTexture.new()) 
	var smol = tex[0].get_image() #make smol overflow things
	smol.resize(tex[0].get_width() * .25, tex[0].get_height() * .125, 4)
	tex[3].set_image(smol)
	save(); boardUpdate.emit()
var white2D: Array[Texture2D]

@export var black2DPath: String = "res://assets/Pieces2D/Black/Standard.svg":
	set = setBlack2D
func setBlack2D(value):
	var tex = imgToPlaytak(loadImg(value))
	if tex.size() != 3 or null in tex: return 
	black2D = tex; black2DPath = value
	tex.append(ImageTexture.new()) 
	var smol = tex[0].get_image() #make smol overflow thing
	smol.resize(tex[0].get_width() * .25, tex[0].get_height() * .125, 4)
	tex[3].set_image(smol)
	save(); boardUpdate.emit()
var black2D: Array[Texture2D]

@export var pieceScale2D: float = .5:
	set = setScale2D
func setScale2D(value):
	pieceScale2D = value; save(); boardUpdate.emit()

@export_category("3D")
@export var FOV3D: int = 75:
	set = setFOV3D
func setFOV3D(value):
	FOV3D = value; save(); boardUpdate.emit()

@export var sq3DPath: String = "res://assets/Squares/Standard.svg":
	set = setSq3D
func setSq3D(value):
		var tex = loadTexture(value)
		if tex == null: return 
		sq3D = tex; sq3DPath = value
		save(); boardUpdate.emit()
var sq3D: Texture2D

@export var white3DPath: String = "res://assets/Pieces3D/White/Standard.glb":
	set = setWhite3D
func setWhite3D(value):
	var meshes = loadGLB(value) if value.ends_with(".glb") or value.ends_with(".gltf") else loadPlaytak3D(value)
	if meshes.size() != 2 or null in meshes: return
	white3DPath = value; white3D = meshes
	save(); boardUpdate.emit()
var white3D: Array[Mesh]

@export var black3DPath: String = "res://assets/Pieces3D/Black/Standard.glb":
	set = setBlack3D
func setBlack3D(value):
	var meshes = loadGLB(value) if value.ends_with(".glb") or value.ends_with(".gltf") else loadPlaytak3D(value)
	if meshes.size() != 2 or null in meshes: return
	black3DPath = value; black3D = meshes
	save(); boardUpdate.emit()
var black3D: Array[Mesh]

@export var wallRotation3D: Vector3 = Vector3(PI/2, PI/4, 0):
	set = setWall3D
func setWall3D(value):
	wallRotation3D = value; save(); boardUpdate.emit()

@export var pieceSize3D: float = .65:
	set = setSize3D
func setSize3D(value):
	pieceSize3D = value; save(); boardUpdate.emit()
@export var flatHeight3D: float = .14:
	set = setFlatHeight3D
func setFlatHeight3D(value):
	flatHeight3D = value; save(); boardUpdate.emit()
@export var capHeight3D: float = .65:
	set = setCapHeight3D
func setCapHeight3D(value):
	capHeight3D = value; save(); boardUpdate.emit()



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
		
		data.setSq2D(data.sq2DPath)
		data.setWhite2D(data.white2DPath)
		data.setBlack2D(data.black2DPath)
		
		data.setSq3D(data.sq3DPath)
		data.setWhite3D(data.white3DPath)
		data.setBlack3D(data.black3DPath)
	
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


static func loadImg(path: String) -> Image:
	var img
	if path.begins_with("res://"):
		img = load(path).get_image()
	else:
		img = Image.load_from_file(path)
	if img == null: return null
	if img.is_compressed():
		if img.decompress() != OK:
			return null
	img.fix_alpha_edges()
	return img


static func imgToPlaytak(img: Image) -> Array[Texture2D]:
	if img == null: return []
	var s: Vector2i = img.get_size() / 64
	var flat = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y * 37, s.x * 26, s.y * 26)))
	var wall = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y * 27, s.x * 26, s.y * 10)))
	var cap  = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y *  1, s.x * 26, s.y * 26)))
	return [flat, wall, cap]


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
