extends TabMenuTab
class_name NewSeek

const rPTNLine = "^[0-9]+. ([FCS]?[A-Ha-h][1-8]|[1-8]?[A-Ha-h][1-8][<>+-][1-8]*\\*?)(?: ([FCS]?[A-Ha-h][1-8]|[1-8]?[A-Ha-h][1-8][<>+-][1-8]*\\*?))?$"
const rClock = "\"(\\d+):(\\d+) \\+(\\d+)\""
const standardFlats = [10, 15, 21, 30, 40, 50]
const standardCaps = [0, 0, 1, 1, 2, 2]

var ptnLineRegex: RegEx = RegEx.new()
var clockRegex: RegEx = RegEx.new()

@export var interface: PlayTakI

@export_category("standard")
const OPTIONS = [
	[5, 12, 10, 0, 0, 2, 21, 1, SeekData.RATED],
	[6, 15, 10, 0, 0, 2, 30, 1, SeekData.RATED],# classic 5,6,7
	[7, 20, 15, 0, 0, 2, 40, 2, SeekData.RATED],
	
	[5, 5, 5, 0, 0, 2, 21, 1, SeekData.RATED],# blitz 5,6
	[6, 5, 5, 0, 0, 2, 30, 1, SeekData.RATED],
	
	[6, 15, 10, 35, 5, 2, 30, 1, SeekData.TOURNAMENT],# league
	[6, 15, 10, 0, 0, 0, 30, 1, SeekData.TOURNAMENT],# beginner
	[6, 15, 10, 0, 0, 2, 30, 1, SeekData.TOURNAMENT],# intermediate (does intermediate not have extra time at trigger?)
]
@export var opponentStandard: LineEdit
@export var colorStandard: OptionButton
@export var options: ItemList

@export_category("custom")
@export var opponentCustom: LineEdit
@export var colorCustom: OptionButton
@export var type: OptionButton
@export var sizeCustom: OptionButton
@export var komi: SpinBox
@export var time: SpinBox
@export var inc: SpinBox
@export var trigger: SpinBox
@export var amount: SpinBox
@export var confirmCustom: Button

@export_category("scratch")
@export var sizeScratch: OptionButton
@export var flatsScratch: SpinBox
@export var capsScratch: SpinBox
@export var notationEntry: TextEdit
@export var confirmScratch: Button


func _ready() -> void:
	ptnLineRegex.compile(rPTNLine)
	clockRegex.compile(rClock)
	
	options.item_activated.connect(createStandard)
	confirmCustom.pressed.connect(createCustom)
	confirmScratch.pressed.connect(createScratch)


func createStandard(index: int):
#size: int, time: int, inc: int, trigger: int, extra: int, color: String, komi: int, flats: int, caps: int, rated: RATED):
	var opt = OPTIONS[index]
	var color = ["A", "W", "B"][colorStandard.selected]
	var seek = SeekData.new(opponentStandard.text, interface, opt[0], opt[1] * 60, opt[2], opt[3], opt[4] * 60, color, opt[5] * 2, opt[6], opt[7], opt[8])
	interface.sendSeek(seek)
	Globals.gameUI.notify("Seek Created!")


func createCustom():
	var size = sizeCustom.get_selected_id()
	var flats = standardFlats[size - 3]
	var caps = standardCaps[size - 3]
	var color = ["A", "W", "B"][colorCustom.selected]
	var t = SeekData.RATED if type.selected == 0 else SeekData.UNRATED if type.selected == 2 else SeekData.TOURNAMENT
	var seek = SeekData.new(opponentCustom.text, interface, size, time.value * 60, inc.value, trigger.value, amount.value * 60, color, komi.value * 2, flats, caps, t)
	interface.sendSeek(seek)
	Globals.gameUI.notify("Seek Created!")


func createScratch():
	if notationEntry.text.is_empty():
		var g = GameData.new(
			sizeScratch.get_selected_id(),
			Globals.board, Globals.board,
			"Player White",
			"Player Black",
			0, 0, 0, 0, 0,
			flatsScratch.value,
			capsScratch.value
		)
		Globals.board.setup(g)
		
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
							Globals.gameUI.notify("Invalid TPS \"%s\"" % tps)
							return
							
						elif size == 0:
							size = startState.size
							
						elif size != startState.size:
							Globals.gameUI.notify("TPS size doesnt match Size tag!")
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
							Globals.gameUI.notify("%s is not valid clock format!" % x[1])
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
					Globals.gameUI.notify("\"%s\" is malformed ptn!" % line)
					return
				
				plyList.append(Ply.fromPTN(m.get_string(1))) #TODO actually add these plies
				if not m.get_string(2).is_empty():
					plyList.append(Ply.fromPTN(m.get_string(2)))
			
			elif line in ["R-0", "0-R", "F-0", "0-F", "1-0", "0-1", "1/2-1/2"]:
				pass
			
			else:
				Globals.gameUI.notify("Could not recognize \"%s\"" % line)
				return
		
		if size == 0:
			Globals.gameUI.notify("Could not determine board size!")
			return
		
		if flats == -1: flats = standardFlats[size-3]
		if caps == -1: caps = standardCaps[size-3]
		
		Globals.board.setup(GameData.new(size, null, null, pw, pb, time, inc, trigger, extra, komi, flats, caps))
		if startState != null: 
			Globals.board.startState = startState
			Globals.board.setState(startState)
		
		for i in plyList:
			Globals.board.play(null, i)
		
		notationEntry.clear()
