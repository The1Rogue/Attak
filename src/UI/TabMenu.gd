extends VBoxContainer
class_name TabMenu


# PLANNED FOR NEXT RELEASE:
# TEST: mobile seek / watch wrapping
# TODO: auto attempt reconnect on disconnect (and save chats for a bit) (how to prevent disconnect due to reconnect somewhere else?)

# MAYBE:
# mobile show active game's chat on screen (text bubbles perhaps?)
# 2d prevent tall stack covering stacks behind them

# BUG:
# tabmenutab wrapping oob (only sometimes????)
# Web disconnects if tab not active
# can press undo on first ply
# mobile chat entry box stays up if virtual keyboard hidden manually
# mobile placement of first white flat in 3D scratch immediately selects it (double touch input)
# laptop close lid disconnects without closing socket, which is not detected
# mobile scroll goes through menu with mouse
# mobile and web sometimes gives load_source_code errors (though non-fatal and not noticable without in the app)(perhaps thats just a debugger issue?)

# TEST:
# upload to google play / appstore?
# do we want to support mobile landscape?
# does web log out if not focused?
# verify last 2 entries on gamelist add message
# find all remaining TODOs
# what happens if you accept a new game when one is still active?

# TODO functional
# allow user to revoke seek
# local bot support
# puzzle integration?
# TakBot support ????
# peer to peer / lan play ????
# add more general settings / board specific settings
# save settings?

# TODO functional / pretty
# 3D add custom pieces / playtak texture support
# make join / watch entries not rely on monospace font
# color in join game
# disable things when not logged in
# click through pieces
# show online count
# seperate bot from human seeks
# show ratings (player, and for seeks)

# TODO pretty
# add tweens to ui
# add tweens to board
# add result tag to ptn display
# prettify ui
# better login success/fail feedback
# chat message notif sound / notif dot
# more detailed watch ui

# TODO low priority
# choose what to do with ptn clock / result
# more detailed seek created confirmation / add created seek to seek list?
# handle server messages/errors/NOKs
# smash on server move
# custom new game piece counts
# user settings (change password, forget on logout)

@export var start: TabMenuTab
var active: TabMenuTab
var last: TabMenuTab


func _ready() -> void:
	for child in get_children():
		if not child is TabMenuTab: continue
		child.size_flags_vertical |= Control.SIZE_EXPAND
		var b = Button.new()
		child.tabButton = b
		child.hide()
		b.text = child.name
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.pressed.connect(func(): select(child))
		child.add_sibling(b)
		move_child(b, b.get_index() - 1)
		b.theme_type_variation = &"TabButton"
	
	active = start
	active.show()


func select(node: Control):
	if active == node:
		if last == null: return
		active = last
		last = node
		last.hide()
		active.show()
		
	else:
		last = active
		active = node
		last.hide()
		active.show()


func addNode(node: TabMenuTab, name: String, select: bool = true):
	var b = Button.new()
	node.tabButton = b
	add_child(b)
	node.size_flags_vertical |= Control.SIZE_EXPAND
	b.add_sibling(node)
	node.hide()
	b.text = name
	b.autowrap_mode = TextServer.AUTOWRAP_WORD
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
	if node == active: 
		active = last
		last = null
	
