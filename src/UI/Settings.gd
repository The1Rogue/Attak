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
	$"Board/2D Board/Squares".setSetting.connect(set2DSq)
	
	$"Board/2D Board/White".setNoSignal(saveData.white2DPath)
	$"Board/2D Board/White".setSetting.connect(set2DWhite)
	
	$"Board/2D Board/Black".setNoSignal(saveData.black2DPath)
	$"Board/2D Board/Black".setSetting.connect(set2DBlack)
	
	$"Board/2D Board/PieceSize".setNoSignal(saveData.pieceScale2D)
	$"Board/2D Board/PieceSize".setSetting.connect(set2DPieceSize)
	
	# 3D
	$"Board/3D Board/FOV".setNoSignal(saveData.FOV3D)
	$"Board/3D Board/FOV".setSetting.connect(set3DFOV)
	
	$"Board/3D Board/Squares".setNoSignal(saveData.sq3DPath)
	$"Board/3D Board/Squares".setSetting.connect(set3DSq)
	
	$"Board/3D Board/White".setNoSignal(saveData.white3DPath)
	$"Board/3D Board/White".setSetting.connect(set3DWhite)
	
	$"Board/3D Board/Black".setNoSignal(saveData.black3DPath)
	$"Board/3D Board/Black".setSetting.connect(set3DBlack)
	
	$"Board/3D Board/WallAngle".setNoSignal(saveData.wallRotation3D.y / PI * 180)
	$"Board/3D Board/WallAngle".setSetting.connect(setWallRot)
	
	$"Board/3D Board/PieceSize".setNoSignal(saveData.pieceSize3D)
	$"Board/3D Board/PieceSize".setSetting.connect(set3DPieceSize)
	
	$"Board/3D Board/FlatHeight".setNoSignal(saveData.flatHeight3D)
	$"Board/3D Board/FlatHeight".setSetting.connect(setFlatHeight)
	
	$"Board/3D Board/CapHeight".setNoSignal(saveData.capHeight3D)
	$"Board/3D Board/CapHeight".setSetting.connect(setCapHeight)
	
	loadFull(saveData)
	setBoard(0 if saveData.is2D else 1)
	$Board.current_tab = 0 if saveData.is2D else 1
	$Board.tab_changed.connect(setBoard)


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


func set2DSq(path: String):
	var tex = SettingData.loadTexture(path)
	
	if tex == null:
		Notif.message("Failed to load file %s!" % path)
		return
	
	saveData.sq2DPath = path
	if board is Board2D:
		board.sq = tex
	saveData.save()


func set2DWhite(path: String):
	var tex = [null, null, null]
	tex = SettingData.loadPlaytak2D(path)
		
	if tex.size() != 3 or null in tex:
		Notif.message("Failed to load %s!" % path)
		return
	
	saveData.white2DPath = path
	if board is Board2D:
		board.WhiteCap = tex[0]
		board.WhiteFlat = tex[1]
		board.WhiteWall = tex[2]
	saveData.save()


func set2DBlack(path: String):
	var tex = [null, null, null]
	tex = SettingData.loadPlaytak2D(path)
		
	if tex.size() != 3 or null in tex:
		Notif.message("Failed to load %s!" % path)
		return
	
	saveData.black2DPath = path
	if board is Board2D:
		board.BlackCap = tex[0]
		board.BlackFlat = tex[1]
		board.BlackWall = tex[2]
	saveData.save()


func set2DPieceSize(size: float):
	saveData.pieceScale2D = size
	if board is Board2D:
		board.pieceSize = size
	saveData.save()


func set3DFOV(value: int):
	saveData.FOV3D = value
	if board is Board3D:
		board.Cam.fov = value
	saveData.save()


func set3DSq(path: String):
	var tex = SettingData.loadTexture(path)
	
	if tex == null:
		Notif.message("Failed to load file %s!" % path)
		return
	
	saveData.sq3DPath = path
	if board is Board3D:
		board.squares.mesh.material.albedo_texture = tex
	saveData.save()


func set3DWhite(path: String):
	var meshes = SettingData.loadGLB(path) if path.ends_with(".glb") or path.ends_with(".gltf") else SettingData.loadPlaytak3D(path)
		
	if meshes.size() != 2 or null in meshes:
		Notif.message("Failed to load %s!" % path)
		return
	
	saveData.white3DPath = path
	if board is Board3D:
		board.whiteCapMesh = meshes[0]
		board.whiteFlatMesh = meshes[1]
	saveData.save()


func set3DBlack(path: String):
	var meshes = SettingData.loadGLB(path) if path.ends_with(".glb") or path.ends_with(".gltf") else SettingData.loadPlaytak3D(path)
		
	if meshes.size() != 2 or null in meshes:
		Notif.message("Failed to load %s!" % path)
		return
	
	saveData.black3DPath = path
	if board is Board3D:
		board.blackCapMesh = meshes[0]
		board.blackFlatMesh = meshes[1]
	saveData.save()


func setWallRot(angle: float):
	var rads = angle * PI / 180
	saveData.wallRotation3D.y = rads
	if board is Board3D:
		board.ROTATION[1].y = rads
		for i in 2*board.flats:
			if board.pieces[2*board.caps + i].rotation != board.ROTATION[0]:
				board.pieces[2*board.caps + i].rotation.y = rads
	saveData.save()


func set3DPieceSize(size: float):
	saveData.pieceSize3D = size
	if board is Board3D:
		board.pieceSize = size
	saveData.save()


func setFlatHeight(height: float):
	saveData.flatHeight3D = height
	if board is Board3D:
		board.flatHeight = height
	saveData.save()


func setCapHeight(height: float):
	saveData.capHeight3D = height
	if board is Board3D:
		board.capHeight = height
	saveData.save()
