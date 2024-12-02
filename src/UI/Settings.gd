extends TabMenuTab
class_name Settings



@export var board3D: PackedScene
@export var board2D: PackedScene

var board: BoardLogic

func _ready() -> void:
	$Set2D.toggled.connect(setBoard)
	if Globals.isMobile():
		board = board2D.instantiate()
		$Set2D.set_pressed_no_signal(true)
	else:
		board = board3D.instantiate()
	GameLogic.add_child(board)


func setBoard(is2D: bool):
	GameLogic.remove_child(board)
	board = (board2D if is2D else board3D).instantiate()
	GameLogic.add_child(board)
