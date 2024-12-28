extends VBoxContainer
class_name SeekList

const BOTS = []

var ratingsBots = []
var ratingsPlayers = []

var seeks: Dictionary = {}
var count: Vector3i = Vector3i.ZERO

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
	var rating = PlayTakI.ratingList.get(seek.playerName, 1000)
	
	var time45 = seek.time + 45 * seek.increment
	var type = "blitz" if time45 < 600 else "rapid" if time45 < 1200 else "classic"
	b.text = "%18s (%4d)  %ds +%3.1f %s" % [seek.playerName, rating, seek.size, seek.komi/2.0, type]
	b.tooltip_text = "%2d:00 +:%02d" % [seek.time / 60, seek.increment]
	if seek.triggerTime != 0:
		b.tooltip_text += " +%2d@%d" % [seek.triggerTime/60, seek.triggerMove]
	
	b.icon = [iconBoth, iconWhite, iconBlack][seek.color]
	b.expand_icon = true
	
	var idx = 0
	if seek.playerName == PlayTakI.activeUsername:
		add_child(b)
		move_child(b, 0)
		b.text = "     Outgoing Seek ->   |  %ds +%3.1f %s" % [seek.size, seek.komi/2.0, type]
		var x = Button.new()
		x.text = "remove"
		b.add_child(x)
		x.theme_type_variation = &"ExitButton"
		x.pressed.connect(PlayTakI.sendSeek.bind(SeekData.new("", 0, 0, 0, 0, 0, "A", 0, 0, 0, SeekData.RATED)))
		x.set_anchors_and_offsets_preset(PRESET_CENTER_RIGHT)
		count.z += 1
	
	elif seek.playerName in PlayTakI.bots:
		for r in ratingsBots:
			if rating < r: idx += 1
			else: break
		add_child(b)
		move_child(b, count.x + idx + 3 + count.z)
		ratingsBots.insert(idx, rating)
		count.y += 1
		b.pressed.connect(func(): accept(id))
	
	else:
		for r in ratingsPlayers:
			if rating < r: idx += 1
			else: break
		add_child(b)
		move_child(b, idx + 3 + count.z)
		ratingsPlayers.insert(idx, rating)
		count.x += 1
		b.pressed.connect(func(): accept(id))

	button.text = " Join (%d + %d) " % [count.x, count.y]
	if OS.has_feature("mobile"):
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	if seek.rated != SeekData.RATED:
		b.text += " Unrated" if seek.rated == SeekData.UNRATED else " Tournament" #TODO?
	
	seeks[id] = b
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT


func remove(id: int):
	if id in seeks:
		var idx = seeks[id].get_index()
		if idx > bots.get_index():
			ratingsBots.remove_at(idx - bots.get_index() - 1)
			count.y -= 1
		elif idx > players.get_index():
			ratingsPlayers.remove_at(idx - players.get_index() - 1)
			count.x -= 1
		else:
			count.z = 0
		button.text = " Join (%d + %d) " % [count.x, count.y]
		remove_child(seeks[id])
		seeks.erase(id)


func clear():
	for id in seeks:
		remove_child(seeks[id])
	count = Vector3i.ZERO
	button.text = " Join (0) "
	seeks.clear()
	ratingsPlayers.clear()
	ratingsBots.clear()


func accept(id: int):
	PlayTakI.acceptSeek(id)


func updateRatings():
	ratingsPlayers = []
	ratingsBots = []
	
	for i in seeks:
		if seeks[i].get_index() < players.get_index(): continue
		var idx = 0
		var s = seeks[i].text.split(" ", false, 1)
		var rating =  PlayTakI.ratingList.get(s[0], 1000)
		if s[0] in PlayTakI.bots:
			for r in ratingsBots:
				if rating < r: idx += 1
				else: break
			move_child(seeks[i], 3 + ratingsPlayers.size() + idx + count.z)
			ratingsBots.insert(idx, rating)
			
		else:
			for r in ratingsPlayers:
				if rating < r: idx += 1
				else: break
			move_child(seeks[i], 3 + idx + count.z)
			ratingsPlayers.insert(idx, rating)
			
		seeks[i].text = "%18s (%4d) " % [s[0], rating] + s[1].substr(7)
	count = Vector3i(ratingsPlayers.size(), ratingsBots.size(), count.z)
	button.text = " Join (%d + %d) " % [count.x, count.y]
