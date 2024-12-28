extends Setting
class_name RangeSetting

@export var min: float
@export var max: float
@export var increment: float

var slider: HSlider
var marker: Label
var format: String = " %"

func _ready():
	super()
	columns = 3
	
	slider = HSlider.new()
	slider.size_flags_vertical |= Control.SIZE_FILL
	slider.min_value = min
	slider.max_value = max
	slider.step = increment
	slider.size_flags_horizontal |= Control.SIZE_EXPAND
	
	marker = Label.new()
	if increment as int == increment:
		format = "%%%dd" % str(max as int).length()
	else:
		format = "%%%d.%df" % [str(max as int).length(), str(increment).split(".")[-1].length()]
	marker.text = format % slider.value
	add_child(marker)
	
	add_child(slider)
	slider.value_changed.connect(select)




func select(value: float):
	marker.text = format % slider.value
	setSetting.emit(value)


func setNoSignal(value: Variant):
	assert(value is float or value is int)
	slider.set_value_no_signal(value)
	marker.text = format % slider.value
