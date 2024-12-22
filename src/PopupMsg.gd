extends Node


@onready var audioPlayer: AudioStreamPlayer = $AudioStreamPlayer
@onready var popUp: PanelContainer = $Panel
@onready var popUpLabel: Label = $Panel/Label

@export var popUpLength: float = 5

@export_category("audio")
@export var move: AudioStream
@export var start: AudioStream
@export var end: AudioStream
@export var time: AudioStream
@export var notif: AudioStream


var PopUpTimer: float = 0

func _ready():
	popUpLabel.add_theme_font_size_override(&"font_size",
	(128 if Globals.isMobile() else 32))


func _process(delta: float) -> void:
	if PopUpTimer > 0:
		PopUpTimer -= delta
		if PopUpTimer <= 0:
			popUp.hide()


func message(msg: String, noise: bool = true):
	popUpLabel.text = " " + msg + " "
	popUp.show()
	PopUpTimer = popUpLength
	if noise:
		ping(notif)


func ping(audio: AudioStream = notif):
	audioPlayer.stream = audio
	audioPlayer.play()
