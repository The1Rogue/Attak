extends Control
class_name Settings

var saveData: SettingData

signal experimental(bool)

@export var Board: BoardContainer
@onready var boardSettings: Panel = $"Settings/BoardSettings"

func _ready() -> void:
	saveData = SettingData.loadOrNew()
	
	$"Settings/GridContainer/FullS".set_pressed_no_signal(saveData.fullScreen)
	$"Settings/GridContainer/FullS".toggled.connect(func(v): saveData.fullScreen = v)
	
	$"Settings/GridContainer/EXP".set_pressed_no_signal(saveData.experimental)
	$"Settings/GridContainer/EXP".toggled.connect(setEXP)
	
	$"Settings/GridContainer/BG".color = saveData.bgColor
	$"Settings/GridContainer/BG".color_changed.connect(setBG)
	
	$"Settings/GridContainer/Board".selected = 0 if saveData.is2D else 1
	$"Settings/GridContainer/Board".item_selected.connect(setBoard)
	
	experimental.emit(saveData.experimental)
	RenderingServer.set_default_clear_color(saveData.bgColor)
	setBoard(0 if saveData.is2D else 1)


func setEXP(on: bool):
	experimental.emit(on)
	saveData.experimental = on
	saveData.save()


func setBG(color: Color):
	RenderingServer.set_default_clear_color(color)
	saveData.bgColor = color
	saveData.save()


func setBoard(i: int):
	saveData.is2D = i == 0
	var b = await Board.set2D(i == 0)
	for c in boardSettings.get_children(): boardSettings.remove_child(c)
	boardSettings.add_child(b.settings.getScene())
	saveData.save()
