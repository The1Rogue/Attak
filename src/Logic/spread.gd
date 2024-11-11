extends Ply
class_name Spread

enum DIRECTION {
	LEFT,
	RIGHT,
	UP,
	DOWN
}
#yes up and down are flipped, because godots up is negative y
const dirToVec = {DIRECTION.LEFT: Vector2i.LEFT, DIRECTION.RIGHT: Vector2i.RIGHT, DIRECTION.UP: Vector2i.DOWN, DIRECTION.DOWN: Vector2i.UP}
const vecToDir = {Vector2i.LEFT: DIRECTION.LEFT, Vector2i.RIGHT: DIRECTION.RIGHT, Vector2i.DOWN: DIRECTION.UP, Vector2i.UP: DIRECTION.DOWN}


var dir: DIRECTION
var drops: Array[int]
var smash: bool

func _init(tile: Vector2i, dir: DIRECTION, drops: Array[int], smash: bool) -> void:
	self.tile = tile
	self.dir = dir
	self.drops = drops
	self.smash = smash


func total() -> int:
	return drops.reduce(func(a,b): return a+b, 0)


func toPTN() -> String:
	var out = ""
	var total = drops.reduce(func(a,b):return a+b, 0)
	out += str(total) if total != 1 else ""
	out += tileStr(tile) + {DIRECTION.LEFT: "<", DIRECTION.RIGHT: ">", DIRECTION.UP: "+", DIRECTION.DOWN: "-"}[dir]
	out += drops.reduce(func(a,b):return str(a)+str(b), "") if drops.size() > 1 else ""
	return out + "*" if smash else out


func toPlayTak() -> String:
	var out = "M " + tileStr(tile)
	var t2 = tile + drops.size() * {DIRECTION.LEFT: Vector2i.LEFT, DIRECTION.RIGHT: Vector2i.RIGHT, DIRECTION.UP: Vector2i.DOWN, DIRECTION.DOWN: Vector2i.UP}[dir]
	out += " " + tileStr(t2)
	return out + drops.reduce(func(a,b):return str(a)+" "+str(b), "")
