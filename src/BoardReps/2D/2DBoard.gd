extends BoardLogic
class_name Board2D

@onready var board = $Board
@onready var reserves = $Reserves

@export var selectionHeight: float = 8
@export var heightOffset: float = 2

var pieceSize: float: 
	set(value): pieceSize = value; for i in pieces: i.scale = value * Vector2.ONE * 16 / i.texture.get_size()
var sq: Texture2D:
	set(t):
		sq = t
		board.texture = t
		board.region_rect.size = Vector2.ONE * size * sq.get_height()
		board.scale = Vector2.ONE * (16.0 / sq.get_height())

var WhiteCap: Texture2D:
	set(value): WhiteCap = value; for i in caps: 
		pieces[2*i].texture = value
		pieces[2*i].scale = pieceSize * Vector2.ONE * 16 / value.get_size()
var WhiteFlat: Texture2D:
	set(value):
		for i in flats: if pieces[2*(caps+i)].texture != WhiteWall: 
			pieces[2*(caps+i)].texture = value
			pieces[2*(caps+i)].scale = pieceSize * Vector2.ONE * 16 / value.get_size()
		WhiteFlat = value
var WhiteWall: Texture2D:
	set(value):
		for i in flats: if pieces[2*(caps+i)].texture == WhiteWall: 
			pieces[2*(caps+i)].texture = value
			pieces[2*(caps+i)].scale = pieceSize * Vector2.ONE * 16 / value.get_size()
		WhiteWall = value

var BlackCap: Texture2D:
	set(value): BlackCap = value; for i in caps: 
		pieces[2*i+1].texture = value
		pieces[2*i+1].scale = pieceSize * Vector2.ONE * 16 / value.get_size()
var BlackFlat: Texture2D:
	set(value):
		for i in flats: if pieces[2*(caps+i)+1].texture != BlackWall: 
			pieces[2*(caps+i)+1].texture = value
			pieces[2*(caps+i)+1].scale = pieceSize * Vector2.ONE * 16 / value.get_size()
		BlackFlat = value
var BlackWall: Texture2D:
	set(value):
		for i in flats: if pieces[2*(caps+i)+1].texture == BlackWall: 
			pieces[2*(caps+i)+1].texture = value
			pieces[2*(caps+i)+1].scale = pieceSize * Vector2.ONE * 16 / value.get_size()
		BlackWall = value

@export var highlightMaterial: ShaderMaterial

var pieces: Array[Piece2D] = []

func _ready():
	super()
	get_viewport().size_changed.connect(resizeCam)


func resizeCam():
	var sizeLimit = Vector2(size * 16 + 48, size * 16 + 18)
	var z: Vector2 = $Camera2D.get_viewport_rect().size / sizeLimit
	$Camera2D.zoom = Vector2.ONE * min(z.x, z.y)


func setData(data: SettingData):
	var tex = data.white2D
	WhiteCap = tex[0]
	WhiteFlat = tex[1]
	WhiteWall = tex[2]
	
	tex = data.black2D
	BlackCap = tex[0]
	BlackFlat = tex[1]
	BlackWall = tex[2]
	
	pieceSize = data.pieceScale2D
	
	if not self.is_node_ready():
		await self.ready
	sq = data.sq2D

func makeBoard():
	if sq != null:
		board.region_rect.size = Vector2.ONE * size * sq.get_height()
		board.scale = Vector2.ONE * (16.0 / sq.get_height())
		
	for i in pieces:
		reserves.remove_child(i)
	pieces = []
	
	for i in get_children():
		if i is Label: remove_child(i)
	
	resizeCam()
	
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
