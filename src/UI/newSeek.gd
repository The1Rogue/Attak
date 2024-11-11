extends VBoxContainer


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
	var flats = [10, 15, 21, 30, 40, 50][size - 3]
	var caps = [0, 0, 1, 1, 2, 2][size - 3]
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
		pass
		# if tps: make game, setup, set startState, set state to startstate
		# else: make game, and reconstruct plies
		
