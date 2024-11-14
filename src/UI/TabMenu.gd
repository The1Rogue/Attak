extends VBoxContainer
class_name TabMenu

# BUG:
# laptop close lid disconnects without closing socket, which is not detected
# timer probably doesnt end if game ends on resign or abandon

# TEST:
# watch game correct chat
# verify last 2 entries on gamelist add message
# find all remaining TODOs
# what happens if you accept a new game when one is still active?

# TODO functional
# adaptive ui size (mostly font)
# default tab in right menu
# finish removing gameUI from Globals
# add more general settings
# auto attempt reconnect on disconnect (and save chats for a bit)
# 2d board texture scaling (is that needed for 3d too?)
# 2d prevent tall stack covering stacks behind them
# 3d decide what to do with border/viewport size

# TODO functional / pretty
# make chat names less bulky
# disable things when not logged in
# click through pieces
# show online count
# seperate bot from human seeks
# show ratings (player, and for seeks)

# TODO pretty
# add tweens to ui
# add tweens to board
# make ui mobile friendly
# undo/draw buttons show opponent request
# add result tag to ptn display
# prettify ui
# better login success/fail feedback
# chat message notif sound / notif dot
# more detailed seek/watch ui

# TODO low priority
# choose what to do with ptn clock / result
# more detailed seek created confirmation / add created seek to seek list?
# handle server messages/errors/NOKs
# smash on server move
# custom new game piece counts
# user settings (change password, forget on logout)

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
	if active != null:
		active.hide()
		
	if active == node:
		active = null
		
	else:
		active = node
		active.show()


func addNode(node: TabMenuTab, name: String, select: bool = true):
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


func remove(node: TabMenuTab):
	remove_child(node.tabButton)
	remove_child(node)
	if node == active: active = null
