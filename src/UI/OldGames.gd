extends GridContainer
class_name OldGames

const GAMES_URL = "https://api.playtak.com/v1/games-history?"

@onready var http = HTTPRequest.new()


func _ready():
	add_child(http) #TODO this will be removed by clear
	http.request_completed.connect(parseResults)
	makeSearch({"page":0, "limit":50, "mirror":true})


func makeSearch(queries: Dictionary):
	var q = GAMES_URL
	for i in queries:
		q += i + "=" + str(queries[i]) + "&"
		
	q.rstrip("&")
	http.request(q)


func clear():
	for i in get_children():
		remove_child(i)


func appendEntry(data: Array[String]):
	assert(data.size() == 10)
	
	var label: Label
	for i in 9:
		label = Label.new()
		label.text = data[i]
		add_child(label)
	
	var button = Button.new()
	button.text = "Load"
	button.pressed.connect(loadGame.bind(data[9]))
	add_child(button)
	
	button = URLButton.new()
	button.text = "PTN.NINJA"
	button.URL = "https://playtak.com/games/%s/ninjaviewer" % data[0] #TODO dont pass this through playtak
	add_child(button)


func parseResults(result:int, response_code: int, header: PackedStringArray, body: PackedByteArray):
	var json: Dictionary = JSON.parse_string(body.get_string_from_utf8()) #TODO error handling
	
	for entry in json["items"]:
		#TODO clock
		#TODO rating (and rating-change)
		#TODO timestamp formatting?
		var data:Array[String] = [str(entry["id"]), str(entry["size"]), str(entry["komi"] as float / 2), 
		"00:00", entry["player_white"], entry["player_black"], entry["result"], 
		Time.get_datetime_string_from_unix_time(entry["date"]/1000, true), 
		"unrated" if entry["unrated"] == 1 else "tournament" if entry["tournament"] == 1 else "normal", entry["notation"]] 
		appendEntry(data)


func loadGame(notation: String):
	print("loading: " + notation)
