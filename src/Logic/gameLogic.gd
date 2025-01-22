extends Node

enum { #TODO unused?
	WHITE = 0,
	BLACK = 1
}

var timerWhite: Timer
var timerBlack: Timer

var gameData: GameData = GameData.new("", 5, GameData.LOCAL, GameData.LOCAL, "Player White", "Player Black", 0, 0, 0, 0, 0, 21, 1)

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
	timerWhite = Timer.new()
	timerWhite.autostart = true
	timerWhite.one_shot = true
	add_child(timerWhite)
	
	timerBlack = Timer.new()
	timerBlack.autostart = true
	timerBlack.one_shot = true
	add_child(timerBlack)
	
	doSetup(gameData, null)


func doSetup(game: GameData, start: GameState = null):
	if active: #stop game if ongoing
		end.emit(GameState.ONGOING)
	
	history = []
	view = 0
	active = true
	
	gameData = game
	if start == null:
		startState = GameState.emptyState(game.size, game.flats, game.caps, game.komi / 2.0)
	else:
		assert(start.size == game.size, "STARTSTATE SIZE DOES NOT MATCH GAME DATA SIZE")
		startState = start
	
	if undoRequest.is_connected(localUndoReq):
		undoRequest.disconnect(localUndoReq)
	if game.playerWhite == GameData.LOCAL and game.playerBlack == GameData.LOCAL: #apparently this gives "Condion "det == 0" is true" error, i dont understand why, but its not fatal and still correct... so....
		undoRequest.connect(localUndoReq)
	
	
	timerWhite.paused = true
	timerBlack.paused = true
	if game.playerBlack != GameData.BOT: #no timer if you play against a bot locally
		timerWhite.start(game.time)
	else:
		timerWhite.start(0)
		
	if game.playerWhite != GameData.BOT:
		timerBlack.start(game.time)
	else:
		timerBlack.start(0)
	
	setup.emit(gameData, start)


func timeSync(timeWhite: int, timeBlack: int):
	sync.emit(timeWhite, timeBlack)
	timerWhite.start(timeWhite / 1000.0)
	timerBlack.start(timeBlack / 1000.0)


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
	else:
		Notif.ping(Notif.move)
	
	var i = ply.boardState.ply % 2
	
	timerWhite.paused = i == 1 or ply.boardState.win != GameState.ONGOING
	timerBlack.paused = i == 0 or ply.boardState.win != GameState.ONGOING
	
	history.append(ply)
	move.emit(origin, ply)
	if view+1 == history.size():
		view += 1
		viewState.emit(ply.boardState)


#handles undos in local games
func localUndoReq(o: Node, r: bool):
	doUndo()


func doUndo():
	if history.is_empty(): return
	history.pop_back()
	
	active = true
	
	timerWhite.paused = currentPly() % 2 == 1
	timerBlack.paused = currentPly() % 2 == 0
	
	
	undo.emit()
	if view > history.size():
		view = history.size()
		viewState.emit(history[-1].boardState if not history.is_empty() else startState)


func endGame(type: int):
	if not active: return #game already ended, no need to repeat it
	
	assert(activeState().win == GameState.ONGOING or activeState().win == type, "GAME END TYPE DOES NOT MATCH")
	timerWhite.paused = true
	timerBlack.paused = true
	
	active = false
	end.emit(type)
	if type != GameState.ONGOING:
		activeState().win = type
		Notif.ping(Notif.end)
		Notif.message("Game Ended " + GameState.resultStrings[type], false)
