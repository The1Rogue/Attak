extends Panel
class_name Graph

const markers = 5

var points: Array[Vector2]
var min: Vector2
var max: Vector2

func _ready():
	draw.connect(func(): custom_minimum_size = Vector2.ONE * size.x)

func _draw():
	if points.size() == 0: return
	var font: Font = get_theme_default_font()
	var fSize = get_theme_default_font_size()
	
	for i in points.size() - 1:
		draw_line(points[i] * size, points[i+1] * size, Color.TURQUOISE)

	for i in markers:
		var v = i as float / (markers - 1)
		draw_line(Vector2(v, 1) * size, Vector2(v, 1.02) * size, Color.WHITE)
		draw_line(Vector2(0, v) * size, Vector2(-.02,v) * size, Color.WHITE)
		var x:int = min.x + v * (max.x-min.x)
		var y:int = max.y - v * (max.y-min.y)
		var textSize = font.get_string_size(str(y), 0, -1, fSize)
		textSize.y *= -.25
		draw_string(font, Vector2(-.03, v) * size - textSize, str(y), 0, -1, fSize)
		
		var date = Time.get_date_string_from_unix_time(x).substr(5)
		textSize = font.get_string_size(date, 0, -1, fSize)
		textSize.y *= -1
		textSize.x *= .5
		draw_string(font, Vector2(v, 1.03) * size - textSize, date, 0, -1, fSize)
	
