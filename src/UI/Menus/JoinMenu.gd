extends ButtonPopup

@onready var box = $VBoxContainer

@export var I: PlayTakI
func _ready():
	super()
	#about_to_popup.connect(reloadSeeks)
	visibility_changed.connect(reloadSeeks)


func reloadSeeks():
	for i in box.get_children():
		box.remove_child(i)
	
	print("reloading seeks")
	for i in I.seeks:
		var b = Button.new()
		
		b.pressed.connect(func(): pressed(i))
		b.text = "%s %dx%d" % [I.seeks[i].playerName, I.seeks[i].size, I.seeks[i].size]
		
		box.add_child(b)

func pressed(seek: int):
	I.acceptSeek(seek)
