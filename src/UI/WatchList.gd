extends TabMenuTab
class_name WatchList



@export var interface: PlayTakI
var count = 0
var games: Dictionary = {}

var gameActive: int = -1

func _ready():
	interface.addGame.connect(add)
	interface.removeGame.connect(remove)


func add(game: GameData, id: int):
	count += 1
	tabButton.text = " Watch Game (%d) " % count
	var b = Button.new()
	add_child(b)
	b.text = " %-14s vs %14s %dx%d +%3.1f" % [game.playerWhiteName, game.playerBlackName, game.size, game.size, game.komi/2.0]
	
	games[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func(): observe(id))
	
	if game.playerWhiteName == interface.activeUsername or game.playerBlackName == interface.activeUsername:
		gameActive = id



func remove(id: int):
	if gameActive == id: gameActive = -1
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
	if gameActive == -1:
		interface.socket.send_text("Observe " + str(id))
	else:
		Globals.gameUI.notify("Can't watch a game while you're still playing!")
