class_name GameState

#Pieces are represented by unique numbers from 0 to 2*(flats+caps)
#piece % 2 is the color of that piece
#caps come before pieces, so
#if piece < 2*caps its a cap

var size: int
var flats: int
var caps: int

var komi: float

var ply: int

var board: Array #Array[Array[Pile]]
var reserves: Reserves

var highlights: Array[int]

var win = ONGOING

enum {
	WHITE = 0,
	BLACK = 1
}

enum {
	FLAT = 0,
	WALL = 1,
	CAP = 2
}

enum {
	ROAD_WIN_WHITE,
	ROAD_WIN_BLACK,
	FLAT_WIN_WHITE,
	FLAT_WIN_BLACK,
	DEFAULT_WIN_WHITE,
	DEFAULT_WIN_BLACK,
	DRAW,
	ONGOING
}
const resultStrings = [
	"R-0",
	"0-R",
	"F-0",
	"0-F",
	"1-0",
	"0-1",
	"1/2-1/2",
	"0-0"
]

class Reserves extends Resource:
	@export var flats = {WHITE: 0, BLACK: 0}
	@export var caps = {WHITE: 0, BLACK: 0}
	@export var maxCaps: int = 0
	
	static func make(flats:int, caps:int) -> Reserves:
		var r = Reserves.new()
		r.flats[WHITE] = flats; r.flats[BLACK] = flats
		r.caps[WHITE] = caps; r.caps[BLACK] = caps
		r.maxCaps = caps
		return r
		
	func getPiece(type: int, color: int) -> int:
		if type == CAP:
			caps[color] -= 1
			return caps[color] * 2 + color
		else:
			flats[color] -= 1
			return (maxCaps + flats[color]) * 2 + color


class Pile extends Resource:
	@export var pieces: Array[int] = [] #low index is bottom
	@export var type: int = FLAT

	static func fromTps(tps: String, reserves: Reserves) -> Pile:
		var s: PackedStringArray = tps.split("")
		var p = Pile.new()
		if s[-1] == "S":
			s.resize(s.size()-1) #imagine if packedstring array had a pop function....
			p.type = WALL
		elif s[-1] == "C":
			s.resize(s.size()-1)
			p.type = CAP
		for i in s.size():
			if not s[i].to_int() in [1,2]: 
				return null
			p.pieces.append(reserves.getPiece(p.type if i == s.size()-1 else FLAT, s[i].to_int() - 1))
		return p 

	func getTPS() -> String:
		var out = ""
		for i in pieces:
			out += str(i % 2 + 1)
		return out + ("S" if type == WALL else "C" if type == CAP else "")

	func take(n:int) -> Pile:
		var top = Pile.new()
		top.type = type
		top.pieces = pieces.slice(-n)
		pieces = pieces.slice(0, -n)
		type = FLAT
		return top
	
	func size() -> int: return pieces.size()
	
	func is_empty() -> bool: return pieces.is_empty()
	
	func put(piece: int, newType: int):
		assert(type == FLAT or (type == WALL and newType == CAP), "CANT PUT THIS PIECE HERE!")
		pieces.append(piece)
		type = newType
	
	func drop(pile: Pile, n: int) -> Pile:
		assert(type == FLAT or (type == WALL and 1 == pile.size() and pile.type == CAP), "CANT PUT THIS HERE!")
		assert(pile.size() >= n, "TRIED TO PLACE MORE THAN SIZE")
		if pile.size() == n:
			type = pile.type
			pieces.append_array(pile.pieces)
			return Pile.new()
		
		pieces.append_array(pile.pieces.slice(0, n))
		pile.pieces = pile.pieces.slice(n)
		return pile


static func emptyState(size: int, flats: int, caps: int, komi: float) -> GameState:
	var state = GameState.new()
	state.size = size
	state.flats = flats
	state.caps = caps
	state.komi = komi
	state.ply = 0
	state.reserves = Reserves.make(flats, caps)
	
	state.board = []
	for x in size:
		state.board.append([])
		for y in size:
			state.board[x].append(Pile.new())
	
	return state


static func fromTPS(tps: String, flats: int, caps: int) -> GameState:
	var s = tps.split(" ")
	var rows = s[0].split("/")
	var state = GameState.new()
	state.size = rows.size()
	state.ply = s[2].to_int() * 2 + s[1].to_int() - 3
	
	state.flats = flats if flats != -1 else NewSeek.standardFlats[state.size-3]
	state.caps = caps if caps != -1 else NewSeek.standardCaps[state.size-3]
	
	state.reserves = Reserves.make(state.flats, state.caps)
	
	state.board = []
	for x in state.size:
		state.board.append([])
		for y in state.size:
			state.board[x].append(Pile.new())
	
	var count:int = 0
	for row in rows:
		for c in row.split(","):
			if c[0] == "x":
				count += c[1].to_int() if c.length() > 1 else 1
			else:
				var p = Pile.fromTps(c, state.reserves)
				if p == null: 
					return null
				state.board[count % state.size][state.size - 1 - count/state.size] = p
				count += 1
	if count != state.size**2:
		return null
	
	return state


func getPile(tile: Vector2i):
	return board[tile.x][tile.y]

#returns gamestate after playing ply, also sets new gamestate in ply
func apply(ply: Ply) -> GameState:
	var newState = nextState()
	
	if ply is Place:
		assert(getPile(ply.tile).is_empty(), "TRIED PLACING ON NON-EMPTY TILE!")
		assert(ply.piece == FLAT or self.ply >= 2, "INVALID FIRST TURN PIECE")
		var piece = newState.reserves.getPiece(ply.piece, 1 if (self.ply % 2 == 0) == (self.ply < 2) else 0)
		newState.getPile(ply.tile).put(piece, ply.piece)
		ply.boardState = newState
		newState.highlights = [piece] as Array[int] #really godot? do i need to be this specific?
		newState.win = newState.detectWin()
		return newState
	
	elif ply is Spread:
		var pieces = newState.getPile(ply.tile).take(ply.total())
		newState.highlights = pieces.pieces.duplicate()
		var delta = Spread.dirToVec[ply.dir]
		for i in ply.drops.size():
			pieces = newState.getPile(ply.tile + delta * (i+1)).drop(pieces, ply.drops[i])
		assert(pieces.size() == 0, "didnt drop correct amount of pieces")
		ply.boardState = newState
		newState.win = newState.detectWin()
		return newState
	
	else: return null


func nextState() -> GameState:
	var newState = GameState.new()
	newState.size = size
	newState.flats = flats
	newState.caps = caps
	newState.komi = komi
	newState.ply = ply+1
	
	newState.board = []
	for x in board:
		newState.board.append([])
		for y in x:
			newState.board[-1].append(y.duplicate(true))
			
	newState.reserves = reserves.duplicate(true)
	return newState


func detectWin() -> int: # im not *100%* confident this is correct, but it should be
	var roads = [false, false]
	
	var map = 0 # already visited (bitmap)
	for i in size: # flood from bottom
		if board[i][0].is_empty() or board[i][0].type == WALL: continue
		var color = board[i][0].pieces[-1] % 2
		if roads[color]: continue
		var q = [Vector2i(i,0)]
		map |= 1 << i
		
		while not q.is_empty():
			var p = q.pop_back()
			for d in Spread.vecToDir:
				var n = p+d
				if n.y == size:
					q = []
					roads[color] = true
					break
				if n.x >= size or n.x < 0 or n.y >= size or n.y < 0: continue
				var pile = getPile(n)
				if pile.is_empty() or pile.type == WALL or pile.pieces[-1] % 2 != color: continue
				if 1 << n.x + n.y * 8 & map == 0:
					q.append(n)
					map |= 1 << n.x + n.y * 8

	map = 0 # already visited (bitmap)
	for i in size: # flood from side
		if board[0][i].is_empty() or board[0][i].type == WALL: continue
		var color = board[0][i].pieces[-1] % 2
		if roads[color]: continue
		var q = [Vector2i(0,i)]
		map |= 1 << i * 8
		
		while not q.is_empty():
			var p = q.pop_back()
			for d in Spread.vecToDir:
				var n = p+d
				if n.x == size:
					q = []
					roads[color] = true
					break
				if n.x >= size or n.x < 0 or n.y >= size or n.y < 0: continue #oob detection
				var pile = getPile(n)
				if pile.is_empty() or pile.type == WALL or pile.pieces[-1] % 2 != color: continue #valid pile detection
				if 1 << n.x + n.y * 8 & map == 0: #avoid revisiting
					q.append(n)
					map |= 1 << n.x + n.y * 8

	
	if roads[WHITE]:
		return ROAD_WIN_WHITE if (not roads[BLACK]) or ply % 2 == BLACK else ROAD_WIN_BLACK
	elif roads[BLACK]:
		return ROAD_WIN_BLACK
	
	if reserves.caps[WHITE] == 0 and reserves.flats[WHITE] == 0:
		return flatWin()
	elif reserves.caps[BLACK] == 0 and reserves.flats[BLACK] == 0:
		return flatWin()
	
	
	for x in size:
		for y in size:
			if board[x][y].is_empty():
				return ONGOING
	
	return flatWin()


func flatWin() -> int:
	var count = komi
	for x in size:
		for y in size:
			if not board[x][y].is_empty() and board[x][y].type == FLAT:
				if board[x][y].pieces[-1] % 2 == WHITE:
					count -= 1
				else: 
					count += 1
	return DRAW if count == 0 else FLAT_WIN_WHITE if count < 0 else FLAT_WIN_BLACK

func getTPS() -> String:
	var out = ""
	for y in size:
		var eCount = 0
		for x in size:
			var s = board[x][size-y-1].getTPS()
			if s.is_empty(): eCount += 1
			else:
				if eCount != 0:
					out += "x%d," % eCount if eCount > 1 else "x,"
					eCount = 0
				out += s + ","
		if eCount > 0:
			out += "x%d" % eCount if eCount > 1 else "x"
		else:
			out = out.rstrip(",")
		out += "/"
		
	return out.rstrip("/") + " %d %d" % [ply % 2 + 1, ply / 2 + 1]
