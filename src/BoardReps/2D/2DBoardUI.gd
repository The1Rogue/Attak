extends BoardLogic
class_name Board2DUI

@onready var board = $AspectRatioContainer/Board

@export var sq: Texture2D

var pieces: Array = []


func _ready():
	super()
	var g = GameData.new(5, self, self, "Player White", "Player Black", 0, 0, 0, 0, 0, 21, 1)
	setup(g) #TODO This is temporary (is it?)


func makeBoard(flats: int, caps: int):
	for i in board.get_children():
		board.remove_child(i)
	
	board.columns = size
	for i in size**2:
		var t = TextureRect.new()
		t.size_flags_horizontal |= Control.SIZE_EXPAND
		t.size_flags_vertical |= Control.SIZE_EXPAND
		t.texture = sq
		board.add_child(t)
		


func putPiece(id: int, v: Vector3i):
	pass


func putReserve(id: int):
	pass


func highlight(id: int):
	pass


func deHighlight(id: int):
	pass


func setWall(id: int, wall: bool):
	pass


func select(id: int):
	pass


func deselect(id: int):
	pass


func inputEvent(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	pass


func clickPiece(piece: Piece3D, isRight: bool):
	pass
