extends Control

@onready var entry: LineEdit = $HBoxContainer/LineEdit

@onready var colorEntry: OptionButton = $GridContainer/Color2
@onready var sizeEntry: OptionButton = $GridContainer/Size2
@onready var komiEntry: SpinBox = $GridContainer/Komi2
@onready var timeEntry: SpinBox = $GridContainer/Time2
@onready var incEntry: SpinBox = $GridContainer/Incr2

@onready var tei: TEI = $TEI



var count = 0
var games: Dictionary = {}

func _ready():
	#if not (OS.has_feature("tei") or OS.has_feature("editor")): TODO
		#if not get_parent().is_node_ready():
			#await get_parent().ready
		#get_parent().remove(self)
		#queue_free()
		#return
		
	$HBoxContainer/Button.pressed.connect($FileDialog.show)
	$FileDialog.file_selected.connect(select)
	$Button.pressed.connect(start)


func select(path: String):
	entry.text = path


func start():
	if GameLogic.active:
		if GameLogic.gameData.playerWhite == GameData.BOT or GameLogic.gameData.playerBlack == GameData.BOT:
			GameLogic.end.emit(GameState.ONGOING)
		elif not (GameLogic.gameData.isObserver() or GameLogic.gameData.isScratch()):
			Notif.message("Can't start a new game while you're still playing!")
			return
			
	var playerName = PlayTakI.activeUsername if not PlayTakI.activeUsername.is_empty() else "Player"
	var size = sizeEntry.get_selected_id()

	if not FileAccess.file_exists(entry.text):
		Notif.message("Cant find file: %s" % entry.text)
		return #TODO can we detect executability too?

	if not await tei.startConnection(entry.text):
		Notif.message("Detected fatal error starting bot, restart Attak and try again")
		return
	
	var game = GameData.new(
		"", size,
		GameData.LOCAL if colorEntry.get_selected_id() == GameState.WHITE else GameData.BOT,
		GameData.LOCAL if colorEntry.get_selected_id() == GameState.BLACK else GameData.BOT,
		playerName if colorEntry.get_selected_id() == GameState.WHITE else tei.botName,
		playerName if colorEntry.get_selected_id() == GameState.BLACK else tei.botName,
		timeEntry.value * 60, incEntry.value, 0, 0, komiEntry.value * 2, 
		NewSeek.standardFlats[size-3], NewSeek.standardCaps[size-3]
	)
	
	tei.startGame(game)
