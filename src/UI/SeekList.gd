extends VBoxContainer
class_name SeekList

var seeks: Dictionary = {}

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
	var rating = await PlayTakI.getRating(seek.playerName)
	b.pivot_offset.x = rating #abusing unused pivot to store metadata
	
	var time45 = seek.time + 45 * seek.increment
	var type = "blitz" if time45 < 600 else "rapid" if time45 < 1200 else "classic"
	b.text = "%18s (%4d)  %ds +%3.1f %s" % [seek.playerName, rating, seek.size, seek.komi/2.0, type]
	b.tooltip_text = "%2d:00 +:%02d" % [seek.time / 60, seek.increment]
	if seek.triggerTime != 0:
		b.tooltip_text += " +%2d@%d" % [seek.triggerTime/60, seek.triggerMove]
	
	if OS.has_feature("mobile"):
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	if seek.rated != SeekData.RATED:
		b.text += " Unrated" if seek.rated == SeekData.UNRATED else " Tournament" #TODO?
	
	b.icon = [iconBoth, iconWhite, iconBlack][seek.color]
	b.expand_icon = true
	
	seeks[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	add_child(b)
	if seek.playerName == PlayTakI.activeUsername:
		move_child(b, 0)
		b.text = "     Outgoing Seek ->   |  %ds +%3.1f %s" % [seek.size, seek.komi/2.0, type]
		var x = Button.new()
		x.text = "remove"
		b.add_child(x)
		x.theme_type_variation = &"ExitButton"
		x.pressed.connect(PlayTakI.sendSeek.bind(SeekData.new("", false, 0, 0, 0, 0, 0, "A", 0, 0, 0, SeekData.RATED)))
		x.set_anchors_and_offsets_preset(PRESET_CENTER_RIGHT)
		return
	
	b.pressed.connect(func(): accept(id))
	var idx = bots.get_index() + 1 if seek.isBot else players.get_index() + 1
	while idx < get_child_count():
		if b.pivot_offset.x > get_child(idx).pivot_offset.x or idx == bots.get_index() - 1:
			move_child(b, idx)
			break
		idx += 1

	updateCounts()


func remove(id: int):
	if id in seeks:
		#var idx = seeks[id].get_index()
		remove_child(seeks[id])
		seeks.erase(id)
		updateCounts()


func clear():
	for id in seeks:
		remove_child(seeks[id])
	button.text = " Join (0) "
	seeks.clear()


func accept(id: int):
	PlayTakI.acceptSeek(id)


func updateRatings():
	var c = get_children()
	
	for b in c:
		if b is Button and b.get_index() != 0:
			remove_child(b)

	for b in c:
		if b.get_parent() == null:
			add_child(b)
			var s = b.text.split(" ", false, 1)
			var rating = PlayTakI.ratingList.get(s[0], 1000)
			b.pivot_offset.x = rating
			b.text = "%18s (%4d) " % [s[0], rating] + s[1].substr(7)

			var idx = bots.get_index() + 1 if s[0] in PlayTakI.bots else players.get_index() + 1
			while idx < get_child_count():
				if b.pivot_offset.x > get_child(idx).pivot_offset.x:
					move_child(b, idx)
					break
				idx += 1
				
	updateCounts()


func updateCounts():
	var c = get_child_count()
	var b = bots.get_index()
	var p = players.get_index()
	button.text = " Join (%d + %d) " % [b - p - 2, c - b - 1]
