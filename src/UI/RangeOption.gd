extends Setting
class_name RangeSetting

@export var min: float
@export var max: float
@export var increment: float

var slider: HSlider
var marker: Label

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
	marker.text = str(slider.value) + " "
	add_child(marker)
	
	add_child(slider)
	slider.value_changed.connect(select)




func select(value: float):
	marker.text = str(slider.value) + " "
	setSetting.emit(value)


func setNoSignal(value: Variant):
	assert(value is float or value is int)
	slider.set_value_no_signal(value)
	marker.text = str(slider.value) + " "
