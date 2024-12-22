extends Resource
class_name SettingData

const savePath = "user://settings.res"


const playtakCap = "res://assets/3D/PlayTak/cap.obj"
const playtakFlat = "res://assets/3D/PlayTak/flat.obj"

static var DA: DirAccess = DirAccess.open("res://")

@export_category("Global")
@export var bgColor: Color = Color("21232c")
@export var is2D: bool = false

@export_category("2D")
@export var sq2DPath: String = "res://assets/Squares/standard.png"
var sq2D: Texture2D:
	get: return loadTexture(sq2DPath)
	set(value): sq2DPath = value.resource_path 

@export var white2DPath: String = "res://assets/Pieces2D/White Standard"
var white2D: Array[Texture2D]:
	get:
		if isDir(white2DPath):
			return loadTextures(white2DPath)
		return playtakTo2D(loadTexture(white2DPath))
	set(value): assert(false, "Cant set this var!")

@export var black2DPath: String = "res://assets/Pieces2D/Black Standard"
var black2D: Array[Texture2D]:
	get:
		if isDir(black2DPath):
			return loadTextures(black2DPath)
		return playtakTo2D(loadTexture(black2DPath))
	set(value): assert(false, "Cant set this var!")

@export var pieceScale2D: float = .75

@export_category("3D")
@export var sq3DPath: String = "res://assets/Squares/standard.png"
var sq3D: Texture2D:
	get: return loadTexture(sq3DPath)
	set(value): sq3DPath = value.resource_path 

@export var white3DPath: String = "res://assets/Pieces3D/White Standard"
var white3D: Array[Mesh]:
	get:
		if isDir(white3DPath):
			return loadMeshes(white3DPath)
		var cap = load(playtakCap)
		var flat = load(playtakFlat)
		cap.surface_get_material(0).albedo_texture = loadTexture(white3DPath)
		flat.surface_get_material(0).albedo_texture = loadTexture(white3DPath)
		return [cap, flat]
	set(value): assert(false, "Cant set this var!")

@export var black3DPath: String = "res://assets/Pieces3D/Black Standard"
var black3D: Array[Mesh]:
	get:
		if isDir(black3DPath):
			return loadMeshes(black3DPath)
		var cap = load(playtakCap)
		var flat = load(playtakFlat)
		cap.surface_get_material(0).albedo_texture = loadTexture(black3DPath)
		flat.surface_get_material(0).albedo_texture = loadTexture(black3DPath)
		return [cap, flat]
	set(value): assert(false, "Cant set this var!")

@export var wallRotation3D: Vector3 = Vector3(PI/2, PI/4, 0)

@export var pieceSize3D: float = .9
@export var flatHeight3D: float = .2
@export var capHeight3D: float = 1.2


func repair():
	var defaults = SettingData.new()
	if not DA.file_exists(sq2DPath):
		sq2DPath = defaults.sq2DPath
	
	if not DA.file_exists(sq3DPath):
		sq2DPath = defaults.sq3DPath
	
	var meshes = white3D
	if meshes.size() != 2 or meshes[0] == null or meshes[1] == null:
		white3DPath = defaults.white3DPath
	
	meshes = black3D
	if meshes.size() != 2 or meshes[0] == null or meshes[1] == null:
		black3DPath = defaults.black3DPath

	var texs = white2D
	if texs.size() != 3 or texs[0] == null or texs[1] == null or texs[2] == null:
		white2DPath = defaults.white2DPath
	
	texs = black2D
	if texs.size() != 3 or texs[0] == null or texs[1] == null or texs[2] == null:
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


static func loadMeshes(path: String) -> Array[Mesh]:
	if path.begins_with("res://"):
		var files = DA.get_files_at(path)
		var cap
		var flat
		for i in files:
			if i.begins_with("cap."):
				cap = i.trim_suffix(".import")
			elif i.begins_with("flat."):
				flat = i.trim_suffix(".import")
		if cap == null or flat == null: return []
		return [load(path + "/" + cap), load(path + "/" + flat)]
		
	else:
		return []


static func loadTextures(path: String) -> Array[Texture2D]:
	var files = DA.get_files_at(path)
	var cap
	var flat
	var wall
	for i in files:
		if i.begins_with("cap."):
			cap = i.trim_suffix(".import")
		elif i.begins_with("flat."):
			flat = i.trim_suffix(".import")
		elif i.begins_with("wall."):
			wall = i.trim_suffix(".import")
	if cap == null or flat == null or wall == null: return []
	return [loadTexture(path+"/"+cap), loadTexture(path+"/"+flat), loadTexture(path+"/"+wall)]


static func playtakTo2D(playtak: Texture2D) -> Array[Texture2D]:
	var texs: Array[Texture2D] = []
	var tex = AtlasTexture.new()
	tex.atlas = playtak
	tex.region.size = playtak.get_size() * 3.0 / 8
	tex.region.position = playtak.get_size() * Vector2(9.0/16, 1.0/32)
	texs.append(tex)
	tex = AtlasTexture.new()
	tex.atlas = playtak
	tex.region.size = playtak.get_size() * 3.0 / 8
	tex.region.position = playtak.get_size() * Vector2(9.0/16, 19.0/32)
	texs.append(tex)
	tex = AtlasTexture.new()
	tex.atlas = playtak
	tex.region.size = playtak.get_size() * Vector2(3.0 / 8, 3.0 / 32)
	tex.region.position = playtak.get_size() * Vector2(9.0/16, 29.0/64)
	texs.append(tex)
	return texs


static func loadTexture(path: String) -> Texture2D:
	if path.begins_with("res://"):
		return load(path)
	else:
		var img = Image.load_from_file(path)
		return ImageTexture.create_from_image(img)


static func isDir(path: String):
	#print("checking " + path)
	var t = not DA.file_exists(path)
	#print(t)
	return t
