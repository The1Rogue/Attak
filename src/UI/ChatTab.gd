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


func toggle(visible: bool) -> void:
	reddot.hide()
	set_offset(SIDE_RIGHT, -list.size.x if visible else 0)
	isVisible = visible

func select(chat: Chat):
	if active != null:
		active.hide()
	active = chat
	chat.show()


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


func remove(room):
	var idx = rooms[room].get_index()
	remove_child(get_child(idx - 1))
	remove_child(rooms[room])
	rooms.erase(room)
	queue_free()


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
