extends VBoxContainer
class_name SeekList

const BOTS = []

var seeks: Dictionary = {}
var count: Vector2i = Vector2i.ZERO

@export var button: Button

@export var iconBlack: Texture2D
@export var iconWhite: Texture2D
@export var iconBoth: Texture2D

@onready var players = $Players
@onready var bots = $Bots

func _ready():
	PlayTakI.ratingUpdate.connect(updateRatings)
	PlayTakI.addSeek.connect(add)
	PlayTakI.removeSeek.connect(remove)
	PlayTakI.logout.connect(clear)


func add(seek: SeekData, id: int):

	var b = Button.new()
	
	if seek.playerName in PlayTakI.bots:
		bots.add_sibling(b)
		count.y += 1
		
	else:
		players.add_sibling(b)
		count.x += 1
			
	button.text = " Join (%d + %d) " % [count.x, count.y]
	
	var time45 = seek.time + 45 * seek.increment
	var type = "blitz" if time45 < 600 else "rapid" if time45 < 1200 else "classic"
	b.text = "%18s (%4d)  %ds +%3.1f %s" % [seek.playerName, PlayTakI.ratingList.get(seek.playerName, 1000), seek.size, seek.komi/2.0, type]
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
		if seeks[id].get_index() < bots.get_index():
			count.x -= 1
		else:
			count.y -= 1
		button.text = " Join (%d + %d) " % [count.x, count.y]
		remove_child(seeks[id])
		seeks.erase(id)


func clear():
	for id in seeks:
		remove_child(seeks[id])
	count = Vector2i.ZERO
	button.text = " Join (0) "
	seeks.clear()


func accept(id: int):
	PlayTakI.acceptSeek(id)


func updateRatings(): #TODO sort by rating?
	var index = bots.get_index()
	for i in seeks:
		var s = seeks[i].text.split(" ", false, 1)
		if s[0] in PlayTakI.bots:
			if seeks[i].get_index() < index:
				count.x -= 1; count.y += 1;
				move_child(seeks[i], index + 1)
				index -= 1
		elif seeks[i].get_index() > index:
			count.y -= 1; count.x += 1;
			move_child(seeks[i], index - 2)
			index += 1
			
		seeks[i].text = " %18s (%4d) " % [s[0], PlayTakI.ratingList.get(s[0], 1000)] + s[1].substr(7)
	button.text = " Join (%d + %d) " % [count.x, count.y]
