extends Node

enum {
	WHITE = 0,
	BLACK = 1
}


var gameData: GameData = GameData.new(5, GameData.LOCAL, GameData.LOCAL, "Player White", "Player Black", 0, 0, 0, 0, 0, 21, 1)


var startState: GameState = GameState.emptyState(5, 21, 1, 0)
var history: Array[Ply]

var view: int = 0

var active: bool = true

signal setup(gameData: GameData, startState: GameState)
signal move(origin: Node, ply: Ply)
signal undo
signal undoRequest(origin: Node, revoke: bool)
signal drawRequest(origin: Node, revoke: bool)
signal resign
signal viewState(state: GameState)
signal end(type: int)
signal sync(timeWhite: int, timeBlack: int)

func _ready():
	doSetup(gameData, null)


func doSetup(game: GameData, start: GameState = null):
	history = []
	view = 0
	active = true
	
	gameData = game
	if start == null:
		startState = GameState.emptyState(game.size, game.flats, game.caps, game.komi / 2.0)
	else:
		assert(start.size == game.size, "STARTSTATE SIZE DOES NOT MATCH GAME DATA SIZE")
		startState = start
	
	if game.playerWhite == GameData.LOCAL and game.playerBlack == GameData.LOCAL: #apparently this gives "Condion "det == 0" is true" error, i dont understand why, but its not fatal and still correct... so....
		undoRequest.connect(localUndoReq)
	elif undoRequest.is_connected(localUndoReq):
		undoRequest.disconnect(localUndoReq)
	
	
	setup.emit(gameData, start)


func activeState() -> GameState:
	return history[-1].boardState if not history.is_empty() else startState


func viewedState() -> GameState:
	return startState if view == 0 else history[view-1].boardState


func viewIsLast() -> bool:
	return view == history.size()


func currentPly() -> int:
	return activeState().ply


func setView(id: int):
	assert(id >= 0 and id <= history.size())
	view = id
	viewState.emit(history[id-1].boardState if id > 0 else startState)


func doMove(origin: Node, ply: Ply):
	if history.size() == 0:
		startState.apply(ply)
	else:
		history[-1].boardState.apply(ply)
	
	if ply.boardState.win != GameState.ONGOING:
		endGame(ply.boardState.win)
	
	if view == history.size():
		view += 1
		viewState.emit(ply.boardState)
	history.append(ply)
	
	var i = currentPly() % 2
	move.emit(origin, ply)


#handles undos in local games
func localUndoReq(o: Node, r: bool):
	doUndo()


func doUndo():
	if history.is_empty(): return
	history.pop_back()
	
	active = true #this is mostly for undoing in scratch games TODO, ensure this works with the new system
	
	undo.emit()
	if view > history.size():
		view = history.size()
		viewState.emit(history[-1].boardState if not history.is_empty() else startState)


func endGame(type: int):
	assert(type != GameState.ONGOING, "CANT END AN ONGOING GAME")
	assert(activeState().win == GameState.ONGOING or activeState().win == type, "GAME END TYPE DOES NOT MATCH")
	if not active: return #game already ended, no need to repeat it
	active = false
	activeState().win = type
	end.emit(type)