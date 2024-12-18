extends BoardLogic
class_name Board2D

@onready var board = $Board
@onready var reserves = $Reserves

@export var selectionHeight: float = 8
@export var heightOffset: float = 2

@export var pieceSize: float = .5
@export var sq: Texture2D

@export var WhiteCap: Texture2D
@export var WhiteFlat: Texture2D
@export var WhiteWall: Texture2D

@export var BlackCap: Texture2D
@export var BlackFlat: Texture2D
@export var BlackWall: Texture2D

@export var highlightMaterial: ShaderMaterial

var pieces: Array[Piece2D] = []

func _ready():
	super()


func makeBoard():
	assert(sq.get_height() == sq.get_width(), "SQUARE IS NON-SQUARE")
	var tsize:int = sq.get_height()
	for i in pieces:
		reserves.remove_child(i)
	pieces = []
	
	for i in get_children():
		if i is Label: remove_child(i)
	
	$Camera2D.zoom = Vector2.ONE * (80 if OS.has_feature("mobile") else 55) /size # SHOULD BE 55 FOR DESKTOP
	board.texture = sq
	board.region_rect.size = Vector2.ONE * size * tsize
	board.scale = Vector2.ONE * (16.0 / tsize)
	
	for i in size:
		var l = Label.new()
		l.text = str(i+1)
		l.add_theme_font_size_override(&"font_size", 32)
		l.scale = Vector2.ONE * .2
		l.position = Vector2(-16 * size/2.0 - 4, 16 * (size/2.0 - i) - 8)
		l.position.y -= l.size.y * l.scale.y
		add_child(l)

		l = Label.new()
		l.text = char(i + 65)
		l.add_theme_font_size_override(&"font_size", 32)
		l.scale = Vector2.ONE * .2
		l.position = Vector2(8 - 16 * (size/2.0 - i), 16 * size/2.0 + 1)
		l.position.x -= l.size.x * l.scale.x
		add_child(l)


	
	var piece
	for i in caps:
		piece = Piece2D.new(WhiteCap, pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*i)
		
		piece = Piece2D.new(BlackCap, pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*i + 1)

	for i in flats:
		piece = Piece2D.new(WhiteFlat, pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*(caps+i))
		
		piece = Piece2D.new(BlackFlat, pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*(caps+i) + 1)


func putPiece(id: int, v: Vector3i):
	pieces[id].z_index = v.y + 1
	pieces[id].position = Vector2((v.x - size/2.0 + .5) * 16, (size/2.0 - v.z - .5) * 16 - v.y * heightOffset)
	if pieces[id].selected: 
		pieces[id].position.y -= selectionHeight
		pieces[id].z_index += 10


func putReserve(id: int):
	if id < 2*caps:
		pieces[id].position = Vector2(
			16 * (size/2.0 + .75) * (-1 if id %2 == 1 else 1),
			16 * (size/2.0 - .75 - (id/2 + flats) * (size-1) / (caps+flats - 1.0))
		)
		pieces[id].z_index = (id/2 + flats)
		
	else:
		pieces[id].position = Vector2(
			16 * (size/2.0 + .75) * (-1 if id %2 == 1 else 1),
			16 * (size/2.0 - (id/2 - caps) * (size-1) / (caps+flats - 1.0))
		)
		pieces[id].z_index = (id/2 - caps)


func highlight(id: int):
	pieces[id].material = highlightMaterial


func deHighlight(id: int):
	pieces[id].material = null


func setWall(id: int, wall: bool):
	if id % 2 == 0:
		pieces[id].texture = WhiteWall if wall else WhiteFlat
	else:
		pieces[id].texture = BlackWall if wall else BlackFlat


func select(id: int):
	pieces[id].position.y -= selectionHeight
	pieces[id].z_index += 10
	pieces[id].selected = true


func deselect(id: int):
	pieces[id].position.y += selectionHeight
	pieces[id].z_index -= 10
	pieces[id].selected = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		var v = board.get_global_mouse_position()
		var tile = Vector2(v.x/16 + size/2.0, size/2.0 - v.y / 16)
		if tile.x >= 0 and tile.x < size and tile.y >= 0 and tile.y < size:
			if event.button_index == MOUSE_BUTTON_LEFT:
				clickTile(Vector2i(tile))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				rightClickTile(Vector2i(tile))
		
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var color = 0 if v.x > 0 else 1
				var type = GameState.FLAT if v.y > 16 * (size/2.0 - .5 - (size-1.0) * flats / (flats+caps)) else GameState.CAP
				if type == GameState.CAP and GameLogic.activeState().reserves.caps[color] == 0: return
				elif type == GameState.FLAT and GameLogic.activeState().reserves.flats[color] == 0: return
				clickReserve(color, type)
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				rightClickReserve()
