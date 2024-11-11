extends BoardRep
class_name BoardLogic


var size: int
var flats: int
var caps: int

enum {
	NONE,
	RESERVE,
	PILE
}

var selection: int
var selectedReserve: int = -1 #piece id
var selectedReserveType: int = -1 #pieceType

var selectedPile: Array[int] = []
var selectedPileType: int = -1
var startingTile: Vector2i = Vector2i.ZERO
var totals: int = 0 #sum of drops
var drops: Array[int] = []
var direction: Vector2i = Vector2i.ZERO 

func setup(game: GameData):
	super(game)
	size = game.size
	flats = game.flats
	caps = game.caps
	
	makeBoard(game.flats, game.caps)


func setState(state: GameState):
	match selection:
		RESERVE:
			deselect(selectedReserve)
		PILE:
			deselectPile(currentState())
	selection = NONE
	
	deHighlight()
	for i in state.highlights:
		highlight(i)
	
	for color in 2:
		for piece in state.reserves.caps[color]:
			putReserve(piece * 2 + color)
			
	for color in 2:
		for piece in state.reserves.flats[color]:
			setWall((state.caps + piece) * 2 + color, false)
			putReserve((state.caps + piece) * 2 + color)
	
	for x in size:
		for y in size:
			var pile = state.board[x][y]
			for piece in pile.size():
				if piece != pile.size()-1:
					setWall(pile.pieces[piece], false)
				elif pile.type != GameState.CAP:
					setWall(pile.pieces[piece], pile.type == GameState.WALL)
				putPiece(pile.pieces[piece], Vector3i(x, piece, y))


func makeBoard(flats: int, caps: int):
	pass


func putPiece(id: int, v: Vector3i):
	pass


func putReserve(id: int):
	pass


func setWall(id: int, wall: bool):
	pass


func deHighlight():
	pass #TODO implement


func highlight(id: int):
	pass #TODO implement


func select(id: int):
	pass


func deselect(id: int):
	pass


func currentState() -> GameState:
	return history[-1].boardState if history.size() > 0 else startState


func vecToTile(vec: Vector3) -> Vector2i:
	return Vector2i(vec.x + size/2.0, size/2.0 - vec.z)


func deselectReserve():
	deselect(selectedReserve)
	if selectedReserve >= caps * 2:
		setWall(selectedReserve, false)
	selectedReserve = -1
	selectedReserveType = -1


func selectPile(tile: Vector2i, pile: GameState.Pile):
	if pile.is_empty() or history.size() < 2 or history.size() % 2 != pile.pieces[-1] % 2: return #illegal piles filter
	selection = PILE
	selectedPile = pile.pieces.slice(-size)
	selectedPileType = pile.type
	startingTile = tile
	totals = 0
	drops = []
	for i in selectedPile:
		select(i)


func deselectPile(state: GameState):
	var pile = state.getPile(startingTile)
	for i in pile.size():
		deselect(pile.pieces[i])
		putPiece(pile.pieces[i], Vector3(startingTile.x, i, startingTile.y))
	selectedPile = []
	selectedPileType = -1
	startingTile = Vector2i.ZERO
	totals = 0
	drops = []
	direction = Vector2i.ZERO 


func clickReserve(color: int, type: int):
	if not canPlay or plyView != history.size() - 1: return
	if (color != history.size() % 2) != (history.size() < 2): return #correct color + swap opening
	if type != GameState.FLAT and history.size() < 2: return #only flats for first move
	
	var state = currentState()
	var id = (state.reserves.caps[color]-1) * 2 + color if type == GameState.CAP else (caps + state.reserves.flats[color]-1) * 2 + color
	
	if selection == NONE:
			selection = RESERVE
			selectedReserve = id
			selectedReserveType = type
			select(id)
	
	elif selection == RESERVE:
		if selectedReserve == id:
			if type == GameState.CAP or history.size() < 2 or selectedReserveType == GameState.WALL:
				deselectReserve()
				selection = NONE
			else:
				selectedReserveType = GameState.WALL
				setWall(id, true)
		
		else:
			deselectReserve()
			select(id)
			selectedReserve = id
			selectedReserveType = type
			
	else:
		deselectPile(state)
		select(id)
		selectedReserve = id
		selectedReserveType = type
		selection = RESERVE


func clickTile(tile: Vector2i):
	if not canPlay or plyView != history.size() - 1: return
	var state = currentState()
	var pile = state.getPile(tile)
	if selection == NONE:
		selectPile(tile, pile)
		
	elif selection == RESERVE:
		if pile.is_empty():
			selection = NONE
			var ply = Place.new(tile, selectedReserveType)
			deselect(selectedReserve)
			selectedReserve = -1
			selectedReserveType = -1
			onMove.emit(self, ply)
		
		else:
			deselectReserve()
			selection = NONE
			selectPile(tile, pile)
	
	else: #TODO handle reselection / deselection?
		var currentTile = startingTile + drops.size() * direction
		
		if pile.type != GameState.FLAT and tile != currentTile: 
			if not (pile.type == GameState.WALL and selectedPileType == GameState.CAP and totals + 1 == selectedPile.size()): #SMASH CONDITION
				return
		
		if tile == currentTile:
			if tile == startingTile:
				deselect(selectedPile.pop_front())
				if selectedPile.size() == 0:
					selection = NONE
					selectedPileType = -1
					startingTile = Vector2i.ZERO
				
			else:
				drops[-1] += 1
				deselect(selectedPile[totals])
				totals += 1
				if totals == selectedPile.size():
					var spread = Spread.new(startingTile, Spread.vecToDir[direction], drops, false)
					selection = NONE
					direction = Vector2i.ZERO
					onMove.emit(self, spread)
		
		elif direction != Vector2i.ZERO and currentTile + direction == tile:
			for i in selectedPile.size() - totals:
				putPiece(selectedPile[totals + i], Vector3(tile.x, pile.size() + i, tile.y))
			drops.append(1)
			deselect(selectedPile[totals])
			totals += 1
			if totals == selectedPile.size():
				var spread = Spread.new(startingTile, Spread.vecToDir[direction], drops, pile.type == GameState.WALL and selectedPileType == GameState.CAP)
				selection = NONE
				direction = Vector2i.ZERO 
				onMove.emit(self, spread)
		
		elif direction == Vector2i.ZERO:
			var delta = tile - currentTile
			if delta.length_squared() != 1.0: return
			direction = delta
			for i in selectedPile.size() - totals:
				putPiece(selectedPile[totals + i], Vector3(tile.x, pile.size() + i, tile.y))
			drops.append(1)
			deselect(selectedPile[totals])
			totals += 1
			if totals == selectedPile.size():
				var spread = Spread.new(startingTile, Spread.vecToDir[direction], drops, pile.type == GameState.WALL and selectedPileType == GameState.CAP)
				selection = NONE
				direction = Vector2i.ZERO 
				onMove.emit(self, spread)
