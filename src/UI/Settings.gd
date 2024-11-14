extends TabMenuTab
class_name Settings



@export var board3D: PackedScene
@export var board2D: PackedScene

@onready var boardHolder = $/root/Root/Main/HSplitContainer/AspectRatioContainer/SubViewportContainer/SubViewport

func _ready() -> void:
	$Set2D.toggled.connect(setBoard)



func setBoard(is2D: bool):
	boardHolder.remove_child(boardHolder.get_child(0))
	var newBoard: BoardLogic = (board2D if is2D else board3D).instantiate()
	boardHolder.add_child(newBoard)
