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

var rated: int

func _init(id: String, size: int, pw: int, pb: int, pwn: String, pbn: String, time: int, increment: int, trigger: int, extra: int, komi: int, flats: int, caps: int, rated: int):
	self.id = id
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
	self.rated = rated

func isObserver() -> bool:
	return playerWhite == PLAYTAK and playerBlack == PLAYTAK


func isScratch() -> bool:
	return playerWhite == LOCAL and playerBlack == LOCAL


func ptnHeader() -> String:
	return '[Site "%s"]\n[Player1 "%s"]\n[Player2 "%s"]\n[Size "%d"]\n[Komi "%.*f"]\n[Flats "%d"]\n[Caps "%d"]\n[Opening "swap"]' % [
		"playtak.com" if playerWhite == PLAYTAK or playerBlack == PLAYTAK else "Attak",
		playerWhiteName,
		playerBlackName,
		size,
		komi % 2, #komi decimal places
		komi / 2.0, #actual komi value
		flats,
		caps
	]
