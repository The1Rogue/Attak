extends TabMenuTab
class_name Chat

const MAXINT = 2**32

static var rooms: Dictionary = {}
var room: String
var type: int

var textBox: RichTextLabel
var entryBox: LineEdit
enum {
	GLOBAL,
	ROOM,
	PRIVATE
}

func _init(name: String, type: int = ROOM):
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
	
	
	if OS.has_feature("mobile"):
		var c = Control.new()
		add_child(c)
		entryBox.focus_entered.connect(addKeyboardBuffer)
		entryBox.focus_exited.connect(removeKeyboardBuffer)


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
	match type:
		GLOBAL:
			PlayTakI.socket.send_text("Shout " + msg)
		ROOM:
			PlayTakI.socket.send_text("ShoutRoom " + room + " " + msg)
		PRIVATE:
			PlayTakI.socket.send_text("Tell " + room + " " + msg)
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


func addKeyboardBuffer():
	await get_tree().create_timer(.5).timeout
	get_child(-1).custom_minimum_size.y = DisplayServer.virtual_keyboard_get_height() / get_viewport_transform().get_scale().y


func removeKeyboardBuffer():
	get_child(-1).custom_minimum_size.y = 0
