class_name GameData


enum { #PlayerType
	LOCAL,
	PLAYTAK,
	BOT #not yet implemented
}

var id: String

var playerWhite: int
var playerBlack: int

var playerWhiteName: String
var playerBlackName: String

var size: int

var flats: int
var caps: int

var komi: int

var time: int #in seconds
var increment: int

var triggerMove: int
var triggerTime: int

func _init(size: int, pw: int, pb: int, pwn: String, pbn: String, time: int, increment: int, trigger: int, extra: int, komi: int, flats: int, caps: int):
	self.size = size
	self.playerWhite = pw
	self.playerBlack = pb
	self.playerWhiteName = pwn
	self.playerBlackName = pbn
	self.time = time
	self.increment = increment
	self.triggerMove = trigger
	self.triggerTime = extra
	self.komi = komi
	self.flats = flats
	self.caps = caps
