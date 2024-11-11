extends ButtonPopup

@onready var user = $VBoxContainer/Username
@onready var password = $VBoxContainer/Password
@onready var button = $VBoxContainer/Button

@export var I: PlayTakI
func _ready():
	super()
	button.pressed.connect(login)

func login():
	var success = await I.signIn(user.text, password.text)
	if success:
		editText.emit(I.activeUsername)
		get_parent().disabled = true
		hide()
	else:
		password.clear()
		var tween = Tween.new()
		tween.tween_property(password, "position.x", 10, .1)
		tween.tween_property(password, "position.x", -10, .1)
		tween.tween_property(password, "position.x", 0, .1)
