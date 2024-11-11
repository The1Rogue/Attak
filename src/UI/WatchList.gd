extends VBoxContainer
class_name WatchList



@export var interface: PlayTakI
@onready var label: Label = $Label
var gameCount = 0
var games: Dictionary = {}

func _ready():
	interface.addGame.connect(add)
	interface.removeGame.connect(remove)


func add(game: GameData, id: int):
	gameCount += 1
	label.text = " %d Games being played " % gameCount
	var b = Button.new()
	add_child(b)
	b.text = " %-14s vs %14s %dx%d +%3.1f" % [game.playerWhiteName, game.playerBlackName, game.size, game.size, game.komi/2.0]
	
	games[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func(): observe(id))


func remove(id: int):
	gameCount -= 1
	label.text = "%d Games being played" % gameCount
	remove_child(games[id])
	games.erase(id)


func observe(id: int):
	interface.socket.send_text("Observe " + str(id))
