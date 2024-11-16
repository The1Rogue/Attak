extends VBoxContainer


func _ready() -> void:
	$Button.toggled.connect(toggle)


func toggle(on: bool):
	$PlaytakUI.visible = on
	$GameUIMobile.visible = not on
