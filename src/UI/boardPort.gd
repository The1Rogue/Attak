extends Container
class_name BoardContainer

@export var board3D: PackedScene
@export var board2D: PackedScene

@onready var UI = $GameUI
@onready var Board = $Board
@onready var EndGame = $End

@onready var EndText: RichTextLabel = $End/VBoxContainer/Label
@onready var EndLink: Button = $End/VBoxContainer/NinjaLink
@onready var EndRematch: Button = $End/VBoxContainer/Rematch
@onready var EndID: Button = $End/VBoxContainer/GameID


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
	
	EndID.pressed.connect(func(): DisplayServer.clipboard_set(GameLogic.gameData.id))
	EndLink.pressed.connect(func(): OS.shell_open("https://ptn.ninja/%s" % GameLogic.getPTN().replace("\n", " ")))
	EndGame.gui_input.connect(func(e): if e is InputEventMouseButton: EndGame.hide())
	EndRematch.pressed.connect(sendRematch)

	GameLogic.end.connect(endGame)


func setup(gameData: GameData, startState: GameState):
	get_parent().select(self)


func _draw():
	EndGame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Board.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	if Globals.isMobile():
		UI.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		
		if $GameUI/MobilePTN.position.y == 0: #UI doesnt have a proper size yet, redraw when we know the size of it
			queue_redraw.call_deferred()
		
		Board.set_anchor_and_offset(SIDE_TOP, 0, $GameUI/MobilePTN.position.y)
		Board.set_anchor_and_offset(SIDE_BOTTOM, 1, $GameUI/MobilePTN/HBoxContainer.global_position.y - size.y)
		$GameUI/GameInfo.hide()
		$GameUI/MobilePTN.show()
		$GameUI/DesktopPTN.hide()
		
	else:
		var s = $GameUI.size
		draw_rect(Rect2(size.x - s.x, 0, s.x, size.y), Color(0,0,0,.5))
		UI.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
		Board.set_anchor_and_offset(SIDE_RIGHT, 1, -UI.size.x)
		$GameUI/MobilePTN.hide()
		$GameUI/DesktopPTN.show()


func endGame(type: int):
	if type == GameState.ONGOING: return
	EndText.clear()
	EndText.append_text(" Game over %s \n" % GameState.resultStrings[type])
	
	if type == GameState.DRAW:
		EndText.append_text(" Game was drawn ")
	else:
		var p = GameLogic.gameData.playerWhiteName if type%2==0 else GameLogic.gameData.playerBlackName
		EndText.push_color(Chat.color(p))
		EndText.append_text(Chat.escape_bbcode(p))
		EndText.pop()
		EndText.append_text(" wins " + ["with a road ", "with flats ", "by default "][type/2])
	
	EndRematch.disabled = false
	EndRematch.visible = (GameLogic.gameData.playerBlack == GameData.PLAYTAK and GameLogic.gameData.playerWhite == GameData.LOCAL) or (GameLogic.gameData.playerBlack == GameData.LOCAL and GameLogic.gameData.playerWhite == GameData.PLAYTAK)
	EndGame.show()
	Notif.ping(Notif.end)


func sendRematch(): #TODO: local rematches?
	EndRematch.disabled = true
	Notif.ping()
	PlayTakI.sendRematch()
