extends TabMenuTab
class_name LoginMenu

const loginResource = "user://playtakLogin.res"

@onready var login: VBoxContainer = $Menu/Login
@onready var userEntry: LineEdit = $Menu/Login/User
@onready var passEntry: LineEdit = $Menu/Login/Pass
@onready var remember: CheckBox = $Menu/Login/Remember
@onready var confirm: Button = $Menu/Login/Button

@onready var settings: VBoxContainer = $Menu/Settings
@onready var logoutButton: Button = $Menu/Settings/Logout

@export var interface: PlayTakI

func _ready():
	userEntry.text_submitted.connect(passEntry.grab_focus)
	passEntry.text_submitted.connect(submit)
	confirm.pressed.connect(submit)

	logoutButton.pressed.connect(logout)

	var p = get_parent()
	if not p.is_node_ready():
		await get_parent().ready
		
	if ResourceLoader.exists(loginResource):
		tabButton.disabled = true
		var login = ResourceLoader.load(loginResource)
		signin(login.user, login.password)
		tabButton.disabled = false


func signin(user:String, passw: String):
	if await interface.signIn(user, passw):
		login.hide()
		settings.show()
		tabButton.text = interface.activeUsername
		get_parent().select(interface.seekMenu) #bit convoluted maybe but eh
		
		if user != "Guest" and remember.button_pressed:
			ResourceSaver.save(Login.new(interface.activeUsername, passw), loginResource)


func submit():
	signin(userEntry.text, passEntry.text)
	passEntry.clear()


func logout():
	tabButton.text = "Login"
	interface.logout()
	
	settings.hide()
	login.show()
