extends BoardSettings
class_name Settings2D


const path: String = "user://Settings2D.res"
const scene = preload("res://scenes/Settings2D.tscn")


@export var size: float = .5: 
	set(value): 
		size = value
		save(); update.emit()

@export var sqName: String
@export var sq: Texture
func setSq(value):
	sq = ImageTexture.create_from_image(value[0])
	sqName = value[1]
	save(); update.emit()

@export var whiteName: String
@export var white: Array[Texture]
func setWhite(value):
	white = splitImg(value[0])
	whiteName = value[1]
	save(); update.emit()

@export var blackName: String
@export var black: Array[Texture]
func setBlack(value):
	black = splitImg(value[0])
	blackName = value[1]
	save(); update.emit()


func getScene():
	var s = scene.instantiate()
	
	s.get_child(0).setNoSignal(sqName)
	s.get_child(0).setSetting.connect(setSq)
	
	s.get_child(1).setNoSignal(whiteName)
	s.get_child(1).setSetting.connect(setWhite)
	
	s.get_child(2).setNoSignal(blackName)
	s.get_child(2).setSetting.connect(setBlack)
	
	s.get_child(3).setNoSignal(size)
	s.get_child(3).setSetting.connect(func(value): size = value; save())
	return s


func check():
	if sq == null:
		sq = ImageTexture.create_from_image(loadImg("res://assets/Squares/Standard.svg"))
	
	if white == null or white.size() != 4 or null in white:
		white = splitImg(loadImg("res://assets/Pieces2D/White/Standard.svg"))
	
	if black == null or black.size() != 4 or null in black:
		black = splitImg(loadImg("res://assets/Pieces2D/Black/Standard.svg"))
	
	size = clamp(.3, size, 1)


static func splitImg(img: Image) -> Array[Texture]:
	if img == null: return []
	var s: Vector2i = img.get_size() / 64
	var flat = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y * 37, s.x * 26, s.y * 26)))
	var wall = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y * 27, s.x * 26, s.y * 10)))
	var cap  = ImageTexture.create_from_image(img.get_region(Rect2i(s.x * 35, s.y *  1, s.x * 26, s.y * 26)))
	
	var smol = ImageTexture.new()
	var tmp = flat.get_image()
	tmp.resize(flat.get_width() * .25, flat.get_height() * .125, 4)
	smol.set_image(tmp)
	return [flat, wall, cap, smol]
