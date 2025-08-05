extends Sprite2D
class_name Piece2D

var tween: Tween
var selected: bool = false
var target: Vector2 = position

func _init(sprite: Texture2D, scale: float):
	texture = sprite
	self.scale = scale * Vector2.ONE * 16 / sprite.get_size()

func setTexture(sprite: Texture2D):
	self.scale /= sprite.get_size()
	texture = sprite
	self.scale *= sprite.get_size()

func getPosition():
	return target

func setPosition(pos: Vector2):
	target = pos
	if tween != null and tween.is_running():
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", target, .1).set_trans(Tween.TRANS_SINE)
