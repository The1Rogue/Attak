extends Control


func _ready() -> void:
	GameLogic.setup.connect(setup)

func setup(gameData: GameData, startState: GameState):
	get_parent().select(self)
