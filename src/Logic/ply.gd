class_name Ply


var boardState

var tile: Vector2i

static func getTile(s: String) -> Vector2i:
	var x = s.to_upper().unicode_at(0) - "A".unicode_at(0)
	var y = s.unicode_at(1) - "1".unicode_at(0)
	return Vector2i(x,y)


static func tileStr(tile: Vector2i) -> String:
	return char(tile.x + "a".unicode_at(0)) + char(tile.y + "1".unicode_at(0)) 


static func fromPTN(ptn: String) -> Ply:
	var m = Globals.ptnRegex.search(ptn)
	if m == null: return null
	
	var tile: Vector2i
	if m.get_string(2).is_empty(): #its a spread
		tile = getTile(m.get_string(4))
		var dir = {"<": Spread.DIRECTION.LEFT, ">": Spread.DIRECTION.RIGHT, "+": Spread.DIRECTION.UP, "-": Spread.DIRECTION.DOWN}[m.get_string(5)]
		var smash = m.get_string(7) == "*" #TODO verify smash?
		var total = m.get_string(3).to_int() if not m.get_string(3).is_empty() else 1
		var drops: Array[int] = []
		for i in m.get_string(6):
			drops.append(i.to_int())
		if drops.size() == 0: drops = [total]
		return Spread.new(tile, dir, drops, smash)
		
	else:
		tile = getTile(m.get_string(2))
		var piece = {"": Place.TYPE.FLAT, "F": Place.TYPE.FLAT, "C": Place.TYPE.CAP, "S": Place.TYPE.WALL}[m.get_string(1)]
		return Place.new(tile, piece)


static func fromPlayTak(playtak: String, oldState) -> Ply:
	var m = Globals.playTakRegex.search(playtak)
	if m == null: return null
	
	var tile: Vector2i
	if playtak[0] == "M": #its a spread
		tile = getTile(m.get_string(3))
		var smash = false #TODO verify
		var dir
		var t2 = getTile(m.get_string(4))
		if t2.x == tile.x:
			dir = Spread.DIRECTION.UP if t2.y > tile.y else Spread.DIRECTION.DOWN
		else:
			dir = Spread.DIRECTION.RIGHT if t2.x > tile.x else Spread.DIRECTION.LEFT
		var drops = []
		for i in m.get_string(5).replace(" ", ""):
			drops.append(i)
		return Spread.new(tile, dir, drops, smash)
		
	else:
		tile = getTile(m.get_string(1))
		var piece = {"": Place.TYPE.FLAT, "C": Place.TYPE.CAP, "W": Place.TYPE.WALL}[m.get_string(2)]
		return Place.new(tile, piece)


func toPTN() -> String:
	return ""


func toPlayTak() -> String:
	return ""
