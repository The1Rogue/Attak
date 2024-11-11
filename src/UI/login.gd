extends Control
class_name LoginMenu

const loginResource = "user://playtakLogin.res"

@onready var login: VBoxContainer = $Login
@onready var userEntry: LineEdit = $Login/User
@onready var passEntry: LineEdit = $Login/Pass
@onready var remember: CheckBox = $Login/Remember
@onready var confirm: Button = $Login/Button

@onready var settings: VBoxContainer = $Settings
@onready var logoutButton: Button = $Settings/Logout

var menuButton: Button

@export var interface: PlayTakI

func _ready():
	userEntry.text_submitted.connect(passEntry.grab_focus)
	passEntry.text_submitted.connect(submit)
	confirm.pressed.connect(submit)

	logoutButton.pressed.connect(logout)

	var p = get_parent()
	if not p.is_node_ready():
		await get_parent().ready
		
	menuButton = p.get_child(get_index() - 1)
	if ResourceLoader.exists(loginResource):
		menuButton.disabled = true
		var login = ResourceLoader.load(loginResource)
		signin(login.user, login.password)
		menuButton.disabled = false

func signin(user:String, passw: String):
	if await interface.signIn(user, passw):
		login.hide()
		settings.show()
		menuButton.text = interface.activeUsername
		get_parent().select(get_parent().get_child(5)) #bit convoluted maybe but eh
		
		if user != "Guest" and remember.button_pressed:
			ResourceSaver.save(Login.new(interface.activeUsername, passw), loginResource)


func submit():
	signin(userEntry.text, passEntry.text)
	passEntry.clear()


func logout():
	menuButton.text = "Login"
	interface.logout()
	
	settings.hide()
	login.show()
