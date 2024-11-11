extends Button
class_name ExpandButton

@export var panel: Control

func _ready() -> void:
	pressed.connect(toggle)

func toggle():
	if panel.visible:
		panel.hide()
	else:
		panel.show()
