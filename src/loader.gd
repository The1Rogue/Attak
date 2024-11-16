extends CanvasLayer


func _ready() -> void:
	if OS.has_feature("mobile"):
		add_child(preload("res://scenes/mainMobile.tscn").instantiate())
	else:
		add_child(preload("res://scenes/mainDesktop.tscn").instantiate())
