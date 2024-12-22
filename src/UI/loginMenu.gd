extends Control
class_name LoginMenu

const loginResource = "user://playtakLogin.res"

@export var tabOnLogin: Control
@export var button: Button

@onready var login: VBoxContainer = $Menu/Login
@onready var userEntry: LineEdit = $Menu/Login/User
@onready var passEntry: LineEdit = $Menu/Login/Pass
@onready var remember: CheckBox = $Menu/Login/Remember
@onready var confirm: Button = $Menu/Login/Button

@onready var settings: VBoxContainer = $Menu/Settings
@onready var logoutButton: Button = $Menu/Settings/Logout

func _ready():
	PlayTakI.ratingUpdate.connect(updateRating)
	PlayTakI.logout.connect(logout)
	
	userEntry.text_submitted.connect(passEntry.grab_focus)
	passEntry.text_submitted.connect(submit)
	confirm.pressed.connect(submit)

	logoutButton.pressed.connect(PlayTakI.onLogout)

	var p = get_parent()
	if not p.is_node_ready():
		await get_parent().ready
		
	if ResourceLoader.exists(loginResource):
		#button.disabled = true  TODO prevent login attempts during this?
		var login = ResourceLoader.load(loginResource)
		await signin(login.user, login.password)
		#button.disabled = false TODO


func signin(user:String, passw: String):
	if await PlayTakI.signIn(user, passw):
		login.hide()
		settings.show()
		button.text = "%s (%d)" % [PlayTakI.activeUsername, PlayTakI.ratingList.get(PlayTakI.activeUsername, 1000)]
		get_parent().select(tabOnLogin)
		
		if user != "Guest" and remember.button_pressed:
			ResourceSaver.save(Login.new(PlayTakI.activeUsername, passw), loginResource)


func submit():
	signin(userEntry.text, passEntry.text)
	passEntry.clear()


func logout():
	button.text = "Login"
	
	settings.hide()
	login.show()


func updateRating():
	if not PlayTakI.active: return
	button.text = "%s (%d)" % [PlayTakI.activeUsername, PlayTakI.ratingList.get(PlayTakI.activeUsername, 1000)]
