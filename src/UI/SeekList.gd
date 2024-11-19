extends TabMenuTab
class_name SeekList

var seeks: Dictionary = {}
var count: int = 0

func _ready():
	PlayTakI.ratingUpdate.connect(updateRatings)
	PlayTakI.addSeek.connect(add)
	PlayTakI.removeSeek.connect(remove)
	PlayTakI.logout.connect(clear)


func add(seek: SeekData, id: int):
	count += 1
	tabButton.text = " Join Game (%d) " % count
	var b = Button.new()
	add_child(b)
	b.text = " %-14s (%04d) %dx%d +%3.1f    %2d:00+:%02ds" % [seek.playerName, PlayTakI.ratingList.get(seek.playerName, 1000), seek.size, seek.size, seek.komi/2.0, seek.time/60, seek.increment]
	if seek.triggerTime != 0:
		b.text += " +%2d@%d" % [seek.triggerTime/60, seek.triggerMove]
	
	if OS.has_feature("mobile"):
		b.text = b.text.insert(24, "\n")
		
	if seek.rated != SeekData.RATED:
		b.text += " Unrated" if seek.rated == SeekData.UNRATED else " Tournament"
	seeks[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func(): accept(id))


func remove(id: int):
	if id in seeks:
		count -= 1
		tabButton.text = " Join Game (%d) " % count
		remove_child(seeks[id])
		seeks.erase(id)


func clear():
	for id in seeks:
		remove_child(seeks[id])
	count = 0
	tabButton.text = " Join Game (0) "
	seeks.clear()


func accept(id: int):
	PlayTakI.acceptSeek(id)


func updateRatings():
	for i in seeks:
		var user = seeks[i].text.split(" ")[1]
		seeks[i].text = Globals.ratingRegex.sub(seeks[i].text, "(%04d)" % PlayTakI.ratingList.get(user, 1000))
		
