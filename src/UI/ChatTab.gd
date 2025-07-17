extends Control

var active: Control
var rooms: Dictionary = {}

@onready var button = $Button
@onready var reddot = $Button/Reddot
@onready var list = $Panel/ChatList

signal toggle(bool)

var isVisible: bool = false

func _ready() -> void:
	reddot.hide()
	button.toggled.connect(setVisible)
	#toggle.connect(setVisible)
	get_parent().move_child.call_deferred(self, -1)
	hide()


func _draw():
	list.custom_minimum_size.x = get_viewport_rect().size.y / 6
	setVisible.call_deferred(isVisible) #resets offset


func setVisible(visible: bool) -> void:
	reddot.hide()
	set_offset(SIDE_RIGHT, -list.size.x if visible else 0)
	isVisible = visible
	toggle.emit(isVisible)


func select(chat: Chat):
	if active != null:
		active.hide()
		list.get_child(active.get_index()-1).disabled = false
	active = chat
	chat.show()
	list.get_child(chat.get_index()-1).disabled = true


func newChat(name: String, type: int = Chat.ROOM):
	show()
	if rooms.has(name): 
		select(rooms[name])
		return
		
	var chat = Chat.new(name, type)
	var button = Button.new()
	
	button.text = name
	button.pressed.connect(select.bind(chat))
	
	if type != Chat.GLOBAL: #add close button
		var closeB = Button.new()
		closeB.text = " X "
		closeB.theme_type_variation = &"ExitButton"
		closeB.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		closeB.hide()
		button.add_child(closeB)
		button.mouse_entered.connect(closeB.show)
		button.mouse_exited.connect(closeB.hide)
		closeB.mouse_entered.connect(closeB.show)
		closeB.mouse_exited.connect(closeB.hide)
		
		if type == Chat.ROOM:
			closeB.pressed.connect(PlayTakI.leavechat.bind(name))
		else:
			closeB.pressed.connect(remove.bind(name))
	
	list.add_child(button)
	list.add_child(chat)
	chat.hide()
	rooms[name] = chat
	select(chat)


func remove(room: String):
	var idx = rooms[room].get_index()
	list.remove_child(list.get_child(idx - 1))
	list.remove_child(rooms[room])
	rooms[room].queue_free()
	rooms.erase(room)
	queue_redraw()


func clear():
	hide()
	setVisible(false)


func parseMsg(room: String, user: String, msg: String):
	if not isVisible: 
		reddot.show()
		Notif.ping()
	
	if room.is_empty():
		if not rooms.has(user):
			ChatTab.newChat(user, Chat.PRIVATE)
		rooms[user].add_message(user, msg)
		if shouldShow(PlayTakI.activeUsername, user):
			Notif.chatMessage(user, msg)
	
	else:
		if not rooms.has(room):
			ChatTab.newChat(room, Chat.ROOM)
		rooms[room].add_message(user, msg)
		var names = room.split("-")
		if names.size() == 2 and shouldShow(names[0], names[1]):
			Notif.chatMessage(user, msg)


func shouldShow(u1: String, u2: String):
	return (not isVisible) and ((GameLogic.gameData.playerWhiteName == u1 and GameLogic.gameData.playerBlackName == u2) or (GameLogic.gameData.playerWhiteName == u2 and GameLogic.gameData.playerBlackName == u1))


const BOUND = 120
func _input(event):
	if not visible: return
	if event is InputEventScreenDrag:
		if event.relative.abs().max_axis_index() == Vector2.AXIS_X:
			if event.relative.x > 0:
				if get_viewport_rect().size.x - event.position.x - event.relative.x < BOUND:
					setVisible(false)
					get_viewport().set_input_as_handled()
			else:
				if get_viewport_rect().size.x - event.position.x + event.relative.x < BOUND:
					setVisible(true)
					get_viewport().set_input_as_handled()
