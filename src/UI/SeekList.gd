extends TabMenuTab
class_name SeekList

@export var interface: PlayTakI

var seeks: Dictionary = {}
var count: int = 0

func _ready():
	interface.addSeek.connect(add)
	interface.removeSeek.connect(remove)


func add(seek: SeekData, id: int):
	count += 1
	tabButton.text = " Join Game (%d) " % count
	var b = Button.new()
	add_child(b)
	b.text = " %-14s %dx%d +%3.1f    %2d:00+:%02ds" % [seek.playerName, seek.size, seek.size, seek.komi/2.0, seek.time/60, seek.increment]
	if seek.triggerTime != 0:
		b.text += " +%2d@%d" % [seek.triggerTime/60, seek.triggerMove]
		
	if seek.rated != SeekData.RATED:
		b.text += " Unrated" if seek.rated == SeekData.UNRATED else " Tournament"
	seeks[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func(): accept(id))


func remove(id: int):
	count -= 1
	tabButton.text = " Join Game (%d) " % count
	remove_child(seeks[id])
	seeks.erase(id)


func accept(id: int):
	interface.acceptSeek(id)
