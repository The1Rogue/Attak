extends TabMenuTab
class_name WatchList

var count = 0
var games: Dictionary = {}

func _ready():
	PlayTakI.addGame.connect(add)
	PlayTakI.removeGame.connect(remove)
	PlayTakI.logout.connect(clear)


func add(game: GameData, id: int):
	count += 1
	tabButton.text = " Watch Game (%d) " % count
	var b = Button.new()
	b.text = " %s vs %s %dx%d +%3.1f" % [game.playerWhiteName, game.playerBlackName, game.size, game.size, game.komi/2.0]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(b)
	b.reset_size()
	
	
	games[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func(): observe(id))


func remove(id: int):
	count -= 1
	tabButton.text = " Watch Game (%d) " % count
	remove_child(games[id])
	games.erase(id)


func clear():
	for id in games:
		remove_child(games[id])
	count = 0
	tabButton.text = " Watch Game (0) "
	games.clear()


func observe(id: int):
	if GameLogic.gameData.isObserver() or GameLogic.gameData.isScratch() or not GameLogic.active:
		PlayTakI.socket.send_text("Observe " + str(id))
	else:
		Notif.message("Can't watch a game while you're still playing!")
