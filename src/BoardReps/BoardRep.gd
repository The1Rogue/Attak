extends Player
class_name BoardRep

const endMsg = ["Game Ended R-0", "Game Ended 0-R", "Game Ended F-0", "Game Ended 0-F", "Game Ended in a DRAW", "Game Ended 1-0", "Game Ended 0-1"]

enum {
	WHITE = 0,
	BLACK = 1
}

var active: bool = false
var canPlay: bool = false

var players: Array[Player] = [null, null]

var history: Array[Ply] = []

var startState: GameState

var plyView: int = -1


@export var GUI: GameUI

func _ready():
	GUI.clickPly.connect(setPly)

	GUI.drawButton.toggled.connect(pressDraw)
	GUI.undoButton.toggled.connect(pressUndo)
	GUI.resignButton.pressed.connect(resign)
	Globals.board = self


func setup(game: GameData):
	history = []
	plyView = -1
	
	if players[WHITE] != null: players[WHITE].onMove.disconnect(play)
	if players[BLACK] != null and players[BLACK] != players[WHITE]: players[BLACK].onMove.disconnect(play)
	
	if players[WHITE] is Interface: players[WHITE].timeSync.disconnect(sync)
	if players[BLACK] is Interface and players[WHITE] != players[BLACK]: players[BLACK].timeSync.disconnect(sync)
	
	GUI.setup(game)
	
	if game.playerWhite == null: game.playerWhite = self
	if game.playerBlack == null: game.playerBlack = self
	players[WHITE] = game.playerWhite
	players[BLACK] = game.playerBlack
	players[WHITE].onMove.connect(play)
	if players[BLACK] != players[WHITE]: players[BLACK].onMove.connect(play)
	
	startState = GameState.emptyState(game.size, game.flats, game.caps, game.komi / 2.0)
	
	if game.playerWhite is Interface:
		game.playerWhite.timeSync.connect(sync)
	elif game.playerBlack is Interface:
		game.playerBlack.timeSync.connect(sync)
	
	active = true
	canPlay = players[WHITE] == self
	
	var c: Chat
	if game.playerWhite == self and game.playerBlack is PlayTakI:
		game.playerBlack.menu.gotoOrMakeChat(game.playerBlack, game.playerBlackName, Chat.PRIVATE)
	elif game.playerBlack == self and game.playerWhite is PlayTakI:
		game.playerWhite.menu.gotoOrMakeChat(game.playerWhite, game.playerWhiteName, Chat.PRIVATE)
		
	elif game.playerWhite is PlayTakI and game.playerBlack is PlayTakI:
		var n = [game.playerWhiteName, game.playerBlackName]; n.sort()
		game.playerWhite.menu.gotoOrMakeChat(game.playerWhite, "-".join(n), Chat.ROOM)


func play(player: Player, ply: Ply):
	GUI.undoButton.set_pressed_no_signal(false)
	if history.size() == 0:
		startState.apply(ply)
	else:
		history[-1].boardState.apply(ply)
	
	
	if ply.boardState.win != GameState.ONGOING:
		end(endMsg[ply.boardState.win])
	
	GUI.addPly(ply)
	
	if plyView == history.size()-1:
		plyView += 1
		setState(ply.boardState)
	history.append(ply)
	
	var i = history.size() % 2
	
	canPlay = players[i] == self and active
	if player == self and players[i] is Interface:
		players[i].sendMove(ply)


func undo():
	assert(history.size() > 0, "CANT UNDO AN EMPTY BOARD")
	GUI.undoButton.set_pressed_no_signal(false)
	history.pop_back()
	
	active = true #this is mostly for undoing in scratch games
	canPlay = players[history.size()%2] == self
	
	GUI.removeLast()
	if plyView == history.size():
		plyView -= 1
		setState(history[-1].boardState if history.size() > 0 else startState)


func sync(timeWhite: int, timeBlack: int): #time in ms
	GUI.sync(timeWhite, timeBlack)


func setState(state: GameState):
	pass


func setPly(ply: int):
	assert(history.size() > ply, "CANT VIEW PLY BECAUSE IT DOES NOT EXIST")
	canPlay = (ply == history.size()-1) and (players[1 - ply%2] == self)
	plyView = ply
	setState(history[ply].boardState)


func pressDraw(toggle: bool):
	if players[0] == self and players[1] is PlayTakI:
		players[1].sendToGame("OfferDraw" if toggle else "RemoveDraw")
	elif players[1] == self and players[0] is PlayTakI:
		players[0].sendToGame("OfferDraw" if toggle else "RemoveDraw")


func pressUndo(toggle: bool):
	if players[0] == self and players[1] == self and history.size() > 0:
		undo()
	if players[0] == self and players[1] is PlayTakI:
		players[1].sendToGame("RequestUndo" if toggle else "RemoveUndo")
	elif players[1] == self and players[0] is PlayTakI:
		players[0].sendToGame("RequestUndo" if toggle else "RemoveUndo")


func resign():
	if players[0] is PlayTakI and players[1] == self:
		players[0].sendToGame("Resign")
	elif players[1] is PlayTakI and players[0] == self:
		players[1].sendToGame("Resign")


func end(msg: String):
	if not active: return
	GUI.timeWhite.paused = true
	GUI.timeBlack.paused = true
	GUI.notify(msg, false)
	active = false
	canPlay = false


func _unhandled_key_input(event):
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_LEFT and plyView > 0:
			setPly(plyView - 1)
		elif event.keycode == KEY_RIGHT and plyView < history.size()-1:
			setPly(plyView + 1)
