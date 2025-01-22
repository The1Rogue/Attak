extends VBoxContainer
class_name OldGames

const GAMES_URL = "https://api.playtak.com/v1/games-history?"
const ENTRY = preload("res://scenes/UI/GameEntry.tscn")

var lastQueries: Dictionary
var maxPage: int = 0

@onready var tz = Time.get_time_zone_from_system()["bias"] * 60

@onready var http = HTTPRequest.new()

@onready var pageLabel = $"../../HBoxContainer/Count"

@onready var panel = $"../../HBoxContainer/Search/PopupPanel"
@onready var confirm:Button = $"../../HBoxContainer/Search/PopupPanel/GridContainer/Confirm"
@onready var ID:LineEdit = $"../../HBoxContainer/Search/PopupPanel/GridContainer/ID"
@onready var white:LineEdit = $"../../HBoxContainer/Search/PopupPanel/GridContainer/white"
@onready var black:LineEdit = $"../../HBoxContainer/Search/PopupPanel/GridContainer/black"
@onready var type:OptionButton = $"../../HBoxContainer/Search/PopupPanel/GridContainer/type"
@onready var result:OptionButton = $"../../HBoxContainer/Search/PopupPanel/GridContainer/result"
@onready var sizeButton:OptionButton = $"../../HBoxContainer/Search/PopupPanel/GridContainer/size"
@onready var mirror = $"../../HBoxContainer/Search/PopupPanel/GridContainer/mirror"

func _ready():
	add_child(http)
	http.request_completed.connect(parseResults)
	lastQueries = {"page":0, "limit":50, "mirror":true}
	makeSearch(lastQueries)

	$"../../HBoxContainer/Search".pressed.connect(panel.show)
	confirm.pressed.connect(newSearch)
	
	$"../../HBoxContainer/Prev".pressed.connect(diff.bind(-1))
	$"../../HBoxContainer/Next".pressed.connect(diff.bind(1))


func makeSearch(queries: Dictionary):
	var q = GAMES_URL
	for i in queries:
		q += i + "=" + str(queries[i]) + "&"
		
	q.rstrip("&")
	http.request(q)


func newSearch():
	panel.hide()
	lastQueries = {"page": 0, "limit": 50}
	lastQueries["mirror"] = mirror.button_pressed
	if not ID.text.is_empty():
		lastQueries["id"] = ID.text
	if not white.text.is_empty():
		lastQueries["player_white"] = white.text
	if not black.text.is_empty():
		lastQueries["player_black"] = black.text

	if type.selected != 0:
		lastQueries["type"] = ["Normal", "Tournament", "Unrated"][type.selected - 1]
	if result.selected != 0:
		lastQueries["game_result"] = result.get_item_text(result.selected)
	if sizeButton.selected != 0:
		lastQueries["size"] = sizeButton.selected + 2
	
	makeSearch(lastQueries)


func diff(i: int):
	var d = lastQueries["page"] + i
	if d < 0 or d >= maxPage: return
	lastQueries["page"] = d
	makeSearch(lastQueries)


func clear():
	for i in get_children():
		remove_child(i)
		
	add_child(http)


func appendEntry(data: GameData, result: String, date: int, notation: String):
	var entry = ENTRY.instantiate()
	var hbox = entry.get_child(0)
	hbox.get_child(0).text = data.id
	
	var results = result.split("-")
	
	var grid = hbox.get_child(2)
	grid.get_child(0).text = str(data.size)
	grid.get_child(2).text = "%18s " % data.playerWhiteName
	grid.get_child(3).text = results[0]
	grid.get_child(5).text = "%2d'+%2d\"" % [data.time / 60, data.increment]
	
	grid.get_child(6).text = "+%3.1f" % (data.komi as float / 2)
	grid.get_child(8).text = "%18s " % data.playerBlackName
	grid.get_child(9).text = results[1]
	grid.get_child(11).text = "+%d@%d" % [data.triggerTime / 60, data.triggerMove] if data.triggerTime > 0 else ""
	
	hbox.get_child(4).text = Time.get_datetime_string_from_unix_time(date, true)
	hbox.get_child(5).pressed.connect(loadGame.bind(data, notation))
	hbox.get_child(6).URL = "https://playtak.com/games/%s/ninjaviewer" % data.id
	
	add_child(entry)
	if get_child_count() % 2:
		entry.theme_type_variation = &"PanelDark"
	else:
		entry.theme_type_variation = &"PanelLight"


func parseResults(result:int, response_code: int, header: PackedStringArray, body: PackedByteArray):
	clear()
	var json: Dictionary = JSON.parse_string(body.get_string_from_utf8()) #TODO error handling
	
	
	maxPage = json["totalPages"]
	pageLabel.text = " %d-%d / %d " % [(json["page"]-1) * json["perPage"] + 1, min(json["page"] * json["perPage"], json["total"]), json["total"]]
	
	for entry in json["items"]:
		#TODO rating (and rating-change)
		#TODO timestamp formatting?
		var data: GameData = GameData.new(str(entry["id"]), entry["size"], GameData.LOCAL, GameData.LOCAL, 
		entry["player_white"], entry["player_black"], entry["timertime"], entry["timerinc"], entry["extra_time_trigger"], entry["extra_time_amount"], 
		entry["komi"], entry["pieces"], entry["capstones"])
		appendEntry(data, entry["result"], entry["date"] / 1000 + tz, entry["notation"])


func loadGame(data: GameData, notation: String):
	if GameLogic.active and not (GameLogic.gameData.isObserver() or GameLogic.gameData.isScratch()):
		Notif.message("End the ongoing game first!")
		return
		
	GameLogic.doSetup(data)
	if notation.is_empty(): return
	for i in notation.split(","):
		GameLogic.doMove(self, Ply.fromPlayTak(i, null))
