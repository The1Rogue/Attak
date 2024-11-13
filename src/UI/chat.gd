extends TabMenuTab
class_name Chat

const MAXINT = 2**32

static var rooms: Dictionary = {}
var interface: PlayTakI
var room: String
var type: int

var textBox: RichTextLabel

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
	var entry = LineEdit.new()
	
	entry.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	entry.placeholder_text = ">"
	textBox.size_flags_vertical |= Control.SIZE_EXPAND
	
	add_child(textBox)
	add_child(entry)
	entry.text_submitted.connect(send)
	rooms[name] = self
	
	if type != GLOBAL:
		pass


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
	get_child(0).clear()


func add_message(user: String, message: String):
	var c = Color.RED
	c.h = user.hash() as float / MAXINT
	textBox.push_color(c)
	textBox.append_text("<"+escape_bbcode(user) + ">: ")
	textBox.pop()
	textBox.append_text(escape_bbcode(message) + "\n")
