extends Control
class_name LoginMenu

const loginResource = "user://playtakLogin.res"
const GAMES_URL = "https://api.playtak.com/v1/games-history?page=0&limit=100&mirror=true&player_white=%s"
const RATINGS_URL = "https://api.playtak.com/v1/ratings/%s"

@export var tabOnLogin: Control
@export var button: Button

@onready var login: VBoxContainer = $Menu/Login
@onready var userEntry: LineEdit = $Menu/Login/User
@onready var passEntry: LineEdit = $Menu/Login/Pass
@onready var remember: CheckBox = $Menu/Login/Remember
@onready var confirm: Button = $Menu/Login/Button

@onready var register: VBoxContainer = $Menu/Register
@onready var nameEntry: LineEdit = $Menu/Register/User
@onready var emailEntry: LineEdit = $Menu/Register/Email
@onready var createAccount: Button = $Menu/Register/Button
@onready var goLogin: Button = $Menu/Register/Back


@onready var settings: VBoxContainer = $Menu/Settings
@onready var logoutButton: Button = $Menu/Settings/Logout

@onready var nameLabel: Label = $Menu/Settings/Name
@onready var gamesLabel: Label = $Menu/Settings/Games
@onready var graph: Panel = $Menu/Settings/Graph

@onready var guest: Button = $Menu/Login/HBoxContainer/Guest
@onready var goRegister: Button = $Menu/Login/HBoxContainer/Register

@onready var http: HTTPRequest = HTTPRequest.new()

var callbackUser = JavaScriptBridge.create_callback(func(args): userEntry.text = args[0].target.value) if OS.has_feature("web") else null
var callbackPass = JavaScriptBridge.create_callback(func(args): passEntry.text = args[0].target.value) if OS.has_feature("web") else null


func _ready():
	add_child(http)
	
	PlayTakI.login.connect(onLogin)
	PlayTakI.logout.connect(onLogout)
	
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("username").oninput = callbackUser
		JavaScriptBridge.get_interface("password").oninput = callbackPass
	
	userEntry.text_submitted.connect(passEntry.grab_focus)
	passEntry.text_submitted.connect(submit)
	confirm.pressed.connect(submit)

	guest.pressed.connect(signin.bind("Guest", ""))

	goRegister.pressed.connect(func(): login.hide(); register.show())
	goLogin.pressed.connect(func(): register.hide(); login.show())

	nameEntry.text_submitted.connect(emailEntry.grab_focus)
	emailEntry.text_submitted.connect(registerAccount)
	createAccount.pressed.connect(registerAccount)

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
	if not await PlayTakI.signIn(user, passw): return
	
	if user != "Guest" and remember.button_pressed:
		ResourceSaver.save(Login.new(PlayTakI.activeUsername, passw), loginResource)


func setData(result: int, response_code: int, header: PackedStringArray, body: PackedByteArray):
	var json: Dictionary = JSON.parse_string(body.get_string_from_utf8()) #TODO error handling
	
	button.text = "%s (%d)" % [json["name"], json["rating"]]
	nameLabel.text = "%s (%d)" % [json["name"], json["rating"]]
	nameLabel.add_theme_font_size_override(&"font_size", 160 if Globals.isMobile() else 80)
	gamesLabel.text = "%d games played" % json["ratedgames"]


func makeGraph(result: int, response_code: int, header: PackedStringArray, body: PackedByteArray):
	var json: Dictionary = JSON.parse_string(body.get_string_from_utf8()) #TODO error handling
	
	graph.custom_minimum_size = Vector2.ONE * 256
	
	var points: Array[Vector2] = []
	for i in json["items"]:
		if i["rating_change_white"] == -2000: continue
		points.append(Vector2(i["date"] / 1000, i["rating_white"] + i["rating_change_white"]/10 if i["player_white"] == PlayTakI.activeUsername else i["rating_black"] + i["rating_change_black"]/10))
	points.sort_custom(func(a,b): return a.x < b.x)
	var min = Vector2(points[0].x, points.reduce(func(a, b): return Vector2i(0,min(a.y, b.y))).y)
	var max = Vector2(points[-1].x, points.reduce(func(a, b): return Vector2i(0,max(a.y, b.y))).y)
	
	for i in points.size():
		points[i] -= min
		points[i] /= max-min
		points[i].y = 1 - points[i].y
	
	graph.points = points
	graph.min = min
	graph.max = max
	graph.queue_redraw()


func submit():
	signin(userEntry.text, passEntry.text)
	passEntry.clear()

func registerAccount():
	PlayTakI.register(nameEntry.text, emailEntry.text)

func onLogin(username: String):
	login.hide()
	
	settings.show()
	var rating = PlayTakI.ratingList.get(username, 1000)
	button.text = "%s (%d)" % [username, rating]
	get_parent().select(tabOnLogin)
	
	if username.begins_with("Guest"): return
	
	http.request_completed.connect(setData)
	http.request(RATINGS_URL % username)
	await http.request_completed
	http.request_completed.disconnect(setData)
	http.request_completed.connect(makeGraph)
	http.request(GAMES_URL % username)
	await http.request_completed
	http.request_completed.disconnect(makeGraph)


func onLogout():
	button.text = "Login"
	
	settings.hide()
	login.show()
