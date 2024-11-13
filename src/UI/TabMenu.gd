extends VBoxContainer
class_name TabMenu

# BUG:
# remove seeks/watches on logout (also chat rooms?)

# TEST:
# watch game correct chat
# verify last 2 entries on gamelist add message
# verify game start message / makeGame function
# find all remaining TODOs

# TODO functional
# choose what to do with ptn clock / result
# add general settings?
# close chats

# TODO functional / pretty
# disable things when not logged in
# click through pieces
# add game details (komi, time etc)
# show online count
# better watch / seek count
# seperate bot from human seeks
# show ratings (player, and for seeks)
 
# TODO pretty
# add tweens to ui
# add tweens to board
# make ui mobile friendly
# undo/draw buttons show opponent request
# prettify ui
# better login success/fail feedback
# chat message notif sound / notif dot
# more detailed seek/watch ui

# TODO low priority
# more detailed seek created confirmation / add created seek to seek list?
# handle server messages/errors/NOKs
# smash on server move
# custom new game piece counts
# 2d board
# user settings

var active: Control


func _ready() -> void:
	for child in get_children():
		if not child is TabMenuTab: continue
		child.size_flags_vertical |= Control.SIZE_EXPAND
		var b = Button.new()
		child.tabButton = b
		child.hide()
		b.text = child.name
		b.pressed.connect(func(): select(child))
		child.add_sibling(b)
		move_child(b, b.get_index() - 1)
		b.theme_type_variation = &"TabButton"
	
	active = get_child(1)
	active.show()


func select(node: Control):
	active.hide()
	active = node
	active.show()


func addNode(node: Control, name: String, select: bool = true):
	if not node is TabMenuTab: return
	var b = Button.new()
	node.tabButton = b
	add_child(b)
	node.size_flags_vertical |= Control.SIZE_EXPAND
	b.add_sibling(node)
	node.hide()
	b.text = name
	b.pressed.connect(func(): select(node))
	b.theme_type_variation = &"TabButton"
	if select:
		self.select(node)


func gotoOrMakeChat(interface: PlayTakI, name: String, type: int):
	if name in Chat.rooms:
		select(Chat.rooms[name])
	else:
		var c = Chat.new(interface, name, type)
		addNode(c, "Chat: "+name)
