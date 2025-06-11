extends VBoxContainer


const rPTNLine = "^[0-9]+. ([FCS]?[A-Ha-h][1-8]|[1-8]?[A-Ha-h][1-8][<>+-][1-8]*\\*?)(?: ([FCS]?[A-Ha-h][1-8]|[1-8]?[A-Ha-h][1-8][<>+-][1-8]*\\*?))?$"
const rClock = "\"(\\d+):(\\d+) \\+(\\d+)\""
const standardFlats = [10, 15, 21, 30, 40, 50]
const standardCaps = [0, 0, 1, 1, 2, 2]

var ptnLineRegex: RegEx = RegEx.new()
var clockRegex: RegEx = RegEx.new()

@export var sizeEntry: OptionButton
@export var flats: SpinBox
@export var caps: SpinBox
@export var notationEntry: TextEdit
@export var confirm: Button

func _ready():
	ptnLineRegex.compile(rPTNLine)
	clockRegex.compile(rClock)
	confirm.pressed.connect(create)
	sizeEntry.item_selected.connect(setPieces)

func create():
	if notationEntry.text.is_empty():
		var g = GameData.new(
			"",
			sizeEntry.get_selected_id(),
			GameData.LOCAL, GameData.LOCAL,
			"Player White",
			"Player Black",
			0, 0, 0, 0, 0,
			flats.value,
			caps.value,
			SeekData.UNRATED
		)
		GameLogic.doSetup(g)
		
	else:
		var notation = notationEntry.text.strip_edges().split("\n", false)
		
		var size: int
		var komi: int
		var flats: int = -1
		var caps: int = -1
		var pw: String = "Player White"
		var pb: String = "Player Black"
		
		var time: int
		var inc: int
		var trigger: int
		var extra: int
		
		var c = 0
		var plyList: Array[Ply] = []
		
		var startState: GameState
		
		for line : String in notation:
			if line[0] == "[" and line[-1] == "]":
				var x = line.substr(1, line.length() - 2).split(" ", true, 1)
				match x[0]:
					"TPS":
						var tps = x[1].substr(1, x[1].length()-2)
						startState = GameState.fromTPS(tps, flats, caps)
						if startState == null:
							Notif.message("Invalid TPS \"%s\"" % tps)
							return
							
						elif size == 0:
							size = startState.size
							
						elif size != startState.size:
							Notif.message("TPS size doesnt match Size tag!")
							return
						
					"Komi":
						komi = x[1].substr(1).to_float() * 2
						
					"Size":
						size = x[1].to_int()
						
					"Player1":
						pw = x[1].substr(1, x[1].length() - 2)
						
					"Player2":
						pb = x[1].substr(1, x[1].length() - 2)
						
					"Clock":
						var m: RegExMatch = clockRegex.search(x[1])
						if m == null:
							Notif.message("%s is not valid clock format!" % x[1])
							return
						time = 60 * m.get_string(1).to_int() + m.get_string(2).to_int()
						inc = m.get_string(3).to_int()
						
					"Flats":
						flats = x[1].to_int()
						
					"Caps":
						caps = x[1].to_int()
			
			elif line.begins_with(str(c+1)):
				c += 1
				var m = ptnLineRegex.search(line)
				if m == null:
					Notif.message("\"%s\" is malformed ptn!" % line)
					return
				
				plyList.append(Ply.fromPTN(m.get_string(1)))
				if not m.get_string(2).is_empty():
					plyList.append(Ply.fromPTN(m.get_string(2)))
			
			elif line in ["R-0", "0-R", "F-0", "0-F", "1-0", "0-1", "1/2-1/2"]:
				pass
			
			else:
				Notif.message("Could not recognize \"%s\"" % line)
				return
		
		if size < 3 or size > 8:
			Notif.message("Could not determine board size!")
			return
		
		if flats == -1: flats = standardFlats[size-3]
		if caps == -1: caps = standardCaps[size-3]
		
		GameLogic.doSetup(GameData.new("", size, GameData.LOCAL, GameData.LOCAL, pw, pb, time, inc, trigger, extra, komi, flats, caps, SeekData.UNRATED), startState)
		
		for i in plyList:
			GameLogic.doMove(self, i)
		
		notationEntry.clear()


func setPieces(idx: int):
	var s = sizeEntry.get_item_id(idx)
	flats.value = standardFlats[s-3]
	caps.value = standardCaps[s-3]
