extends Node
class_name TEI

enum {
	INACTIVE,
	STARTING,
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

var FATAL: bool #TODO actually solve the fatal bug


func send(s: String):
	while state == THINKING or state == STARTING:
		await get_tree().create_timer(.1).timeout
	if state == INACTIVE: return
	stdio.store_line(s)


func askReady():
	state = THINKING
	stdio.store_line("isready")


func _threadFunc():
	while stdio.is_open() and stdio.get_error() == OK:
		var s = stdio.get_line()
		if not s.is_empty(): parse(s)
	
	if state == INACTIVE or stdio.get_error() == OK: return #it was simply closed, all good
	
	#clean up a crash
	botExit.call_deferred()
	GameLogic.endGame.call_deferred(GameState.DEFAULT_WIN_WHITE if GameLogic.gameData.playerWhite == GameData.LOCAL else GameState.DEFAULT_WIN_BLACK)
	Notif.message.call_deferred("The Bot program has crashed!", false)
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
			state = READY
			var move = Ply.fromPTN(data[1])
			GameLogic.doMove.call_deferred(self, move)
		
		["readyok"]:
			state = READY
		
		_:
			pass
			#print("unrecognized message! %s" % s)


func startConnection(executable: String) -> bool:
	if FATAL: return false
	botName = "Undefined Bot"
	
	var d = OS.execute_with_pipe(executable, PackedStringArray())
	state = STARTING
	
	stdio = d["stdio"]
	stderr = d["stderr"]
	pid = d["pid"]
	
	await get_tree().create_timer(1).timeout
	if not OS.is_process_running(pid):
		print("FATALITY DETECTED")
		FATAL = true
		botExit()
		return false
	
	print("started bot with pid %d" % pid)

	thread = Thread.new()
	thread.start(_threadFunc)
	stdio.store_line("tei")
	return true


func sendMove(origin: Node, ply: Ply):
	if origin == self: return
	var pos = "position %s moves" % startTPS
	for i in GameLogic.history:
		pos += " %s" % i.toPTN()
	send(pos)
	send("go wtime %d btime %d winc %d binc %d" % [GameLogic.timerWhite.time_left * 1000, GameLogic.timerBlack.time_left * 1000, GameLogic.gameData.increment * 1000, GameLogic.gameData.increment * 1000])
	state = THINKING


func onResign():
	GameLogic.endGame(GameState.DEFAULT_WIN_WHITE if GameLogic.gameData.playerWhite == GameData.BOT else GameState.DEFAULT_WIN_BLACK)


func startGame(game: GameData):
	while state == THINKING or state == STARTING:
		await get_tree().create_timer(.1).timeout
	
	if state == INACTIVE: return
	
	if game.playerWhite == GameData.BOT:
		game.playerWhiteName = botName
	elif game.playerBlack == GameData.BOT:
		game.playerBlackName = botName
	
	GameLogic.doSetup(game)
	startTPS = "startpos" if GameLogic.startState.isEmpty else ("tps %s" % GameLogic.startState.getTPS())
	GameLogic.move.connect(sendMove)
	GameLogic.end.connect(endGame)
	GameLogic.resign.connect(onResign)
	
	send("setoption name HalfKomi value %d" % game.komi)
	send("teinewgame %d" % game.size)
	askReady()
	if game.playerWhite == GameData.BOT:
		send("position tps %s" % startTPS)
		send("go wtime %d btime %d winc %d binc %d" % [game.time*1000, game.time*1000, game.increment*1000, game.increment*1000])


func botExit():
	state = INACTIVE
	if thread != null and thread.is_started():
		thread.wait_to_finish()
	if stdio != null and stdio.is_open():
		stdio.close()
	if OS.is_process_running(pid):
		OS.kill(pid)


func endGame(type: int):
	GameLogic.move.disconnect(sendMove)
	GameLogic.end.disconnect(endGame)
	GameLogic.resign.disconnect(onResign)
	stdio.store_line("quit")
	state = INACTIVE
	while stdio.is_open():
		await get_tree().create_timer(.1).timeout
	botExit()


func _exit_tree() -> void:
	if state != INACTIVE:
		stdio.store_line("quit")
	botExit()
