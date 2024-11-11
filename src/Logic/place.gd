extends Ply
class_name Place

enum TYPE {
	FLAT = 0,
	WALL = 1,
	CAP = 2
}

var piece: TYPE

func _init(tile: Vector2i, piece: TYPE) -> void:
	self.tile = tile
	self.piece = piece


func toPTN() -> String:
	return {TYPE.CAP: "C", TYPE.FLAT: "", TYPE.WALL: "S"}[piece] + tileStr(tile)


func toPlayTak() -> String:
	return "P " + tileStr(tile) +  {TYPE.CAP: " C", TYPE.FLAT: "", TYPE.WALL: " W"}[piece]
