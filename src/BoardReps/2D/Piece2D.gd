extends Sprite2D
class_name Piece2D

var selected: bool = false

func _init(sprite: Texture2D, scale: float):
	texture = sprite
	self.scale = scale * Vector2.ONE
