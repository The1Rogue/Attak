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
	
	if OS.get_name() != "web":
		var p = FileDialog.new()
		p.file_selected.connect(selectCustom)
		p.dir_selected.connect(selectCustom)
		p.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		p.access = FileDialog.ACCESS_FILESYSTEM
		p.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		p.size = get_viewport_rect().size / 2
		
		customButton.pressed.connect(p.show)
		customButton.add_child(p)
		p.hide()
		
	else:
		pass
		#customButton.pressed.connect()
		
	
	for i in DirAccess.get_files_at(path):
		if not i.ends_with(".import"): continue
		var name = i.split(".", false, 1)[0]
		options.append(i.trim_suffix(".import"))
		optionButton.add_item(name, options.size())
		
	optionButton.item_selected.connect(select)


func select(i: int):
	customButton.visible = i == 0
	
	if i != 0:
		setSetting.emit(path + options[i-1])


func selectCustom(custom: String):
	setSetting.emit(custom)


func setNoSignal(value: Variant):
	assert(value is String)
	optionButton.selected = options.find(value.trim_prefix(path)) + 1
	if optionButton.selected == 0:
		customButton.show()


func getCustomFile():
	pass
