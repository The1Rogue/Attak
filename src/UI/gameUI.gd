extends VBoxContainer
class_name GameUI


@onready var WhiteName = $PlayerWhite
@onready var WhiteTime = $PlayerWhiteTime
@onready var timeWhite: Timer  = $TimerWhite

@onready var BlackName = $PlayerBlack
@onready var BlackTime = $PlayerBlackTime
@onready var timeBlack: Timer  = $TimerBlack

@onready var ptnDisplay = $ScrollContainer/PtnDisplay

@onready var audioPlayer: AudioStreamPlayer = $AudioStreamPlayer

@export var criticalTime: int = 30
var whiteCritical: bool = false
var blackCritical: bool = false

@export_category("audio")
@export var move: AudioStream
@export var start: AudioStream
@export var end: AudioStream
@export var time: AudioStream
@export var ping: AudioStream

var PopUpTimer: float = 0

@onready var undoButton = $HBoxContainer/Undo 
@onready var drawButton = $HBoxContainer/Draw
@onready var resignButton = $HBoxContainer/Resign

var i = 0

static func timeString(sec: int) -> String:
	return "%02d:%02d" % [sec / 60, sec % 60]


func _ready() -> void:
	Globals.gameUI = self
	GameLogic.setup.connect(setup)
	GameLogic.move.connect(addPly)
	GameLogic.undo.connect(removeLast)
	GameLogic.end.connect(endMessage)
	GameLogic.sync.connect(sync)
	
	GameLogic.undoRequest.connect(undoRequest)
	GameLogic.drawRequest.connect(drawRequest)
	
	setup(GameLogic.gameData, null)
	
	undoButton.toggled.connect(func(t:bool): GameLogic.undoRequest.emit(self, not t))
	drawButton.toggled.connect(func(t:bool): GameLogic.drawRequest.emit(self, not t))
	resignButton.pressed.connect(GameLogic.resign.emit)


func setup(game: GameData, startState: GameState):
	if not self.is_node_ready():
		await self.ready
	
	audioPlayer.stream = start; audioPlayer.play()
	for child in ptnDisplay.get_children():
		ptnDisplay.remove_child(child)
	
	i = 0
	WhiteName.text = game.playerWhiteName
	BlackName.text = game.playerBlackName
	timeWhite.paused = true
	timeBlack.paused = true
	timeWhite.start(game.time)
	timeBlack.start(game.time)
	WhiteTime.text = timeString(game.time)
	BlackTime.text = timeString(game.time)
	whiteCritical = game.time == 0 #prevent critical sound on not timed game
	blackCritical = game.time == 0


func sync(timeWhite: int, timeBlack: int):
	whiteCritical = false
	blackCritical = false
	self.timeWhite.start(timeWhite / 1000.0)
	self.timeBlack.start(timeBlack / 1000.0)
	WhiteTime.text = timeString(timeWhite / 1000.0)
	BlackTime.text = timeString(timeBlack / 1000.0)


func _process(delta: float) -> void:
	if not timeWhite.paused:
		WhiteTime.text = timeString(timeWhite.time_left)
		if not whiteCritical and timeWhite.time_left < criticalTime:
			whiteCritical = true
			audioPlayer.stream = time; audioPlayer.play()
	
	elif not timeBlack.paused:
		BlackTime.text = timeString(timeBlack.time_left)
		if not blackCritical and timeBlack.time_left < criticalTime:
			blackCritical = true
			audioPlayer.stream = time; audioPlayer.play()
		
	if PopUpTimer > 0:
		PopUpTimer -= delta
		if PopUpTimer <= 0:
			$Popup/Panel.hide()


func addPly(origin: Node, ply: Ply):
	undoButton.set_pressed_no_signal(false)
	drawButton.set_pressed_no_signal(false)
	
	if ply.boardState.win != GameState.ONGOING:
		audioPlayer.stream = end;
	else:
		audioPlayer.stream = move
	audioPlayer.play()
	
	
	if ply.boardState.ply % 2 == 1:
		var l = Label.new()
		l.text = str((ply.boardState.ply+1)/2) + ". "
		ptnDisplay.add_child(l)
	
	elif i == 0:
		var l = Label.new()
		l.text = str(ply.boardState.ply/2) + ". "
		ptnDisplay.add_child(l)
		ptnDisplay.add_child(Control.new()) #empty filler to align things
	
	timeWhite.paused = (ply.boardState.ply) % 2 == 1 or ply.boardState.win != GameState.ONGOING
	timeBlack.paused = (ply.boardState.ply) % 2 == 0 or ply.boardState.win != GameState.ONGOING

	var b = Button.new()
	b.text = ply.toPTN()
	var c = i #this ensures the lambda expression works correctly
	b.pressed.connect(func(): GameLogic.setView(c+1))
	ptnDisplay.add_child(b)
	i += 1


func removeLast():
	assert(i > 0, "CANT REMOVE IF THERES NOTHING TO REMOVE")
	undoButton.set_pressed_no_signal(false)
	drawButton.set_pressed_no_signal(false)
	
	ptnDisplay.remove_child(ptnDisplay.get_child(-1))
	var c = ptnDisplay.get_child(-1)
	if c is Label:
		ptnDisplay.remove_child(c)
		
	timeWhite.paused = i % 2 == 0
	timeBlack.paused = i % 2 == 1
	i -= 1


func endMessage(type: int):
	assert(type != GameState.ONGOING, "Cant end an ongoing Game!")
	notify("Game Ended " + GameState.resultStrings[type], false)
	audioPlayer.stream = end; audioPlayer.play()


func undoRequest(origin: Node, revoke: bool):
	if origin == self: return
	notify("Your opponent retracts their undo request." if revoke else "Your opponent requests an undo!")


func drawRequest(origin: Node, revoke: bool):
	if origin == self: return
	notify("Your opponent retracts their draw offer." if revoke else "Your opponent offers a draw!")


func notify(msg: String, ping: bool = true):
	$Popup/Panel/Label.text = " " + msg + " "
	$Popup/Panel.show()
	PopUpTimer = 10
	if ping:
		audioPlayer.stream = self.ping
		audioPlayer.play()
