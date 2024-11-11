extends VBoxContainer
class_name GameUI


@onready var WhiteName = $PlayerWhite
@onready var WhiteTime = $PlayerWhiteTime
var timeWhite: int = 0

@onready var BlackName = $PlayerBlack
@onready var BlackTime = $PlayerBlackTime
var timeBlack: int = 0

@onready var ptnDisplay = $ScrollContainer/PtnDisplay

@onready var audioPlayer: AudioStreamPlayer = $AudioStreamPlayer

@export var criticalTime: int = 30 * 1000

@export_category("audio")
@export var move: AudioStream
@export var start: AudioStream
@export var end: AudioStream
@export var time: AudioStream
@export var ping: AudioStream

signal clickPly(id: int)

var PopUpTimer: float = 0

@onready var undoButton = $HBoxContainer/Undo
@onready var drawButton = $HBoxContainer/Draw
@onready var resignButton = $HBoxContainer/Resign


var i = 0
var active = false


static func msToTime(ms: int) -> String:
	var secs = ms / 1000
	return "%02d:%02d" % [secs / 60, secs % 60]

func _ready() -> void:
	Globals.gameUI = self

func setup(game: GameData):
	if not self.is_node_ready():
		await self.ready
	
	audioPlayer.stream = start; audioPlayer.play()
	for child in ptnDisplay.get_children():
		ptnDisplay.remove_child(child)
	
	active = false
	i = 0
	WhiteName.text = game.playerWhiteName
	BlackName.text = game.playerBlackName
	timeWhite = game.time
	timeBlack = game.time
	WhiteTime.text = msToTime(timeWhite)
	BlackTime.text = msToTime(timeBlack)


func sync(timeWhite: int, timeBlack: int):
	self.timeWhite = timeWhite
	self.timeBlack = timeBlack
	WhiteTime.text = msToTime(timeWhite)
	BlackTime.text = msToTime(timeBlack)


func _process(delta: float) -> void:
	var critical
	if i % 2 == 1:
		critical = timeBlack > criticalTime
		timeBlack -= min(timeBlack, delta * 1000)
		if critical and timeBlack < criticalTime:
			audioPlayer.stream = time; audioPlayer.play()
		BlackTime.text = msToTime(timeBlack)
		
	elif active:
		critical = timeWhite > criticalTime
		timeWhite -= min(timeWhite, delta * 1000)
		if critical and timeWhite < criticalTime:
			audioPlayer.stream = time; audioPlayer.play()
		WhiteTime.text = msToTime(timeWhite)
		
	if PopUpTimer > 0:
		PopUpTimer -= delta
		if PopUpTimer <= 0:
			$Popup/Panel.hide()


func addPly(ply: Ply):
	if ply.boardState.win != GameState.ONGOING:
		audioPlayer.stream = end;
		active = false
	else:
		audioPlayer.stream = move
		active = true
	audioPlayer.play()
	
	if i % 2 == 0:
		var l = Label.new()
		l.text = str(i/2 + 1) + ". "
		ptnDisplay.add_child(l)
	var b = Button.new()
	b.text = ply.toPTN()
	var c = i #this ensures the lambda expression works correctly
	b.pressed.connect(func(): clickPly.emit(c))
	ptnDisplay.add_child(b)
	i += 1


func removeLast():
	assert(i > 0, "CANT REMOVE IF THERES NOTHING TO REMOVE")
	ptnDisplay.remove_child(ptnDisplay.get_child(-1))
	if i % 2 == 1:
		ptnDisplay.remove_child(ptnDisplay.get_child(-1))
	i -= 1


func notify(msg: String, ping: bool = true):
	$Popup/Panel/Label.text = " " + msg + " "
	$Popup/Panel.show()
	PopUpTimer = 10
	if ping:
		audioPlayer.stream = self.ping
		audioPlayer.play()
