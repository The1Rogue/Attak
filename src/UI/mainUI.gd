extends Node
class_name mainUI


var theme: Theme = load("res://baseTheme.tres")
var repeat: bool = false

func _ready() -> void:
	get_tree().get_root().size_changed.connect(resize)
	resize()


func resize():
	if repeat:
		repeat = false
		return
	
	var v = DisplayServer.screen_get_size()
	var d = DisplayServer.screen_get_dpi()
	var nd = d / 90.0
	var nv = min(v.x, v.y) / 1080.0
	var x = nd * nv
	
	theme.default_font_size = nd * 16
