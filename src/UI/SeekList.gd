extends TabMenuTab
class_name SeekList

var seeks: Dictionary = {}
var count: int = 0

@export var iconBlack: Texture2D
@export var iconWhite: Texture2D
@export var iconBoth: Texture2D


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
	#b.text = " %-14s (%04d) %dx%d +%3.1f    %2d:00+:%02ds" % [seek.playerName, PlayTakI.ratingList.get(seek.playerName, 1000), seek.size, seek.size, seek.komi/2.0, seek.time/60, seek.increment]
	var time45 = seek.time + 45 * seek.increment
	var type = "blitz" if time45 < 600 else "rapid" if time45 < 1200 else "classic"
	b.text = "%s (%4d) %ds +%3.1f %s" % [seek.playerName, PlayTakI.ratingList.get(seek.playerName, 1000), seek.size, seek.komi/2.0, type]
	b.tooltip_text = "%2d:00 +:%02d" % [seek.time / 60, seek.increment]
	if seek.triggerTime != 0:
		b.tooltip_text += " +%2d@%d" % [seek.triggerTime/60, seek.triggerMove]
	
	b.icon = [iconBoth, iconWhite, iconBlack][seek.color]
	b.expand_icon = true
	
	if OS.has_feature("mobile"):
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
	else:
		var v = get_theme_default_font().get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_default_font_size())
		b.custom_minimum_size.x = v.x + v.y + 20 #ensure the icon is visible
	
	if seek.rated != SeekData.RATED:
		b.text += " Unrated" if seek.rated == SeekData.UNRATED else " Tournament" #TODO?
	
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
		var s = seeks[i].text.split(" ", false, 2)
		seeks[i].text = s[0] + " (%4d) " % PlayTakI.ratingList.get(s[0], 1000) + s[2]
