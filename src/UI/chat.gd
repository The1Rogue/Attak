extends TabMenuTab
class_name Chat

const MAXINT = 2**32

static var rooms: Dictionary = {}
var interface: PlayTakI
var room: String
var type: int

var textBox: RichTextLabel
var entryBox: LineEdit
enum {
	GLOBAL,
	ROOM,
	PRIVATE
}

func _init(interface: PlayTakI, name: String, type: int = ROOM):
	self.interface = interface
	self.room = name.lstrip("<").rstrip(">")
	self.type = type
	
	textBox = RichTextLabel.new()
	entryBox = LineEdit.new()
	
	entryBox.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	entryBox.placeholder_text = ">"
	textBox.size_flags_vertical |= Control.SIZE_EXPAND
	textBox.scroll_following = true
	
	add_child(textBox)
	add_child(entryBox)
	entryBox.text_submitted.connect(send)
	rooms[name] = self
	

func _ready():
	if type != GLOBAL:
		var exit = Button.new()
		exit.text = "X"
		exit.theme_type_variation = &"ExitButton"
		tabButton.add_child(exit)
		exit.pressed.connect(remove)
		exit.set_anchors_and_offsets_preset(PRESET_CENTER_RIGHT)
		exit.position.x -= 7

static func escape_bbcode(bbcode_text):
	return bbcode_text.replace("[", "[lb]")


func send(msg: String):
	add_message(interface.activeUsername, msg)
	match type:
		GLOBAL:
			interface.socket.send_text("Shout " + msg)
		ROOM:
			interface.socket.send_text("ShoutRoom " + room + " " + msg)
		PRIVATE:
			interface.socket.send_text("Tell " + room + " " + msg)
	entryBox.clear()


func add_message(user: String, message: String):
	var c = Color.RED
	c.h = user.hash() as float / MAXINT
	textBox.push_color(c)
	textBox.append_text("<"+escape_bbcode(user) + ">: ")
	textBox.pop()
	textBox.append_text(escape_bbcode(message) + "\n")


func remove():
	get_parent().remove(self)
	rooms.erase(room)
	queue_free()
