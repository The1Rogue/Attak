extends GridContainer
class_name Setting

@export var label: String


signal setSetting(value: Variant)

func _ready():
	columns = 2
	var l = Label.new()
	l.text = label + ": "
	add_child(l)

#set the option without emitting a signal, useful for setting the ui from loaded savedata
func setNoSignal(value: Variant):
	pass
