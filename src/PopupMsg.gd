extends Node


@onready var audioPlayer: AudioStreamPlayer = $AudioStreamPlayer
@onready var popUp: PanelContainer = $Panel
@onready var popUpLabel: RichTextLabel = $Panel/Label

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


func _process(delta: float) -> void:
	if PopUpTimer > 0:
		PopUpTimer -= delta
		if PopUpTimer <= 0:
			popUp.hide()


func message(msg: String, noise: bool = true):
	popUpLabel.text = "[center]" + escape_bbcode(msg) + "[/center]"
	popUp.show()
	PopUpTimer = popUpLength
	if noise:
		ping(notif)


func chatMessage(user: String, msg: String):
	popUp.show()
	PopUpTimer = popUpLength
	var c = Color.RED
	c.h = user.hash() as float / (2**32)
	popUpLabel.clear()
	popUpLabel.push_color(c)
	popUpLabel.append_text("<"+escape_bbcode(user) + ">: ")
	popUpLabel.pop()
	popUpLabel.append_text(escape_bbcode(msg) + "\n")


func ping(audio: AudioStream = notif):
	audioPlayer.stream = audio
	audioPlayer.play()
