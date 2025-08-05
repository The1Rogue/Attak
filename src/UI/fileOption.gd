extends Setting
class_name FolderSetting

@export var path: String

var optionButton: OptionButton
var options: Array[String] = []

var customButton: Button

var callbackFile = JavaScriptBridge.create_callback(parseFile) if OS.has_feature("web") else null


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


func setNoSignal(value: Variant):
	assert(value is String)
	if not is_node_ready(): await ready
	optionButton.selected = options.find(value) + 1
	if optionButton.selected == 0:
		customButton.show()


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
	var window = JavaScriptBridge.get_interface("window")
	window.readFile(callbackFile)
	window.input.click()


func parseFile(args):
	args = args[0].split(",")
	var type = args[0].split(";")
	
	var data = args[1]
	if type[1] == "base64":
		data = Marshalls.base64_to_raw(data)
	else:
		Notif.message("Unsupported Encoding: %s" % type[1])
		return
	
	if type[0].begins_with("data:model/"):
		if not type[0] == "data:model/gltf-binary":
			Notif.message("Unsupported Model Type")
			return
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		var error = doc.append_from_buffer(data, "", state)
		if error != OK:
			Notif.message("Failed to load custom model")
			return
		data = doc.generate_scene(state)
		data = [data.get_node("Cap"), data.get_node("Flat")]
		if null in data:
			Notif.message("Model does not include 'Cap' and/or 'Flat'")
			return
		setSetting.emit([[data[0].mesh, data[1].mesh], "custom"])
	
	elif type[0].begins_with("data:image/"):
		var img = Image.new()
		if type[0] == "data:image/bmp":
			img.load_bmp_from_buffer(data)
		elif type[0] == "data:image/jpg":
			img.load_jpg_from_buffer(data)
		elif type[0] == "data:image/ktx":
			img.load_ktx_from_buffer(data)
		elif type[0] == "data:image/png":
			img.load_png_from_buffer(data)
		elif type[0] == "data:image/svg+xml":
			img.load_svg_from_buffer(data)
		elif type[0] == "data:image/tga":
			img.load_tga_from_buffer(data)
		elif type[0] == "data:image/webp":
			img.load_webp_from_buffer(data)
		else:
			Notif.message("Unsupported Image Type %s" % type[0].substr(11))
			return
		
		setSetting.emit([img, "custom"])
	
	else:
		Notif.message("Cant recognize File")
		return
