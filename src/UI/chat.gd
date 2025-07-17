extends VBoxContainer
class_name Chat

const MAXINT = 2**32

var room: String
var type: int

var textBox: RichTextLabel
var entryBox: LineEdit
enum {
	GLOBAL,
	ROOM,
	PRIVATE
}

static func color(u: String):
	var c = Color.RED
	c.h = u.hash() as float / MAXINT 
	return c

func _init(name: String, type: int = ROOM):
	size_flags_vertical |= Control.SIZE_EXPAND
	self.room = name.lstrip("<").rstrip(">")
	self.type = type
	
	textBox = RichTextLabel.new()
	entryBox = LineEdit.new()
	var sendButton = Button.new()
	
	entryBox.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	entryBox.placeholder_text = ">"
	entryBox.keep_editing_on_text_submit = true
	textBox.size_flags_vertical |= Control.SIZE_EXPAND
	textBox.scroll_following = true
	sendButton.text = "Send"
	sendButton.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	sendButton.position.y = entryBox.size.y

	add_child(textBox)
	add_child(entryBox)
	entryBox.add_child(sendButton)
	entryBox.text_submitted.connect(send)
	sendButton.pressed.connect(func(): send(entryBox.text))


static func escape_bbcode(bbcode_text):
	return bbcode_text.replace("[", "[lb]")

func send(msg: String):
	match type:
		GLOBAL:
			PlayTakI.socket.send_text("Shout " + msg)
		ROOM:
			PlayTakI.socket.send_text("ShoutRoom " + room + " " + msg)
		PRIVATE:
			PlayTakI.socket.send_text("Tell " + room + " " + msg)
	entryBox.clear()

func add_message(user: String, message: String):
	textBox.push_color(color(user))
	textBox.append_text("<"+escape_bbcode(user) + ">: ")
	textBox.pop()
	textBox.append_text(escape_bbcode(message) + "\n")

func _process(delta: float) -> void:
	entryBox.global_position.y = get_viewport_rect().size.y - 2*entryBox.size.y - (DisplayServer.virtual_keyboard_get_height() / get_viewport_transform().get_scale().y if Globals.isMobile() else 0) 
