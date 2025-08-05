extends BoardLogic
class_name Board2D

@onready var board = $Board
@onready var reserves = $Reserves

@onready var cam = $Camera2D

@export var selectionHeight: float = 8
@export var heightOffset: float = 2
var portrait = false

@export var highlightMaterial: ShaderMaterial
@export var LabelSets: LabelSettings

var pieces: Array[Piece2D] = []


func _ready():
	settings = BoardSettings.loadOrNew(Settings2D)
	settings.update.connect(updateSettings)
	board.texture = settings.sq
	super()
	get_viewport().size_changed.connect(resizeCam)

func updateSettings():
	var w = settings.sq.get_width() / 15
	board.texture = settings.sq
		
	board.region_rect.size = Vector2.ONE * size * w
	board.region_rect.position.x = size % 2 * 8 * w
	board.region_rect.position.y = [0, 8, 14][(8-size)/2] * w
	board.scale = Vector2.ONE * (16.0/w)
	setState(GameLogic.viewedState())


func resizeCam():
	var c = cam.get_viewport_rect().size
	
	if (c.y > c.x) != portrait:
		portrait = c.y > c.x
		setState.call_deferred(GameLogic.viewedState())
		
	var sizeLimit = Vector2(size * 16 + 2, size * 16 + 30) if portrait else Vector2(size * 16 + 30, size * 16 + 2)
	var z: Vector2 = c / sizeLimit
	cam.zoom = Vector2.ONE * min(z.x, z.y)


#func setData(data: BoardSettings):
	#assert(data is Settings2D, "2D board needs 2D Settings")
	#WhiteTex = data.white2D
	#BlackTex = data.black2D
	#
	#pieceSize = data.pieceScale2D
	#
	#if not self.is_node_ready():
		#await self.ready
	#sq = data.sq2D


func makeBoard():
	var w = settings.sq.get_width() / 15
		
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
		l.text = char(i + 49)
		l.label_settings = LabelSets
		l.scale = Vector2.ONE * .1
		l.position = Vector2(.5 - 16 * size/2.0, 16 * (size/2.0 - i - 1))
		add_child(l)
		
		l = Label.new()
		var s = l.get_theme_default_font().get_char_size(i+49, 32) * .1
		l.text = char(i + 65)
		l.label_settings = LabelSets
		l.scale = Vector2.ONE * .1
		l.position = Vector2(-16 * (size/2.0 - i - 1), 16 * size/2.0) - s
		add_child(l)
	
	var piece
	for i in caps:
		piece = Piece2D.new(settings.white[CAP], settings.size)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*i)
		
		piece = Piece2D.new(settings.black[CAP], settings.size)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*i + 1)

	for i in flats:
		piece = Piece2D.new(settings.white[FLAT], settings.size)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*(caps+i))
		
		piece = Piece2D.new(settings.black[FLAT], settings.size)
		reserves.add_child(piece)
		pieces.append(piece)
		putReserve(2*(caps+i) + 1)


func setPieceState(id: int, state: int):
	pieces[id].rotation = 0 if state != WALL else PI/4 if id%2 == 0 else -PI/4
	pieces[id].texture = settings.white[state] if id%2 == 0 else settings.black[state]


func putPiece(id: int, v: Vector3i):
	var h = GameLogic.viewedState().board[v.x][v.z].size()
	pieces[id].z_index = v.y + 1
	if h > size:
		v.y -= h - size
	
	var p: Vector2
	if v.y < 0:
		#pieces[id].scale = Vector2(pieceSize * 4, .9) / pieces[id].texture.get_size()
		#pieces[id].texture = WhiteSmol if id % 2 == 0 else BlackSmol
		p = Vector2((v.x - size/2.0 + .5 + settings.size * .65) * 16, (size/2.0 - v.z - .5 + settings.size * .4) * 16 - (v.y + h - size))
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
	pieces[id].scale = settings.size * 16 * Vector2.ONE / pieces[id].texture.get_size()
	if id < 2*caps:
		p = Vector2(
			16 * (size/2.0 + .5) * (-1 if id %2 == 1 else 1),
			16 * (size/2.0 - .75 - (id/2 + flats) * (size-1) / float(caps+flats))
		)
		pieces[id].z_index = (id/2 + flats)
	
	else:
		p = Vector2(
			16 * (size/2.0 + .5) * (-1 if id %2 == 1 else 1),
			16 * (size/2.0 - (id/2 - caps) * (size-1) / float(caps+flats) - settings.size/2) 
		)
		pieces[id].z_index = (id/2 - caps)
	
	if portrait:
		p = Vector2(p.y, p.x)
		if playAbleColor == BLACK_MASK:
			p.y *= -1
	
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
				var color = -1
				var type = -1
				if portrait:
					if v.y > -8 * size - 23 and v.y < -8 * size - 7: 
						color = 0 if (playAbleColor==BLACK_MASK) else 1
					elif v.y > 8 * size + 1 and v.y < 8 * size + 17:
						color = 1 if (playAbleColor==BLACK_MASK) else 0
					type = GameState.FLAT if v.x > 16 * (size/2.0 - .5 - (size-1.0) * flats / (flats+caps)) else GameState.CAP
				
				else:
					if v.x > -8 * size - 20 and v.x < -8 * size - 4: 
						color = 1
					elif v.x > 8 * size + 4 and v.x < 8 * size + 20:
						color = 0
					type = GameState.FLAT if v.y > 16 * (size/2.0 - .5 - (size-1.0) * flats / (flats+caps)) else GameState.CAP
				
				if color == -1:
					rightClickReserve() #deselect if click outside board
					return 
					
				if type == GameState.CAP and GameLogic.activeState().reserves.caps[color] == 0: return
				elif type == GameState.FLAT and GameLogic.activeState().reserves.flats[color] == 0: return
				clickReserve(color, type)
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				rightClickReserve()
