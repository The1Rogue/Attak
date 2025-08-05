extends Resource
class_name SettingData

const savePath = "user://settings.res"

const playtakCap = preload("res://assets/Pieces3D/cap.obj")
const playtakFlat = preload("res://assets/Pieces3D/flat.obj")

signal boardUpdate

@export var experimental: bool = false
@export var fullScreen: bool = false:
	set(v):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED)
		fullScreen = v
		save()
@export var bgColor: Color = Color("222a61")
@export var is2D: bool = false

@export var pieceScale2D: float = .5:
	set = setScale2D
func setScale2D(value):
	pieceScale2D = value; save(); boardUpdate.emit()


func save():
	ResourceSaver.save(self, savePath)


static func loadOrNew() -> SettingData:
	var data
	if ResourceLoader.exists(savePath):
		ResourceLoader.load_threaded_request(savePath, "", true)
		data = ResourceLoader.load_threaded_get(savePath)
		if data == null: # data couldnt load correctly
			data = SettingData.new()
			
	else:
		data = SettingData.new()
		data.is2D = Globals.isMobile()
		data.save()
	
	return data
