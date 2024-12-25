extends Button
class_name TabButton

@onready var subtabs: BoxContainer = $SubTabs
var isVertical: bool

func _ready():
	size_flags_horizontal |= SIZE_EXPAND
	
	isVertical = not Globals.isMobile()
	
	mouse_filter = MOUSE_FILTER_PASS
	subtabs.mouse_filter = MOUSE_FILTER_PASS
	theme_type_variation = &"TabButton"
	
	for i in subtabs.get_children():
		i.mouse_filter = MOUSE_FILTER_PASS
		i.theme_type_variation = &"TabButton"
	
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)

	subtabs.mouse_entered.connect(_mouse_entered)
	subtabs.mouse_exited.connect(_mouse_exited)

func _draw():
	if isVertical:
		subtabs.set_anchors_preset(PRESET_RIGHT_WIDE)
		subtabs.set_anchor_and_offset(SIDE_LEFT, 0, get_parent().size.x)
	else:
		subtabs.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT if get_index() >= get_parent().get_child_count()/2 else PRESET_TOP_LEFT)
		subtabs.set_anchor_and_offset(SIDE_BOTTOM, 0, -get_parent().size.y)
		subtabs.set_anchor_and_offset(SIDE_TOP, 0, -subtabs.size.y)

func _mouse_entered():
	subtabs.show()

func _mouse_exited():
	subtabs.hide()
