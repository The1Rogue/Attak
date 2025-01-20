extends VBoxContainer
class_name GameUI


@export var WhiteName: Label
@export var WhiteTime: Label

@export var BlackName: Label
@export var BlackTime: Label

@export var undoButton: Button
@export var drawButton: Button
@export var resignButton: Button
@export var leftButton: Button
@export var rightButton: Button

@export var gameInfo: Label
@export var ptnDisplay: GridContainer
@export var ptnCurrent: Button
@export var ptnLast: Button


@export var criticalTime: int = 30
var whiteCritical: bool = false
var blackCritical: bool = false

var i = 0
var currentButton: Button

static func timeString(sec: int) -> String:
	return "%02d:%02d" % [sec / 60, sec % 60]


func _ready() -> void:
	GameLogic.setup.connect(setup)
	GameLogic.viewState.connect(view)
	GameLogic.move.connect(addPly)
	GameLogic.undo.connect(removeLast)
	GameLogic.end.connect(end)
	
	if leftButton != null:
		leftButton.pressed.connect(func(): if GameLogic.view > 0: GameLogic.setView(GameLogic.view - 1))
	if rightButton != null:
		rightButton.pressed.connect(func(): if GameLogic.view < GameLogic.history.size(): GameLogic.setView(GameLogic.view + 1))
	
	GameLogic.undoRequest.connect(undoRequest)
	GameLogic.drawRequest.connect(drawRequest)
	
	setup(GameLogic.gameData, null)
	
	undoButton.toggled.connect(func(t:bool): GameLogic.undoRequest.emit(self, not t))
	drawButton.toggled.connect(func(t:bool): GameLogic.drawRequest.emit(self, not t))
	resignButton.pressed.connect(GameLogic.resign.emit)


func setup(game: GameData, startState: GameState):
	if not self.is_node_ready():
		await self.ready
	
	Notif.ping(Notif.start) #TODO move to gameLogic?
	if ptnDisplay != null:
		for child in ptnDisplay.get_children():
			ptnDisplay.remove_child(child)
	
	i = 0
	BlackName.text = game.playerBlackName
	BlackTime.text = timeString(game.time)
	WhiteName.text = game.playerWhiteName
	WhiteTime.text = timeString(game.time)

	whiteCritical = game.time == 0 #prevent critical sound on not timed game
	blackCritical = game.time == 0
	
	gameInfo.text = " +%3.1f | %d flats/%d cap%s " % [game.komi/2.0, game.flats, game.caps, "" if game.caps == 1 else "s"]
	if game.triggerTime > 0:
		gameInfo.text += "| +%d@%d " % [game.triggerTime/60, game.triggerMove]


func _process(delta: float) -> void:
	WhiteTime.text = timeString(GameLogic.timerWhite.time_left)
	BlackTime.text = timeString(GameLogic.timerBlack.time_left)
	
	if not GameLogic.timerWhite.paused:
		if not whiteCritical and GameLogic.timerWhite.time_left < criticalTime:
			whiteCritical = true
			Notif.ping(Notif.time)
	
	elif not GameLogic.timerBlack.paused:
		if not blackCritical and GameLogic.timerBlack.time_left < criticalTime:
			blackCritical = true
			Notif.ping(Notif.time)


func addPly(origin: Node, ply: Ply):
	undoButton.set_pressed_no_signal(false)
	undoButton.theme_type_variation = &"GameUIButton"
	
	if ptnDisplay == null: return
	if ply.boardState.ply % 2 == 1:
		var l = Label.new()
		l.text = str((ply.boardState.ply+1)/2) + ". "
		ptnDisplay.add_child(l)
	
	elif i == 0:
		var l = Label.new()
		l.text = str(ply.boardState.ply/2) + ". "
		ptnDisplay.add_child(l)
		ptnDisplay.add_child(Control.new()) #empty filler to align things

	var b = Button.new()
	b.theme_type_variation = &"PlyButton"
	b.text = ply.toPTN()
	var c = i #this ensures the lambda expression works correctly
	b.pressed.connect(GameLogic.setView.bind(c+1))
	ptnDisplay.add_child(b)
	i += 1
	
	#(ptnDisplay.get_parent() as ScrollContainer).scroll_vertical = (ptnDisplay.get_parent() as ScrollContainer).get_v_scroll_bar().max_value
	
	ptnLast.text = " >> %d. %s " % [(ply.boardState.ply + 1) /2, b.text]
	var conn = ptnLast.pressed.get_connections()
	for con in conn: ptnLast.pressed.disconnect(con["callable"])
	ptnLast.pressed.connect(GameLogic.setView.bind(c+1))


func view(state: GameState):
	var startPly = GameLogic.startState.ply
	if currentButton != null:
		currentButton.disabled = false
	if state.ply == startPly:
		ptnCurrent.text = " %d. - " % ((state.ply + 1) /2)
		currentButton = null
	else:
		var button = (state.ply + 1) / 2 + state.ply - 1 - startPly / 2 + startPly % 2 - startPly
		currentButton = ptnDisplay.get_child(button)
		currentButton.disabled = true
		ptnCurrent.text = " %d. %s " % [(state.ply + 1) /2, currentButton.text]
		await get_tree().process_frame #incase the button was just added this frame
		ptnDisplay.get_parent().ensure_control_visible(currentButton)


func removeLast():
	undoButton.set_pressed_no_signal(false)
	undoButton.theme_type_variation = &"GameUIButton"
	
	if ptnDisplay == null: return
	assert(i > 0, "CANT REMOVE IF THERES NOTHING TO REMOVE")
	ptnDisplay.remove_child(ptnDisplay.get_child(-1))
	var c = ptnDisplay.get_child(-1)
	if c is Label:
		ptnDisplay.remove_child(c)
	i -= 1
	ptnLast.text = " >> %d. %s " % [(GameLogic.currentPly() + 1) /2, ptnDisplay.get_child(-1).text] if i != 0 else " >> %d. - " % ((GameLogic.currentPly() + 1) /2)
	var d = i
	ptnLast.pressed.disconnect(ptnLast.pressed.get_connections()[0]["callable"])
	ptnLast.pressed.connect(GameLogic.setView.bind(d))


func undoRequest(origin: Node, revoke: bool):
	if origin == self: return
	undoButton.theme_type_variation = &"GameUIButton" if revoke else &"HighlightButton"
	Notif.message("Your opponent retracts their undo request." if revoke else "Your opponent requests an undo!")


func drawRequest(origin: Node, revoke: bool):
	if origin == self: return
	drawButton.theme_type_variation = &"GameUIButton" if revoke else &"HighlightButton"
	Notif.message("Your opponent retracts their draw offer." if revoke else "Your opponent offers a draw!")


func end(type: int):
	undoButton.theme_type_variation = &"GameUIButton"
	drawButton.theme_type_variation = &"GameUIButton"


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT and GameLogic.view > 0:
			GameLogic.setView(GameLogic.view - 1)
			get_viewport().set_input_as_handled()
			
		elif event.keycode == KEY_RIGHT and GameLogic.view < GameLogic.history.size():
			GameLogic.setView(GameLogic.view + 1)
			get_viewport().set_input_as_handled()
