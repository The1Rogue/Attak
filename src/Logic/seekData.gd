class_name SeekData

enum COLOR {
	EITHER = 0,
	WHITE = 1,
	BLACK = 2
}

enum {
	UNRATED,
	RATED,
	TOURNAMENT
}

var playerName: String
var interface: Interface

var size: int

var time: int #seconds
var increment: int
var triggerMove: int
var triggerTime: int

var color: COLOR

var komi: int

var flats: int
var caps: int
var rated: int

func _init(player: String, interface: Interface, size: int, time: int, inc: int, trigger: int, extra: int, color: String, komi: int, flats: int, caps: int, rated: int):
	self.playerName = player
	self.interface = interface
	self.size = size
	self.time = time
	self.increment = inc
	self.triggerMove = trigger
	self.triggerTime = extra
	self.color = {"W": COLOR.WHITE, "B": COLOR.BLACK, "A": COLOR.EITHER}[color]
	self.komi = komi
	self.flats = flats
	self.caps = caps
	self.rated = rated
