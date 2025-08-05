extends Node


var callbackUser = JavaScriptBridge.create_callback(func(args): setUser.emit(args[0].target.value))
var callbackPass = JavaScriptBridge.create_callback(func(args): setPass.emit(args[0].target.value))
var callbackFile = JavaScriptBridge.create_callback(getFile)

signal setUser(value: String)
signal setPass(value: String)
signal setFile(path: String)


func _ready():
	if not OS.has_feature("web"): return
	
	JavaScriptBridge.get_interface("username").oninput = callbackUser
	JavaScriptBridge.get_interface("password").oninput = callbackPass

	var window = JavaScriptBridge.get_interface("window")
	window.readFile(callbackFile)

func openFile():
	JavaScriptBridge.get_interface("window").input.click()

# request a custom file dialog option
func getFile(args): #filetype?
	if not DirAccess.dir_exists_absolute("user://custom"):
		DirAccess.make_dir_absolute("user://custom")
	
	var data = args[0].split(",")[-1]
	var path = "user://custom/%s.png" % hash(data)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(Marshalls.base64_to_raw(data))
	file.close()
	setFile.emit(path)
	
	
