extends Control
class_name Settings

var saveData: SettingData

signal experimental(bool)

@export var board3D: PackedScene
@export var board2D: PackedScene

@export var boardHolder: SubViewport

var board: BoardLogic


func loadFull(data: SettingData):
	experimental.emit(data.experimental)
	RenderingServer.set_default_clear_color(data.bgColor)


func _ready() -> void:
	saveData = SettingData.loadOrNew()
	
	$"GridContainer/EXP".set_pressed_no_signal(saveData.experimental)
	$"GridContainer/EXP".toggled.connect(setEXP)
	
	$"GridContainer/BG".color = saveData.bgColor
	$"GridContainer/BG".color_changed.connect(setBG)
	
	# 2D
	$"Board/2D Board/Squares".setNoSignal(saveData.sq2DPath)
	$"Board/2D Board/Squares".setSetting.connect(saveData.setSq2D)
	
	$"Board/2D Board/White".setNoSignal(saveData.white2DPath)
	$"Board/2D Board/White".setSetting.connect(saveData.setWhite2D)
	
	$"Board/2D Board/Black".setNoSignal(saveData.black2DPath)
	$"Board/2D Board/Black".setSetting.connect(saveData.setBlack2D)
	
	$"Board/2D Board/PieceSize".setNoSignal(saveData.pieceScale2D)
	$"Board/2D Board/PieceSize".setSetting.connect(saveData.setScale2D)
	
	# 3D
	$"Board/3D Board/FOV".setNoSignal(saveData.FOV3D)
	$"Board/3D Board/FOV".setSetting.connect(saveData.setFOV3D)
	
	$"Board/3D Board/Squares".setNoSignal(saveData.sq3DPath)
	$"Board/3D Board/Squares".setSetting.connect(saveData.setSq3D)
	
	$"Board/3D Board/White".setNoSignal(saveData.white3DPath)
	$"Board/3D Board/White".setSetting.connect(saveData.setWhite3D)
	
	$"Board/3D Board/Black".setNoSignal(saveData.black3DPath)
	$"Board/3D Board/Black".setSetting.connect(saveData.setBlack3D)
	
	$"Board/3D Board/WallAngle".setNoSignal(saveData.wallRotation3D.y / PI * 180)
	$"Board/3D Board/WallAngle".setSetting.connect(saveData.setWall3D)
	
	$"Board/3D Board/PieceSize".setNoSignal(saveData.pieceSize3D)
	$"Board/3D Board/PieceSize".setSetting.connect(saveData.setSize3D)
	
	$"Board/3D Board/FlatHeight".setNoSignal(saveData.flatHeight3D)
	$"Board/3D Board/FlatHeight".setSetting.connect(saveData.setFlatHeight3D)
	
	$"Board/3D Board/CapHeight".setNoSignal(saveData.capHeight3D)
	$"Board/3D Board/CapHeight".setSetting.connect(saveData.setCapHeight3D)
	
	loadFull(saveData)
	setBoard(0 if saveData.is2D else 1)
	$Board.current_tab = 0 if saveData.is2D else 1
	$Board.tab_changed.connect(setBoard)
	saveData.boardUpdate.connect(updateGFX)

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
	if board != null:
		boardHolder.remove_child(board)
		board.queue_free()
	board = (board2D if i == 0 else board3D).instantiate()
	board.setData(saveData)
	boardHolder.add_child(board)
	saveData.save()

func updateGFX():
	if board == null: return
	else: board.setData(saveData)
