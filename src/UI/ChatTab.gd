extends Control

var active: Control
var rooms: Dictionary = {}

@onready var button = $Button
@onready var reddot = $Button/Reddot
@onready var list = $Panel/ChatList

var isVisible: bool = false

func _ready() -> void:
	reddot.hide()
	button.toggled.connect(toggle)
	get_parent().move_child.call_deferred(self, -1)
	hide()

func _draw():
	list.custom_minimum_size.x = get_viewport_rect().size.y / 6
	

func toggle(visible: bool) -> void:
	reddot.hide()
	set_offset(SIDE_RIGHT, -list.size.x if visible else 0)
	isVisible = visible


func select(chat: Chat):
	if active != null:
		active.hide()
		list.get_child(active.get_index()-1).disabled = false
	active = chat
	chat.show()
	list.get_child(chat.get_index()-1).disabled = true


func newChat(name: String, type: int = Chat.ROOM):
	show()
	var chat = Chat.new(name, type)
	var button = Button.new()
	
	button.text = name
	button.pressed.connect(select.bind(chat))
	
	list.add_child(button)
	list.add_child(chat)
	chat.hide()
	rooms[name] = chat
	select(chat)


func remove(room):
	var idx = rooms[room].get_index()
	list.remove_child(list.get_child(idx - 1))
	list.remove_child(rooms[room])
	rooms[room].queue_free()
	rooms.erase(room)


func clear():
	for chat in rooms.keys():
		remove(chat)
		#rooms[chat].remove()
	#rooms.clear()
	hide()


func parseMsg(room: String, user: String, msg: String):
	if not isVisible: 
		reddot.show()
		Notif.ping()
	
	if room.is_empty():
		if not rooms.has(user):
			ChatTab.newChat(room, Chat.PRIVATE)
		rooms[user].add_message(user, msg)
	else:
		if not rooms.has(room):
			ChatTab.newChat(room, Chat.ROOM)
		rooms[room].add_message(user, msg)


const BOUND = 120
func _input(event):
	if event is InputEventScreenDrag:
		if event.relative.abs().max_axis_index() == Vector2.AXIS_X:
			if event.relative.x > 0:
				if get_viewport_rect().size.x - event.position.x - event.relative.x < BOUND:
					toggle(false)
					get_viewport().set_input_as_handled()
			else:
				if get_viewport_rect().size.x - event.position.x + event.relative.x < BOUND:
					toggle(true)
					get_viewport().set_input_as_handled()
					
