extends Button
class_name PopUpButton

var panel: ButtonPopup

func _ready() -> void:
	for i in get_children():
		if i is ButtonPopup:
			panel = i
			break

	panel.editText.connect(set_text)
	pressed.connect(showScene)

func showScene() -> void:
	panel.show()
	
