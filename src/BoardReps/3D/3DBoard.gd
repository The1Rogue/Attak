extends BoardLogic
class_name Board3D

const SELECTIONHEIGHT = 1

@export var capSize: float = .9: 
	set(v): capSize = v; for i in caps*2: pieces[i].scale = Vector3(v,capHeight,v)
@export var capHeight: float = 1.2:
	set(v): capHeight = v; for i in caps*2: pieces[i].scale = Vector3(capSize,v,capHeight)

@export var pieceSize: float = .9:
	set(v): pieceSize = v; for i in flats*2: pieces[caps*2 + i].scale = Vector3(v,pieceHeight,v)
@export var pieceHeight: float = .2:
	set(v): pieceHeight = v; for i in flats*2: pieces[caps*2 + i].scale = Vector3(pieceSize,v,pieceSize)

const ROTATION = [Vector3.ZERO, Vector3(PI/2, PI/4, 0)]

var pieces: Array[Piece3D]
@onready var board = $board
@onready var squares = $board/top
@onready var shape = $shape

var dragLength: float
@export var dragThreshHold: float = 8: 
	set(v):
		dragThreshHold = v
		Piece3D.dragThreshHold = v

const dist = 300
const mobileZoomMod: float = .02
var I0: Vector2
@onready var Cam = $Pivot/Camera3D
@onready var Pivot = $Pivot

@onready var pieceHolder = $Pieces

@export var whiteFlatMesh: Mesh
@export var whiteCapMesh: Mesh

@export var blackFlatMesh: Mesh
@export var blackCapMesh: Mesh

@export var flatShape: Shape3D
@export var capShape: Shape3D

@export var highlightMaterial: ShaderMaterial
@export var hoverMaterial: ShaderMaterial


func vecToTile(vec: Vector3) -> Vector2i:
	return Vector2i(vec.x + size/2.0, size/2.0 - vec.z)


func _ready():
	super()
	
	Piece3D.highlight = highlightMaterial
	Piece3D.hover = hoverMaterial

	#$Collider.input_event.connect(inputEvent)


func makeBoard():
	for i in pieces:
		pieceHolder.remove_child(i)
		i.queue_free()
	pieces = []
	
	squares.mesh.size = Vector2(size, size)
	squares.mesh.material.uv1_offset = Vector3(.5, 0, .5) if size % 2 == 1 else Vector3.ZERO
	board.mesh.size = Vector3(size + 1, .3, size + 1)
	board.position.y = -.15 - pieceHeight/2
	shape.position.y = -pieceHeight/2
	
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
		pieces.append(Piece3D.new(whiteCapMesh, capShape, cap*2))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(capSize, capHeight, capSize)
		pieces[-1].click.connect(clickPiece)
		
		pieces.append(Piece3D.new(blackCapMesh, capShape, cap*2 + 1))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(capSize, capHeight, capSize)
		pieces[-1].click.connect(clickPiece)
	
	for flat in flats:
		pieces.append(Piece3D.new(whiteFlatMesh, flatShape, (flat + caps)*2))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(pieceSize, pieceHeight, pieceSize)
		pieces[-1].click.connect(clickPiece)
		
		pieces.append(Piece3D.new(blackFlatMesh, flatShape, (flat + caps)*2 + 1))
		pieceHolder.add_child(pieces[-1])
		pieces[-1].scale = Vector3(pieceSize, pieceHeight, pieceSize)
		pieces[-1].click.connect(clickPiece)

	for i in (caps+flats) * 2:
		putReserve(i)


func putPiece(id: int, v: Vector3i):
	pieces[id].position = Vector3(v.x - size/2.0 + .5, pieceHeight * v.y, size/2.0 - v.z - .5)
	
	if id < caps*2:
		pieces[id].position.y += (capHeight - pieceHeight)/2
	
	if pieces[id].rotation == ROTATION[1]:
		pieces[id].position.y += (pieceSize - pieceHeight)/2
	
	
	if pieces[id].selected: pieces[id].position.y += SELECTIONHEIGHT


func putReserve(id: int):
	var x = (size/2.0 + 1.5) * (-1 if id % 2 == 1 else 1)
	var y; var z
	if id < caps*2:
		y = capHeight / 2
		z = (1 + id/2 * 1.5) * (-1 if id % 2 == 0 else 1)
	else:
		y = pieceHeight * (((id-2*caps)/2) % 10 + .5)
		z = (1 + (id-2*caps)/20) * (-1 if id % 2 == 1 else 1)
		
	pieces[id].position = Vector3(x, y, z)


func highlight(id: int):
	pieces[id].highlighted = true


func deHighlight(id: int):
	pieces[id].highlighted = false


func setWall(id: int, wall: bool):
	pieces[id].rotation = ROTATION[1 if wall else 0]


func select(id: int):
	pieces[id].position.y += SELECTIONHEIGHT
	pieces[id].selected = true


func deselect(id: int):
	pieces[id].position.y -= SELECTIONHEIGHT 
	pieces[id].selected = false


func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and dragLength < dragThreshHold:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var tile = vecToTile(event_position)
				if tile.x >= 0 and tile.x < size and tile.y >= 0 and tile.y < size:
					clickTile(tile)
			
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
			Cam.position.z = clamp(Cam.position.z + drag * mobileZoomMod, 1, 15)


func _unhandled_input(event: InputEvent) -> void: #these are seperate so they work while hovering Piece3D
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Cam.position.z = clamp(Cam.position.z - .5, 1, 15)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Cam.position.z = clamp(Cam.position.z + .5, 1, 15)
				
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
