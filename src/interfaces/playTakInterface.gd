extends Node

const url = "ws://playtak.com:9999/ws" #WARNING TODO? unsecured connection?? (is it actually?)

var socket: WebSocketPeer = WebSocketPeer.new()
var active: bool = false
var activeUsername: String = ""
var activePass: String = "" #WARNING having this in ram is *not* secure, but we need it to re-establish broken connections somehow, and i dont think a playtak account is critical, so....

const ratingURL = "http://playtak.com/ratinglist.json"
@onready var http = HTTPRequest.new()
var ratingList: Dictionary = {}
var bots = []

var pingtime: float = 0
var t: float

signal addSeek(seek: SeekData, id: int)
signal removeSeek(id: int)

signal addGame(game: GameData, id: int)
signal removeGame(id: int)

signal login(username: String)
signal logout
signal ratingUpdate

func _ready():
	GameLogic.end.connect(handleUnobserve)
	
	add_child(http)
	http.request_completed.connect(parseRatings)
	http.request(ratingURL)


func signInGuest() -> bool:
	return await signIn("Guest", "")


func signIn(username: String, password: String) -> bool:
	if active: return false #already active
	
	socket.supported_protocols = PackedStringArray(["binary"])
	
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Unable to connect")
		Notif.message("Could not reach the playtak server!")
		return false
	
	var packet: String = await awaitPacket() #should be welcome packet
	packet = await awaitPacket() #should be login request

	socket.send_text("Login %s %s" % [username, password])
	packet = await awaitPacket() #confirmation or rejection
	
	if packet.begins_with("Welcome"):
		activeUsername = packet.substr(8, packet.length()-9)
		activePass = password
		active = true
		ChatTab.newChat("Global", Chat.GLOBAL)
		print("successfully logged in as %s" % activeUsername)
		login.emit(activeUsername)
		return true
	
	print("failed to login")
	Notif.message("Invalid Login!")
	socket.close()
	return false


func onLogout():
	active = false

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close()

	while socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		await get_tree().create_timer(.1).timeout
		socket.poll()

	
	
	logout.emit()
	ChatTab.clear()
	
	activeUsername = ""


func awaitPacket() -> String:
	while socket.get_available_packet_count() < 1:
		await get_tree().create_timer(.1).timeout
		socket.poll()
	return getPacket()


func getPacket() -> String:
	return socket.get_packet().get_string_from_utf8().rstrip("\n")


func _process(delta: float):
	if not active: return
	
	var nt = Time.get_unix_time_from_system()
	
	socket.poll()

	var state = socket.get_ready_state()
	if state != WebSocketPeer.STATE_OPEN:
		var u = activeUsername
		onLogout()
		if socket.get_close_code() == -1:
			print("disconnected. was idle for %fs" % (nt - t))
			if (nt - t) > 30:
				if not await signIn(u, activePass):
					Notif.message("Disconnected Unexpectedly!", false)
					return
			else:
				Notif.message("You were disconnected")
				return
		else:
			print("websocket closed with code %d, reason: %d | trying to reconnect" % [socket.get_close_code(), socket.get_close_reason()])
			if not await signIn(u, activePass):
				Notif.message("Disconnected Unexpectedly!", false)
				return
	
	pingtime += nt - t
	if pingtime >= 30:
		socket.send_text("PING")
		pingtime -= 30
	
	if nt - t > 1:
		print("dt > 1! -> %fs" % (nt - t))
	if delta > 1:
		print("delta > 1! -> %fs" % delta)
	
	t = nt
	
	
	var packet
	while socket.get_available_packet_count():
		packet = getPacket()
		var data = packet.replace("#", " ").split(" ") #TODO BUG this will replace #'s in messages
		match Array(data):
			["GameList", "Add", var id, var pw, var pb, var size, var time, var inc, var komi, var flats, var caps, var unrated, var tournament, var triggerMove, var triggerAmount]:
				var game = GameData.new(
					id, size.to_int(),
					GameData.PLAYTAK, GameData.PLAYTAK, pw, pb, 
					time.to_int(), inc.to_int(), triggerMove.to_int(), triggerAmount.to_int(),
					komi.to_int(), flats.to_int(), caps.to_int()
				)
				addGame.emit(game, id.to_int())
			
			["GameList", "Remove", var id, ..] when id != "0":
				removeGame.emit(id.to_int())
			
			["Observe", var id, var pw, var pb, var size, var time, var inc, var komi, var flats, var caps, var unrated, var tournament, var triggerMove, var triggerAmount]:
				var game = GameData.new(
					id, size.to_int(), GameData.PLAYTAK, GameData.PLAYTAK, pw, pb, time.to_int(), inc.to_int(), triggerMove.to_int(), triggerAmount.to_int(), komi.to_int(), flats.to_int(), caps.to_int()
				)
				GameLogic.doSetup(game)
				var players=[pw,pb]
				players.sort()
				var room = "-".join(players)
				if room in ChatTab.rooms:
					ChatTab.select(ChatTab.rooms[room])
				else:
					socket.send_text("JoinRoom "+room)
			
			["Game", "Start", ..]:
				startGame(data)
			
			["Game", var id, "P", var sq, ..] when id == GameLogic.gameData.id:
				var type = Place.TYPE.FLAT if data.size() == 4 else Place.TYPE.WALL if data[4] == "W" else Place.TYPE.CAP
				var ply = Place.new(Ply.getTile(sq), type)
				GameLogic.doMove(self, ply)
				
			["Game", var id, "M", var sq1, var sq2, ..] when id == GameLogic.gameData.id:
				var tile1 = Ply.getTile(sq1)
				var tile2 = Ply.getTile(sq2)
				var smash = false
				var dir
				if tile2.x == tile1.x:
					dir = Spread.DIRECTION.UP if tile2.y > tile1.y else Spread.DIRECTION.DOWN
				else:
					dir = Spread.DIRECTION.RIGHT if tile2.x > tile1.x else Spread.DIRECTION.LEFT
				var drops: Array[int] = []
				for i in data.slice(5):
					drops.append(i.to_int())
				GameLogic.doMove(self, Spread.new(tile1, dir, drops, smash))
				
			["Game", var id, "Time", var timeW, var timeB] when id == GameLogic.gameData.id:
				GameLogic.timeSync(timeW.to_int() * 1000, timeB.to_int() * 1000)
			
			["Game", var id, "Timems", var timeW, var timeB] when id == GameLogic.gameData.id:
				GameLogic.timeSync(timeW.to_int(), timeB.to_int())
			
			["Game", var id, "Over", var result] when id == GameLogic.gameData.id:
				endGame(GameState.resultStrings.find(result))
				
			["Game", var id, "OfferDraw"] when id == GameLogic.gameData.id:
				GameLogic.drawRequest.emit(self, false)
			
			["Game", var id, "RemoveDraw"] when id == GameLogic.gameData.id:
				GameLogic.drawRequest.emit(self, true)
			
			["Game", var id, "RequestUndo"] when id == GameLogic.gameData.id:
				GameLogic.undoRequest.emit(self, false)
			
			["Game", var id, "RemoveUndo"] when id == GameLogic.gameData.id:
				GameLogic.undoRequest.emit(self, true)
			
			["Game", var id, "Undo"] when id == GameLogic.gameData.id:
				GameLogic.doUndo()
			
			["Game", var id, "Abandoned.", var player, "quit"] when id == GameLogic.gameData.id:
				endGame(GameState.DEFAULT_WIN_WHITE if player == GameLogic.gameData.playerWhiteName else GameState.DEFAULT_WIN_BLACK)
			
			["Seek", "new", var id, var name, var size, var time, var inc, var color, var komi, var flats, var caps, var unrated, var tourney, var trigger, var extra, var opponent] when opponent == "" or opponent == activeUsername:
				var seek = SeekData.new(
					name, size.to_int(), time.to_int(), inc.to_int(), trigger.to_int(), extra.to_int(),
					color, komi.to_int(), flats.to_int(), caps.to_int(), 
					SeekData.TOURNAMENT if tourney == "1" else SeekData.UNRATED if unrated == "1" else SeekData.RATED
				)
				addSeek.emit(seek, id.to_int())
			
			["Seek", "remove", var id, ..]:
				removeSeek.emit(id.to_int())
			
			["Shout", var user, ..]:
				ChatTab.parseMsg("Global", user.lstrip("<").rstrip(">"), " ".join(data.slice(2)))
				
			["Joined", "room", var room]:
				ChatTab.newChat(room, Chat.ROOM)
			
			["Left", "room", var room]:
				pass #not sure if this even ever happens, playtak doesnt seem to handle it 
				#well perhaps i was stupid for writing that ^
				#because i realize that we probably *should* tell playtak that we left the room, so we dont get messages from it
			
			["ShoutRoom", var room, var user, ..]:
				ChatTab.parseMsg(room, user.lstrip("<").rstrip(">"), " ".join(data.slice(3)))
				
			["Tell", var user, ..]:
				ChatTab.parseMsg("", user.lstrip("<").rstrip(">"), " ".join(data.slice(2)))
			
			["Told", var user, ..]:
				ChatTab.parseMsg(user.lstrip("<").rstrip(">"), activeUsername, " ".join(data.slice(2))) #BUG* technically, if you send a msg in a private, and close the tab before getting this response, it will think it is a room instead of private, unlikely to happen though, and equally unlikely to cause real issues
			
			["Message", ..]:
				print(packet)
				Notif.message(packet.substr(8))
			
			["NOK"]:
				print("NOK") #TODO
			
			["OK"]:
				pass
			
			_:
				print("Unparsed Message:")
				print(packet)
				


func parseRatings(result:int , response_code: int, header: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		pass
	
	else:
		#Array[ [" ".join(unames), activeRating, rating, gamesplayed, isBot ]   ]
		var json: Array = JSON.parse_string(body.get_string_from_utf8())
		ratingList = {}
		bots = []
		for entry in json:
			for username in entry[0].split(" "):
				if entry[4] == 1:
					bots.append(username)
				ratingList[username] = entry[2]
		ratingUpdate.emit()
	
	# target time is 10m past the hour, + random to avoid ddos
	# last +3600 is because % can (and in this case always will) return negative
	var offset = (600 + randi_range(5, 300) - Time.get_unix_time_from_system() as int) % 3600 + 3600
	get_tree().create_timer(offset).timeout.connect(func(): http.request(ratingURL)) #BUG this loop breaks if we get no response


func startGame(data: PackedStringArray):
	var game = makeGame(data)
	GameLogic.doSetup(game)
	
	GameLogic.move.connect(sendMove)
	GameLogic.drawRequest.connect(sendDraw)
	GameLogic.undoRequest.connect(sendUndo)
	GameLogic.resign.connect(resign)
	
	var opponent = data[4] if data[7] == "black" else data[6]
	if not opponent in ChatTab.rooms:
		ChatTab.newChat(opponent, Chat.PRIVATE)


func resign():
	socket.send_text("Game#" + GameLogic.gameData.id + " Resign")


func endGame(type: int):
	GameLogic.endGame(type)
	if GameLogic.gameData.isObserver(): return  #we werent connected, so dont disconnect
	
	GameLogic.move.disconnect(sendMove)
	GameLogic.drawRequest.disconnect(sendDraw)
	GameLogic.undoRequest.disconnect(sendUndo)
	GameLogic.resign.disconnect(resign)


func handleUnobserve(type: int):
	if GameLogic.gameData.isObserver() and GameLogic.active:
		socket.send_text("Unobserve %s" % GameLogic.gameData.id)


func sendMove(origin: Node, ply: Ply):
	if origin == self: return #prevents the client from sending received moves back
	var t = ply.toPlayTak()
	socket.send_text("Game#" + GameLogic.gameData.id + " " + ply.toPlayTak().to_upper())


func sendDraw(origin: Node, revoke: bool):
	if origin == self: return #prevents the client from sending received moves back
	socket.send_text("Game#" + GameLogic.gameData.id + " " + ("RemoveDraw" if revoke else "OfferDraw"))


func sendUndo(origin: Node, revoke: bool):
	if origin == self: return #prevents the client from sending received moves back
	socket.send_text("Game#" + GameLogic.gameData.id + " " + ("RemoveUndo" if revoke else "RequestUndo"))


func sendToGame(msg: String):
	socket.send_text("Game#" + GameLogic.gameData.id + " " + msg)


func sendSeek(seek: SeekData):
	socket.send_text(
		"Seek %d %d %d %s %d %d %d %d %d %d %d %s" % [seek.size, seek.time, seek.increment, ["A","W","B"][seek.color], seek.komi, seek.flats, seek.caps, 
		1 if seek.rated == SeekData.UNRATED else 0, 1 if seek.rated == SeekData.TOURNAMENT else 0, seek.triggerMove, seek.triggerTime, seek.playerName])


func acceptSeek(seek: int):
	socket.send_text("Accept " + str(seek))


func makeGame(data: PackedStringArray) -> GameData:
	var pWhite = GameData.PLAYTAK if data[7] == "black" else GameData.LOCAL
	var pBlack = GameData.PLAYTAK if data[7] == "white" else GameData.LOCAL
	
	return GameData.new(
		data[2], #id
		data[3].to_int(), #size 
		pWhite,
		pBlack,
		data[4], #pw
		data[6], #pb
		data[8].to_int(), #time
		0, #for *some* god forsaken reason, playtak doesnt send increment time on game start.....
		data[12].to_int(), #triggermove
		data[13].to_int(), #triggertime
		data[9].to_int(),  #komi
		data[10].to_int(), #flats
		data[11].to_int()) #caps
