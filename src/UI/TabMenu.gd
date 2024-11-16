extends VBoxContainer
class_name TabMenu

# BUG:
# mobile notifs dont scale
# mobile spinbox and checkbox icons are super small
# chat names too long on mobile
# chat cant handle emotes?
# laptop close lid disconnects without closing socket, which is not detected
# mobile scroll goes through menu with mouse

# TEST:
# do we want to support mobile landscape?
# does web log out if not focused?
# verify last 2 entries on gamelist add message
# find all remaining TODOs
# what happens if you accept a new game when one is still active?

# TODO functional
# mobile show active game's chat on screen
# add more general settings
# auto attempt reconnect on disconnect (and save chats for a bit)
# 2d board texture scaling (is that needed for 3d too?)
# 2d prevent tall stack covering stacks behind them

# TODO functional / pretty
# auto open last tab instead of closing it (in right menu)
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

@export var start: TabMenuTab

var active: TabMenuTab


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
	
	active = start
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
