extends Node
class_name BoardLogic

enum{
	NEITHER = 0,
	WHITE_MASK = 1,
	BLACK_MASK = 2,
	BOTH = 3
}

var playAbleColor: int = NEITHER

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


func setData(data: SettingData):
	pass


func _ready():
	GameLogic.viewState.connect(setState)
	GameLogic.setup.connect(setup)
	setup(GameLogic.gameData, null)
	setState(GameLogic.viewedState())


func setup(game: GameData, startState: GameState):
	playAbleColor = WHITE_MASK if game.playerWhite == GameData.LOCAL else 0
	playAbleColor |= BLACK_MASK if game.playerBlack == GameData.LOCAL else 0
	
	size = game.size
	flats = game.flats
	caps = game.caps
	
	makeBoard()
	if startState != null: setState(startState)


func canPlay() -> bool:
	return (1 << (GameLogic.currentPly() % 2)) & playAbleColor != 0 and GameLogic.active


func makeBoard():
	pass


func setState(state: GameState):
	match selection:
		RESERVE:
			deselect(selectedReserve)
		PILE:
			deselectPile(GameLogic.activeState())
	selection = NONE
	
	for i in (caps+flats)*2:
		deHighlight(i)

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


func putPiece(id: int, v: Vector3i):
	pass


func putReserve(id: int):
	pass


func setWall(id: int, wall: bool):
	pass


func deHighlight(id: int):
	pass


func highlight(id: int):
	pass


func select(id: int):
	pass


func deselect(id: int):
	pass


func deselectReserve():
	deselect(selectedReserve)
	if selectedReserve >= caps * 2:
		setWall(selectedReserve, false)
	selectedReserve = -1
	selectedReserveType = -1


func selectPile(tile: Vector2i, pile: GameState.Pile):
	var c = GameLogic.currentPly()
	if pile.is_empty() or c < 2 or c % 2 != pile.pieces[-1] % 2: return #illegal piles filter
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
	if not (canPlay() and GameLogic.viewIsLast()): return
	var c = GameLogic.currentPly()
	if (color != c % 2) != (c < 2): return #correct color + swap opening
	if type == GameState.CAP and c < 2: return #only flats for first move
	
	var state = GameLogic.activeState()
	var id = (state.reserves.caps[color]-1) * 2 + color if type == GameState.CAP else (caps + state.reserves.flats[color]-1) * 2 + color
	
	if selection == NONE:
			selection = RESERVE
			selectedReserve = id
			selectedReserveType = type
			select(id)
	
	elif selection == RESERVE:
		if selectedReserve == id:
			if type == GameState.CAP or c < 2 or selectedReserveType == GameState.WALL:
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
	if not (canPlay() and GameLogic.viewIsLast()): return
	var state = GameLogic.activeState()
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
			GameLogic.doMove(self, ply)
		
		else:
			deselectReserve()
			selection = NONE
			selectPile(tile, pile)
	
	else:
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
					GameLogic.doMove(self, spread)
		
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
				GameLogic.doMove(self, spread)
		
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
				GameLogic.doMove(self, spread)


func rightClickReserve():
	if not (canPlay() and GameLogic.viewIsLast()): return
	match selection:
		RESERVE:
			deselectReserve()
		PILE:
			deselectPile(GameLogic.activeState())
	selection = NONE


func rightClickTile(tile: Vector2i):
	if not (canPlay() and GameLogic.viewIsLast()): return

	match selection:
		RESERVE:
			deselectReserve()
			selection = NONE
		PILE:
			var currentTile = startingTile + drops.size() * direction
			var delta = tile - startingTile
			
			if tile == currentTile:
				if drops.size() == 0:
					var pile = GameLogic.activeState().getPile(tile)
					if selectedPile.size() < size and selectedPile.size() < pile.size():
						selectedPile.push_front(pile.pieces[-selectedPile.size() - 1])
						select(selectedPile[0])
				
				elif drops[-1] > 1:
					drops[-1] -= 1
					totals -= 1
					select(selectedPile[totals])
				
				else:
					assert(drops[-1] == 1, "IMPOSSIBLE STATE")
					drops.pop_back()
					totals -= 1
					select(selectedPile[totals])
					currentTile = startingTile + drops.size() * direction
					var l
					if drops.size() > 0:
						l = drops[-1]
					else:
						l = 0
						direction = Vector2i.ZERO
						
					var pile = GameLogic.activeState().getPile(tile)
					for i in selectedPile.size() - totals:
						putPiece(selectedPile[totals + i], Vector3(currentTile.x, pile.size() + l + i , currentTile.y))
			
			elif delta.sign() == direction and delta.length() < drops.size():
				for x in drops.size() - delta.length():
					var l = drops.pop_back()
					totals -= l
					for i in l:
						select(selectedPile[totals + i])
						
				var pile = GameLogic.activeState().getPile(tile)
				for i in selectedPile.size() - totals:
						putPiece(selectedPile[totals + i], Vector3(tile.x, pile.size() + drops[-1] + i , tile.y))
				
			else:
				deselectPile(GameLogic.activeState())
				selection = NONE
