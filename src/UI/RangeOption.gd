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
	slider.value_changed.connect(func(v): marker.text = format % v)
	slider.drag_ended.connect(func(v): setSetting.emit(slider.value))


func setNoSignal(value: Variant):
	assert(value is float or value is int)
	if not is_node_ready(): await ready
	slider.set_value_no_signal(value)
	marker.text = format % slider.value
