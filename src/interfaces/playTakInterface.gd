extends Node

const url = "wss://playtak.com/ws"
const maxTimeout = 5 #in seconds

var socket: WebSocketPeer = WebSocketPeer.new()
var active: bool = false
var activeUsername: String = ""
var activePass: String = "" 

const ratingURL = "https://api.playtak.com/v1/ratings/%s"
@onready var http = HTTPRequest.new()
var ratingList: Dictionary = {} # User [rating, lastFetch]
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
	http.request_completed.connect(parseRatingFetch)
	#ratingFetch()


func getConnect():
	if active: return false #already active
	socket.supported_protocols = PackedStringArray(["binary"])
	
	var err = socket.connect_to_url(url)
	if err != OK:
		Notif.message("Could not reach the playtak server!")
		return false
	
	if not await expectPacket("Welcome!"): return false
	if not await expectPacket("Login or Register"): return false
	
	socket.send_text("Client Attak")
	if not await expectPacket("OK"): return false
	
	socket.send_text("Protocol 2")
	if not await expectPacket("OK"): return false
	
	return true


func signIn(username: String, password: String) -> bool:
	Lock.show()
	if not await getConnect(): 
		Lock.hide()
		return false
	
	socket.send_text("Login %s %s" % [username, password])
	var packet = await awaitPacket() #confirmation or rejection

	if packet.begins_with("Welcome"):
		activeUsername = packet.substr(8, packet.length()-9)
		activePass = password
		active = true
		ChatTab.newChat("Global", Chat.GLOBAL)
		print("successfully logged in as %s" % activeUsername)
		login.emit(activeUsername)
		Lock.hide()
		return true
	
	elif packet == "":
		Notif.message("Server is not responding!")
		socket.close()
		Lock.hide()
		return false
	
	Notif.message("Invalid Login! (%s)" % packet)
	socket.close()
	Lock.hide()
	return false


func register(username: String, email: String) -> bool:
	Lock.show()
	if not await getConnect(): 
		Lock.hide()
		return false
		
	socket.send_text("Register %s %s" % [username, email])
	var packet = await awaitPacket() #confirmation or rejection
	
	if packet == "":
		Notif.message("Server is not responding!")
		socket.close()
		Lock.hide()
		return false

	if packet.begins_with("Registered"):
		Notif.message("Registered %s! check your email to login!" % username)
		print("successfully registered %s" % username)
		socket.close()
		Lock.hide()
		return true
		
	Notif.message("Failed to register! (%s)" % packet)
	socket.close()
	Lock.hide()
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
	var i = 0
	while socket.get_available_packet_count() < 1:
		i += .2
		await get_tree().create_timer(.2).timeout
		socket.poll()
		if i > maxTimeout:
			socket.close()
			Notif.message("Server not responding!")
			return ""
	return getPacket()


func expectPacket(packet) -> bool:
	var p = await awaitPacket()
	if p == "": return false
	elif p != packet:
		Notif.message("Expected \"%s\", but server sent \"%s\"" % [packet, p])
		socket.close()
		return false
	return true


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
		pingtime = 0.0
	
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
					komi.to_int(), flats.to_int(), caps.to_int(), SeekData.ratingType(unrated, tournament)
				)
				addGame.emit(game, id.to_int())
			
			["GameList", "Remove", var id, ..] when id != "0":
				removeGame.emit(id.to_int())
			
			["Observe", var id, var pw, var pb, var size, var time, var inc, var komi, var flats, var caps, var unrated, var tournament, var triggerMove, var triggerAmount]:
				var game = GameData.new(
					id, size.to_int(), 
					GameData.PLAYTAK, GameData.PLAYTAK, pw, pb, 
					time.to_int(), inc.to_int(), triggerMove.to_int(), triggerAmount.to_int(), 
					komi.to_int(), flats.to_int(), caps.to_int(), SeekData.ratingType(unrated, tournament)
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
			
			["Accept", "Rematch", var id]:
				acceptSeek(int(id))
			
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
				endGame(GameState.DEFAULT_WIN_BLACK if player == GameLogic.gameData.playerWhiteName else GameState.DEFAULT_WIN_WHITE)
			
			["Seek", "new", var id, var name, var size, var time, var inc, var color, var komi, var flats, var caps, var unrated, var tourney, var trigger, var extra, var opponent, var bot]:
				if opponent != "0" and opponent.to_lower() != activeUsername.to_lower() and name != activeUsername:
					break
				var seek = SeekData.new(
					name, bot == "1", size.to_int(), time.to_int(), inc.to_int(), trigger.to_int(), extra.to_int(),
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
			
			["Online", var count]:
				pass #TODO
				
			["OnlinePlayers", ..]:
				pass #TODO
			
			["NOK"]:
				print("NOK") #TODO
			
			["OK"]:
				pass
			
			_:
				print("Unparsed Message:")
				print(packet)


func getRating(user: String):
	if user.begins_with("Guest"): return -1
	
	if user in ratingList:
		return ratingList[user]
	
	else:
		while http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
			await http.request_completed
		http.request(ratingURL % user)
		await http.request_completed
		return ratingList.get(user, -1)


func parseRatingFetch(result:int, response_code: int, header: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	ratingList[json["name"]] = json["rating"]


func startGame(data: PackedStringArray):
	var game = makeGame(data)
	GameLogic.doSetup(game)
	
	GameLogic.move.connect(sendMove)
	GameLogic.drawRequest.connect(sendDraw)
	GameLogic.undoRequest.connect(sendUndo)
	GameLogic.resign.connect(resign)
	
	var opponent = data[3] if data[6] == "black" else data[5]
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


func sendRematch():
	var d = GameLogic.gameData
	var opp = d.playerWhiteName if d.playerWhite == d.PLAYTAK else d.playerBlackName
	var c = "W" if d.playerWhite == d.PLAYTAK else "B"
	assert(d.playerBlack == d.LOCAL or d.playerWhite == d.LOCAL, "CANT REMATCH A GAME YOURE NOT A PART OF!")
	assert(d.playerBlack == d.PLAYTAK or d.playerWhite == d.PLAYTAK, "CANT REMATCH A NON-PLAYTAK GAME!")
	
	socket.send_text( 
		"Rematch %s %d %d %d %s %d %d %d %d %d %d %d %s" % [d.id, d.size, d.time, d.increment, c, d.komi, d.flats, d.caps, 
		1 if d.rated == SeekData.UNRATED else 0, 1 if d.rated == SeekData.TOURNAMENT else 0, d.triggerMove, d.triggerTime, opp]
	)


func acceptSeek(seek: int):
	socket.send_text("Accept " + str(seek))


func makeGame(data: PackedStringArray) -> GameData:
	var pWhite = GameData.PLAYTAK if data[6] == "black" else GameData.LOCAL
	var pBlack = GameData.PLAYTAK if data[6] == "white" else GameData.LOCAL
	
	return GameData.new(
		data[2], #id
		data[7].to_int(), #size 
		pWhite,
		pBlack,
		data[3], #pw
		data[5], #pb
		data[8].to_int(), #time
		data[9].to_int(), #increment
		data[15].to_int(), #triggermove
		data[16].to_int(), #triggertime
		data[10].to_int(),  #komi
		data[11].to_int(), #flats
		data[12].to_int(), #caps
		SeekData.ratingType(data[13], data[14])
		)
		
