extends Player
class_name Interface

signal startGame(interface: Interface, data: GameData)

signal timeSync(white: int, black: int)

signal error(msg: String)

func sendMove(ply: Ply):
	pass
