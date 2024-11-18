extends TabMenuTab
class_name Settings



@export var board3D: PackedScene
@export var board2D: PackedScene


func _ready() -> void:
	$Set2D.toggled.connect(setBoard)
	if OS.has_feature("mobile"):
		GameLogic.add_child(board2D.instantiate())
		$Set2D.set_pressed_no_signal(true)
	else:
		GameLogic.add_child(board3D.instantiate())


func setBoard(is2D: bool):
	GameLogic.remove_child(GameLogic.get_child(0))
	var newBoard: BoardLogic = (board2D if is2D else board3D).instantiate()
	GameLogic.add_child(newBoard)
