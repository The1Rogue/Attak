extends Container
class_name Selector

@onready var tabBar = $tabBar
@export var start: Control

var active: Control

func _ready() -> void:
	assert(start in get_children(), "start node is invalid!")
	
	tabBar.vertical = not Globals.isMobile()
	
	active = start
	redraw()
	tabBar.resized.connect(redraw)
	for i in get_children():
		i.visible = i == start or i == tabBar

	$tabBar/Home/SubTabs/Profile.pressed.connect(select.bind($Login))
	$tabBar/Home/SubTabs/Settings.pressed.connect(select.bind($Settings))
	
	$tabBar/Board.pressed.connect(select.bind($Board))
	
	$tabBar/Play/SubTabs/New.pressed.connect(select.bind($New))
	$tabBar/Play/SubTabs/Join.pressed.connect(select.bind($Join))
	$tabBar/Play/SubTabs/TEI.pressed.connect(select.bind($TEI))
	$tabBar/Play/SubTabs/Scratch.pressed.connect(select.bind($Scratch))
	
	$tabBar/Watch/SubTabs/Current.pressed.connect(select.bind($Watch))
	$tabBar/Watch/SubTabs/Past.pressed.connect(select.bind($OldGames))


func select(node: Control) -> void:
	assert(node in get_children(), "selected node is invalid! its not a child!")
	active.hide()
	node.show()
	active = node


func redraw():
	if tabBar.vertical:
		tabBar.set_anchors_and_offsets_preset(PRESET_LEFT_WIDE)
		for i in get_children():
			if i == tabBar: continue
			i.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			i.set_offset(SIDE_LEFT, tabBar.size.x)
			
	else:
		tabBar.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
		for i in get_children():
			if i == tabBar: continue
			i.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			i.set_offset(SIDE_BOTTOM, -tabBar.size.y)
