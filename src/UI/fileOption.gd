extends Setting
class_name FolderSetting

@export var path: String

var optionButton: OptionButton
var options: Array[String] = []

var customButton: Button

func _ready() -> void:
	super()
	
	optionButton = OptionButton.new()
	optionButton.add_item("Custom", 0)
	add_child(optionButton)

	add_child(Control.new())


	customButton = Button.new()
	customButton.text = "Select Custom"
	add_child(customButton)
	customButton.hide()
	
	if not OS.has_feature("web"):
		var p = FileDialog.new()
		p.file_selected.connect(loadPath)
		p.use_native_dialog = true
		p.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		p.access = FileDialog.ACCESS_FILESYSTEM
		p.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		p.size = get_viewport_rect().size / 2
		
		customButton.pressed.connect(p.show)
		customButton.add_child(p)
		p.hide()
		
	else:
		customButton.pressed.connect(getJSFile)
		
	
	for i in DirAccess.get_files_at(path):
		if not i.ends_with(".import"): continue
		var name = i.split(".", false, 1)[0]
		options.append(i.trim_suffix(".import"))
		optionButton.add_item(name, options.size())
		
	optionButton.item_selected.connect(select)


func select(i: int):
	customButton.visible = i == 0
	if i != 0:
		loadPath(path + options[i-1])

#
#func selectCustom(custom: String):
	#setSetting.emit(custom)


func setNoSignal(value: Variant):
	assert(value is String)
	if not is_node_ready(): await ready
	optionButton.selected = options.find(value) + 1
	if optionButton.selected == 0:
		customButton.show()


#func getCustomFile():
	#JsInterface.setFile.connect(setSetting.emit, CONNECT_ONE_SHOT)
	#JsInterface.openFile()/


func loadPath(path: String):
	var data
	var suffix = path.split(".")[-1]
	if suffix in ["glb", "gltf"]:
		if path.begins_with("res://"):
			data = load(path).instantiate()
		else:
			var doc = GLTFDocument.new()
			var state = GLTFState.new()
			var error = doc.append_from_file(path, state)
			if error != OK:
				Notif.message("Failed to load '%s'" % path)
				return
			data = doc.generate_scene(state)
		data = [data.get_node("Cap"), data.get_node("Flat")]
		if null in data:
			Notif.message("%s does not include 'Cap' and/or 'Flat'" % path)
			return
		data = [data[0].mesh, data[1].mesh]
		
	elif suffix in ["jpg", "ktx", "png", "svg", "tga", "webp", "bmp"]:
		if path.begins_with("res://"):
			data = load(path).get_image()
		else:
			data = Image.load_from_file(path)
		
		if data == null: 
			Notif.message("Failed to load '%s'" % path)
			return
		if data.is_compressed():
			if data.decompress() != OK:
				Notif.message("Failed to load '%s'" % path)
				return
		data.fix_alpha_edges()
		
	else:
		Notif.message("Unsupported file type '%s'" % suffix)
		return
		
	if data == null:
		Notif.message("Failed to load '%s'" % path)
	else:
		setSetting.emit([data, path.split("/")[-1]])


func getJSFile():
	pass
