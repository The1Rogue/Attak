extends Button
class_name URLButton

@export var URL: String

func _pressed() -> void:
	OS.shell_open(URL)
