extends BoardLogic
class_name Board2D

@onready var board = $Board
@onready var reserves = $Reserves

@onready var cam = $Camera2D

@export var selectionHeight: float = 8
@export var heightOffset: float = 2
var portrait = false


var pieceSize: float: 
	set(value): 
		for i in pieces: i.scale *= value / pieceSize
		pieceSize = value

var sq: Texture2D:
	set(t):
		sq = t
		var s = t.get_width() / 15
		board.region_rect.size = Vector2.ONE * size * s
		board.region_rect.position.x = size % 2 * 8 * s
		board.region_rect.position.y = [0, 8, 14][(8-size)/2] * s
		
		board.texture = t
		board.scale = Vector2.ONE * (16.0/s)

var WhiteTex: Array[Texture2D]:
	set(value):
		if value.size() != 4 or null in value:
			Notif.message("Failed to load white textures")
			return
		WhiteTex = value
		if pieces.size() > 0: setState(GameLogic.viewedState())

var BlackTex: Array[Texture2D]:
	set(value):
		if value.size() != 4 or null in value:
			Notif.message("Failed to load black textures")
			return
		BlackTex = value
		if pieces.size() > 0: setState(GameLogic.viewedState())

@export var highlightMaterial: ShaderMaterial

var pieces: Array[Piece2D] = []


func _ready():
	super()
	get_viewport().size_changed.connect(resizeCam)


func resizeCam():
	var c = cam.get_viewport_rect().size
	
	if (c.y > c.x) != portrait:
		portrait = c.y > c.x
		setState.call_deferred(GameLogic.viewedState())
		
	var sizeLimit = Vector2(size * 16 + 18, size * 16 + 48) if portrait else Vector2(size * 16 + 48, size * 16 + 18)
	var z: Vector2 = c / sizeLimit
	cam.zoom = Vector2.ONE * min(z.x, z.y)


func setData(data: SettingData):
	WhiteTex = data.white2D
	BlackTex = data.black2D
	
	pieceSize = data.pieceScale2D
	
	if not self.is_node_ready():
		await self.ready
	sq = data.sq2D


func makeBoard():
	if sq != null:
		var w = sq.get_width() / 15
			
		board.region_rect.size = Vector2.ONE * size * w
		board.region_rect.position.x = size % 2 * 8 * w
		board.region_rect.position.y = [0, 8, 14][(8-size)/2] * w
		board.scale = Vector2.ONE * (16.0/w)
		
	for i in pieces:
		reserves.remove_child(i)
	pieces = []
	
	for i in get_children():
		if i is Label: remove_child(i)
	
	resizeCam()
	
	for i in size:
		var l = Label.new()
		var s = l.get_theme_default_font().get_char_size(i+49, 32) * .1
		l.text = char(i+49)
		l.add_theme_font_size_override(&"font_size", 32)
		l.scale = Vector2.ONE * .2
		l.position = Vector2(-16 * size/2.0 - 2, 16 * (size/2.0 - i - .5)) - s
		add_child(l)

		l = Label.new()
		s = l.get_theme_default_font().get_char_size(i+49, 32) * .1
		l.text = char(i + 65)
		l.add_theme_font_size_override(&"font_size", 32)
		l.scale = Vector2.ONE * .2
		l.position = Vector2(- 16 * (size/2.0 - i - .5), 16 * size/2.0 + 4) - s
		add_child(l)
	
	var piece
	for i in caps:
		piece = Piece2D.new(WhiteTex[CAP], pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*i)
		
		piece = Piece2D.new(BlackTex[CAP], pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*i + 1)

	for i in flats:
		piece = Piece2D.new(WhiteTex[FLAT], pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*(caps+i))
		
		piece = Piece2D.new(BlackTex[FLAT], pieceSize)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*(caps+i) + 1)


func setPieceState(id: int, state: int):
	pieces[id].rotation = 0 if state != WALL else PI/4 if id%2 == 0 else -PI/4
	pieces[id].texture = WhiteTex[state] if id%2 == 0 else BlackTex[state]


func putPiece(id: int, v: Vector3i):
	var h = GameLogic.viewedState().board[v.x][v.z].size()
	pieces[id].z_index = v.y + 1
	if h > size:
		v.y -= h - size
	
	var p: Vector2
	if v.y < 0:
		#pieces[id].scale = Vector2(pieceSize * 4, .9) / pieces[id].texture.get_size()
		#pieces[id].texture = WhiteSmol if id % 2 == 0 else BlackSmol
		p = Vector2((v.x - size/2.0 + .5 + pieceSize * .65) * 16, (size/2.0 - v.z - .5 + pieceSize * .4) * 16 - (v.y + h - size))
	else:
		#pieces[id].scale = pieceSize * 16 * Vector2.ONE / pieces[id].texture.get_width()
		#if id >= 2*caps: pieces[id].texture = WhiteFlat if id % 2 == 0 else BlackFlat #TODO handle if this is a wall
		p = Vector2((v.x - size/2.0 + .5) * 16, (size/2.0 - v.z - .5) * 16 - v.y * heightOffset)
	
	if pieces[id].selected: 
		p.y -= selectionHeight
		pieces[id].z_index += 10
	pieces[id].setPosition(p)


func putReserve(id: int):
	var p: Vector2
	pieces[id].scale = pieceSize * 16 * Vector2.ONE / pieces[id].texture.get_size()
	if id < 2*caps:
		p = Vector2(
			16 * (size/2.0 + .75) * (-1 if id %2 == 1 else 1),
			16 * (size/2.0 - .75 - (id/2 + flats) * (size-1) / (caps+flats - 1.0))
		)
		pieces[id].z_index = (id/2 + flats)
		
	else:
		p = Vector2(
			16 * (size/2.0 + .75) * (-1 if id %2 == 1 else 1),
			16 * (size/2.0 - (id/2 - caps) * (size-1) / (caps+flats - 1.0))
		)
		pieces[id].z_index = (id/2 - caps)
	
	if portrait:
		p = Vector2(p.y, p.x)
		if playAbleColor == BLACK_MASK:
			p.y *= -1
		p += Vector2(-3,3)
		
	pieces[id].setPosition(p)


func highlight(id: int):
	pieces[id].material = highlightMaterial


func deHighlight(id: int):
	pieces[id].material = null


func select(id: int):
	pieces[id].setPosition(pieces[id].getPosition() + Vector2.UP * selectionHeight)
	pieces[id].z_index += 10
	pieces[id].selected = true


func deselect(id: int):
	pieces[id].setPosition(pieces[id].getPosition() - Vector2.UP * selectionHeight)
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
				var color
				var type
				if portrait:
					color = 0 if v.y > 0 != (playAbleColor==BLACK_MASK) else 1
					type = GameState.FLAT if v.x > 16 * (size/2.0 - .5 - (size-1.0) * flats / (flats+caps)) else GameState.CAP
				else:
					color = 0 if v.x > 0 else 1
					type = GameState.FLAT if v.y > 16 * (size/2.0 - .5 - (size-1.0) * flats / (flats+caps)) else GameState.CAP
					
				if type == GameState.CAP and GameLogic.activeState().reserves.caps[color] == 0: return
				elif type == GameState.FLAT and GameLogic.activeState().reserves.flats[color] == 0: return
				clickReserve(color, type)
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				rightClickReserve()
