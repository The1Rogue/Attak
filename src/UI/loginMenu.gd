extends TabMenuTab
class_name LoginMenu

const loginResource = "user://playtakLogin.res"

@export var tabOnLogin: TabMenuTab

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
		tabButton.disabled = true
		var login = ResourceLoader.load(loginResource)
		signin(login.user, login.password)
		tabButton.disabled = false


func signin(user:String, passw: String):
	if await PlayTakI.signIn(user, passw):
		login.hide()
		settings.show()
		tabButton.text = "%s (%d)" % [PlayTakI.activeUsername, PlayTakI.ratingList.get(PlayTakI.activeUsername, 1000)]
		get_parent().select(tabOnLogin)
		
		if user != "Guest" and remember.button_pressed:
			ResourceSaver.save(Login.new(PlayTakI.activeUsername, passw), loginResource)


func submit():
	signin(userEntry.text, passEntry.text)
	passEntry.clear()


func logout():
	tabButton.text = "Login"
	
	settings.hide()
	login.show()


func updateRating():
	if not PlayTakI.active: return
	tabButton.text = "%s (%d)" % [PlayTakI.activeUsername, PlayTakI.ratingList.get(PlayTakI.activeUsername, 1000)]
