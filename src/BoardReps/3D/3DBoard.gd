extends BoardLogic
class_name Board3D

const SELECTIONHEIGHT = 1

#var settings.size: float = .9:
	#set(value): settings.size = value; for i in pieces: i.scale = Vector3(value, i.scale.y, value)
#var settings.capH: float = 1.2:
	#set(value): 
		#settings.capH = value
		#for i in 2*caps: 
			#pieces[i].scale.y = value
		#setState(GameLogic.viewedState())
#var settings.flatH: float = .2:
	#set(value): 
		#settings.flatH = value
		#for i in 2*flats: 
			#pieces[2*caps + i].scale.y = value
		#setState(GameLogic.viewedState())
#
#var ROTATION = [Vector3.ZERO, Vector3(PI/2, PI/4, 0)]

var pieces: Array[Piece3D]
@onready var board = $board
@onready var squares = $board/top

var dragLength: float
@export var dragThreshHold: float = 8: 
	set(v):
		dragThreshHold = v
		Piece3D.dragThreshHold = v

const dist = 300
const mobileZoomMod: float = .02
const CAM_MAX = 50
const CAM_MIN = 1
var I0: Vector2
@onready var Cam: Camera3D = $Pivot/Camera3D
@onready var Pivot: Node3D = $Pivot

@onready var pieceHolder = $Pieces

#var settings.white[1]: Mesh:
	#set(value): 
		#settings.white[1] = value
		#for i in flats:
			#pieces[2 * (i+caps)].mesh.mesh = value
#var whiteCapMesh: Mesh:
	#set(value): 
		#whiteCapMesh = value
		#for i in caps:
			#pieces[2 * i].mesh.mesh = value
#
#var settings.black[1]: Mesh:
	#set(value): 
		#settings.black[1] = value
		#for i in flats:
			#pieces[2 * (i+caps) + 1].mesh.mesh = value
#var blackCapMesh: Mesh:
	#set(value): 
		#blackCapMesh = value
		#for i in caps:
			#pieces[2 * i + 1].mesh.mesh = value

@export var flatShape: Shape3D
@export var capShape: Shape3D

@export var highlightMaterial: ShaderMaterial
@export var hoverMaterial: ShaderMaterial


func vecToTile(vec: Vector3) -> Vector2i:
	return Vector2i(vec.x + size/2.0, size/2.0 - vec.z)

func _ready():
	settings = BoardSettings.loadOrNew(Settings3D)
	settings.update.connect(updateSettings)
	super()
	
	Piece3D.highlight = highlightMaterial
	Piece3D.hover = hoverMaterial

func updateSettings():
	for i in caps:
		pieces[2 * i].mesh.mesh = settings.white[0]
		pieces[2*i+1].mesh.mesh = settings.black[0]
		
	
	for i in flats:
		pieces[2 * (caps+i)].mesh.mesh = settings.white[1]
		pieces[2*(caps+i)+1].mesh.mesh = settings.black[1]
	
	squares.mesh.material.albedo_texture = settings.sq
	for i in 2*caps:
		pieces[i].scale = Vector3(settings.size, settings.capH, settings.size)
	
	for i in 2*flats:
		pieces[i + 2*caps].scale = Vector3(settings.size, settings.flatH, settings.size)
		
	#ROTATION[1] = settings.wallRotation3D
	Cam.fov = settings.fov
	
	setState(GameLogic.viewedState())


func makeBoard():
	for i in pieces:
		pieceHolder.remove_child(i)
		i.queue_free()
	pieces = []
	
	squares.mesh.size = Vector2(size/6.0, size/6.0)
	squares.mesh.material.uv1_offset = Vector3((8 * (size % 2) + size/2.0)/15, 0, ([0,8,14][(8-size)/2] + size/2.0 ) /18.0)
	
	board.mesh.size = Vector3(size + 1, .3, size + 1)
	
	for i in board.get_children():
		if i is Label3D:
			board.remove_child(i)
	
	var l
	for i in size:
		l = Label3D.new()
		l.text = str(i+1)
		l.position = Vector3(-size/2.0 - .25, 0.151, size/2.0 - .5 - i)
		l.rotation = Vector3(-PI/2, 0, 0)
		l.font_size = 64
		board.add_child(l)
		
		l = Label3D.new()
		l.text = char(i + 65)
		l.position = Vector3(.5 + i - size/2.0, 0.151, size/2.0 + .25)
		l.rotation = Vector3(-PI/2, 0, 0)
		l.font_size = 64
		board.add_child(l)
	
		l = Label3D.new()
		l.text = str(i+1)
		l.position = Vector3(size/2.0 + .25, 0.151, size/2.0 - .5 - i)
		l.rotation = Vector3(-PI/2, PI, 0)
		l.font_size = 64
		board.add_child(l)
		
		l = Label3D.new()
		l.text = char(i + 65)
		l.position = Vector3(.5 + i - size/2.0, 0.151, -size/2.0 - .25)
		l.rotation = Vector3(-PI/2, PI, 0)
		l.font_size = 64
		board.add_child(l)
	
	for cap in caps:
		pieces.append(Piece3D.new(settings.white[0], capShape, cap*2))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(settings.size, settings.capH, settings.size)
		pieces[-1].click.connect(clickPiece)
		
		pieces.append(Piece3D.new(settings.black[0], capShape, cap*2 + 1))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(settings.size, settings.capH, settings.size)
		pieces[-1].click.connect(clickPiece)
	
	for flat in flats:
		pieces.append(Piece3D.new(settings.white[1], flatShape, (flat + caps)*2))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(settings.size, settings.flatH, settings.size)
		pieces[-1].click.connect(clickPiece)
		
		pieces.append(Piece3D.new(settings.black[1], flatShape, (flat + caps)*2 + 1))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(settings.size, settings.flatH, settings.size)
		pieces[-1].click.connect(clickPiece)

	for i in (caps+flats) * 2:
		putReserve(i)


func setPieceState(id: int, state: int):
	pieces[id].rotation = Vector3(PI/2, settings.wall, 0) if state == WALL else Vector3.ZERO


func putPiece(id: int, v: Vector3i):
	var p = Vector3(v.x - size/2.0 + .5, settings.flatH * v.y, size/2.0 - v.z - .5)
	if id < caps*2:
		p.y += settings.capH / 2
	elif pieces[id].rotation == Vector3(PI/2, settings.wall, 0):
		p.y += settings.size / 2
	else:
		p.y += settings.flatH / 2
	
	if pieces[id].selected: p.y += SELECTIONHEIGHT
	pieces[id].setPosition(p)


func putReserve(id: int):
	var x = (size/2.0 + 1.5) * (-1 if id % 2 == 1 else 1)
	var y; var z
	if id < caps*2:
		y = settings.capH / 2
		z = (1 + id/2 * 1.5) * (-1 if id % 2 == 0 else 1)
	else:
		y = settings.flatH * (((id-2*caps)/2) % 10 + .5)
		z = (1 + (id-2*caps)/20) * (-1 if id % 2 == 1 else 1)
		
	pieces[id].setPosition(Vector3(x, y, z))


func highlight(id: int):
	pieces[id].highlighted = true


func deHighlight(id: int):
	pieces[id].highlighted = false


func select(id: int):
	pieces[id].setPosition(pieces[id].getPosition() + Vector3.UP * SELECTIONHEIGHT)
	pieces[id].selected = true


func deselect(id: int):
	pieces[id].setPosition(pieces[id].getPosition() - Vector3.UP * SELECTIONHEIGHT)
	pieces[id].selected = false


func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and dragLength < dragThreshHold:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var tile = vecToTile(event_position)
				if tile.x >= 0 and tile.x < size and tile.y >= 0 and tile.y < size:
					clickTile(tile)
				else:
					rightClickReserve()
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				var tile = vecToTile(event_position)
				if tile.x >= 0 and tile.x < size and tile.y >= 0 and tile.y < size:
					rightClickTile(tile)
	
	elif event is InputEventScreenTouch:
		I0 = event.position
		if not event.pressed and dragLength < dragThreshHold:
			var tile = vecToTile(event_position)
			if tile.x >= 0 and tile.x < size and tile.y >= 0 and tile.y < size:
				clickTile(tile)
		dragLength = 0
	
	elif event is InputEventScreenDrag:
		dragLength += event.relative.length()
		if event.index == 0:
			I0 = event.position
			
		else:
			var diff = I0 - event.position
			var drag = diff.dot(event.relative) / diff.length()
			Cam.position.z = clamp(Cam.position.z + drag * mobileZoomMod, CAM_MIN, CAM_MAX)


func _unhandled_input(event: InputEvent) -> void: #these are seperate so they work while hovering Piece3D
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Cam.position.z = clamp(Cam.position.z - .5, CAM_MIN, CAM_MAX)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Cam.position.z = clamp(Cam.position.z + .5, CAM_MIN, CAM_MAX)
				
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			Pivot.rotation.x = clamp(Pivot.rotation.x - event.relative.y / dist, -PI/2, 0)
			Pivot.rotation.y -= event.relative.x / dist
			dragLength += event.relative.length()
		
		else:
			dragLength = 0


func clickPiece(piece: Piece3D, isRight: bool):
	var tile = vecToTile(piece.position)
	if tile.x < 0 or tile.x > size or tile.y < 0 or tile.y > size:
		if not isRight: clickReserve(piece.id % 2, GameState.CAP if piece.id < caps*2 else GameState.FLAT)
		else: rightClickReserve()
	else:
		if not isRight: clickTile(tile)
		else: rightClickTile(tile)
