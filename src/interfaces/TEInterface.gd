extends Node
class_name TEI

#WARNING: userdefined executables pose security risks, TODO: disable on web version
const tempEXE = "/home/fay/Projects/attak-misc/tiltak/target/release/tei"

enum {
	INACTIVE,
	THINKING,
	READY
}

var pid: int
var stdio: FileAccess
var stderr: FileAccess

var state: int = INACTIVE
var botName: String = "Undefined Bot"

var thread: Thread
var startTPS: String

func _ready():
	return
	if not GameLogic.is_node_ready():
		await GameLogic.ready
		
	startConnection(tempEXE)
	var game = GameData.new("", 6, GameData.LOCAL, GameData.BOT, "You", "Bot", 0, 0, 0, 0, 0, 30, 1)
	startGame(game)


func send(s: String):
	while state != READY:
		await get_tree().create_timer(.1).timeout
	stdio.store_string(s + "\n")
	stdio.store_string("isready\n")
	state = THINKING


func _threadFunc():
	while stdio.is_open() and stdio.get_error() == OK:
		var s = stdio.get_line()
		if not s.is_empty(): parse(s)
	
	if state == INACTIVE: return #it was simply closed, all good
	
	GameLogic.endGame(GameState.DEFAULT_WIN_WHITE if GameLogic.gameData.playerWhite == GameData.LOCAL else GameState.DEFAULT_WIN_BLACK)
	Notif.message("The Bot program has crashed!", false)
	print("BOT DIED! THE PIPE CLOSED WITH ID %d" % stdio.get_error())


func parse(s: String):
	var data = s.split(" ")
	match Array(data):
		["id", "name", ..]:
			botName = " ".join(data.slice(2))
		
		["id", "author", ..]:
			pass #TODO set?
		
		["teiok"]:
			state = READY
		
		["option", ..]:
			pass #TODO
		
		["info", ..]:
			pass #TODO
		
		["bestmove", ..]:
			var move = Ply.fromPTN(data[1])
			GameLogic.doMove.call_deferred(self, move)
		
		["readyok"]:
			state = READY
		
		_:
			print("unrecognized message! %s" % s)


func startConnection(executable: String):
	botName = "Undefined Bot"
	
	var d = OS.execute_with_pipe(executable, PackedStringArray())
	state = READY
	thread = Thread.new()
	thread.start(_threadFunc)
	
	stdio = d["stdio"]
	stderr = d["stderr"]
	pid = d["pid"]
	print("started bot with pid %d" % pid)
	send("tei")


func sendMove(origin: Node, ply: Ply):
	if origin == self: return 
	#TODO deal with custom startposition
	var pos = "position tps %s moves" % startTPS
	for i in GameLogic.history:
		pos += " %s" % i.toPTN()
	send(pos)
	send("go movetime %d" % (10000 if ply.boardState.ply > 4 else 100)) #TODO proper time implementation


func onResign():
	GameLogic.endGame(GameState.DEFAULT_WIN_WHITE if GameLogic.gameData.playerWhite == GameData.BOT else GameState.DEFAULT_WIN_BLACK)


func startGame(game: GameData):
	while state != READY:
		await get_tree().create_timer(.1).timeout
	
	if game.playerWhite == GameData.BOT:
		game.playerWhiteName = botName
	elif game.playerBlack == GameData.BOT:
		game.playerBlackName = botName
	
	GameLogic.doSetup(game)
	startTPS = GameLogic.startState.getTPS()
	GameLogic.move.connect(sendMove)
	GameLogic.end.connect(endGame)
	GameLogic.resign.connect(onResign)
	
	send("teinewgame %d" % game.size) #TODO handle start if bot is white


func endGame(type: int):
	GameLogic.move.disconnect(sendMove)
	GameLogic.end.disconnect(endGame)
	GameLogic.resign.disconnect(onResign)
	stdio.store_string("quit")
	state = INACTIVE
	stdio.close()
	thread.wait_to_finish()


func _exit_tree() -> void:
	if state != INACTIVE:
		stdio.store_string("quit")
		state = INACTIVE
	if stdio != null:
		stdio.close()
		thread.wait_to_finish()