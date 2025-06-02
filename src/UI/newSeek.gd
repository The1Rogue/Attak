extends VBoxContainer
class_name NewSeek


const standardFlats = [10, 15, 21, 30, 40, 50]
const standardCaps = [0, 0, 1, 1, 2, 2]

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
@export var opponent: LineEdit
@export var color: OptionButton
@export var options: ItemList
@export var confirmStandard: Button

@export_category("custom")
@export var type: OptionButton
@export var sizeCustom: OptionButton
@export var komi: SpinBox
@export var time: SpinBox
@export var inc: SpinBox
@export var trigger: SpinBox
@export var amount: SpinBox
@export var confirmCustom: Button



func _ready() -> void:
	options.item_activated.connect(createStandard)
	confirmStandard.pressed.connect(createStandard.bind(-1))
	confirmCustom.pressed.connect(createCustom)
	sizeCustom.get_parent().columns = 2 if OS.has_feature("mobile") else 4


func createStandard(index: int):
#size: int, time: int, inc: int, trigger: int, extra: int, color: String, komi: int, flats: int, caps: int, rated: RATED):
	if not options.is_anything_selected(): return
	var opt = OPTIONS[index if index >= 0 else options.get_selected_items()[0]] 
	var color = ["A", "W", "B"][color.selected]
	var seek = SeekData.new(opponent.text, false, opt[0], opt[1] * 60, opt[2], opt[3], opt[4] * 60, color, opt[5] * 2, opt[6], opt[7], opt[8])
	PlayTakI.sendSeek(seek)
	Notif.message("Seek Created!")


func createCustom():
	var size = sizeCustom.get_selected_id()
	var flats = standardFlats[size - 3]
	var caps = standardCaps[size - 3]
	var color = ["A", "W", "B"][color.selected]
	var t = SeekData.RATED if type.selected == 0 else SeekData.UNRATED if type.selected == 2 else SeekData.TOURNAMENT
	var seek = SeekData.new(opponent.text, false, size, time.value * 60, inc.value, trigger.value, amount.value * 60, color, komi.value * 2, flats, caps, t)
	PlayTakI.sendSeek(seek)
	Notif.message("Seek Created!")
