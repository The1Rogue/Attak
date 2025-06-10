extends Node


@onready var audioPlayer: AudioStreamPlayer = $AudioStreamPlayer
@onready var popUp: PanelContainer = $Notif
@onready var popUpLabel: RichTextLabel = $Notif/Label

@onready var endMenu: PanelContainer = $GameEnd
@onready var endText: RichTextLabel = $GameEnd/VBoxContainer/Label
@onready var endLink: URLButton = $GameEnd/VBoxContainer/URLButton
@onready var endID: Button = $GameEnd/VBoxContainer/GameID


@export var popUpLength: float = 5

@export_category("audio")
@export var move: AudioStream
@export var start: AudioStream
@export var end: AudioStream
@export var time: AudioStream
@export var notif: AudioStream


var PopUpTimer: float = 0

static func escape_bbcode(bbcode_text):
	return bbcode_text.replace("[", "[lb]")

func _ready():
	var s = (4 if Globals.isMobile() else 1)
	popUpLabel.add_theme_font_size_override(&"normal_font_size", 32*s)
	popUp.custom_minimum_size.x = 300 * s
	
	endID.pressed.connect(func(): DisplayServer.clipboard_set(GameLogic.gameData.id))
	endMenu.gui_input.connect(func(e): if e is InputEventMouseButton: endMenu.hide())

func _process(delta: float) -> void:
	if PopUpTimer > 0:
		PopUpTimer -= delta
		if PopUpTimer <= 0:
			popUp.hide()


func message(msg: String, noise: bool = true):
	print(msg)
	popUpLabel.text = "[center]" + escape_bbcode(msg) + "[/center]"
	popUp.show()
	PopUpTimer = popUpLength
	if noise:
		ping(notif)


func chatMessage(user: String, msg: String):
	popUp.show()
	PopUpTimer = popUpLength
	popUpLabel.clear()
	popUpLabel.push_color(Chat.color(user))
	popUpLabel.append_text("<"+escape_bbcode(user) + ">: ")
	popUpLabel.pop()
	popUpLabel.append_text(escape_bbcode(msg) + "\n")


func ping(audio: AudioStream = notif):
	audioPlayer.stream = audio
	audioPlayer.play()


func endGame(type: int):
	endText.text = " Game over %s \n" % GameState.resultStrings[type]
	
	if type == GameState.DRAW:
		endText.text += " Game was drawn "
	elif type == GameState.ONGOING:
		endText.text += " Game is ongoing? (please report a bug) "
	else:
		var p = GameLogic.gameData.playerWhiteName if type%2==0 else GameLogic.gameData.playerBlackName
		endText.push_color(Chat.color(p))
		endText.append_text(escape_bbcode(p))
		endText.pop()
		endText.append_text(" wins with " + ("a road " if type < 2 else "flats "))
	
	endLink.URL = "https://playtak.com/games/%s/ninjaviewer" % GameLogic.gameData.id
	endMenu.show()
	ping(end)
