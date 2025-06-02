extends Container
class_name BoardContainer

@export var board3D: PackedScene
@export var board2D: PackedScene

@onready var UI = $GameUI
@onready var Board = $Board

@onready var boardHolder = $Board/SubViewport
var board: BoardLogic

func set2D(v: bool, save: SettingData):
	if not is_node_ready(): await ready
	if board != null:
		boardHolder.remove_child(board)
		board.queue_free()
	board = (board2D if v else board3D).instantiate()
	board.setData(save)
	boardHolder.add_child(board)


func _ready() -> void:
	GameLogic.setup.connect(setup)


func setup(gameData: GameData, startState: GameState):
	get_parent().select(self)


func _draw():
	if Globals.isMobile():
		UI.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		Board.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		$GameUI/MobilePTN.show()
		$GameUI/DesktopPTN.hide()
		
	else:
		UI.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
		Board.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		Board.set_anchor_and_offset(SIDE_RIGHT, 1, -UI.size.x)
		$GameUI/MobilePTN.hide()
		$GameUI/DesktopPTN.show()
		
